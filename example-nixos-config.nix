{ config, pkgs, illuminanced-nix-flake, ... }:

{
  imports = [
    illuminanced-nix-flake.nixosModules.default
  ];

  # Enable udev rules for backlight access
  # This allows users to control brightness without root
  services.illuminanced = {
    enable = true;
    enableUdevRules = true;  # Default is true when enable = true
    
    # Specify your backlight device path
    # The module will automatically generate appropriate udev rules
    settings.general = {
      backlight_file = "/sys/class/backlight/amdgpu_bl0/brightness";
      max_backlight_file = "/sys/class/backlight/amdgpu_bl0/max_brightness";
      
      # For Intel laptops, use:
      # backlight_file = "/sys/class/backlight/intel_backlight/brightness";
      # max_backlight_file = "/sys/class/backlight/intel_backlight/max_brightness";
    };
  };
  
  # Optional: Apply the overlay to make pkgs.illuminanced available
  nixpkgs.overlays = [ illuminanced-nix-flake.overlays.default ];
  
  # Note: This NixOS module only sets up udev rules.
  # To run illuminanced as a service, configure it in home-manager:
  #
  # home-manager.users.youruser = {
  #   imports = [ illuminanced-nix-flake.homeManagerModules.default ];
  #   
  #   services.illuminanced = {
  #     enable = true;
  #     settings = {
  #       general = {
  #         backlight_file = "/sys/class/backlight/amdgpu_bl0/brightness";
  #         max_backlight_file = "/sys/class/backlight/amdgpu_bl0/max_brightness";
  #         illuminance_file = "/sys/bus/iio/devices/iio:device0/in_illuminance_raw";
  #       };
  #     };
  #   };
  # };
}
