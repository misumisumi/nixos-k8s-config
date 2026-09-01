{ config, lib, pkgs, options ? {}, ... }:
let
  cfg = config.apt;

  # helpers
  mkPackageString = p: if p.version != null then "${p.name}=${p.version}" else p.name;

  desiredPackages = map mkPackageString cfg.packages;
  desiredHolds = map (p: p.name) (lib.filter (p: p.hold) cfg.packages);
  desiredPpas = cfg.ppas;

  desiredJson = pkgs.writeText "nix-apt-desired.json" (builtins.toJSON {
    packages = desiredPackages;
    holds = desiredHolds;
    ppas = desiredPpas;
    repos = lib.attrNames cfg.repos;
    pins = lib.attrNames cfg.pins;
  });

  # For validation script (system.checks / preActivationAssertions)
  # We generate a JSON with repos URIs for curl checks
  repoValidationData = pkgs.writeText "nix-apt-repos.json" (builtins.toJSON (
    lib.mapAttrs (n: v: { inherit (v) uri suite; }) cfg.repos
  ));

  stateFile = cfg.stateFile;
  stateDir = builtins.dirOf stateFile;

in
{
  ###### interface
  options.apt = {
    enable = lib.mkEnableOption "declarative APT management via Nix (apt.packages/repos/ppas/pins)";

    packages = lib.mkOption {
      type = with lib.types; listOf (coercedTo str (name: { inherit name; }) (submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "APT package name (e.g. \"htop\", \"nginx\").";
          };
          version = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "1.24.0-2ubuntu1";
            description = ''
              Exact version to install (apt syntax `package=version`, supports wildcards `1.24*` for pin+hold use).
              If null, latest candidate is installed.
            '';
          };
          hold = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Whether to `apt-mark hold` the package after installation (prevent upgrades).
              Equivalent to `Pin-Priority: 1001` but enforced via dpkg hold.
            '';
          };
        };
      }));
      default = [ ];
      example = lib.literalExpression ''[ "htop" { name = "nginx"; version = "1.24*"; hold = true; } ]'';
      description = "List of APT packages to ensure installed declaratively.";
    };

    repos = lib.mkOption {
      type = with lib.types; attrsOf (submodule {
        options = {
          uri = lib.mkOption {
            type = lib.types.str;
            example = "https://download.docker.com/linux/ubuntu";
            description = "Repository URI.";
          };
          suite = lib.mkOption {
            type = lib.types.str;
            example = "jammy";
            description = "Distribution suite (e.g. $RELEASE, jammy, noble). Use \"$RELEASE\" to be replaced at runtime if needed, but prefer explicit codename for reproducibility.";
          };
          components = lib.mkOption {
            type = with lib.types; listOf str;
            example = [ "stable" ];
            description = "Repository components.";
          };
          arch = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "amd64";
            description = "Optional Architectures restriction.";
          };
          signedBy = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "/etc/apt/keyrings/docker.gpg";
            description = "Optional Signed-By keyring path.";
          };
          types = lib.mkOption {
            type = with lib.types; listOf (enum [ "deb" "deb-src" ]);
            default = [ "deb" ];
            description = "Types field for deb822.";
          };
          trusted = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to add Trusted: yes (discouraged).";
          };
        };
      });
      default = { };
      example = lib.literalExpression ''
        {
          docker = {
            uri = "https://download.docker.com/linux/ubuntu";
            suite = "jammy";
            components = [ "stable" ];
            signedBy = "/etc/apt/keyrings/docker.gpg";
          };
        }
      '';
      description = ''
        Declarative APT repositories (DEB822 `.sources` files under `/etc/apt/sources.list.d/`).
        Each attribute name becomes `nix-apt-<name>.sources`. Managed via `environment.etc`, therefore
        fully declarative and removed automatically when dropped from configuration.
      '';
    };

    ppas = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      example = [ "ppa:fish-shell/release-3" ];
      description = ''
        List of Ubuntu PPAs (e.g. `ppa:user/repo`). Implemented as sugar over `repos`:
        at activation time `add-apt-repository -y <ppa>` is invoked (Ubuntu only).
        Tracked in `state.json` for cleanup (`onActivation.cleanup`). For reproducible
        declarative use, prefer `repos` with explicit `uri` pointing to `ppa.launchpadcontent.net`.
        PPAs are validated via `curl --head` when `onActivation.validate` is enabled.
      '';
    };

    pins = lib.mkOption {
      type = with lib.types; attrsOf (submodule {
        options = {
          package = lib.mkOption {
            type = lib.types.str;
            example = "nginx";
            description = "Package name or wildcard (`*`).";
          };
          pin = lib.mkOption {
            type = lib.types.str;
            example = "version 1.24*";
            description = "Pin expression (e.g. `version 1.24*`, `release o=Docker`, `origin \"\"`). See `man apt_preferences`.";
          };
          priority = lib.mkOption {
            type = lib.types.int;
            example = 1001;
            description = "Pin-Priority (1001 to force downgrade, -1 to forbid).";
          };
          explanation = lib.mkOption {
            type = lib.types.str;
            default = "";
            example = "Prefer nginx 1.24 from stable";
            description = "Optional Explanation field.";
          };
        };
      });
      default = { };
      example = lib.literalExpression ''
        {
          nginx-stable = { package = "nginx"; pin = "version 1.24*"; priority = 1001; };
        }
      '';
      description = ''
        APT preferences (`/etc/apt/preferences.d/nix-apt-<name>.pref`). Each attr generates one file.
        Use for version pinning without `hold`. Combine with `packages.*.hold` for strict locking.
      '';
    };

    keys = lib.mkOption {
      type = with lib.types; attrsOf (submodule {
        options = {
          url = lib.mkOption {
            type = lib.types.str;
            description = "HTTPS URL of GPG key to fetch (armored or binary).";
          };
          dest = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Destination path under /etc/apt/keyrings/. Default: /etc/apt/keyrings/nix-apt-<name>.gpg";
          };
        };
      });
      default = { };
      example = lib.literalExpression ''
        {
          docker = { url = "https://download.docker.com/linux/ubuntu/gpg"; };
        }
      '';
      description = ''
        Optional GPG keys to fetch into `/etc/apt/keyrings/`. Prefer to use `repos.<name>.signedBy`
        pointing to these paths. Keys are fetched at activation time via `curl` + `gpg --dearmor` if needed.
      '';
    };

    stateFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/nix-apt/state.json";
      description = "Path to state file tracking packages/PPAs installed by this module (for cleanup).";
    };

    onActivation = lib.mkOption {
      type = lib.types.submodule {
        options = {
          autoUpdate = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Whether to run `apt-get update` during activation. Default `false` for idempotency
              (like `homebrew.onActivation.autoUpdate`). Set to `true` to always refresh before install.
              Note: repo/PPA changes always trigger an update regardless of this setting.
            '';
          };
          upgrade = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Whether to run `apt-get upgrade -y` during activation. Default `false` for idempotency.
            '';
          };
          cleanup = lib.mkOption {
            type = lib.types.enum [ "none" "check" "uninstall" ];
            default = "none";
            example = "uninstall";
            description = ''
              What to do with packages/PPAs installed by this module but no longer in desired state.

              - `none` (default): leave them installed.
              - `check`: fail activation if extra packages/PPAs are found (like `homebrew.onActivation.cleanup=="check"`). Useful for CI / drift detection.
              - `uninstall`: remove them via `apt-get purge` / `add-apt-repository -r`.

              Packages not tracked in `state.json` (i.e. manually installed) are never removed.
            '';
          };
          validate = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Whether to validate repo reachability (`curl --head`) and package availability
              (`apt-cache madison`) before installing. When `true`, activation aborts early with
              a clear error if a repo/package does not exist.
            '';
          };
          extraFlags = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            example = [ "--allow-downgrades" ];
            description = "Extra flags appended to `apt-get install` (e.g. `--allow-downgrades`).";
          };
        };
      };
      default = { };
      description = "Options controlling activation behaviour (mirrors `homebrew.onActivation`).";
    };
  };

  ###### implementation
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

    assertions = [
      {
        assertion = lib.all (p: p.name != "") cfg.packages;
        message = "apt.packages: package name must not be empty";
      }
      {
        assertion = lib.all (n: cfg.repos.${n}.uri != "" && cfg.repos.${n}.suite != "") (lib.attrNames cfg.repos);
        message = "apt.repos: uri and suite must not be empty";
      }
      {
        assertion = lib.all (s: lib.hasPrefix "ppa:" s) cfg.ppas || cfg.ppas == [ ];
        message = "apt.ppas: each entry must start with \"ppa:\" (e.g. \"ppa:fish-shell/release-3\")";
      }
    ];

    # -- DEB822 repos via environment.etc (fully declarative, auto-removed on drop)
    environment.etc = lib.mkMerge [
      (lib.mapAttrs' (name: repo:
        lib.nameValuePair "apt/sources.list.d/nix-apt-${name}.sources" {
          text = lib.concatStringsSep "\n" ([
            "Types: ${lib.concatStringsSep " " repo.types}"
            "URIs: ${repo.uri}"
            "Suites: ${repo.suite}"
            "Components: ${lib.concatStringsSep " " repo.components}"
          ] ++ lib.optional (repo.arch != null) "Architectures: ${repo.arch}"
          ++ lib.optional (repo.signedBy != null) "Signed-By: ${repo.signedBy}"
          ++ lib.optional repo.trusted "Trusted: yes"
          ++ [ "" ]);
          mode = "0644";
        }) cfg.repos)

      # pins -> preferences.d
      (lib.mapAttrs' (name: pin:
        lib.nameValuePair "apt/preferences.d/nix-apt-${name}.pref" {
          text = lib.concatStringsSep "\n" ([
            (lib.optionalString (pin.explanation != "") "Explanation: ${pin.explanation}")
            "Package: ${pin.package}"
            "Pin: ${pin.pin}"
            "Pin-Priority: ${toString pin.priority}"
            ""
          ]);
          mode = "0644";
        }) cfg.pins)

      # keys: generate fetch script? We handle keys via activation script, but also ensure keyrings dir exists via tmpfiles.
      # If keys are provided, we don't write etc source directly; activation script fetches them.
    ];

    systemd.tmpfiles.rules = [
      "d ${stateDir} 0755 root root -"
      "d /etc/apt/keyrings 0755 root root -"
    ];

    # Ensure jq/curl/gnupg are available for activation (via PATH, not necessarily systemPackages)
    # Activation scripts run with PATH containing jq/curl; we reference them via absolute store paths.

    system.activationScripts.apt = {
      text = ''
        # Nix APT declarative management
        echo >&2 "APT: ensuring declarative state..."
        if [ ! -x /usr/bin/apt-get ]; then
          echo >&2 "APT: /usr/bin/apt-get not found, skipping."
          exit 0
        fi

        export DEBIAN_FRONTEND=noninteractive
        STATE="${stateFile}"
        DESIRED="${desiredJson}"
        REPOS_JSON="${repoValidationData}"
        JQ="${lib.getExe pkgs.jq}"
        CURL="${lib.getExe pkgs.curl}"
        GPG="${lib.getExe' pkgs.gnupg "gpg"}"

        mkdir -p "$(dirname "$STATE")"
        if [ ! -f "$STATE" ]; then
          echo '{"packages":[],"holds":[],"ppas":[],"repos":[],"pins":[]}' > "$STATE"
          chmod 600 "$STATE"
        fi

        # --- helper: repo validation (curl HEAD) when enabled
        if [ "${lib.boolToString cfg.onActivation.validate}" = "true" ]; then
          echo >&2 "APT: validating repos..."
          # Validate generic repos via curl HEAD on InRelease
          ${lib.concatMapStringsSep "\n" (name:
            let repo = cfg.repos.${name}; in
            "# repo ${name}: ${repo.uri} suite ${repo.suite}\n"
            + "if ! \"$CURL\" --fail --head --silent --location --max-time 15 \"${repo.uri}/dists/${repo.suite}/InRelease\" >/dev/null 2>&1 && \\\n"
            + "   ! \"$CURL\" --fail --head --silent --location --max-time 15 \"${repo.uri}/dists/${repo.suite}/Release\" >/dev/null 2>&1; then\n"
            + "  echo >&2 \"APT validation failed: repo ${name} not reachable: ${repo.uri} suite ${repo.suite}\"\n"
            + "  echo >&2 \"  hint: check apt.repos.${name}.uri/suite\"\n"
            + "  exit 2\n"
            + "fi"
          ) (lib.attrNames cfg.repos)}
          # Validate PPAs via ppa.launchpadcontent.net
          ${lib.concatMapStringsSep "\n" (ppa:
            "# ppa ${ppa}\n"
            + "_ppa=\"${ppa}\"\n"
            + "_user_repo=\"\${_ppa#ppa:}\"\n"
            + "_user=\"\${_user_repo%%/*}\"\n"
            + "_repo=\"\${_user_repo#*/}\"\n"
            + "_codename=\"$(. /etc/os-release 2>/dev/null; lsb_release -cs 2>/dev/null || echo \"$VERSION_CODENAME\" || echo \"noble\")\"\n"
            + "if [ -z \"$_codename\" ] || [ \"$_codename\" = \"\" ]; then _codename=\"noble\"; fi\n"
            + "if ! \"$CURL\" --fail --head --silent --location --max-time 15 \"https://ppa.launchpadcontent.net/$_user/$_repo/ubuntu/dists/$_codename/InRelease\" >/dev/null 2>&1 && \\\n"
            + "   ! \"$CURL\" --fail --head --silent --location --max-time 15 \"https://ppa.launchpadcontent.net/$_user/$_repo/ubuntu/dists/$_codename/Release\" >/dev/null 2>&1; then\n"
            + "  echo >&2 \"APT validation failed: PPA \${_ppa} not reachable for codename \${_codename}\"\n"
            + "  exit 2\n"
            + "fi"
          ) cfg.ppas}
        fi

        # --- keys: fetch if apt.keys defined
        ${lib.concatMapStringsSep "\n" (name:
          let k = cfg.keys.${name}; dest = if k.dest != null then k.dest else "/etc/apt/keyrings/nix-apt-${name}.gpg"; in
          "_key_url=\"${k.url}\"\n"
          + "_key_dest=\"${dest}\"\n"
          + "mkdir -p \"$(dirname \"$_key_dest\")\"\n"
          + "if [ ! -f \"$_key_dest\" ] || [ \"${lib.boolToString cfg.onActivation.validate}\" = \"true\" ]; then\n"
          + "  echo >&2 \"APT: fetching key ${name} from \$_key_url -> \$_key_dest\"\n"
          + "  _tmp_key=\"$(mktemp)\"\n"
          + "  if ! \"$CURL\" --fail --silent --location --max-time 30 \"$_key_url\" -o \"$_tmp_key\"; then\n"
          + "    echo >&2 \"APT: failed to fetch GPG key ${name} from \$_key_url\"\n"
          + "    rm -f \"$_tmp_key\"\n"
          + "    exit 2\n"
          + "  fi\n"
          + "  if grep -q \"BEGIN PGP\" \"$_tmp_key\" 2>/dev/null; then\n"
          + "    _tmp_dearmored=\"$(mktemp)\"\n"
          + "    if \"$GPG\" --dearmor < \"$_tmp_key\" > \"$_tmp_dearmored\" 2>/dev/null; then\n"
          + "      mv \"$_tmp_dearmored\" \"$_key_dest\"\n"
          + "    else\n"
          + "      echo >&2 \"APT: failed to dearmor key ${name}\"\n"
          + "      rm -f \"$_tmp_key\" \"$_tmp_dearmored\"\n"
          + "      exit 2\n"
          + "    fi\n"
          + "    rm -f \"$_tmp_key\"\n"
          + "  else\n"
          + "    mv \"$_tmp_key\" \"$_key_dest\"\n"
          + "  fi\n"
          + "  chmod 644 \"$_key_dest\"\n"
          + "fi"
        ) (lib.attrNames cfg.keys)}

        # --- ppas convergence (tracked in state.json)
        _ppas_desired_count=${toString (lib.length cfg.ppas)}
        _repos_changed=false
        if [ "$_ppas_desired_count" -gt 0 ] || [ "$("$JQ" -r '.ppas | length' "$STATE")" -gt 0 ]; then
          _desired_ppas="$("$JQ" -r '.ppas[]?' "$DESIRED" | sort -u)"
          _current_ppas="$("$JQ" -r '.ppas[]?' "$STATE" | sort -u)"
          _to_add_ppas="$(comm -23 <(echo "$_desired_ppas" | sort -u) <(echo "$_current_ppas" | sort -u) 2>/dev/null || true)"
          _to_remove_ppas="$(comm -13 <(echo "$_desired_ppas" | sort -u) <(echo "$_current_ppas" | sort -u) 2>/dev/null || true)"
          if [ -n "$_to_add_ppas" ]; then
            echo "$_to_add_ppas" | while IFS= read -r _ppa; do
              [ -z "$_ppa" ] && continue
              echo >&2 "APT: adding PPA $_ppa"
              if ! add-apt-repository -y "$_ppa" 2>&1; then
                echo >&2 "APT: failed to add PPA $_ppa"
                exit 2
              fi
              _repos_changed=true
            done
            # re-evaluate after add (add-apt-repository already runs apt-get update on Ubuntu, but we track)
            _repos_changed=true
          fi
          if [ -n "$_to_remove_ppas" ]; then
            if [ "${cfg.onActivation.cleanup}" = "check" ]; then
              echo >&2 "APT: cleanup check failed: PPAs not in desired but in state:"
              echo >&2 "$_to_remove_ppas"
              echo >&2 "  hint: add them to apt.ppas or set apt.onActivation.cleanup=\"uninstall\""
              exit 2
            elif [ "${cfg.onActivation.cleanup}" = "uninstall" ]; then
              echo "$_to_remove_ppas" | while IFS= read -r _ppa; do
                [ -z "$_ppa" ] && continue
                echo >&2 "APT: removing PPA $_ppa"
                add-apt-repository -r -y "$_ppa" 2>&1 || true
                _repos_changed=true
              done
            else
              echo >&2 "APT: PPAs not in desired but left installed (cleanup=none):"
              echo >&2 "$_to_remove_ppas"
            fi
          fi
        fi

        # --- apt-get update logic
        _need_update=false
        if [ "${lib.boolToString cfg.onActivation.autoUpdate}" = "true" ]; then _need_update=true; fi
        # also update if repos changed (etc files are managed declaratively, but we detect via need)
        # For simplicity, if any repo/pin file changed, apt still needs update. We trigger update if _repos_changed or if desired repos differ from state repos
        if [ "$_repos_changed" = "true" ]; then _need_update=true; fi
        # Check if repos/pins state differs (first run)
        if [ "$("$JQ" -r '.repos | length' "$STATE")" != "${toString (lib.length (lib.attrNames cfg.repos))}" ]; then _need_update=true; fi

        if [ "$_need_update" = "true" ]; then
          echo >&2 "APT: running apt-get update..."
          if ! apt-get update 2>&1; then
            echo >&2 "APT: apt-get update failed"
            exit 2
          fi
        fi

        # --- validate packages exist in cache when validate=true (after update)
        if [ "${lib.boolToString cfg.onActivation.validate}" = "true" ] && [ "$("$JQ" -r '.packages | length' "$DESIRED")" -gt 0 ]; then
          echo >&2 "APT: validating packages..."
          for _pkg in $("$JQ" -r '.packages[]?' "$DESIRED"); do
            _pkg_name="''${_pkg%%=*}"
            if ! apt-cache policy "$_pkg_name" 2>/dev/null | grep -q "Candidate:"; then
              echo >&2 "APT validation failed: package $_pkg_name not found in apt cache"
              echo >&2 "  hint: check apt.packages and apt.repos/ppas"
              exit 2
            fi
            # if version pinned, check madison
            if echo "$_pkg" | grep -q "="; then
              _ver="''${_pkg#*=}"
              # allow wildcards: skip strict check if contains *
              if ! echo "$_ver" | grep -q "\*"; then
                if ! apt-cache madison "$_pkg_name" 2>/dev/null | grep -q "''${_ver}"; then
                  echo >&2 "APT validation warning: version $_ver for $_pkg_name not found in cache (will rely on apt pin)"
                fi
              fi
            fi
          done
        fi

        # --- packages convergence
        _desired_pkgs="$("$JQ" -r '.packages[]? // empty' "$DESIRED" | tr '\n' ' ')"
        _current_pkgs="$("$JQ" -r '.packages[]? // empty' "$STATE" | tr '\n' ' ')"

        if [ -n "$_desired_pkgs" ]; then
          echo >&2 "APT: installing packages: $_desired_pkgs"
          # shellcheck disable=SC2086
          if ! apt-get install -y --no-install-recommends ${lib.concatStringsSep " " cfg.onActivation.extraFlags} $_desired_pkgs 2>&1; then
            echo >&2 "APT: apt-get install failed"
            exit 2
          fi
        fi

        # --- hold/unhold
        _desired_holds="$("$JQ" -r '.holds[]? // empty' "$DESIRED" | sort -u)"
        _current_holds="$(apt-mark showhold 2>/dev/null | sort -u || true)"
        _to_hold="$(comm -23 <(echo "$_desired_holds" | sort -u) <(echo "$_current_holds" | sort -u) 2>/dev/null || true)"
        _to_unhold="$(comm -13 <(echo "$_desired_holds" | sort -u) <(echo "$_current_holds" | sort -u) 2>/dev/null || true)"
        # only unhold packages that we previously held (i.e. in state holds) to avoid touching manual holds
        _state_holds="$("$JQ" -r '.holds[]? // empty' "$STATE" | sort -u)"
        _to_unhold_filtered="$(comm -12 <(echo "$_to_unhold" | sort -u) <(echo "$_state_holds" | sort -u) 2>/dev/null || true)"
        if [ -n "$_to_hold" ]; then
          echo "$_to_hold" | while IFS= read -r _h; do [ -z "$_h" ] && continue; echo >&2 "APT: holding $_h"; apt-mark hold "$_h" >/dev/null 2>&1 || true; done
        fi
        if [ -n "$_to_unhold_filtered" ]; then
          echo "$_to_unhold_filtered" | while IFS= read -r _h; do [ -z "$_h" ] && continue; echo >&2 "APT: unholding $_h"; apt-mark unhold "$_h" >/dev/null 2>&1 || true; done
        fi

        # --- cleanup for packages
        _to_remove_pkgs="$(comm -13 <(echo "$_desired_pkgs" | tr ' ' '\n' | sed 's/=.*//' | sort -u) <(echo "$_current_pkgs" | tr ' ' '\n' | sed 's/=.*//' | sort -u) 2>/dev/null || true)"
        # Filter to only packages that were in state (tracked)
        if [ -n "$_to_remove_pkgs" ]; then
          if [ "${cfg.onActivation.cleanup}" = "check" ]; then
            echo >&2 "APT: cleanup check failed: packages not in desired but in state:"
            echo >&2 "$_to_remove_pkgs"
            echo >&2 "  hint: add them to apt.packages or set apt.onActivation.cleanup=\"uninstall\""
            exit 2
          elif [ "${cfg.onActivation.cleanup}" = "uninstall" ]; then
            echo >&2 "APT: removing packages: $_to_remove_pkgs"
            # shellcheck disable=SC2086
            echo "$_to_remove_pkgs" | tr '\n' ' ' | xargs -r apt-get purge -y 2>&1 || true
            apt-get autoremove -y 2>&1 || true
          else
            echo >&2 "APT: packages not in desired but left installed (cleanup=none):"
            echo >&2 "$_to_remove_pkgs"
          fi
        fi

        # --- upgrade if requested
        if [ "${lib.boolToString cfg.onActivation.upgrade}" = "true" ]; then
          echo >&2 "APT: running apt-get upgrade..."
          apt-get upgrade -y 2>&1 || true
        fi

        # --- update state.json atomically
        _tmp_state="$(mktemp)"
        "$JQ" -n --slurpfile d "${desiredJson}" '$d[0]' > "$_tmp_state"
        chmod 600 "$_tmp_state"
        mv "$_tmp_state" "$STATE"
        echo >&2 "APT: state updated at $STATE"
      '';
    };

    warnings = lib.optional (cfg.ppas != [ ] && cfg.repos != { }) "apt: both repos and ppas are set; ensure they don't overlap codename handling";
    })
    (lib.optionalAttrs (options ? system-manager) (lib.mkIf (cfg.enable && cfg.onActivation.validate) {
      system-manager.preActivationAssertions.apt-validation = {
        enable = true;
        script = ''
          # Lightweight pre-activation validation (same curl checks as activation, but without apt-get update)
          # This runs before activation via system-manager engine; failures abort switch early.
          # We reuse the same logic as activation validation; if curl is missing, skip.
          if ! command -v curl >/dev/null 2>&1; then exit 0; fi
          ${lib.concatMapStringsSep "\n" (name:
            let repo = cfg.repos.${name}; in
            ''
              if ! curl --fail --head --silent --location --max-time 10 "${repo.uri}/dists/${repo.suite}/InRelease" >/dev/null 2>&1 && \
                 ! curl --fail --head --silent --location --max-time 10 "${repo.uri}/dists/${repo.suite}/Release" >/dev/null 2>&1; then
                echo "APT pre-validation: repo ${name} unreachable: ${repo.uri} suite ${repo.suite}" >&2
                exit 1
              fi
            ''
          ) (lib.attrNames cfg.repos)}
        '';
      };
    }))
  ];
}
