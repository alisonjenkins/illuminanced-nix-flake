{ config, pkgs, illuminanced-nix-flake, ... }:

{
  imports = [
    illuminanced-nix-flake.homeManagerModules.default
  ];

  # Optional: Apply the overlay to make pkgs.illuminanced available
  # nixpkgs.overlays = [ illuminanced-nix-flake.overlays.default ];

  # Add illuminanced to your packages
  home.packages = [
    illuminanced-nix-flake.packages.${pkgs.system}.illuminanced
  ];

  # Enable and configure illuminanced service
  # Note: The package will be automatically provided from the flake,
  # whether or not you apply the overlay above
  services.illuminanced = {
    enable = true;

    # Full configuration example
    settings = {
      daemonize = {
        log_to = "syslog";
        pid_file = "/run/user/1000/illuminanced.pid";
        log_level = "INFO";  # Change to "DEBUG" for more verbose logging
      };

      general = {
        check_period_in_seconds = 1;
        light_steps = 10;
        min_backlight = 70;
        step_barrier = 0.1;

        # Framework Laptop AMD (adjust for your system)
        max_backlight_file = "/sys/class/backlight/amdgpu_bl0/max_brightness";
        backlight_file = "/sys/class/backlight/amdgpu_bl0/brightness";
        illuminance_file = "/sys/bus/iio/devices/iio:device0/in_illuminance_raw";

        # For Intel systems, use these instead:
        # max_backlight_file = "/sys/class/backlight/intel_backlight/max_brightness";
        # backlight_file = "/sys/class/backlight/intel_backlight/brightness";
        # illuminance_file = "/sys/bus/acpi/devices/ACPI0008:00/iio:device0/in_illuminance_raw";

        event_device_mask = "/dev/input/event*";
        event_device_name = "Asus WMI hotkeys";  # Adjust for your laptop
        enable_max_brightness_mode = true;
        filename_for_sensor_activation = "";
        
        # KEY_ALS_TOGGLE - adjust if your laptop uses a different key
        switch_key_code = 560;
      };

      # Kalman filter settings for sensor smoothing
      kalman = {
        q = 1;
        r = 20;
        covariance = 10;
      };

      # Brightness calibration points
      # Adjust these values based on your preferences and environment
      light = {
        points_count = 6;

        # Point 0: Complete darkness
        illuminance_0 = 0;
        light_0 = 0;

        # Point 1: Very dim
        illuminance_1 = 20;
        light_1 = 1;

        # Point 2: Indoor dim lighting
        illuminance_2 = 300;
        light_2 = 3;

        # Point 3: Normal indoor lighting
        illuminance_3 = 700;
        light_3 = 4;

        # Point 4: Bright indoor lighting
        illuminance_4 = 1100;
        light_4 = 5;

        # Point 5: Very bright / outdoor
        illuminance_5 = 7100;
        light_5 = 10;
      };
    };
  };
}
