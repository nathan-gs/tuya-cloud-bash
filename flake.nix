{
  description = "Tuya Cloud Bash Prometheus Exportor";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-21.11;

  outputs = { self, nixpkgs }: {

    defaultPackage.x86_64-linux =
      # Notice the reference to nixpkgs here.
      with import nixpkgs { system = "x86_64-linux"; };

      { 
        nixosModules.tuya-cloud-prometheus = { lib, pkgs, config, ... }:
        let
          cfg = config.services.tuya-cloud-prometheus;
        in
        {
          options = with lib; {
            services.tuya-cloud-prometheus = {
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
            };
          };
          config = with lib; mkIf cfg.enable {
            systemd.services.tuya-cloud-prometheus = {
              enable = true;
              path = [ pkgs.bash pkgs.openssl pkgs.curl pkgs.jq ];
              environment = {
                TUYA_CLOUD_CLIENTID = cfg.clientId;
                TUYA_CLOUD_SECRET = cfg.secret;
                TUYA_CLOUD_BASEURL = cfg.baseUrl;
              };
              script = ''
                mkdir -pm 0775 ${cfg.prometheusTextDirectory}
                F=${cfg.prometheusTextDirectory}/tuya-cloud.prom
                cat /dev/null > $F.next
                ${self.outputs.packages.tuya-cloud-bash}/bin/tuya_prometheus_exportor.sh > $F
                mv $F.next $F
              '';
              startAt = "*:0/15";
            };
          };
        };
      };

      {
        stdenv.mkDerivation {
          name = "tuya-cloud-bash";
          buildInputs = [jq curl openssl];
          src = self;
          buildPhase = "";
          installPhase = "mkdir -p $out/bin; cp *.sh $out/bin";
        };
      };
  };
}
