pragma Singleton
import QtQuick

import NixTheme

QtObject {
	readonly property color bg: Theme.bg0
	readonly property color accent: Theme.blue

	readonly property var bar: QtObject {
		readonly property int width: 8
	}

	readonly property var workspace: QtObject {
		readonly property int spacing: 2
		readonly property int height: 40
		readonly property color urgent: Theme.red
		readonly property color focused: Theme.blue
		readonly property color unfocused: Theme.fg3
		readonly property color empty: Theme.bg2
	}

	readonly property var volume: QtObject {
		readonly property int height: 200
		readonly property color fill: Theme.green
		readonly property color fillMuted: Theme.fg3
		readonly property color trough: Theme.bg2
	}

	readonly property var clock: QtObject {
		readonly property int spacing: 2
		readonly property int spacingBig: 10
		readonly property int barHeight: 24
		readonly property color fill: Theme.fg3
		readonly property color trough: Theme.bg2
	}
}

