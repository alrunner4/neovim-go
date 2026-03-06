{
	inputs = { nixpkgs = { type = "indirect"; id = "nixpkgs"; }; };

	outputs = { self, nixpkgs }: {
		packages = builtins.mapAttrs (import ./packages.nix) nixpkgs.legacyPackages;
	};
}
