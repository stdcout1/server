{ inputs, pkgs, lib, ... }:
let
  modpack = pkgs.fetchPackwizModpack {
    url = "https://raw.githubusercontent.com/stdcout1/minecraft-modpack/refs/heads/main/pack.toml";
    packHash = "sha256-/WVfLaXL5jXzLZEj4ZWXJScjBlDeDQU2pStLzWqNBIw=";
  };
  neoforgeServer =
    let
      version = modpack.manifest.versions.neoforge;
      installer = pkgs.fetchurl {
        pname = "neoforge-installer";
        inherit version;
        url = "https://maven.neoforged.net/releases/net/neoforged/neoforge/${version}/neoforge-${version}-installer.jar";
        hash = "sha256-QfJ7zph0/bUQQOt2yomDDEng3QvkJhqdq7qzzXyfFoc=";
      };
      java = "${pkgs.jdk21}/bin/java";
    in
    pkgs.writeShellScriptBin "server" ''
      if ! [ -e "neoforge-${version}.jar" ]; then
        ${java} -jar ${installer} --installServer
      fi
      exec ${java} $@ -jar forge-${version}.jar nogui
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
    jvmOpts = "-Xmx8G -Xms8G";
    serverProperties = {
      level-type = "biomesoplenty";
      difficulty = "normal";
    };
    symlinks = {
      "mods" = "${modpack}/mods";
    };
  };
}
