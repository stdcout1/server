{ inputs, pkgs, lib, ... }:
let
  modpack = pkgs.fetchPackwizModpack {
    url = "https://raw.githubusercontent.com/stdcout1/minecraft-modpack/refs/heads/main/pack.toml";
    packHash = "sha256-673FyhzDKh6t4bTSK5Exg7KjvFuMePwdTQrsbPeravM=";
  };

  atm9 = pkgs.fetchzip {
    url = "https://www.curseforge.com/api/v1/mods/715572/files/6451435/download";
    hash = "";
    extension = "zip";
    stripRoot = true;
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

  forgeServer =
    let
      version = "1.20.1-47.4.0";
      installer = pkgs.fetchurl {
        pname = "forge-installer";
        inherit version;
        url = "https://maven.minecraftforge.net/net/minecraftforge/forge/${version}/forge-${version}-installer.jar";
        hash = "sha256-8/V0ZeLL3DKBk/d7p/DJTLZEBfMe1VZ1PZJ16L3Abiw=";
      };
      java = "${pkgs.jdk21}/bin/java";
    in
    pkgs.writeShellScriptBin "server" ''
      if ! [ -e "./libraries/net/minecraftforge/forge/${version}/unix_args.txt" ]; then
        ${java} -jar ${installer} --installServer
      fi
      exec ${java} $@ @libraries/net/minecraftforge/forge/${version}/unix_args.txt nogui 
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


  services.minecraft-servers.servers = {
    cool-modpack = {
      enable = false;
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

    atm9 = {
      enable = true;
      package = forgeServer;
      jvmOpts = "-Xmx6G -Xms6G";
      serverProperties = {
        level-type = "biomesoplenty";
        difficulty = "normal";
        allow-flight = true;
        max-tick-time = 180000;
      };
      files = {
        config = "${atm9}/config";
        defaultconfigs = "${atm9}/defaultconfigs";
        kubejs = "${atm9}/kubejs";
      };
      symlinks = {
        mods = "${atm9}/mods";
        "server-icon.png" = "${atm9}/server-icon.png";
      };
    };
  };
}
