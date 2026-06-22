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
    ./ratoverlay.nix
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  # NIX SETTINGS

  nix.settings.system-features = [
    "gccarch-znver3"
  ];

  networking.hostName = "Auburn";
  system.stateVersion = "24.11";
  # This should append based on how nix works
  #   users.users.soup.extraGroups = ["libvirtd" "beep"];

  # HARDWARE

  hardware.enableAllFirmware = true;
  services.lact.enable = true;

  # Beep! (broken/wip)
  users.groups.beep = { };
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="PC Speaker", ENV{DEVNAME}!="", GROUP="beep", MODE="0660"
  '';

  boot.kernelModules = [
    "pcspkr"
  ];

  fileSystems."/mnt/backup" = {
    device = "/dev/disk/by-uuid/1ddcfd3d-735e-4b99-8b5a-117edb7b6d95";
    fsType = "ext4";
    options = [
      "auto"
      "nofail"
    ];
  };

  boot.kernelParams = [
    "video=DP-2:2560x1440@144"
    "video=DP-3:1024x768@85"
  ];

  hardware.amdgpu.overdrive.enable = true;

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 33 * 1024;
    }
  ];

  # SOFTWARE

  virtualisation.waydroid.enable = true;

  environment.systemPackages = with pkgs; [
    lact
  ];

  # SERVICES

  services.smartd = {
    devices = [
      { device = "/dev/disk/by-id/nvme-SOLIDIGM_SSDPFKKW010X7_SJC2N419710102C1L"; }
      { device = "/dev/disk/by-id/ata-TEAM_TM8PS7001T_AA000000000000000161"; }
    ];
  };

}
