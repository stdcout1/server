{ config, pkgs, inputs, ... }:

let
  easyshort = inputs.easyshort.packages.${pkgs.system}.default;
in {
  systemd.services.easyshort = {
    description = "easyshort backend";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${easyshort}/bin/easyshort";
      Restart = "always";
    };
  };

  networking.firewall.allowedTCPPorts = [ 3000 ]; # or whatever your app uses
}

