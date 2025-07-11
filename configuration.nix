{ modulesPath
, lib
, pkgs
, ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    ./apps/easyshort.nix
    ./apps/qmovie.nix
    ./apps/minecraft.nix
  ];

  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://nasirserver.cachix.org"
    ];
    trusted-public-keys = [
      "nasirserver.cachix.org-1:V5YL2N0XRm2FEmHtDqmtNzGE/+hCC9J+YWDuNO0vr3o="
    ];
  };
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLanevb0IASiaiJgo4SNo0XEbKEcW5d+w58xGMFOXdb nasir@laptop"
  ];

  system.stateVersion = "24.05";
}
