import QtQuick
import Quickshell
import Niri

import Shared

PanelWindow {
	id: root

	required property Niri niri

	anchors {
		bottom: true
		left: true
		right: true
	}
	implicitHeight: Style.bar.thickness
	color: Style.bg
}
