{ config, pkgs, ... }:

{
  home.username = "vagrant";
  home.homeDirectory = "/home/vagrant";
  home.stateVersion = "24.11"; # Please read the comment before changing.

  home.packages = with pkgs; [
    neovim # just in case editor
    neofetch # system summary info
    xclip # copy things from terminal
    tmux # multiple terminals in a single terminal
    emacs # ide
    # qt5Full # qt desktop sdk
    # qtcreator # the ide
    libgcc # c and c++ compilers
    ripgrep # for doom emacs search
    fd # for doom emacs search 2
    bash-completion # auto completion in bash
    ncdu # find out what eats up free space
    shellcheck # for doom emacs
    ranger # midnight commander-like
    tldr # explain commands with summary
    radare2 # disassembler
    cpio # buildroot dependency
    util-linux # buildroot dependency
    bc # buildroot dependency
    cmake # need for doom emacs
    libtool # need for doom emacs
    fira-code # font for doom emacs
    fira-code-symbols # ligatures and stuff
    nixfmt-rfc-style # need for nixfmt to work (doom emacs)
    nodejs_22 # doom emacs installs lsp automatically with this
    spice-vdagent # enable clipboard sharing between host and kvm machines
    spice-autorandr # automatically adjust resolution of a kvm machine
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  programs.git = {
    enable = true;
    userName = "savolla";  
    userEmail = "savolla@protonmail.com"; 
  };
  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/genemek/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
