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
	property bool showMusic: false

	property bool volumeHovered: false
	Volume {
		anchors.verticalCenter: parent.verticalCenter
		HoverHandler {
			onHoveredChanged: root.volumeHovered = hovered
		}
	}
	Timer {
		id: showTimer
		interval: 0
		running: root.volumeHovered && !root.showMusic
		onTriggered: root.showMusic = true
	}

	property bool musicHovered: false
	Music {
		id: musicPopup
		bar: root
		visible: root.showMusic
		HoverHandler {
			onHoveredChanged: root.musicHovered = hovered
		}
	}
	Timer {
		id: hideTimer
		interval: 100
		running: !root.volumeHovered && !root.musicHovered && root.showMusic
		onTriggered: root.showMusic = false
	}
	// }}}

	Clock {
		anchors.bottom: parent.bottom
	}
}
