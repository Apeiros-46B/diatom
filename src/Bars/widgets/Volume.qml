import QtQuick
import Quickshell.Services.Pipewire

import Shared

Rectangle {
	id: root
	width: Style.bar.width
	height: Style.volume.height
	color: Style.volume.trough

	property real progressValue: 0.7
	property var activeSink: Pipewire.defaultAudioSink
	PwObjectTracker {
		objects: [ root.activeSink ]
	}

	property real volume: activeSink?.audio?.volume ?? 0.0
	property bool muted: activeSink?.audio?.muted ?? false

	Slider {
		anchors.fill: parent
		vertical: true
		value: root.volume
		fillColor: root.muted ? Style.volume.fillMuted : Style.volume.fill

		onMoved: (value) => {
			if (root.activeSink && root.activeSink.audio) {
				root.activeSink.audio.volume = value;
			}
		}
	}

	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.RightButton
		onClicked: {
			if (root.activeSink && root.activeSink.audio) {
				root.activeSink.audio.muted = !root.activeSink.audio.muted;
			}
		}
	}
}
