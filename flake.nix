{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  inputs.deploy-rs.url = "github:serokell/deploy-rs";
  inputs.easyshort.url = "github:stdcout1/easyshort";

  outputs =
    inputs@{ self
    , nixpkgs
    , disko
    , nixos-facter-modules
    , deploy-rs
    , ...
    }:
    let
      system = "x86_64-linux";
    in
    {
      # Slightly experimental: Like generic, but with nixos-facter (https://github.com/numtide/nixos-facter)
      # nixos-anywhere --flake .#generic-nixos-facter --generate-hardware-config nixos-facter facter.json <hostname>
      nixosConfigurations.generic-nixos-facter = nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          disko.nixosModules.disko
          ./nginx.nix
          ./configuration.nix
          nixos-facter-modules.nixosModules.facter
          {
            config.facter.reportPath =
              if builtins.pathExists ./facter.json then
                ./facter.json
              else
                throw "Have you forgotten to run nixos-anywhere with `--generate-hardware-config nixos-facter ./facter.json`?";
          }
        ];
        specialArgs = { inherit inputs; };
      };
      deploy.nodes.server = {
        hostname = "mc.nasirk.ca";
        sshUser = "root";
        sshOpts = [ "-i" "~/.ssh/server" ]; # or use ssh-agent
        profiles.server = {
          user = "root";
          magicRollback = false;
          path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.generic-nixos-facter;
        };
      };
    };
}
