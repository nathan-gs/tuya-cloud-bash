{
  inputs = {
    nixpkgs.url = "nixpkgs/release-21.11";    
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, flake-compat }:
    flake-utils.lib.eachDefaultSystem
      (
        system:
        let
          pkgs = import nixpkgs
            {
              inherit system; overlays = [
              self.overlay              
            ];
              config = {
                allowUnsupportedSystem = true;
              };
            };
        in
        with pkgs;
        rec {
          packages = flake-utils.lib.flattenTree {
            tuya-cloud-bash = pkgs.tuya-cloud-bash;
          };

          defaultPackage = packages.tuya-cloud-bash;

          checks.build = packages.tuya-cloud-bash;

          devShell = mkShell {
            shellHook = ''
              source ${pkgs.tuya-cloud-bash}/bin/tuya.sh
            '';
          };
        }
      ) // {
      nixosModules.tuya-prometheus = { lib, pkgs, config, ... }:
        let
          cfg = config.services.tuya-prometheus;
        in
        {
          options = with lib; {
            services.tuya-prometheus = {
              enable = mkOption {
                type = types.bool;
                default = false;
              };

              clientId = mkOption {
                type = types.str;
              };

              secret = mkOption {
                type = types.str;
              };

              baseUrl = mkOption {
                type = types.str;
                default = "https://openapi.tuyaeu.com";
              };

              prometheusTextDirectory = mkOption {
                type = types.str;
                default = "/var/lib/prometheus-node-exporter/text-files";
              };

              package = mkOption {
                type = types.package;
                default = self.outputs.packages."${pkgs.system}".tuya-cloud-bash;
                description = "The Tuya Cloud Bash package.";
              };
              
              startAt = mkOption {
                types.str;
                default = "*:0/15";
              };
            };
          };

          config = with lib; mkIf cfg.enable {
            systemd.services.tuya-prometheus = {
              enable = true;
              path = [ pkgs.bash pkgs.openssl pkgs.curl pkgs.jq pkgs.gawk pkgs.gnused ];
              environment = {
                TUYA_CLOUD_CLIENTID = cfg.clientId;
                TUYA_CLOUD_SECRET = cfg.secret;
                TUYA_CLOUD_BASEURL = cfg.baseUrl;
              };
              script = ''
                mkdir -pm 0775 ${cfg.prometheusTextDirectory}
                F=${cfg.prometheusTextDirectory}/tuya-cloud.prom
                cat /dev/null > $F.next
                source ${cfg.package}/bin/tuya.sh
                source ${cfg.package}/bin/tuya_prometheus_exporter.sh
                                
                accessToken=$(tuya_get_token "$TUYA_CLOUD_CLIENTID" "$TUYA_CLOUD_SECRET" "$TUYA_CLOUD_BASEURL")              
                # Batch query for the list of associated App user dimension devices
                tuya "$TUYA_CLOUD_CLIENTID" "$TUYA_CLOUD_SECRET" "$TUYA_CLOUD_BASEURL" $accessToken get '/v1.0/iot-01/associated-users/devices?last_row_key=' | tuya_parse_batch_query > $F.next
                
                mv $F.next $F
              '';
              startAt = cfg.startAt;
            };

            
          };
        };

      overlay = final: prev: {
        tuya-cloud-bash = with final;
          (
            stdenv.mkDerivation {
              name = "tuya-cloud-bash";
              #buildInputs = [jq curl openssl];
              src = self;
              buildPhase = "";
              installPhase = "mkdir -p $out/bin; cp *.sh $out/bin";
            }
          );
        
      };
  };
}
