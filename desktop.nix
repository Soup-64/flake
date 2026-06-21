{ config, lib, pkgs, inputs, ... }:
{
  # Common to machines with head

  # SYSTEM STUFF
  # ROCM is disabled because I am so tired of it breaking literally every nix unstable update

  #brightness control
  services.udev.packages = [pkgs.ddcutil];

  hardware.i2c.enable = true;
  hardware.keyboard.qmk.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GTK_USE_PORTAL = "1";
    PINENTRY_KDE_USE_WALLET = "1";
    FREETYPE_PROPERTIES="cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
    #KWIN_USE_OVERLAYS = "1";
  };

  #clr is broken right now
  #systemd.tmpfiles.rules =
  #let
  #  rocmEnv = pkgs.symlinkJoin {
  #    name = "rocm-combined";
  #    paths = with pkgs.rocmPackages; [
  #      #rocblas
  #      #hipblas
  #      #clr
  #    ];
  #  };
  #in [
  #  #"L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
  #  "L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware"
  #];
# smash if rocm/clr is fucked, needed for QEMU
  systemd.tmpfiles.rules = ["L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware"];

  hardware.graphics = {
  enable = true;
  #package = pkgs.mesa;
  enable32Bit = true;
   extraPackages = with pkgs; [
      libva-utils
      #rocmPackages.clr.icd
    ];
  };

  # bluetooth
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
      Enable = "Source,Sink,Media,Socket";
    };
  };

  #desktops support desktop things like ntsync and desktop-y kernels
  boot.kernelModules = [
    "ntsync"
  ];

  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [
      "--performance" #lavd thing
    ];
  };

  # FONTS

  fonts.fontconfig.subpixel.rgba = "rgb";
  fonts.fontconfig.useEmbeddedBitmaps = true;
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

  fonts.packages = with pkgs; [
    terminus_font # few moments of bitmap fonts breaking in nixpkgs :(
    spleen
    terminus_font_ttf
    courier-prime
    inter
    minecraftia
    monocraft
    corefonts
    vista-fonts
  ];

  # SOFTWARE

  environment.systemPackages = with pkgs; [
    xauth #SSH -Y
    blender #clr/rocm is broken sometimes
    #zluda  #amd cuda, I guess
    gpu-screen-recorder-gtk
    vscode.fhs
    protonup-qt
    #input-remapper
    git-cola
    btop
    usbutils
    killall
    nvtopPackages.amd
    godot3-mono
    godot-mono
    gimp3
    dolphin-emu
    libreoffice-qt-fresh
    mediawriter
    pied
    alsa-utils
    pinentry-qt #gpg
    ddcutil
    piper
    mpv
    mangohud
    goverlay
    kdiskmark
    kdePackages.partitionmanager
    kdePackages.kgpg
    kdePackages.plasma5support
    #kdePackages.koko #gwenview but new but still bad
    kdePackages.kate
    kdePackages.plasma-vault
    kdePackages.kdenlive
    kdePackages.filelight
    kdePackages.kcoreaddons
    kdePackages.krdc
    kdePackages.kdesdk-thumbnailers
    kdePackages.kimageformats
    kdePackages.kdegraphics-thumbnailers
    kdePackages.ffmpegthumbs
    kdePackages.kdialog
    (kdePackages.spectacle.override {
      tesseractLanguages = [ "all" ];
    })
    kdePackages.libkdcraw
    libraw
    tesseract
    sbctl
    (discord-canary.override {
      withOpenASAR = true;
      withVencord = true;
    })
    #vesktop
    jetbrains.pycharm-oss
    #jetbrains.clion
    darktable
    openconnect
    networkmanager-openconnect
    headsetcontrol
    signal-desktop
    freecad
    android-tools
    unityhub #broken often
    arduino
    cameractrls-gtk4
  ];

  # Install firefox.
  programs.firefox = {
    enable = true;
    preferences = {
      "widget.use-xdg-desktop-portal.file-picker" = 1;
    };
  };

  programs.virt-manager.enable = true;

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    #borked extest
    #extest.enable = true;
    #remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    #dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    #localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  # DESKTOP

  programs.xwayland.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable the KDE Plasma Desktop Environment.
  services.desktopManager.plasma6.enable = true;
  services.displayManager.plasma-login-manager.enable = true;
  xdg = {
  portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
      xdg-desktop-portal-gtk
    ];
  };
  };

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
          matches = [
            {
              #"application.process.binary" = "my-broken-app";
              "application.process.binary" = "firefox";
              #"client.name" = "Firefox";
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

  # MISC SERVICES

  services.pcscd.enable = true; #smart cards and stuff

  virtualisation.libvirtd = {
    enable = true;
    qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
  };

  services.speechd.enable = true; #funne tts

  services.ratbagd.enable = true; #binding g604 macros
  #services.input-remapper.enable = true; #for fixing g604 scroll
  #services.input-remapper.enableUdevRules = false; #borked
  services.flatpak.enable = true; #just prism, unity, ee, blanket

  virtualisation.docker = {
    # Consider disabling the system wide Docker daemon
    enable = false;

    rootless = {
      enable = true;
      setSocketVariable = true;
      # Optionally customize rootless Docker daemon settings
      daemon.settings = {
        #dns = [ "1.1.1.1" "8.8.8.8" ];
        #registry-mirrors = [ "https://mirror.gcr.io" ];
        firewall-backend = "iptables";
        iptables = false;
        ip6tables = false;
      };
    };
  };

}
