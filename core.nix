{ config, lib, pkgs, inputs, ... }:
{
  # Common between all machines

  # NIX SETTINGS


  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 5d";
  };
  nix.settings.auto-optimise-store = true;
  nixpkgs.config = {
    allowUnfree = true;
    #rocmSupport = true;
  };
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      fontconfig
      stdenv.cc.cc.lib # needed for pylance
      zlib             #
      openssl          # extension downloads
      curl
      glib
      util-linux       #
      # Put here any library that is required when running a package
      # uncomment for all of steam-run
      # (pkgs.runCommand "steamrun-lib" {} "mkdir $out; ln -s ${pkgs.steam-run.fhsenv}/usr/lib64 $out/lib")
    ];
  };
  #fix programs that do stuff like hardcode /bin/bash
  services.envfs.enable = true;

  # USERS

  users.users.soup = {
    isNormalUser = true;
    description = "Soup";
    #missing groups do nothing on systems without them so they're just all here
    extraGroups = [ "networkmanager" "docker" "beep" "wheel" "i2c" "libvirtd" "dialout" ];
    packages = with pkgs; [
      #stub
    ];
  };

  # LOCALE

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

  # SYSTEM STUFF

  systemd.services.systemd-journal-flush.enable = true;
  services.journald.extraConfig = "SystemMaxUse=2G";

  environment.sessionVariables = {};

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.systemd-boot.memtest86.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
  services.fwupd.enable = true; #device firmware

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  # oops all AMD!
  boot.kernelParams = [
    "loglevel=3"
    "amd_pstate=active"
  ];

  #fix vconsole race condition where loadkeys fails to find font since the FS isn't ready
  systemd.services.systemd-vconsole-setup = {
    unitConfig = {
      After = "local-fs.target";
    };
  };

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
  #fix for qemu network bridging
  networking.firewall.trustedInterfaces = [ "virbr0" "wlp3s0" ];

  #virt filesystem stuff if you need it
  services.gvfs.enable = true;

  # SOFTWARE

  environment.systemPackages = with pkgs; [
    cifs-utils
    jq
    keyutils
    samba
    wget
    pciutils
    clinfo #opencl
    dateutils
    ffmpeg
    imagemagick
    nixpkgs-review
    nixfmt
    gitFull
    git-lfs
    gh
    nix-output-monitor
    piper-tts
    #(callPackage ./piper-tts.nix {}) #manual build from commit
    lm_sensors
    helix
    conda
    lld
    btop
    zip
    unzip
    xar
    p7zip
    rar
    file
    gvfs
    beep
    smartmontools
    net-tools
    traceroute
    libva-utils #video accel
    vim
    fwupd-efi
    killall
    sbctl
    usbutils
    yt-dlp
  ];

  programs.java = { enable = true; package = pkgs.temurin-jre-bin-11; };

  # SERVICES AND STUFF

  networking.firewall.backend = "firewalld";
  networking.nftables.enable = true;
  services.firewalld = {
    enable = true;
    settings.DefaultZone = "public";
    zones = {
    docker = {
      target = "DROP";
      sources = [
        { address = "172.17.0.1/16"; }
      ];
      interfaces = [
        "docker0"
      ];
      ports = [];
    };
    techlist = {
      target = "DROP";
      sources = [
        { address = "141.219.0.0/16"; }
      ];
      forward = true;
      protocols = [
        "icmp"
      ];
      services = [
        "dhcpv6-client"
      ];
      ports = [];
    };
    public = {
      forward = true;
      services = [
        "dhcpv6-client"
      ];
      ports = [];
    };
  };
  };

  programs.gnupg.agent = {
   enable = true;
   #pinentryPackage = pkgs.pinentry-qt;
   #pinentryFlavor = "qt"; #unsupported
   #enableSSHSupport = true;
  };

  #drive SMART reporting
  services.smartd = {
      enable = true;
      autodetect = false;
  };


#fixes some disgusting bugs with mounting the M drive
system.activationScripts.symlink-requestkey = ''
      if [ ! -d /sbin ]; then
        mkdir /sbin
      fi
      ln -sfn /run/current-system/sw/bin/request-key /sbin/request-key
    '';
    # request-key expects a configuration file under /etc
    environment.etc."request-key.conf" = {
      text = let
        upcall = "${pkgs.cifs-utils}/bin/cifs.upcall";
        keyctl = "${pkgs.keyutils}/bin/keyctl";
      in ''
        #OP     TYPE          DESCRIPTION  CALLOUT_INFO  PROGRAM
        # -t is required for DFS share servers...
        create  cifs.spnego   *            *             ${upcall} -t %k
        create  dns_resolver  *            *             ${upcall} %k
        # Everything below this point is essentially the default configuration,
        # modified minimally to work under NixOS. Notably, it provides debug
        # logging.
        create  user          debug:*      negate        ${keyctl} negate %k 30 %S
        create  user          debug:*      rejected      ${keyctl} reject %k 30 %c %S
        create  user          debug:*      expired       ${keyctl} reject %k 30 %c %S
        create  user          debug:*      revoked       ${keyctl} reject %k 30 %c %S
        create  user          debug:loop:* *             |${pkgs.coreutils}/bin/cat
        create  user          debug:*      *             ${pkgs.keyutils}/share/keyutils/request-key-debug.sh %k %d %c %S
        negate  *             *            *             ${keyctl} negate %k 30 %S
      '';
    };
}
