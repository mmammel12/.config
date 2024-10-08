{
  description = "Marty Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {

      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
          pkgs.bat
          pkgs.espanso
          pkgs.fzf
          pkgs.git
          pkgs.jq
          pkgs.kitty
          pkgs.lsd
          pkgs.mkalias
          pkgs.neovim
          pkgs.obsidian
          pkgs.tree-sitter
          pkgs.zinit
          pkgs.zoxide
          pkgs.zsh
        ];

      homebrew = {
        enable = true;
        brews = [
          "mas"
        ];
        casks = [
          "the-unarchiver"
          "meetingbar"
        ];
        masApps = {};
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      fonts.packages =
        [
          (pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; })
        ];

      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
            '';

      system.defaults = {
        dock.autohide = false;
        dock.launchanim = true;
        dock.show-process-indicators = true;
        dock.orientation = "right";
        dock.magnification = false;
        dock.persistent-apps = [
          "/System/Applications/System Settings.app"
          "/System/Applications/Calendar.app"
          "/Applications/Google Chrome.app"
          "/Applications/zoom.us.app"
          "${pkgs.slack}/Applications/Slack.app"
          "/Applications/Postman.app"
          "${pkgs.kitty}/Applications/kitty.app"
          "/Applications/MongoDB Compass.app"
          "/System/Applications/QuickTime Player.app"
          "/Applications/Screen Studio.app"
          "${pkgs.obsidian}/Applications/Obsidian.app"
          "/Applications/1Password.app"
        ];
        NSGlobalDomain.AppleInterfaceStyle = "Dark";
        NSGlobalDomain.KeyRepeat = 2;
      };

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#FQ-M-F6W9QFQG
    darwinConfigurations."FQ-M-F6W9QFQG" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            # Apple silicon only
            enableRosetta = true;
            # User owning the homebrew prefix
            user = "martinmam";
            # since homebrew is already installed
            autoMigrate = true;
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."FQ-M-F6W9QFQG".pkgs;
  };
}
