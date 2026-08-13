{
	inputs = { nixpkgs = { type = "indirect"; id = "nixpkgs"; }; };

	outputs = { self, nixpkgs }: {
		packages = builtins.mapAttrs (system: pkgs: { default = import ./default.nix { inherit system pkgs; }; }) nixpkgs.legacyPackages;
	};
}
