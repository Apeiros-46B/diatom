import QtQuick
import Quickshell
import Niri

import Shared
import "./widgets"
import "./popups"

PanelWindow {
	id: root

	required property Niri niri
	required property ShellScreen output

	anchors {
		left: true
		top: true
		bottom: true
	}
	implicitWidth: Style.bar.thickness
	color: Style.bg

	Workspaces {
		anchors.top: parent.top
		niri: root.niri
		output: root.output
	}

	// {{{ middle section
	property bool volumeHovered: false
	property bool musicHovered: false

	Volume {
		anchors.verticalCenter: parent.verticalCenter
		id: volume
		HoverHandler {
			onHoveredChanged: root.volumeHovered = hovered
		}
	}

	Music {
		id: musicPopup
		bar: root
		implicitWidth: height * 2
		implicitHeight: volume.height
		HoverHandler {
			onHoveredChanged: root.musicHovered = hovered
		}
	}

	PopupController {
		id: musicController
		target: musicPopup
		triggerHovered: root.volumeHovered
		targetHovered: root.musicHovered
		pinned: root.niri.overview.isOpen
	}
	// }}}

	// {{{ bottom section
	property bool clockHovered: false
	property bool calendarHovered: false

	Clock {
		anchors.bottom: parent.bottom
		id: clock
		HoverHandler {
			onHoveredChanged: root.clockHovered = hovered
		}
	}

	Calendar {
		id: calendarPopup
		bar: root
		implicitWidth: musicPopup.width
		implicitHeight: clock.height
		HoverHandler {
			onHoveredChanged: root.calendarHovered = hovered
		}
	}

	PopupController {
		id: calenderController
		target: calendarPopup
		triggerHovered: root.clockHovered
		targetHovered: root.calendarHovered
		pinned: root.niri.overview.isOpen
	}
	// }}}
}
