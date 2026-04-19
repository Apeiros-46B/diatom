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

	// {{{ middle section
	property bool volumeHovered: false
	property bool musicHovered: false

	Music {
		id: musicPopup
		bar: root
		HoverHandler {
			onHoveredChanged: root.musicHovered = hovered
		}
	}

	Volume {
		anchors.verticalCenter: parent.verticalCenter
		HoverHandler {
			onHoveredChanged: root.volumeHovered = hovered
		}
	}

	PopupController {
		id: musicController
		target: musicPopup
		triggerHovered: root.volumeHovered
		targetHovered: root.musicHovered
	}
	// }}}

	Clock {
		anchors.bottom: parent.bottom
	}
}
