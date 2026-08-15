import QtQuick
import Quickshell
import Niri

import Shared
import "./widgets"

PanelWindow {
	id: root

	required property Niri niri

	anchors {
		right: true
		top: true
		bottom: true
	}
	implicitWidth: Style.bar.thickness
	color: Style.bg
}
