{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.illuminanced;
  
  # Fallback to building the package if not available in pkgs (e.g., overlay not applied)
  defaultPackage = 
    if pkgs ? illuminanced 
    then pkgs.illuminanced
    else pkgs.callPackage (import ./illuminanced) {};
  
  illuminanced = cfg.package;

  configFormat = pkgs.formats.toml {};
  configFile = configFormat.generate "illuminanced.toml" cfg.settings;

in
{
  options.services.illuminanced = {
    enable = mkEnableOption "illuminanced - Ambient Light Sensor Daemon";

    package = mkOption {
      type = types.package;
      default = defaultPackage;
      defaultText = literalExpression "pkgs.illuminanced";
      description = ''
        The illuminanced package to use.
        
        Defaults to pkgs.illuminanced if the overlay is applied,
        otherwise builds the package from this flake.
      '';
    };

    settings = mkOption {
      type = configFormat.type;
      default = {
        daemonize = {
          log_to = "syslog";
          pid_file = "/run/user/1000/illuminanced.pid";
          log_level = "ERROR";
        };
        general = {
          check_period_in_seconds = 1;
          light_steps = 10;
          min_backlight = 70;
          step_barrier = 0.1;
          max_backlight_file = "/sys/class/backlight/intel_backlight/max_brightness";
          backlight_file = "/sys/class/backlight/intel_backlight/brightness";
          illuminance_file = "/sys/bus/acpi/devices/ACPI0008:00/iio:device0/in_illuminance_raw";
          event_device_mask = "/dev/input/event*";
          event_device_name = "Asus WMI hotkeys";
          enable_max_brightness_mode = true;
          filename_for_sensor_activation = "";
          switch_key_code = 560;
        };
        kalman = {
          q = 1;
          r = 20;
          covariance = 10;
        };
        light = {
          points_count = 6;
          illuminance_0 = 0;
          light_0 = 0;
          illuminance_1 = 20;
          light_1 = 1;
          illuminance_2 = 300;
          light_2 = 3;
          illuminance_3 = 700;
          light_3 = 4;
          illuminance_4 = 1100;
          light_4 = 5;
          illuminance_5 = 7100;
          light_5 = 10;
        };
      };
      example = literalExpression ''
        {
          daemonize = {
            log_to = "syslog";
            log_level = "INFO";
          };
          general = {
            illuminance_file = "/sys/bus/iio/devices/iio:device0/in_illuminance_raw";
            backlight_file = "/sys/class/backlight/amdgpu_bl0/brightness";
            max_backlight_file = "/sys/class/backlight/amdgpu_bl0/max_brightness";
          };
        }
      '';
      description = ''
        Configuration for illuminanced. See the example config at
        <https://github.com/mikhail-m1/illuminanced/blob/master/illuminanced.toml>
        for all available options.
      '';
    };

    wantedBy = mkOption {
      type = types.listOf types.str;
      default = [ "graphical-session.target" ];
      description = "Systemd targets that should want this service.";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.illuminanced = {
      Unit = {
        Description = "Ambient Light Sensor Daemon";
        Documentation = "https://github.com/mikhail-m1/illuminanced";
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "forking";
        ExecStart = "${illuminanced}/bin/illuminanced -c ${configFile}";
        PIDFile = cfg.settings.daemonize.pid_file or "/run/user/1000/illuminanced.pid";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install = {
        WantedBy = cfg.wantedBy;
      };
    };
  };
}
