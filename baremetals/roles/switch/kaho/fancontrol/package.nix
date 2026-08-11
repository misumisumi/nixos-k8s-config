{
  lib,
  stdenv,
  python3,
  ipmitool,
  lm_sensors,
  makeWrapper,
}:
stdenv.mkDerivation {
  pname = "irmc-fan";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      (type == "regular" && lib.hasSuffix ".py" (baseNameOf path));
  };

  nativeBuildInputs = [
    makeWrapper
    python3
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m 0755 irmc_fan.py $out/bin/irmc-fan
    install -m 0755 irmc_fan_daemon.py $out/bin/irmc-fan-daemon
    patchShebangs $out/bin/irmc-fan $out/bin/irmc-fan-daemon
    for bin in $out/bin/irmc-fan $out/bin/irmc-fan-daemon; do
      wrapProgram $bin --prefix PATH : ${lib.makeBinPath [ python3 ipmitool lm_sensors ]}
    done
    runHook postInstall
  '';
}
