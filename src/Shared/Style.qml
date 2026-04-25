pragma Singleton
import QtQuick

import NixTheme

QtObject {
	id: root

	readonly property color bg: Theme.bg0
	readonly property color fg: Theme.fg0
	readonly property color fgSubtle: Theme.fg3
	readonly property color bgPopup: Theme.bg1
	readonly property color bgPopup2: Theme.bg2
	readonly property color bgRaised: Theme.bg3
	readonly property color accent: Theme.blue

	readonly property var lengths: QtObject {
		readonly property int tiny: 2
		readonly property int mini: 4
		readonly property int small: 8 // should match wm gap size
		readonly property int medium: 16
		readonly property int huge: 64
	}

	readonly property var bar: QtObject {
		readonly property int width: root.lengths.small
		readonly property int popupGap: width + root.lengths.small
	}

	readonly property var workspace: QtObject {
		readonly property int spacing: root.lengths.tiny
		readonly property int height: root.lengths.small * 5
		readonly property color urgent: Theme.red
		readonly property color focused: Theme.blue
		readonly property color unfocused: Theme.fg3
		readonly property color empty: Theme.bg2
	}

	readonly property var volume: QtObject {
		readonly property int height: root.bar.width * 25
		readonly property color fill: Theme.green
		readonly property color fillMuted: Theme.fg3
		readonly property color track: Theme.bg2
	}

	readonly property var musicPopup: QtObject {
		readonly property int buttonSize: root.lengths.medium
		readonly property int barThickness: root.lengths.mini
		readonly property int albumArtSize: root.lengths.huge
		readonly property real bgArtOpacity: 0.2
		readonly property color bgArtDark: root.bgPopup
		readonly property color bgArtLight: root.fgSubtle
		readonly property color progressFill: Theme.blue
		readonly property color progressTrack: root.bgRaised
	}

	readonly property var clock: QtObject {
		readonly property int spacing: root.lengths.tiny
		readonly property int spacingBig: root.lengths.tiny * 5
		readonly property int barHeight: root.lengths.small * 3
		readonly property color fill: Theme.fg3
		readonly property color track: Theme.bg2
	}

	readonly property var calendarPopup: QtObject {
		readonly property int headerFontPx: 24
		readonly property int worldClockHeight: 64
	}

	readonly property var genericSlider: QtObject {
		readonly property color fill: Theme.blue
		readonly property color track: Theme.bg2
	}
}

