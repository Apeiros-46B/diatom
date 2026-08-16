import QtQuick
import Quickshell
import Niri

import Shared
import "./widgets"

PanelWindow {
	id: root

	required property Niri niri
	required property ShellScreen output

	anchors {
		top: true
		left: true
		right: true
	}
	implicitHeight: Style.bar.thickness
	color: Style.bg

	Minimap {
		anchors.left: parent.left
		niri: root.niri
		output: root.output
	}
}
