{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;

    virtualHosts = {
      "backend.sh.nasirk.ca" = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://localhost:3000";
        };
      };

      "qmovie.nasirk.ca" = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://127.0.0.1:3001";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };

    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 3000 3001 25565 ]; # Allow HTTP/S
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "nasir@nasirk.ca";
}

