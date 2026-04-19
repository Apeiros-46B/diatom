pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

import Shared

PopupWindow {
	visible: true
	id: root
	anchor {
		window: bar
		rect.x: Style.bar.popupGap
		rect.y: bar.height / 2 - height / 2
	}
	implicitWidth: 400
	implicitHeight: Style.musicPopup.height
	color: Style.popupBg

	required property PanelWindow bar

	property string preferred: "io.github.quodlibet.QuodLibet"
	property MprisPlayer player: selectPlayer()

	function selectPlayer() {
		for (const candidate of Mpris.players.values) {
			if (candidate.desktopEntry === preferred) {
				return candidate;
			}
		}
		return null;
	}

	property bool needsLyricsLoad: true
	property int activeLyricIndex: -1

	ListModel { id: lyricModel }

	onActiveLyricIndexChanged: {
		// update ListView from our property
		lyricList.currentIndex = activeLyricIndex;
		if (activeLyricIndex === -1 && lyricModel.count > 0) {
			lyricList.positionViewAtBeginning();
		}
	}

	function loadLyrics(audioUrl) {
		lyricModel.clear();
		activeLyricIndex = -1;

		if (!audioUrl || !audioUrl.startsWith('file://')) return;

		const xhr = new XMLHttpRequest();
		xhr.open("GET", audioUrl.substring(0, audioUrl.lastIndexOf('.')) + '.lrc');
		xhr.onreadystatechange = function() {
			if (xhr.readyState !== XMLHttpRequest.DONE) return;
			if (xhr.status === 200 || xhr.status === 0) {
				parseLrc(xhr.responseText);
			}
		}
		xhr.send();
	}

	function parseLrc(text) {
		const lines = text.split('\n');
		const parsed = [];
		const timeRegex = /\[(\d+):(\d+\.\d+)\]/g;

		for (const line of lines) {
			const times = [];
			let match;

			// extract all timestamps from the line
			// (a line can repeat if there are multiple timestamps)
			while ((match = timeRegex.exec(line)) !== null) {
				const minutes = parseInt(match[1]);
				const seconds = parseFloat(match[2]);
				const time = minutes * 60 + seconds;
				times.push(time);
			}

			if (times.length > 0) {
				var lyricText = line.replace(timeRegex, '').trim();
				if (lyricText === '') {
					lyricText = '♪';
				}

				// separate entry for each timestamp
				for (const time of times) {
					parsed.push({ time: time, lyricText: lyricText });
				}
			}
		}

		// sort chronologically
		parsed.sort((a, b) => a.time - b.time);

		for (var line of parsed) {
			lyricModel.append(line);
		}
	}

	function updateCurrentLyric() {
		if (lyricModel.count === 0 || !player) return;

		const pos = player.position;
		let newIndex = activeLyricIndex;

		if (newIndex < 0) newIndex = 0;

		// backwards seeking, start from the beginning
		if (newIndex > 0 && pos < lyricModel.get(newIndex).time) {
			newIndex = 0;
		}

		// search forward from current lyric
		while (newIndex + 1 < lyricModel.count && pos >= lyricModel.get(newIndex + 1).time) {
			newIndex++;
		}

		// position before the very first lyric
		if (newIndex === 0 && pos < lyricModel.get(0).time) {
			newIndex = -1;
		}

		activeLyricIndex = newIndex;
	}

	Connections {
		target: root.player

		function onMetadataChanged() {
			root.needsLyricsLoad = true;
		}
	}

	Timer {
		interval: 100
		running: root.player && root.player.playbackState === MprisPlaybackState.Playing
		repeat: true
		onTriggered: {
			if (root.needsLyricsLoad) {
				root.needsLyricsLoad = false;
				if (root.player && root.player.metadata) {
					root.loadLyrics(root.player.metadata["xesam:url"]);
				}
			}

			root.updateCurrentLyric();
		}
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 8

		RowLayout {
			Layout.fillWidth: true
			spacing: 8

			Image {
				Layout.preferredWidth: 64
				Layout.preferredHeight: 64
				fillMode: Image.PreserveAspectFit
				mipmap: true // smoother downscale
				source: root.player.trackArtUrl
			}

			Column {
				anchors.verticalCenter: parent.verticalCenter

				Text {
					color: Style.fg
					text: root.player.trackTitle
					font {
						bold: true
						pointSize: 11
					}
				}

				Text {
					color: Style.fg
					text: root.player.trackAlbum
				}

				Text {
					color: Style.fg
					text: root.player.trackArtist
				}
			}
		}

		ListView {
			id: lyricList

			Layout.fillWidth: true
			Layout.fillHeight: true

			model: lyricModel
			snapMode: ListView.SnapToItem
			clip: true

			highlightRangeMode: ListView.StrictlyEnforceRange
			preferredHighlightBegin: height / 2
			preferredHighlightEnd: height / 2
			highlightMoveDuration: 250

			delegate: Text {
				required property int index
				required property string lyricText

				width: ListView.view.width
				// horizontalAlignment: Text.AlignHCenter
				text: lyricText
				color: ListView.isCurrentItem ? Style.fg : Style.fgSubtle
				font.bold: ListView.isCurrentItem
				font.pixelSize: ListView.isCurrentItem ? 13 : 13

				Behavior on color { ColorAnimation { duration: 150 } }
				Behavior on font.pixelSize { NumberAnimation { duration: 150 } }
			}

			Text {
				anchors.fill: parent
				// horizontalAlignment: Qt.AlignHCenter
				verticalAlignment: Qt.AlignVCenter
				visible: parent.count == 0
				text: 'No lyrics available'
				color: Style.fgSubtle
				font.pixelSize: 13
			}

			Rectangle {
				anchors.top: parent.top
				anchors.left: parent.left
				anchors.right: parent.right
				height: 16
				gradient: Gradient {
					GradientStop { position: 0.0; color: Style.popupBg }
					GradientStop { position: 1.0; color: "transparent" }
				}
			}

			Rectangle {
				anchors.bottom: parent.bottom
				anchors.left: parent.left
				anchors.right: parent.right
				height: 16
				gradient: Gradient {
					GradientStop { position: 0.0; color: "transparent" }
					GradientStop { position: 1.0; color: Style.popupBg }
				}
			}
		}
	}
}
