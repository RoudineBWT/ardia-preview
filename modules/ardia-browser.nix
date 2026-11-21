{ config, lib, pkgs, ... }:

with lib;

let
  makeArdiaModule = { name, description, pkgName }:
    let
      cfg = config.programs.${name};
    in
    {
      options.programs.${name} = {
        enable = mkEnableOption description;

        package = mkOption {
          type = types.package;
          default = pkgs.${pkgName} or (throw "Package ${pkgName} not found in pkgs");
          defaultText = literalExpression "pkgs.${pkgName}";
          description = "The ${description} package to use.";
        };

        commandLineArgs = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Command line arguments passed to the browser.";
        };
      };

      config = mkIf cfg.enable {
        environment.systemPackages = [
          (if cfg.commandLineArgs != [ ] then
            pkgs.symlinkJoin {
              name = "${cfg.package.name}-wrapped";
              paths = [ cfg.package ];
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram $out/bin/ardia \
                  --add-flags "${escapeShellArgs cfg.commandLineArgs}"
              '';
            }
          else
            cfg.package)
        ];
      };
    };
in
{
  imports = [
    (makeArdiaModule { name = "ardia"; description = "Ardia Browser"; pkgName = "ardia"; })
    (makeArdiaModule { name = "ardia-nightly"; description = "Ardia Browser Nightly"; pkgName = "ardia-nightly"; })
  ];
}
