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

      "mc.nasirk.ca" = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://localhost:25565";
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 3000 ]; # Allow HTTP/S
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "nasir@nasirk.ca";
}

