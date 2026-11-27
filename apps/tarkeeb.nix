{ config, pkgs, inputs, ... }:

# tarkeeb (github:stdcout1/tarkeebtool, docs/deployment.md there): the web app and the grammar
# graphs as static files from nginx, the API behind it on localhost, Postgres over its socket.
# The tarkeebtool repo's workflow bumps the `tarkeeb` input in flake.lock on every push to its
# master, which deploys it.
let
  tarkeeb = inputs.tarkeeb.packages.${pkgs.stdenv.hostPlatform.system}.tarkeeb;
  domain = "tarkeeb.nasirk.ca";
  port = 3002; # localhost only; not in the firewall
  pgPort = toString config.services.postgresql.settings.port;
in
{
  users.users.tarkeeb = {
    isSystemUser = true;
    group = "tarkeeb";
  };
  users.groups.tarkeeb = { };

  # The role matches the system user, so the socket needs no password.
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "tarkeeb" ];
    ensureUsers = [
      {
        name = "tarkeeb";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.tarkeeb = {
    description = "tarkeeb API";
    wantedBy = [ "multi-user.target" ];
    # postgresql-setup.service creates the database in newer nixpkgs; After= ignores it if absent.
    after = [ "network.target" "postgresql.service" "postgresql-setup.service" ];
    requires = [ "postgresql.service" ];

    environment = {
      DATABASE_URL = "postgresql://tarkeeb@/tarkeeb?host=/run/postgresql&port=${pgPort}";
      API_HOST = "127.0.0.1";
      API_PORT = toString port;
      NODE_ENV = "production";
    };

    serviceConfig = {
      User = "tarkeeb";
      Group = "tarkeeb";
      # Schema first, then the books (idempotent). The seed refuses to change a sentence a learner
      # has worked on: then the start fails and deploy-rs rolls back to the previous generation.
      ExecStartPre = [
        "${tarkeeb}/bin/tarkeeb-migrate"
        "${tarkeeb}/bin/tarkeeb-seed"
      ];
      ExecStart = "${tarkeeb}/bin/tarkeeb-api";
      Restart = "always";
      RestartSec = 5;

      NoNewPrivileges = true;
      PrivateTmp = true; # tsx keeps its compile cache in /tmp
      PrivateDevices = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
    };
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    root = "${tarkeeb}/share/tarkeeb/web";

    # The web app routes in the browser: unknown paths get index.html.
    locations."/".tryFiles = "$uri $uri/ /index.html";
    locations."= /index.html".extraConfig = ''
      add_header Cache-Control "no-cache";
    '';
    # Vite puts a content hash in every file name here.
    locations."/assets/".extraConfig = ''
      add_header Cache-Control "public, max-age=31536000, immutable";
    '';

    # X-Forwarded-Proto from the recommended settings is what gives the session cookie `Secure`.
    locations."/api/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      recommendedProxySettings = true;
    };

    # The grammar-registry graphs (npm run graph): plain SVGs that link to each other.
    locations."= /graph".return = "301 /graph/";
    locations."/graph/" = {
      alias = "${tarkeeb}/share/tarkeeb/grammar-graph/";
      index = "overview.svg";
      extraConfig = ''
        add_header Cache-Control "no-cache";
      '';
    };
  };
}
