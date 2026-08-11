{
  pkgs,
  lib,
  ...
}:
let
  config = {
    daemon = {
      interval = 10;
      min_apply_interval = 20;
      min_pwm = 25;
      max_pwm = 100;
      step_up = 20;
      step_down = 5;
      down_hysteresis = 5;
      missing_sensor_pwm = 50;
      fail_pwm = 60;
      clear_on_exit = true;
    };
    sensors = [
      {
        chip = "coretemp-isa-0000";
        label = "Package id 0";
        ramp = [
          [
            40
            25
          ]
          [
            60
            35
          ]
          [
            75
            50
          ]
          [
            85
            70
          ]
          [
            95
            100
          ]
        ];
      }
      {
        chip = "pch_cannonlake-virtual-0";
        label = "temp1";
        ramp = [
          [
            60
            25
          ]
          [
            70
            35
          ]
          [
            80
            50
          ]
          [
            85
            70
          ]
          [
            95
            100
          ]
        ];
      }
    ];
  };

  configFile = pkgs.writeText "irmc-fan-daemon.json" (builtins.toJSON config);

  fancontrol = pkgs.callPackage ./package.nix { };
in
{
  systemd.services.irmc-fan-daemon = {
    description = "Fujitsu iRMC smart fan control";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      Environment = "PYTHONUNBUFFERED=1";
      ExecStart = "${fancontrol}/bin/irmc-fan-daemon --config ${configFile}";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
