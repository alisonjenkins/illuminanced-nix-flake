{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.illuminanced;
  
  # Extract backlight device names from settings
  backlightFile = cfg.settings.general.backlight_file or "";
  maxBacklightFile = cfg.settings.general.max_backlight_file or "";
  
  # Extract device name from path like /sys/class/backlight/amdgpu_bl0/brightness
  extractDeviceName = path: 
    let
      parts = splitString "/" path;
      deviceIndex = length (filter (x: x == "backlight") parts);
    in
      if deviceIndex > 0 && length parts > deviceIndex + 1
      then elemAt parts (deviceIndex + 1)
      else null;
  
  backlightDevice = extractDeviceName backlightFile;
  
  # Generate udev rules package
  udevRules = pkgs.writeTextFile {
    name = "illuminanced-udev-rules";
    text = ''
      # Backlight access rules for illuminanced
      # Allows users to control backlight brightness
      
      # Generic backlight devices - use uaccess tag for systemd-logind integration
      ACTION=="add", SUBSYSTEM=="backlight", TAG+="uaccess"
      
      ${optionalString (backlightDevice != null) ''
      # Specific device: ${backlightDevice}
      SUBSYSTEM=="backlight", KERNEL=="${backlightDevice}", TAG+="uaccess"
      ''}
      
      # Common backlight devices
      SUBSYSTEM=="backlight", KERNEL=="intel_backlight", TAG+="uaccess"
      SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl*", TAG+="uaccess"
      SUBSYSTEM=="backlight", KERNEL=="nvidia_*", TAG+="uaccess"
      SUBSYSTEM=="backlight", KERNEL=="acpi_video*", TAG+="uaccess"
    '';
    destination = "/etc/udev/rules.d/90-illuminanced-backlight.rules";
  };

in
{
  options.services.illuminanced = {
    enable = mkEnableOption "illuminanced ambient light sensor daemon";

    settings = mkOption {
      type = types.submodule {
        freeformType = pkgs.formats.toml { }.type;
        options = {};
      };
      default = {};
      description = ''
        Configuration for illuminanced daemon.
        
        This is used by the NixOS module to generate udev rules.
        For the full service configuration, use the home-manager module.
      '';
      example = literalExpression ''
        {
          general = {
            backlight_file = "/sys/class/backlight/amdgpu_bl0/brightness";
            max_backlight_file = "/sys/class/backlight/amdgpu_bl0/max_brightness";
          };
        }
      '';
    };

    enableUdevRules = mkOption {
      type = types.bool;
      default = cfg.enable;
      defaultText = literalExpression "config.services.illuminanced.enable";
      description = ''
        Enable udev rules for backlight access.
        
        This grants users access to backlight control using the uaccess tag,
        which works with systemd-logind to give access to the active session user.
      '';
    };
  };

  config = mkIf cfg.enableUdevRules {
    services.udev.packages = [ udevRules ];
    
    # Add video group (standard group for backlight access)
    users.groups.video = {};
    
    # Helpful assertion
    assertions = [
      {
        assertion = cfg.settings ? general -> cfg.settings.general ? backlight_file;
        message = ''
          services.illuminanced.settings.general.backlight_file should be set
          to generate appropriate udev rules.
        '';
      }
    ];
  };
}
