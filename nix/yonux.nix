{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    btop
    wl-clipboard
    cliphist
    fuzzel
    grim
    slurp
    mako
    playerctl
    brightnessctl
    libnotify
    nautilus
    hyprpicker
    hyprpolkitagent
    bibata-cursors
    adw-gtk3
    adwaita-icon-theme
    glib
    matugen
    lm_sensors
    xdg-terminal-exec
  ];

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    (pkgs.runCommand "google-sans-flex" {
      src = pkgs.fetchurl {
        name = "GoogleSansFlex.ttf";
        url = "https://raw.githubusercontent.com/google/fonts/bd8f81ddb5c74d5c8897b36ad88b440266245103/ofl/googlesansflex/GoogleSansFlex%5BROND,opsz,slnt,wdth,wght%5D.ttf";
        hash = "sha256-qax3B5iFfV6KxZPO1Csi5Ap8CM7Jgxn5Kw7Mwng6d7o=";
      };
    } "install -Dm644 $src $out/share/fonts/truetype/GoogleSansFlex.ttf")
  ];

  systemd.packages = [ pkgs.hyprpolkitagent ];
  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;

  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings."org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "adw-gtk3-dark";
        };
      }
    ];
  };
  
  services.udisks2.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  services.hypridle.enable = true;
  programs.hyprlock.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=0
  '';

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  programs.gamescope.enable = true;
  programs.gamemode.enable = true;

  programs.steam.extraPackages = [ pkgs.bibata-cursors ];
}
