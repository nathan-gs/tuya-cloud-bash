{
  description = "Tuya Cloud Bash Prometheus Exportor";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-21.11;

  outputs = { self, nixpkgs }: {

    defaultPackage.x86_64-linux =
      # Notice the reference to nixpkgs here.
      with import nixpkgs { system = "x86_64-linux"; };

      stdenv.mkDerivation {
        name = "tuya-cloud-bash";
        buildInputs = [jq curl openssl];
        src = self;
        buildPhase = "";
        installPhase = "mkdir -p $out/bin; cp *.sh $out/bin";
      };

  };
}
