{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../core.nix
    ../desktop.nix
    ./hardware-configuration.nix
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  # NIX SETTINGS

  networking.hostName = "Selenium";
  system.stateVersion = "26.05";

  # HARDWARE

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4 * 1024;
    }
  ];

  services.smartd = {
    devices = [
      { device = "/dev/disk/by-id/nvme-UMIS_RPETJ512MMW1MDQ_SS1D71551X1RC5664AVV"; }
    ];
  };

  # GOF5

  environment.systemPackages = with pkgs; [
#   gof5
  ];
}
