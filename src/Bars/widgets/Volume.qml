import QtQuick
import Quickshell.Services.Pipewire

import Shared

Rectangle {
	id: volumeBar
	width: Style.bar.width
	height: Style.volume.height
	color: Style.volume.trough

	property real progressValue: 0.7
	property var activeSink: Pipewire.defaultAudioSink
	PwObjectTracker {
		objects: [ volumeBar.activeSink ]
	}

	property real volume: activeSink?.audio?.volume ?? 0.0
	property bool muted: activeSink?.audio?.muted ?? false

	Rectangle {
		id: volumeBarFill
		anchors {
			left: parent.left
			right: parent.right
			bottom: parent.bottom
		}

		height: parent.height * Math.min(1.0, parent.volume)
		Behavior on height {
			NumberAnimation {
				duration: 100
				easing.type: Easing.OutQuad
			}
		}

		color: parent.muted ? Style.volume.fillMuted : Style.volume.fill
		Behavior on color {
			ColorAnimation { duration: 100 }
		}
	}

	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.LeftButton | Qt.RightButton

		function setVolumeFromMouse(mouseY) {
			if (!volumeBar.activeSink || !volumeBar.activeSink.audio) return;
			let p = 1.0 - (mouseY / height);
			volumeBar.activeSink.audio.volume = Math.max(0.0, Math.min(1.0, p));
		}

		onWheel: (ev) => {
			if (!volumeBar.activeSink || !volumeBar.activeSink.audio) return;
			var currentVol = volumeBar.activeSink.audio.volume;
			var delta = (ev.angleDelta.y > 0) ? 0.05 : -0.05;
			var p = Math.round((currentVol + delta) * 20) / 20;
			p = Math.max(0.0, Math.min(1.0, p));
			volumeBar.activeSink.audio.volume = p;
		}
		onPressed: (ev) => {
			if (ev.button === Qt.LeftButton) {
				setVolumeFromMouse(ev.y);
			}
		}
		onPositionChanged: (ev) => {
			if (pressedButtons & Qt.LeftButton) {
				setVolumeFromMouse(ev.y);
			}
		}
		onClicked: (mouse) => {
			if (mouse.button === Qt.RightButton) {
				if (volumeBar.activeSink && volumeBar.activeSink.audio) {
					volumeBar.activeSink.audio.muted = !volumeBar.activeSink.audio.muted;
				}
			}
		}
	}
}
