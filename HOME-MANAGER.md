# Home Manager Module Documentation

This document provides detailed information about the illuminanced home-manager module.

## Quick Start

### 1. Add the flake to your configuration

In your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    illuminanced-nix-flake.url = "github:alisonjenkins/illuminanced-nix-flake";
  };

  outputs = { self, nixpkgs, home-manager, illuminanced-nix-flake, ... }@inputs: {
    homeConfigurations.yourusername = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      
      modules = [
        illuminanced-nix-flake.homeManagerModules.default
        ./home.nix
      ];
      
      extraSpecialArgs = { inherit inputs; };
    };
  };
}
```

### 2. Configure in your home.nix

```nix
{ config, pkgs, ... }:

{
  # Add the package
  home.packages = [ pkgs.illuminanced ];

  # Enable and configure the service
  services.illuminanced = {
    enable = true;
    
    settings = {
      general = {
        illuminance_file = "/sys/bus/iio/devices/iio:device0/in_illuminance_raw";
        backlight_file = "/sys/class/backlight/amdgpu_bl0/brightness";
        max_backlight_file = "/sys/class/backlight/amdgpu_bl0/max_brightness";
      };
    };
  };
}
```

### 3. Apply the configuration

```bash
home-manager switch --flake .#yourusername
```

### 4. Start the service

```bash
systemctl --user enable --now illuminanced
```

## Finding Device Paths

### Light Sensor Path

```bash
# Find the sensor
find /sys/bus -name in_illuminance_raw

# Common locations:
# Framework laptops (AMD): /sys/bus/iio/devices/iio:device0/in_illuminance_raw
# Some laptops: /sys/bus/acpi/devices/ACPI0008:00/iio:device0/in_illuminance_raw

# Test the sensor (values should change when covered/uncovered)
sudo watch cat /sys/bus/iio/devices/iio:device0/in_illuminance_raw
```

### Backlight Path

```bash
# List available backlight devices
ls /sys/class/backlight/

# Common devices:
# AMD: amdgpu_bl0 or amdgpu_bl1
# Intel: intel_backlight
# NVIDIA: nvidia_backlight

# Check current brightness
cat /sys/class/backlight/amdgpu_bl0/brightness

# Check max brightness
cat /sys/class/backlight/amdgpu_bl0/max_brightness
```

## Configuration Options

### services.illuminanced.enable
- **Type:** boolean
- **Default:** `false`
- **Description:** Enable the illuminanced service

### services.illuminanced.package
- **Type:** package
- **Default:** `pkgs.illuminanced`
- **Description:** The illuminanced package to use

### services.illuminanced.settings
- **Type:** TOML attribute set
- **Description:** Full configuration for illuminanced daemon

### services.illuminanced.wantedBy
- **Type:** list of strings
- **Default:** `[ "graphical-session.target" ]`
- **Description:** Systemd targets that want this service

## Configuration Structure

### daemonize section

```nix
settings.daemonize = {
  log_to = "syslog";  # or "/path/to/logfile"
  pid_file = "/run/user/1000/illuminanced.pid";
  log_level = "ERROR";  # OFF, ERROR, WARN, INFO, DEBUG, TRACE
};
```

### general section

```nix
settings.general = {
  check_period_in_seconds = 1;  # How often to check sensor
  light_steps = 10;              # Number of brightness levels
  min_backlight = 70;            # Minimum backlight value
  step_barrier = 0.1;            # Sensitivity threshold (0.0 - 1.0)
  
  # Device paths (adjust for your system)
  max_backlight_file = "/sys/class/backlight/intel_backlight/max_brightness";
  backlight_file = "/sys/class/backlight/intel_backlight/brightness";
  illuminance_file = "/sys/bus/acpi/devices/ACPI0008:00/iio:device0/in_illuminance_raw";
  
  # Input device for mode switching key
  event_device_mask = "/dev/input/event*";
  event_device_name = "Asus WMI hotkeys";  # Use `evtest` to find
  
  # Features
  enable_max_brightness_mode = true;  # Enable max brightness mode
  filename_for_sensor_activation = "";  # Optional sensor activation file
  
  # Key code for switching modes (use `showkey` to find)
  switch_key_code = 560;  # KEY_ALS_TOGGLE (0x230)
};
```

### kalman section

Kalman filter for smoothing sensor readings:

```nix
settings.kalman = {
  q = 1;           # Process noise covariance
  r = 20;          # Measurement noise covariance
  covariance = 10; # Initial covariance estimate
};
```

Higher `r` values make the filter trust measurements less, resulting in smoother changes.

### light section

Brightness calibration points (define how sensor readings map to brightness):

```nix
settings.light = {
  points_count = 6;  # Number of calibration points
  
  # Point format: illuminance_N and light_N
  # illuminance_N: raw sensor reading
  # light_N: brightness level (0 to light_steps)
  
  illuminance_0 = 0;     light_0 = 0;   # Darkness
  illuminance_1 = 20;    light_1 = 1;   # Very dim
  illuminance_2 = 300;   light_2 = 3;   # Dim indoor
  illuminance_3 = 700;   light_3 = 4;   # Normal indoor
  illuminance_4 = 1100;  light_4 = 5;   # Bright indoor
  illuminance_5 = 7100;  light_5 = 10;  # Very bright/outdoor
};
```

The daemon interpolates between these points.

## Calibrating Brightness

1. **Find sensor values:**
   ```bash
   # In different lighting conditions:
   cat /sys/bus/iio/devices/iio:device0/in_illuminance_raw
   ```

2. **Determine desired brightness:**
   ```bash
   # Test different brightness levels:
   echo 500 | sudo tee /sys/class/backlight/amdgpu_bl0/brightness
   ```

3. **Update calibration points:**
   Create pairs of `illuminance_N` and `light_N` values based on your findings.

## Mode Switching

The daemon can switch between three modes using a keyboard shortcut:

1. **Auto Adjust:** Automatically adjusts based on sensor (default)
2. **Disabled:** Manual brightness control
3. **Max Brightness:** Forces maximum brightness (if enabled in config)

Find your key code:
```bash
# Install evtest first: nix-shell -p evtest
sudo evtest

# Or use showkey
sudo showkey
```

Common key codes:
- `560` (0x230): KEY_ALS_TOGGLE (common on ASUS laptops)
- Check your laptop's documentation for the specific key

## Troubleshooting

### Service won't start

1. **Check service status:**
   ```bash
   systemctl --user status illuminanced
   ```

2. **View logs:**
   ```bash
   journalctl --user -u illuminanced -f
   ```

3. **Verify sensor works:**
   ```bash
   cat /sys/bus/iio/devices/iio:device0/in_illuminance_raw
   ```

4. **Check permissions:**
   Ensure your user can read sensor and write to backlight:
   ```bash
   ls -l /sys/bus/iio/devices/iio:device0/in_illuminance_raw
   ls -l /sys/class/backlight/amdgpu_bl0/brightness
   ```

### Sensor values don't change

If sensor readings are always the same:
- The sensor driver may not be working
- Try a different sensor path
- Check if sensor needs activation (some laptops require this)

### Brightness changes too frequently

Increase the `step_barrier` value to make it less sensitive:
```nix
settings.general.step_barrier = 0.2;  # More stable (default: 0.1)
```

Or adjust Kalman filter to smooth more:
```nix
settings.kalman.r = 50;  # Trust measurements less (default: 20)
```

### Brightness changes too slowly

Decrease the `step_barrier`:
```nix
settings.general.step_barrier = 0.05;  # More responsive
```

Or make Kalman filter more responsive:
```nix
settings.kalman.r = 10;  # Trust measurements more
```

## Advanced Examples

### Framework Laptop 13/16 AMD

```nix
services.illuminanced = {
  enable = true;
  settings = {
    general = {
      illuminance_file = "/sys/bus/iio/devices/iio:device0/in_illuminance_raw";
      backlight_file = "/sys/class/backlight/amdgpu_bl0/brightness";
      max_backlight_file = "/sys/class/backlight/amdgpu_bl0/max_brightness";
      event_device_name = "AT Translated Set 2 keyboard";
    };
  };
};
```

### Laptop with wildcard sensor path

If sensor device name changes between reboots:

```nix
services.illuminanced = {
  enable = true;
  settings = {
    general = {
      illuminance_file = "/sys/bus/iio/devices/*/in_illuminance_raw";
      # ... rest of config
    };
  };
};
```

### Custom log file

```nix
services.illuminanced = {
  enable = true;
  settings = {
    daemonize = {
      log_to = "${config.home.homeDirectory}/.local/share/illuminanced/illuminanced.log";
      log_level = "DEBUG";
    };
    # ... rest of config
  };
};
```

## System Service vs User Service

This module creates a **user service** (systemd user unit), which is appropriate because:
- It controls user-specific brightness settings
- Runs in user context without requiring root
- Automatically starts/stops with user session

If you need a system-wide service instead, you would need to create a NixOS module (not covered here).

## See Also

- [illuminanced upstream repository](https://github.com/mikhail-m1/illuminanced)
- [Example configuration](./example-home-config.nix)
- [README](./README.md)
