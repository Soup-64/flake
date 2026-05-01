{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ../core.nix
    ./hardware-configuration.nix
    ./ratoverlay.nix
  ];

  networking.hostName = "Auburn";
  system.stateVersion = "24.11";
  # This should append based on how nix works
  users.users.soup.extraGroups = ["libvirtd"];

  fileSystems."/mnt/backup" =
    { device = "/dev/disk/by-uuid/1ddcfd3d-735e-4b99-8b5a-117edb7b6d95";
      fsType = "ext4";
      options =  [ "auto" "nofail" ];
    };

  boot.kernelParams = [
    "amd_pstate=active"
    "video=DP-2:2560x1440@144"
    "video=DP-3:1024x768@85"
  ];
  hardware.amdgpu.overdrive.enable = true;

  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 33*1024;
  } ];

  hardware.graphics = {
  enable = true;
  enable32Bit = true;
   extraPackages = with pkgs; [
      libva-utils
      rocmPackages.clr.icd
    ];
  };

  systemd.tmpfiles.rules =
  let
    rocmEnv = pkgs.symlinkJoin {
      name = "rocm-combined";
      paths = with pkgs.rocmPackages; [
        rocblas
        hipblas
        clr
      ];
    };
  in [
    "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
    "L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware"
  ];

  virtualisation.waydroid.enable = true;

  environment.systemPackages = with pkgs; [
    freecad
    blender
    lact
  ];

  #fix for qemu network bridging
  networking.firewall.trustedInterfaces = [ "virbr0" "wlp3s0" ];

  services.lact.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
  };

  services.smartd.devices = [
    { device = "/dev/disk/by-id/nvme-SOLIDIGM_SSDPFKKW010X7_SJC2N419710102C1L"; }
#     { device = "/dev/disk/by-id/ata-TEAM_TM8PS7001T_AA000000000000000161"; } #fucking bios
  ];
}
