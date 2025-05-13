{ config, pkgs, inputs, ... }:

let
  jackettDir = "/var/lib/jackett";
  jackettPackage = pkgs.jackett;
  qmovie = inputs.qmovie.packages.${pkgs.system}.qmovie { cachePath = "/var/cache/qmovie"; };
in
{
  environment.systemPackages = with pkgs; [
    openssl
    prisma-engines
    nodePackages.prisma
  ];
  systemd.services.jackett = {
    description = "Jackett Daemon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      WorkingDirectory = jackettDir;
      Environment = "DOTNET_EnableDiagnostics=0";
      ExecStart = "${pkgs.bash}/bin/sh ${jackettDir}/jackett_launcher.sh";
      Restart = "always";
      RestartSec = 5;
      TimeoutStopSec = 30;
    };
  };

  systemd.services.qmovie = {
    path = [ pkgs.pnpm ];
    description = "qmovie";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      WorkingDirectory = "${qmovie}/lib/node_modules/qmovie";
      Type = "simple";
      # ExecStart = "${pkgs.bash}/bin/sh ${qmovie}/bin/qmovie";
      CacheDirectory = "qmovie";
      ExecStart = "${qmovie}/lib/node_modules/qmovie/node_modules/.bin/next start -p 3001";
      Environment = [
        "PRISMA_QUERY_ENGINE_BINARY=${pkgs.prisma-engines}/bin/query-engine"
        "PRISMA_QUERY_ENGINE_LIBRARY=${pkgs.prisma-engines}/lib/libquery_engine.node"
        "PRISMA_SCHEMA_ENGINE_BINARY=${pkgs.prisma-engines}/bin/schema-engine"
      ];
      #make sure this is here. and to copy over a sutible jackett config
      EnvironmentFile = "/root/.env";
      Restart = "always";
    };
  };

  system.activationScripts.jackett-init = ''
    mkdir -p ${jackettDir}
    if [ ! -f ${jackettDir}/jackett_launcher.sh ]; then
      echo "#!/bin/sh" > ${jackettDir}/jackett_launcher.sh
      echo "exec ${jackettPackage}/bin/Jackett" >> ${jackettDir}/jackett_launcher.sh
      chmod +x ${jackettDir}/jackett_launcher.sh
    fi
  '';
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    authentication = ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
    initialScript = pkgs.writeText "init.sql" ''
      CREATE ROLE nasir WITH LOGIN PASSWORD 'nasir';
      CREATE DATABASE db OWNER nasir;

      \c db

      -- Ensure the nasir user has full access to the public schema
      GRANT ALL PRIVILEGES ON SCHEMA public TO nasir;
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO nasir;
      GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO nasir;    
    '';
  };

}


