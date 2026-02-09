import Quickshell
import QtQuick
import Niri

import Shared
import "./widgets"

PanelWindow {
	id: root
	required property Niri niri

	anchors {
		left: true
		top: true
		bottom: true
	}
	implicitWidth: Style.bar.width;
	color: Style.bg;

	Workspaces {
		niri: root.niri
	}
}
