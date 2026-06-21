{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ../core.nix
    ./hardware-configuration.nix
    inputs.lanzaboote-stable.nixosModules.lanzaboote
  ];

  # NIX SETTINGS

  networking.hostName = "Sienna";
  system.stateVersion = "25.11";

  # SYSTEM SETTINGS

  # Potential funnies with RT card
  hardware.enableAllFirmware = true;

  # Server auto stop start jobs
  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 19 * * *      soup    cd /home/soup/Desktop/mc/slopSMP; docker compose start >> /tmp/start.log"
      "0 1 * * *      soup    cd /home/soup/Desktop/mc/slopSMP; docker compose stop >> /tmp/stop.log"
    ];
  };

  # Fix card falling off and not working until link is cycled
  networking.networkmanager.settings = {
    #connection = {
    #  "ipv4.dhcp-client-id" = "mac";
    #  "ipv4.dhcp-vendor-class-identifier" = "MSFT 5.0";
    #};
    connectivity = {
      uri = "http://nmcheck.gnome.org/check_network_status.txt";
      response = "NetworkManager is online";
      interval = 300;
    };
  };

  boot.kernelParams = [
    "video=DP-2:2560x1440@60"
    "pcie_aspm=off" # more attempts at stabilizing network
    "pcie_port_pm=off" #hotswap incompat
  ];

  # SERVICES

  services.samba.nsswins = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  hardware.graphics.enable = true;
  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
  };
  #services.displayManager.enable = false;
  services.displayManager.ly.enable = true;
  services.displayManager.defaultSession = "xfce";

  fileSystems."/mnt/beta" =
    { device = "/dev/disk/by-label/beta";
      fsType = "ext4";
      options =  [ "auto" "nofail" ];
    };
  fileSystems."/mnt/mallow" =
    { device = "/dev/disk/by-label/Mallow";
      fsType = "ext4";
      options =  [ "auto" "nofail" ];
    };

  services.smartd = {
      devices = [
        { device = "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B7783D03CB8"; } #beta
        { device = "/dev/disk/by-id/nvme-KBG40ZNS256G_NVMe_KIOXIA_256GB_Z97PCCI9PTLL"; } #root
        #{ device = "/dev/disk/by-id/usb-JMicron_Generic_0123456789ABCDEF-0:0"; } #mallow
      ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.xrdp.enable = true;
  #services.xrdp.openFirewall = true; #3389
  services.xrdp.defaultWindowManager = "xfce4-session";

  networking.firewall.allowPing = true;

  services.firewalld = {
    zones = {
    techlist = {
      services = [
        "ssh"
        "rdp"
      ];
      ports = [
        {port = 9269; protocol = "tcp"; }  #vanilla/chuds
        {port = 8080; protocol = "tcp"; }  #map
        {port = 9267; protocol = "tcp"; }  #wifeyland/modded
        {port = 3389; protocol = "tcp"; }  #rdp
      ];
    };
    public = {
      forward = true;
      services = [
        #"ssh"
      ];
      ports = [
        {port = 9269; protocol = "tcp"; }  #vanilla/chuds
        {port = 8080; protocol = "tcp"; }  #map
        {port = 9267; protocol = "tcp"; }  #wifeyland/modded
      ];
    };
  };
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      #features.cdi = true;
      #firewall-backend = "iptables";
      iptables = false;
      ip6tables = false;
    };
  };


}
