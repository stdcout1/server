{ inputs, pkgs, lib, ... }:
let
  modpack = pkgs.fetchPackwizModpack {
    url = "https://raw.githubusercontent.com/stdcout1/minecraft-modpack/refs/heads/main/pack.toml";
    packHash = "sha256-673FyhzDKh6t4bTSK5Exg7KjvFuMePwdTQrsbPeravM=";
  };
  neoforgeServer =
    let
      version = modpack.manifest.versions.neoforge;
      installer = pkgs.fetchurl {
        pname = "neoforge-installer";
        inherit version;
        url = "https://maven.neoforged.net/releases/net/neoforged/neoforge/${version}/neoforge-${version}-installer.jar";
        hash = "sha256-msilqkXu1EcG3YwZxsYehi18OPOzh/wGCbk9C6x9rF4=";
      };
      java = "${pkgs.jdk21}/bin/java";
    in
    pkgs.writeShellScriptBin "server" ''
      if ! [ -e "./libraries/net/neoforged/neoforge/${version}/unix_args.txt" ]; then
        ${java} -jar ${installer} --installServer
      fi
      exec ${java} $@ @libraries/net/neoforged/neoforge/${version}/unix_args.txt nogui 
    '';
in
{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];
  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "minecraft-server"
  ];
  # nothing to override; just makes sure the module is loaded
  services.minecraft-servers = {
    enable = true;
    eula = true;
  };


  services.minecraft-servers.servers.cool-modpack = {
    enable = true;
    package = neoforgeServer;
    jvmOpts = "-Xmx6G -Xms6G";
    serverProperties = {
      level-type = "biomesoplenty";
      difficulty = "normal";
    };
    symlinks = {
      "mods" = "${modpack}/mods";
    };
  };
}
