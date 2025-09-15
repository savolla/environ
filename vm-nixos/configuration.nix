{ config, pkgs, lib, ... }:

let
  USERNAME = "savolla";
  HOSTNAME = "xkarna";
  HOME = "/home/savolla";
  ETHERNET_INTERFACE_NAME = "ens18";
  WIRELESS_INTERFACE_NAME = "wlp2s0";
  STATIC_IP_ADDRESS = "192.168.1.108";
  DEFAULT_GATEWAY = "192.168.1.1";

  ncmpcpp = pkgs.ncmpcpp.override {
    visualizerSupport = true;
    clockSupport = true;
  }; # ncmpcpp with visualizer

in {
  imports = [ ./hardware-configuration.nix ];

  # bootloader.
  boot = {
    # extraModprobeConfig = ''
    #   options kvm_intel nested=1
    #   options kvm_intel emulate_invalid_guest_state=0
    #   options kvm ignore_msrs=1
    # '';

    kernelPackages = pkgs.linuxPackages-rt_latest; # linux realtime kernel

    loader = {
      timeout = 5; # seconds
      systemd-boot.enable = false;
      grub = {
        enable = true;
        default = "saved";
        device = "nodev";
        # configurationLimit = 10; # display only 10 configs in grub (disabled due to boot loop issue. activate it again once it's solved)
        useOSProber = true;
        efiSupport = true;
        efiInstallAsRemovable =
          true; # otherwise /boot/EFI/BOOT/BOOTX64.EFI isn't generated
        extraEntriesBeforeNixOS = true;
        # extraEntries = ''
        # menuentry "Fedora" {
        #   insmod btrfs
        #   set root=(hd1,1)
        #   chainloader /EFI/fedora/grubx64.efi
        # }
        # '';
      };

      efi = { efiSysMountPoint = "/boot/efi"; };
    };
  };

  # systemd will prompt for password after root mounts
  environment.etc.crypttab.text = ''
    homecrypt UUID=5ba30f2e-b06a-4588-b594-70fb46ef16d9 none luks,timeout=120
  '';

  fileSystems."/home/savolla" = {
    device = "/dev/mapper/homecrypt";
    fsType = "ext4";
    options = [ "x-systemd.device-timeout=10" ];
    neededForBoot = false;
  };

  # Helpful to ensure USB storage is supported
  boot.initrd.kernelModules = [ "usb_storage" ];
  boot.kernelModules = [ "usb_storage" ];

  hardware = {
    graphics = {
      enable = true; # enable 3d acceleration
      enable32Bit = true; # for older games
    };
    bluetooth = {
      enable = true; # enables support for Bluetooth
      powerOnBoot = true; # powers up the default Bl
    };
  };

  # automatic update
  system = {
    autoUpgrade = {
      enable = false;
      dates = "weekly";
    };
  };

  networking = {
    hostName = "${HOSTNAME}";
    defaultGateway = "${DEFAULT_GATEWAY}";
    interfaces = {
      enp4s0 = {
        ipv4.addresses = [{
          address = "${STATIC_IP_ADDRESS}";
          prefixLength = 24;
        }];
      };
    };
    nameservers = [
      "127.0.0.1"
      "::1"
    ]; # dnscrypt requires this. see https://nixos.wiki/wiki/Encrypted_DNS
    networkmanager = {
      enable = true;
      dns =
        "none"; # prevent network manager from overriding dns settings because dnscrypt will handle this part
      unmanaged = [
        "interface-name:ve-*"
      ]; # for i2p container. network manager should not touch this
    };
    # wireless.enable = true; # Enables wireless support via wpa_supplicant.
    firewall = {
      enable = true; # always keep enabled

      # open ports in the firewall.
      allowedTCPPorts = [
        # 3000 # gitea port
      ];
      allowedUDPPorts = [ ];
    };
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "${ETHERNET_INTERFACE_NAME}";
    };

    extraHosts = ''
      192.168.1.105 api.crc.testing
      192.168.1.105 console-openshift-console.apps-crc.testing
      192.168.1.105 oauth-openshift.apps-crc.testing
      192.168.1.105 java-demo-java-demo.apps-crc.testing
      192.168.1.105 argocd-sample-server-java-demo.apps-crc.testing
    '';
  };

  # Set your time zone.
  time.timeZone = "Europe/Istanbul";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "tr_TR.UTF-8";
      LC_IDENTIFICATION = "tr_TR.UTF-8";
      LC_MEASUREMENT = "tr_TR.UTF-8";
      LC_MONETARY = "tr_TR.UTF-8";
      LC_NAME = "tr_TR.UTF-8";
      LC_NUMERIC = "tr_TR.UTF-8";
      LC_PAPER = "tr_TR.UTF-8";
      LC_TELEPHONE = "tr_TR.UTF-8";
      LC_TIME = "tr_TR.UTF-8";
    };
  };

  # configure console keymap
  console.keyMap = "trq";

  users = {
    motdFile = null; # disable message of the day on tty

    users."${USERNAME}" = {
      isNormalUser = true;
      home = "/home/savolla";
      description = "${USERNAME}";
      shell = pkgs.zsh;

      extraGroups = [
        "networkmanager" # wifi etc.
        "wheel" # sudo
        "input" # xorg
        "video" # xorg
        "audio" # pipewire
        "libvirtd" # virtualization
        "docker" # run docker commands withour sudo
        "podman" # run podman commmands without sudo
        "vboxusers" # vbox guest additions and clipboard share
        "kvm" # android emulation with kvm (faster)
        "adbusers" # interact with android and emulators with adb
        "systemd-journal" # watch system logs with `journalctl -f` witout sudo password
      ];
      packages = with pkgs;
        [
          gparted # install this as a user package to prevent errors in wayland
        ];
    };
  };

  # nix config
  nix = { settings = { experimental-features = [ "flakes" "nix-command" ]; }; };

  qt.style = "adwaita-dark";

  # allow unfree packages
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
      permittedInsecurePackages = [ "electron-27.3.11" ];
    };

    overlays = [
      (self: super: {
        mpv = super.mpv.override {
          scripts = [
            self.mpvScripts.quality-menu # select youtube video quality from the player
            self.mpvScripts.quack # temporarily reduce video and audio quality when skipping
          ];
        };

        weechat = super.weechat.override {
          configure = { availablePlugins, ... }: {
            scripts = with super.weechatScripts; [
              url_hint
              colorize_nicks
              weechat-notify-send
            ];
          };
        };
      })
    ];
  };

  environment = {
    stub-ld =
      { # with this nixos can run dyanamically linked binaries like wine binary that is caried from another environment (gaming)
        enable = true;
      };
    variables = { CURRENT_NIXOS_SPECIALISATION = "vanila"; };
  };

  fileSystems = {
    "/".noCheck = true;
    "/boot/efi".noCheck = true;
  };

  # set variables for all users (including root)
  environment.sessionVariables = {
    GTK_THEME = "Adwaita:dark"; # make sudo applications use dark theme
  };

  environment.systemPackages = with pkgs; [

    # editors
    vim # fallback text editor
    neovim # better vim
    # emacs-pgtk # transparency works in wayland
    emacs-gtk # true transparency works with this one on xorg
    vscodium # just in case ide
    jetbrains.webstorm # vscode sucks sometimes

    wget # download things
    anki # the best spaced repetition tool
    gcolor3 # color palettes for web dev
    # simplescreenrecorder # screen recorder for xorg (disabled because using ffmpeg)
    screenkey # show key presses on screen (screencast)
    xcolor # color picker for xorg
    appimage-run # run appimages on nixos
    ispell # emacs spell checking dep
    jamesdsp # equalizer for pipewire
    libcaca # ascii art viewer
    wipe # securely wipe directories and files on hdd/ssd
    git # version control
    unrar # non-free but needed
    koreader # awesome book reader
    dunst # notification daemon
    opensnitch-ui # enable interactive notifications for application firewall
    gowall # change colorschemes of any wallpaper
    peek # record desktop gifs
    graphviz # org-mode graph generation dependency
    plantuml-c4 # org-mode graph generation
    # teams-for-linux # microsoft teams for linux (unofficial)
    pinentry-gtk2 # password prompt for gnupg
    ffmpeg-full # needed for ncmpcpp cover art display and bunch of other things
    libnotify # dunst dep
    xcalib # invert colors of x
    xorg.xev # find keysims
    firefox # normal browser
    chromium # ungoogled chrome (needed for react-native debugger)
    tor-browser # just in case
    nixos-generators # generate various images from nixos config (qcow2)
    docker-compose # installing self-hosting services via docker is better thank using nixos services (more portable and control data more easily)
    dmg2img # convert apple's disk images to .img files. (needed for installing hackintoch on qemu)
    pandoc # emacs's markdown compiler and org-mode dep
    socat # serial communication with quickemy headless hosts witout ssh
    ferdium # communication
    btrfs-progs # you need this for nixos os-prober detect other oses like fedora which uses btrfs by default
    arp-scan # scan local ips
    librewolf # paranoid browser
    kitty # fallback terminal
    ripgrep # doom emacs dep
    dockfmt # doom emacs (docker file formatting)
    black # doom emacs (python-mode code formatter)
    python313Packages.pyflakes # doom emacs (python-mode import reordering)
    python313Packages.nose2 # doom emacs (python-mode tests)
    bleachbit # system cleanup
    iptraf-ng # watch network traffix in tui
    fd # doom emacs dep
    logseq # note taking tool
    protonvpn-cli_2 # vpn (this does not work anymore)
    protonvpn-cli # vpn
    lilypond-unstable-with-fonts # music notation (for doom emacs org-mode)
    cryptomator
    inetutils # for whois command
    binwalk # check files
    wireshark # network analizer
    libreoffice-qt6 # open .docx
    jq # needed for my adaptive bluelight filter adjuster
    pcmanfm # file manager
    ranger # tui file manager
    gajim # xmpp client for linux
    zip # archiving utility
    p7zip # great archiving tool
    # ollama-cuda # use local llms. installing this via systemPackages to set "models" dir to my home
    tree-sitter # parser for programming
    lazygit # git but fast
    cmake # installed for vterm to compile
    pavucontrol # pipewire buffer size and latency settings can be done from there
    libtool # installed for compiling vterm
    undollar # you copy and paste code from internet? you simply need it
    gperftools # improve memory allocation performance for CPU (need for ai apps use CPU instead f GPU)
    blender # 3d design
    keepassxc # password manager
    gtk3 # emacs requires this
    # nvidia-container-toolkit # needed for docker use nvidia
    w3m # image display for terminal
    gdu # scan storage for size
    tmux # life saver
    smartmontools # check health of ssd drives
    gsmartcontrol # check harddrive health
    btop # better system monitor
    yazi # new ranger
    xorg.xinit # for startx command to work
    xorg.libxcb # fix steam "glXChooseVisual" error
    picom # xorg compositor
    xsel # x clipboard
    xdotool # simulate keyboard and mouse events
    scrcpy # mirror android phone to pc
    nsxiv # image viewer
    yt-dlp # youtube video downloader + you can watch videos from mpv using this utility
    tshark # scan local network
    colordiff # to display colored output (installed for tshark)
    nicotine-plus # pure piracy
    unp # unpack any archive
    mermaid-cli # for org-babel mermaid diagrams support (doom emacs)
    xorg.libxshmfence # appimage-run requires it for some appimages like Mechvibes
    libgen-cli # download books from libgen
    udiskie # auto mount hotplugged block devices
    ntfs3g # make udiskie mount NTFS partitions without problems
    lxappearance # style gtk applications
    nodejs # for emacs to install lsp packages
    mpv # awesome media player (overlayed!)
    syncthing # sync data between devices
    imagemagick # for mp4 to gif conversion and other stuff
    pulseaudio # installed for pactl to work. was trying to record screen with ffmpeg and pipewire. needed pactl
    uv # vital python package. solves all those python version and dependency problems
    unclutter-xfixes # hide mouse cursor after a time period
    tldr # too long didn't read the manual
    xournalpp # draw shapes using your wacom tablet
    tabbed # suckless tabbed
    emacsPackages.nov # to make nov.el work
    xsct # protect your eyes (blue light filter) (disabled because using redshift)
    fftw # fastest fourier transform for ncmpcpp
    vlc # play dvds .VOB
    hugo # generate static site
    mpd # music player daemon
    mpc # control mpd from terminal
    feh # set wallpapers
    # freetube # youtube blocks my video stream after 1 minute when I use ublock origin
    mp3blaster # auto tag mp3 files using mp3tag tool
    zstd # extract .zst files
    isoimagewriter # balena etcher alternative
    neofetch # system info
    weechat # irc client (overlayed!)

    sysstat # get system statistics (used for tmux status bar cpu usage)
    eza # ls alternative
    starship # cross shell (very cool)
    alsa-utils # for amixer and and setting volume via scripts and terminal
    busybox # bunch of utilities (need)
    sxhkd # simple x hotkey daemon
    adw-gtk3 # for adwaita-dark theme
    adwaita-qt # make qt applications use dark theme
    adwaita-icon-theme # pretty icons (objective)
    zathura # pdf reader
    newsboat # rss/atom reader
    transmission_4-gtk # torrent application
    xd # i2p torrenting
    # anydesk # proprietary remote control
    rustdesk # open source remote control
    ncmpcpp # custom ncmpcpp with visualizer. see let/in on top
    unzip # mendatory
    hdparm # remove disks safely from terminal
    flameshot # screenshot utility for xorg
    scrot # for emacs's org-mode screen shot capability
    bat # cat but better
    fzf # fuzzy finder for terminal
    xclip # clipboard for xorg
    sxhkd # simple x11 hotkey daemon
    # lxqt.lxqt-policykit # authentication agent
    lxde.lxsession # session manager
    kdePackages.kdenlive # open source video editing software
    gimp-with-plugins # open source photoshop
    krita # digital art in linux? also comfyui integration using comfyui plugins
    xorg.xf86videoqxl # trying to improve scaling in spice
    inkscape-with-extensions # svg and logo design
    gnupg # encryption and stuff
    stress # simulate high cpu load for testing

    # virtualization related
    vagrant # declarative virtual machines
    quickemu # installed for installing macos sonoma (for react-native dev)
    quickgui # gui for quickemu
    guestfs-tools # bunch of tools with virt-sparsify
    virglrenderer # allows a qemu guest to use the host GPU for accelerated 3D rendering
    virt-viewer # viewer for qemu
    spice-vdagent # shared clipboard between qemu guests and host
    qemu # all supported architectures like arm, mips, powerpc etc.
    distrobox # run other distrox using docker
    edk2 # for osx-kvm (tianocore uefi)
    edk2-uefi-shell # for osx-kvm (tianocore uefi)
    OVMFFull
    virtiofsd # share file system between host and guests

    # wayland related
    waybar # status bar for wayland
    rofi-wayland # application launcher
    wl-clipboard # wayland clipboard
    slurp # region select. combine it with grim to select region for screenshot
    grim # screenshot utility
    gammastep # redshift/sct alternative for wayland
    swaybg # set wallpapers in wayland
    ydotool # xdotool for wayland

    # compiling
    stdenv # build-essentials
    help2man # for crosstool-ng dep
    gnumake # make for all
    autoconf # for crosstool-ng dep
    audit # for crosstool-ng dep
    automake # for crosstool-ng dep
    gcc # for crosstool-ng dep
    flex # for crosstool-ng dep
    file
    bison
    ncurses
    freetype # to be able to compile suckless utils

    # gaming stuff
    # lutris # install and launch windows and linux games
    # mangohud # display fps, temperature etc.
    # cabextract # installed this to install Age of Empires Online (prefix that was created by Kron4ek)
    # bottles-unwrapped # powerful wine thing
    # unigine-valley # test GPU drivers
    # protonup # proton-ge
    # wineWowPackages.staging # wine staging version
    # winetricks # install windows dlls with this
    # retroarchFull # retroarch + cores
    # ryujinx # switch emulator
    # antimicrox # map ps4 controller keys to nintendo switch and others
    # nsz # .nsz to .nsp nintendo switch game convertor for ryujinx emulator
    # input-remapper # map mouse movement to joystick. (play ryujinx games with mouse and keyboard)
    # antimicrox # same as input-remapper but easier to use
    # qjoypad # play ryujinx games with mouse and keyboard
    # sc-controller # emulate joysticks on linux (to play swtich games using mouse and keyboard)

    # # music
    # daw
    reaper
    sonic-pi
    faust # dsp language
    faust2jaqt # faust dependency
    supercollider_scel # supercollider with emacs extension scel

    # guitar stuff
    # gxplugins-lv2 # guitar amps, pedals, effects
    # neural-amp-modeler-lv2 # you'll download guitar tones for this below
    # guitarix # a virtual guitar amplifier for Linux running with JACK
    tuxguitar # guitar pro for linux
    # musescore # sheet happens
    # tonelib-jam # 3d tab editor (paid)
    # tonelib-gfx # good guitar amp
    # tonelib-metal # all in one guitar rig
    # proteus # NAM

    # audio plugins (lv2, vst2, vst3, ladspa)
    # distrho # not in packages anymore
    # calf # high quality music production plugins and vsts
    # eq10q
    # lsp-plugins # collection of open-source audio plugins
    # x42-plugins # collection of lv2 plugins by Robin Gareus
    # x42-gmsynth
    # dragonfly-reverb
    # FIL-plugins
    # geonkick
    # wineasio # for playing Rocksmith 2014 Remastered

    # alsa-scarlett-gui # focusrite scarlett solo gui
    # yabridge # use windows vsts on linux wine is requirement here
    # yabridgectl # yabridge control utility
    # scarlett2 # update firmware of focusrite scarlett devices

    tenacity # audaicty fork
    klick # cli metronom
    qpwgraph
    qjackctl # reduce latency
    helvum # modern jack ui

    # latex
    texliveFull # full latex environment for pdf exports (doom emacs)
    texlivePackages.booktabs # Publication quality tables in LaTeX
    texlivePackages.fvextra # Extensions and patches for fancyvrb (for syntax highlighting)
    texlivePackages.xcolor # Driver-independent color extensions for LaTeX and pdfLaTeX
    texlivePackages.fontspec # Advanced font selection in XeLaTeX and LuaLaTeX
    texlivePackages.microtype # Subliminal refinements towards typographical perfection
    texlivePackages.titlesec # Select alternative section titles
    texlivePackages.minted # syntax highlighting
    latexminted # just in case
    texlivePackages.librebaskerville # main font
    libre-baskerville # above font does not work
    texlivePackages.plex # sans and mono fonts
    texlivePackages.shadowtext # put shadow behind text

    # development
    gh # github cli
    insomnia # make api calls easily (postman alternative)
    tts # coqui-ai TTS (works with cpu)
    drawio # draw rldb, uml diagrams etc.
    genymotion # for testing react native apps in emulators
    # android-studio # for testing react native apps in emulators
    figma-linux # frontend development
    firefox-devedition # bin edition because nix tries to compile `firefox-devedition` and fails
    nodePackages_latest.eas-cli # build expo apk and dmg
    bundletool # convert .abb to .apk
    lua # other python
    dbeaver-bin # database awesomeness
    react-native-debugger # official react-native debugger
    jdk # for JAVA installation. needed for android sdk and other apps (this installs the latest version of jdk)
    sdkmanager # manage android sdk versions
    ruby # language
    pkg-config # needed for building ruby files
    shfmt # doom emacs's dep for bash file formatter to work
    nodePackages.prettier # prettier code formatter for js/ts

    # devops
    # minikube # kubernetes testing and learning environment
    kubernetes-helm # kubernetes package manager
    camunda-modeler # business modeling tool
    eclipses.eclipse-java # for camunda and spring boot
    openshift # kubernetes for stake holders
    crc # locally install openshift
    terraform # iac
    ansible # cac
    localstack # local aws
    terraform-local # use terraform with localstack
    awscli2 # aws cli tools
    spring-boot-cli # vite for java (spring boot)
    argocd # control argocd instances from commandline
    talosctl # control talos clusters
    k9s # lazy kubernetes
    kubectl # control your k8s cluster from your local machine
    kubernetes-helm # kubernetes package manager

    # game development
    # love # awesome 2d game engine written in lua
    godot_4 # 3d and 2d game engine

    # doom emacs dirvish
    vips # doom emacs dirvish dep for displaying images in buffer
    poppler-utils # doom emacs dirvish dep for viewing pdfs first page
    ffmpegthumbnailer # doom emacs dirvish dep
    mediainfo # for displaying audio metadata
    epub-thumbnailer # for displaying epub covers

    ## doom emacs lsp deps

    # c/c++ (clang lsp)
    ccls
    # semgrep # a different lsp. other than clangd. consider removing it later
    glslang
    clang
    clang-tools

    # shell
    shellcheck

    ## rust
    cargo
    rustc
    rust-analyzer

    # nix
    nixfmt-classic # formatting
    nil # language server

    ##  python
    # libraries
    (python3.withPackages (ps: [
      ps.seaborn # plotting
      ps.diagrams # diagrams
      ps.pygments # code hightlighting
      ps.pyautogui # desktop automation
      ps.diagrams # generate nice architecture diagrams
    ]))

    # packages
    python311Packages.isort
    python311Packages.pytest
    python311Packages.nose2
    python311Packages.nose2pytest
    python313Packages.diagrams
    pipenv

    # web
    html-tidy
    stylelint
    jsbeautifier
    rustywind # for tailwind lsp
    pnpm # better npm?
    jpegoptim # optimize jpeg
    optipng # optimize png
    libwebp # convert images to webp
    # responsively-app # responsive design helper

    # custom suckless stuff
    (st.overrideAttrs { src = ../../suckless/st-0.9.2; }) # my custom st
    (slstatus.overrideAttrs {
      src = ../../suckless/slstatus;
    }) # my custom slstatus
    (dmenu.overrideAttrs { src = ../../suckless/dmenu-5.3; }) # my custom dmenu
  ];

  # fonts
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.iosevka-term
    nerd-fonts.iosevka
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  virtualisation = {
    spiceUSBRedirection.enable = true;

    # virtualbox = { # virtualbox cannot be built with linux-rt kernel. hence disabled
    #   host = {
    #     enable = true;
    #   };
    #   guest = {
    #     enable = true;
    #     vboxsf = true;
    #     dragAndDrop = true;
    #     clipboard = true;
    #   };
    # };

    # podman = {
    #   enable = true;
    #   # dockerCompat = true;
    # };

    waydroid.enable = true;

    docker = {
      enable = true;
      enableOnBoot = false;
      daemon.settings = { data-root = "${HOME}/resource/docker"; };
      autoPrune = {
        enable = true;
        dates = "weekly";
      };

      ## NOTICE: I disabled rootless docker because I cannot run nvidia based docker containers with it.
      # rootless = {
      #   enable = true;
      #   setSocketVariable = false;
      #   daemon.settings = {
      #     runtimes = {
      #       nvidia = {
      #         path = "${pkgs.nvidia-docker}/bin/nvidia-container-runtime";
      #       };
      #     };
      #   };
      # };

    };

    # libvirtd = {
    #   enable = true;
    #   qemu = {
    #     package = pkgs.qemu_kvm;
    #     runAsRoot = true;
    #     swtpm.enable = true;
    #     vhostUserPackages = with pkgs; [ virtiofsd ]; # enable file share between host/guest
    #     ovmf = {
    #       enable = true;
    #       packages = [
    #         (pkgs.OVMF.override {
    #           secureBoot = true;
    #           tpmSupport = true;
    #         }).fd
    #       ];
    #     };
    #   };
    # };
  };

  services = {

    # # rebuild process failed last time I activated this
    # clamav = { # antivirus for linux
    #   daemon.enable = true; # normal package installation does not work. need to use service on nixos
    #   scanner.enable = false; # manually scan by user (reduce system load)
    #   updater.enable = false; # manually update the virus database
    # };

    # open-webui = {
    #   enable = true;
    #   port = 10000;
    #   openFirewall = true;
    #   environment = {
    #     ANONYMIZED_TELEMETRY = "False";
    #     DO_NOT_TRACK = "True";
    #     SCARF_NO_ANALYTICS = "True";
    #     OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
    #     WEBUI_AUTH = "False"; # Disable authentication
    #   };
    # };

    cron = {
      enable = true;
      systemCronJobs = [
        # keep your ssd healthy by trimming it hourly (redhat suggestion)
        "0 * * * * root fstrim -av >> /var/log/fstrim.log 2>&1"
      ];
    };

    opensnitch = { # application firewall for linux
      enable = true;
      rules = {
        systemd-timesyncd = {
          name = "systemd-timesyncd";
          enabled = true;
          action = "allow";
          duration = "always";
          operator = {
            type = "simple";
            sensitive = false;
            operand = "process.path";
            data = "${lib.getBin pkgs.systemd}/lib/systemd/systemd-timesyncd";
          };
        };
        systemd-resolved = {
          name = "systemd-resolved";
          enabled = true;
          action = "allow";
          duration = "always";
          operator = {
            type = "simple";
            sensitive = false;
            operand = "process.path";
            data = "${lib.getBin pkgs.systemd}/lib/systemd/systemd-resolved";
          };
        };
      };
    };

    openssh = {
      enable = true;
      startWhenNeeded = true;
    };

    udisks2 = { # mount disks without sudo (requires udiskie)
      enable = true;
    };

    gvfs = { # enable android file system mount in pcmanfm
      enable = true;
    };

    # enhance in-vm performance in SPICE (proxmox)
    # these are disabled because I think I need to manually run `spice-vdagent`
    # from my .xprofile on startup. otherwise spice-vdagent gives up and does
    # not update itself later
    spice-vdagentd.enable = true;
    # qemuGuest.enable = true;

    # enable xorg
    xserver = {
      enable = true;
      xkb = { layout = "tr"; };
      videoDrivers =
        [ "qxl" ]; # to increase in-vm performance when using SPICE via proxmox

      # start desktop with `startx`
      # displayManager = { startx.enable = true; };

      displayManager.lightdm.enable = true;

      # window manager
      windowManager = {
        dwm = { # suckless dynamic window manager
          enable = true;
          package = pkgs.dwm.overrideAttrs { src = ../../suckless/dwm-6.5; };
        };
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # displayManager = {
    #   ly = { # enable ly display manager
    #     enable = true;
    #   };
    # };

    dnscrypt-proxy2 =
      { # encrypt your dns. don't use VPN. use this instead to avoid ISP restrictions
        enable = true;
        # Settings reference:
        # https://github.com/DNSCrypt/dnscrypt-proxy/blob/master/dnscrypt-proxy/example-dnscrypt-proxy.toml
        settings = {
          ipv6_servers = true;
          require_dnssec = true;
          # Add this to test if dnscrypt-proxy is actually used to resolve DNS requests
          query_log.file = "/var/log/dnscrypt-proxy/query.log";
          sources.public-resolvers = {
            urls = [
              "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
              "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
            ];
            cache_file = "/var/cache/dnscrypt-proxy/public-resolvers.md";
            minisign_key =
              "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
          };
        };
      };

    # gitea = {
    #   enable = true;
    #   # stateDir = "${HOME}/resource/tools/services/gitea"; # gitea doesn't like that.. and cannot start. probably permission errors
    #   appName = "Endeku Git Server";
    #   database.type = "sqlite3";
    #   settings.server.HTTP_PORT = 3000;
    #   settings.server.ROOT_URL = "http://${STATIC_IP_ADDRESS}";
    # };

    # nginx = {
    #   enable = true;
    #   recommendedGzipSettings = true;
    #   recommendedOptimisation = true;
    #   recommendedProxySettings = true;
    #   recommendedTlsSettings = true;
    #   virtualHosts."source.MyDomain.tld" = {                  # Gitea hostname
    #     locations."/".proxyPass = "http://localhost:3000/";   # Proxy Gitea
    #   };
    # };

  };

  containers = {
    i2pd-container = {
      autoStart = true;
      config = { ... }: {
        system.stateVersion =
          "23.05"; # If you don't add a state version, nix will complain at every rebuild
        # Exposing the nessecary ports in order to interact with i2p from outside the container
        networking.firewall.allowedTCPPorts = [
          7656 # default sam port
          7654 # default i2cp port
          7070 # default web interface port
          4447 # default socks proxy port
          4444 # default http proxy port
        ];
        services.i2pd = {
          enable = true;
          address =
            "127.0.0.1"; # you may want to set this to 0.0.0.0 if you are planning to use an ssh tunnel
          proto = {
            http.enable = true;
            socksProxy.enable = true;
            httpProxy.enable = true;
            sam.enable = true;
            i2cp = {
              enable = true; # for I2P torrenting
              address = "127.0.0.1";
              port = 7654;
            };
          };
        };
      };
    };
  };

  # # disabled services. don't autostart the following services
  systemd.services.docker.wantedBy = lib.mkForce [ ];
  # systemd.services.libvirtd.wantedBy = lib.mkForce [ ];
  systemd.services.podman.wantedBy = lib.mkForce [ ];
  # systemd.services.open-webui.wantedBy = lib.mkForce [ ];

  # enable coredumps
  systemd.coredump.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs = {
    direnv =
      { # manage environments depending on current directory (doom emacs dep)
        enable = true;
        enableZshIntegration = true;
      };

    firejail = { # run programs without internet access
      enable = true;
    };
    river = { # wayland dwm like window manager
      enable = true;
    };
    slock = { # suckless screen locker
      enable = true;
    };
    starship = { # pretty shell
      enable = true;
    };
    hyprland = { # wayland window manager
      enable = true;
      xwayland.enable = true;
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
    };
    # virt-manager = { enable = true; };
    steam = {
      enable = true;
      gamescopeSession.enable =
        true; # if you have problems launching the game use this
    };
    gamemode =
      { # temporarily apply optimizations to the game. better gaming experience on linux
        enable = true;
      };

    nix-ld = { # run non x86_64 binaries in nixos
      enable = true;
      libraries = with pkgs; [
        icu # libicu for ryujinx switch emulator
        zlib
        zstd
        stdenv.cc.cc
        curl
        openssl
        attr
        libssh
        bzip2
        libxml2
        acl
        libsodium
        util-linux
        xz
        systemd
        bubblewrap
        busybox
        gcc
        openssl
        pkg-config
        wineWowPackages.staging
        libxcrypt-legacy
      ];
    };

    adb = { # android debug bridge
      enable = true;
    };
    # darling = { # wine for macos
    #   enable = true;
    # };

    appimage = { # run appimages on nixos
      enable = true;
      binfmt = true;
    };
  };

  security = {
    #   wrappers = {
    #     slock = { # fix slock: unable to disable OOM killer. Make sure to suid or sgid slock.
    #       setuid = true;
    #       owner = "${USERNAME}";
    #       group = "users";
    #       source = "${pkgs.slock}/bin/slock";
    #     };
    #   };

    polkit = {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (
            subject.isInGroup("users")
            && (
              action.id == "org.freedesktop.login1.reboot" ||
              action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
              action.id == "org.freedesktop.login1.power-off" ||
              action.id == "org.freedesktop.login1.power-off-multiple-sessions"
            )
          )
        {
          return polkit.Result.YES;
        }
        });
      '';
    };
  };

  system.stateVersion = "25.05"; # never change this!

  # specializations
  specialisation = {

    # frontend = {
    #   inheritParentConfig = true;
    #   configuration = {
    #     users.users."${USERNAME}".home = lib.mkForce "/home/frontend";
    #     environment.variables = {
    #       CURRENT_NIXOS_SPECIALISATION = lib.mkForce "frontend";
    #     };
    #
    #     # disable some services for this evironment
    #     systemd.services.opensnitch.wantedBy = lib.mkForce [ ];
    #     systemd.services.spice-vdagentd.wantedBy = lib.mkForce [ ];
    #     containers.i2pd-container.autoStart = lib.mkForce false;
    #   };
    # };

    nvidia = {
      inheritParentConfig = true;
      configuration = {
        boot = {
          # kernelPackages = lib.mkForce pkgs.linuxPackages_zen; # nvidia does not compile with linux-zen. keep it commented for stability
          kernelParams = [ "nvidia_drm.fbdev=1" ];
        };
        environment.variables = {
          CURRENT_NIXOS_SPECIALISATION = lib.mkForce "nvidia";
        };
        services.xserver.videoDrivers = [ "nvidia" ];
        hardware = {
          # nvidia-container-toolkit = { enable = true; };
          graphics.enable = true; # enable 3d acceleration
          graphics.enable32Bit = true; # for older games
          nvidia-container-toolkit.enable =
            true; # enable nvidia acceleration in docker containers
          nvidia = {
            open =
              false; # not nouveau. see https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
            modesetting.enable = true; # required
            powerManagement.enable = false; # causes sleep/suspend to fail
            powerManagement.finegrained = false; # experimental. disable
            nvidiaSettings = true; # enable nvidia settings
          };
        };
        # environment.systemPackages = with pkgs; [
        #   # linuxKernel.packages.linux_zen.opensnitch-ebpf
        #   cudaPackages.cudatoolkit # for CUDA
        #   nvidia-container-toolkit # to use nvidia within docker containers
        # ];
      };
    };

    # amd = {
    #   inheritParentConfig = true;
    #   configuration = {
    #     boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;
    #     environment.variables = {
    #       CURRENT_NIXOS_SPECIALISATION = lib.mkForce "amd";
    #     };
    #     services.xserver.videoDrivers = ["amdgpu"];
    #   };
    # };
  };
}
