{ pkgs ? import <nixpkgs> {} }:

let
	qtPkgs = pkgs.qt6;
	qtLibs = with qtPkgs; [
		pkgs.quickshell
		qtdeclarative
		qtwayland
		qt5compat
	];
	mkPath = dir: pkgs.lib.concatMapStringsSep ":" (lib: "${lib}/lib/qt-6/${dir}") qtLibs;
in pkgs.mkShell {
	packages = with pkgs; [
		qtPkgs.qtdeclarative
		quickshell
	];

	shellHook = ''
		export QT_PLUGIN_PATH='${mkPath "plugins"}'
		export QML_IMPORT_PATH='${mkPath "qml"}'
	'';
}
