import QtQuick
import Quickshell
import Niri

import Shared
import "./widgets"

PanelWindow {
	id: root
	anchors {
		right: true
		top: true
		bottom: true
	}
	implicitWidth: Style.bar.width;
	color: Style.bg;

	required property Niri niri

	// Workspaces {
	// 	anchors.top: parent.top
	// 	niri: root.niri
	// }
}
