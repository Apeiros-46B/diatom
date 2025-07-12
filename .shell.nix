{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
	packages = with pkgs; [
		qt6.full
	];
}
