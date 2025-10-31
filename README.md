# illuminanced-nix-flake

A Nix flake for [illuminanced](https://github.com/mikhail-m1/illuminanced) - an ambient light sensor daemon for Linux that automatically adjusts screen brightness based on light sensor readings.

## Features

- Builds illuminanced from source using Nix
- Provides a home-manager module for easy configuration
- Systemd user service integration
- Fully configurable through Nix options

## Usage

### Adding to your flake

Add this flake as an input to your system flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    illuminanced-nix-flake.url = "github:alisonjenkins/illuminanced-nix-flake";
  };

  outputs = { self, nixpkgs, home-manager, illuminanced-nix-flake, ... }: {
    # Your configuration here
  };
}
```

### Home Manager Configuration

Import the home-manager module and enable the service:

```nix
{ config, pkgs, illuminanced-nix-flake, ... }:

{
  imports = [
    illuminanced-nix-flake.homeManagerModules.default
  ];

  # Optional: Apply overlay to make pkgs.illuminanced available system-wide
  nixpkgs.overlays = [ illuminanced-nix-flake.overlays.default ];

  # Add the illuminanced package to your environment
  home.packages = [
    illuminanced-nix-flake.packages.${pkgs.system}.illuminanced
  ];

  # Enable and configure the service
  # The package is automatically provided - overlay is optional
  services.illuminanced = {
    enable = true;

    # Optional: customize settings
    settings = {
      general = {
        # For Framework laptops (AMD):
        illuminance_file = "/sys/bus/iio/devices/iio:device0/in_illuminance_raw";
        backlight_file = "/sys/class/backlight/amdgpu_bl0/brightness";
        max_backlight_file = "/sys/class/backlight/amdgpu_bl0/max_brightness";
        
        # For Intel laptops:
        # illuminance_file = "/sys/bus/acpi/devices/ACPI0008:00/iio:device0/in_illuminance_raw";
        # backlight_file = "/sys/class/backlight/intel_backlight/brightness";
        # max_backlight_file = "/sys/class/backlight/intel_backlight/max_brightness";
      };
      
      daemonize = {
        log_level = "INFO";  # "OFF", "ERROR", "WARN", "INFO", "DEBUG", "TRACE"
      };
    };
  };
}
```

**Note:** The home-manager module works out of the box without applying the overlay. The overlay is optional and useful if you want `pkgs.illuminanced` available elsewhere in your configuration.

### Finding Your Device Paths

Before using illuminanced, you need to find the correct device paths for your system:

1. **Find the light sensor:**
   ```bash
   find /sys/bus -name in_illuminance_raw
   # Or broader search:
   find /sys/bus -name '*illuminance*'
   ```

2. **Test the sensor:**
   ```bash
   # Replace with your actual path
   sudo watch cat /sys/bus/iio/devices/iio:device0/in_illuminance_raw
   ```
   The readings should change when you cover/uncover the sensor.

3. **Find backlight device:**
   ```bash
   ls /sys/class/backlight/
   ```

### Full Configuration Example

See [example-home-config.nix](./example-home-config.nix) for a complete example.

## Configuration Options

### `services.illuminanced.enable`
- Type: boolean
- Default: `false`
- Description: Enable the illuminanced service

### `services.illuminanced.package`
- Type: package
- Default: `pkgs.illuminanced`
- Description: The illuminanced package to use

### `services.illuminanced.settings`
- Type: TOML configuration
- Description: Configuration for illuminanced daemon

Key settings:

#### `daemonize` section:
- `log_to`: "syslog" or a file path
- `log_level`: "OFF", "ERROR", "WARN", "INFO", "DEBUG", or "TRACE"
- `pid_file`: Path to PID file

#### `general` section:
- `check_period_in_seconds`: How often to check sensor (default: 1)
- `light_steps`: Number of brightness levels (default: 10)
- `min_backlight`: Minimum backlight value
- `step_barrier`: Sensitivity threshold (default: 0.1)
- `illuminance_file`: Path to light sensor device
- `backlight_file`: Path to backlight control file
- `max_backlight_file`: Path to max brightness file
- `event_device_mask`: Device event mask (default: "/dev/input/event*")
- `event_device_name`: Name of the device for key events
- `switch_key_code`: Key code to switch modes (default: 560 for KEY_ALS_TOGGLE)

#### `kalman` section:
Kalman filter parameters for smoothing sensor readings:
- `q`: Process noise covariance (default: 1)
- `r`: Measurement noise covariance (default: 20)
- `covariance`: Initial covariance (default: 10)

#### `light` section:
Define brightness points (interpolation between values):
- `points_count`: Number of calibration points
- `illuminance_N`: Sensor reading at point N
- `light_N`: Brightness level at point N

## Supported Devices

Works on:
- ASUS Zenbooks (UX303UB, UX305LA, UX305FA, UX310UQ, UX330UA)
- Framework 13 AMD
- Framework 16 AMD
- Other laptops with compatible ambient light sensors

## Troubleshooting

If the service fails to start:

1. Check sensor path is correct:
   ```bash
   cat $(find /sys/bus -name in_illuminance_raw | head -1)
   ```

2. Check service status:
   ```bash
   systemctl --user status illuminanced
   ```

3. View logs:
   ```bash
   journalctl --user -u illuminanced -f
   ```

4. Run in foreground mode (requires building with debug logging):
   ```bash
   illuminanced -d -c ~/.config/illuminanced.toml
   ```

## License

This flake configuration is provided as-is. The illuminanced daemon itself is licensed under GPL-3.0.

## Credits

- Original illuminanced project: [mikhail-m1/illuminanced](https://github.com/mikhail-m1/illuminanced)
- Flake structure inspired by: [framework-inputmodule-rs-flake](https://github.com/alisonjenkins/framework-inputmodule-rs-flake)
