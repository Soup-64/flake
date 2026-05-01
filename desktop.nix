{ config, lib, pkgs, inputs, ... }:
{
  # Specific to non-headless/user machines

  ###
  ### Plasma stuff
  ###

  services.desktopManager.plasma6.enable = true;
  services.displayManager.plasma-login-manager.enable = true;
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GTK_USE_PORTAL = "1";
    PINENTRY_KDE_USE_WALLET = "1";
    #KWIN_USE_OVERLAYS = "1";
  };

  xdg = {
  portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
      xdg-desktop-portal-gtk
    ];
  };
  };

  services.speechd.enable = true;
  services.ratbagd.enable = true; #binding g604 macros
  #services.input-remapper.enable = true; #for fixing g604 scroll
  #services.input-remapper.enableUdevRules = false; #borked
  services.flatpak.enable = true; #just prism, unity, ee, blanket

  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [
      "--performance"
    ];
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };
  services.pipewire.extraConfig.pipewire = {
  "15-force-s16-info" = {
      "stream.rules" = [
        {
          actions = {
            quirks = [
              "block-sink-volume"
              "block-source-volume"
            ];
          };
          matches = [ # BROKEN CURRENTLY FUCKKKK
            {
              #"application.process.binary" = "my-broken-app";
              "application.process.binary" = "*firefox*";
              "client.name" = "Firefox";
            }
          ];
        }
      ];
    };
    "98-crackling-fix" = {
      "context.properties" = {
        "link.max-buffers"          = 128;
        "default.clock.rate"        = 48000;
        "default.clock.quantum"     = 512;
        "default.clock.min-quantum" = 512;
        "default.clock.max-quantum" = 2048;
      };
    };
  };
  services.pipewire.wireplumber.extraConfig = {
    "99-crackling-fix" = {
      "api.alsa.period-size" = 1024;
      "api.alsa.headroom" = 8192;
    };
  };

  ###
  ### Other desktop stuff
  ###

  services.printing = {
    enable = true;
    drivers = [ pkgs.epson-escpr ];
  };
  services.printing.cups-pdf.enable = true;

  #printer discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    #openFirewall = true;
  };

  users.users.soup.extraGroups = [ "i2c" ];
  hardware.i2c.enable = true;
  hardware.keyboard.qmk.enable = true;

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
      Enable = "Source,Sink,Media,Socket";
    };
  };

  environment.systemPackages = with pkgs; [
    # Desktop + laptop Utils
    ddcutil
    nvtopPackages.amd
    libva-utils #video accel
    clinfo #opencl

    # Desktop + laptop Apps
    #apps desktop/laptop
    gimp3
    jetbrains.pycharm-oss
    vscode.fhs
    git-cola
    helix
    godot3-mono
    android-tools
    godot-mono
    gpu-screen-recorder-gtk
    #input-remapper
    protonup-qt
    dolphin-emu
    yt-dlp
    libreoffice-qt-fresh
    mediawriter
    pied
    piper-tts
    alsa-utils
    pinentry-qt #gpg
    piper
    mpv
    kdePackages.partitionmanager
    kdePackages.kgpg
    kdePackages.plasma5support
    kdePackages.kate
    kdePackages.plasma-vault
    kdePackages.kdenlive
    kdePackages.filelight
    kdePackages.kcoreaddons
    kdePackages.krdc
    kdiskmark
    darktable
    openconnect
    headsetcontrol
    tesseract
    signal-desktop
    (kdePackages.spectacle.override {
      tesseractLanguages = [ "all" ];
    })

    unityhub #broken often
    xar #specific to unity
  ];

  # Install firefox.
  programs.firefox = {
    enable = true;
    preferences = {
      "widget.use-xdg-desktop-portal.file-picker" = 1;
    };
  };

  programs.java = { enable = true; package = pkgs.temurin-jre-bin-11; };

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    extest.enable = true;
    #remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    #dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    #localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  #virt filesystem stuff if you need it
  services.gvfs.enable = true;

  #brightness control
  services.udev.packages = [pkgs.ddcutil]; #i2c

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  #services.xserver.enable = true;
  programs.xwayland.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
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
