import QtQuick
import Quickshell
import Niri

import Shared
import "./widgets"
import "./popups"

PanelWindow {
	id: root
	anchors {
		left: true
		top: true
		bottom: true
	}
	implicitWidth: Style.bar.width
	color: Style.bg

	required property Niri niri

	Workspaces {
		anchors.top: parent.top
		niri: root.niri
	}

	Volume {
		anchors.verticalCenter: parent.verticalCenter
	}

	Music {
		bar: root
	}

	Clock {
		anchors.bottom: parent.bottom
	}
}
