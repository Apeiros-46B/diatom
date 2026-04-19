import QtQuick
import Quickshell
import Niri

import Shared
import "../Bars/widgets"

PanelWindow {
	id: root
	anchors {
		left: true
		top: true
		bottom: true
	}
	implicitWidth: Style.bar.width * 2;
	color: Style.bg;
}
