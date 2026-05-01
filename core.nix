{ config, lib, pkgs, inputs, ... }:
{
  # Common set of apps and settings

  ###
  ### NIX SETTINGS
  ###
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nixpkgs.config = {
    allowUnfree = true;
    rocmSupport = true;
  };
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 5d";
  };
  services.envfs.enable = true;
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      fontconfig
      ## Put here any library that is required when running a package
      ## ...
      ## Uncomment if you want to use the libraries provided by default in the steam distribution
      ## but this is quite far from being exhaustive
      ## https://github.com/NixOS/nixpkgs/issues/354513
      # (pkgs.runCommand "steamrun-lib" {} "mkdir $out; ln -s ${pkgs.steam-run.fhsenv}/usr/lib64 $out/lib")
    ];
  };

  users.users.soup = {
    isNormalUser = true;
    description = "Soup";
    extraGroups = [ "networkmanager" "wheel" ]; # rootless docker only outside of Sienna
    packages = with pkgs; [
      #stub
    ];
  };

  ###
  ### TIME/FONT STUFF
  ###

  # Time/Locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Font stuff
  fonts.fontconfig.subpixel.rgba = "rgb";
  fonts.fontconfig.useEmbeddedBitmaps = true;
  fonts.packages = with pkgs; [
    terminus_font
    terminus_font_ttf
    courier-prime
    inter
    minecraftia
    monocraft
    corefonts
    vista-fonts
  ];

  # Fix bitmapped fonts
  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <description>Accept bitmap fonts</description>
    <!-- Accept bitmap fonts -->
    <selectfont>
      <acceptfont>
      <pattern>
        <patelt name="outline"><bool>false</bool></patelt>
      </pattern>
      </acceptfont>
    </selectfont>
    </fontconfig>
  '';

  ###
  ### COMMON SYSTEM STUFF
  ###
  services.smartd.enable = true;
  services.fwupd.enable = true;

  # Bootloader.
  # boot.loader.systemd-boot.enable = true; #disable for SB
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.systemd-boot.memtest86.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;
  boot.kernelParams = [
    "loglevel=3"
  ];
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  # Fix vconsole race condition where loadkeys fails to find font since the FS isn't ready
  systemd.services.systemd-vconsole-setup = {
    unitConfig = {
      After = "local-fs.target";
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  boot.kernelModules = [
    "ntsync"
  ];
  systemd.services.systemd-journal-flush.enable = true;
  services.journald.extraConfig = "SystemMaxUse=2G";

  environment.systemPackages = with pkgs; [
    #common
    cifs-utils
    keyutils
    wget
    btop
    dateutils
    ffmpeg
    gitFull
    gh
    imagemagick
    nix-output-monitor
    nixpkgs-review
    usbutils
    sbctl
    killall
    pciutils
    samba
    rar
    file
    lm_sensors
    lld
    zip
    unzip
    p7zip
    networkmanager-openconnect
    smartmontools
    gvfs
    conda
  ];

  programs.gnupg.agent = {
   enable = true;
   pinentryPackage = pkgs.pinentry-qt;
   #pinentryFlavor = "qt"; #unsupported
   #enableSSHSupport = true;
  };

  programs.virt-manager.enable = true;

  ###
  ### NETWORKING
  ###

  # Enable networking
  networking.networkmanager.wifi.powersave = false;
  networking.networkmanager.enable = true;
  #networking.nameservers = [ "127.0.0.1:8053" ]; # breaks MTU VPN services
  #services.resolved = {
  #  enable = true;
  #  dnssec = "true";
  #  #domains = [ "~." ];
  #  fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
  #  #dnsovertls = "true"; # MTU blocks DoT
  #};

#  services.doh-server.enable = true;
#  services.doh-server.settings.upstream = [ "udp:1.1.1.1:53" ];
#  services.doh-server.settings.listen = ["127.0.0.1:8053"];
#  services.doh-server.settings.verbose = true;

  virtualisation.docker = {
    rootless.enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
    daemon.settings = {
      firewall-backend = "iptables";
      iptables = false;
      ip6tables = false;
    };
  };
}
