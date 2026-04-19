pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

import Shared

PopupWindow {
	id: root
	anchor {
		window: bar
		rect.x: Style.bar.popupGap
		rect.y: bar.height / 2 - height / 2
	}
	implicitWidth: Style.musicPopup.width
	implicitHeight: Style.musicPopup.height
	color: Style.bgPopup

	required property PanelWindow bar

	property string preferredPlayer: 'io.github.quodlibet.QuodLibet'

	final property MprisPlayer player: {
		for (const candidate of Mpris.players.values) {
			if (candidate.desktopEntry === preferredPlayer) {
				return candidate;
			}
		}
		return null;
	}

	final property bool settingsOpen: true
	final property bool needsLyricsLoad: true
	final property int activeLyricIndex: -1

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
		xhr.open('GET', audioUrl.substring(0, audioUrl.lastIndexOf('.')) + '.lrc');
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

	component PlayerButton : Item {
		id: btnRoot
		width: Style.musicPopup.buttonSize
		height: Style.musicPopup.buttonSize

		required property url iconSource
		property color color: Style.fgSubtle

		signal clicked()

		Image {
			id: rawIcon
			source: btnRoot.iconSource
			anchors.fill: parent
			sourceSize: Qt.size(width, height)
			visible: false
		}

		MultiEffect {
			source: rawIcon
			anchors.fill: rawIcon
			colorization: 1.0
			colorizationColor: btnRoot.color
		}

		MouseArea {
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			onClicked: btnRoot.clicked()
		}
	}

	Connections {
		target: root.player

		function onMetadataChanged() {
			if (root.player && root.player.metadata) {
				root.loadLyrics(root.player.metadata["xesam:url"]);
			}
		}
	}

	// to smoothly update progress bar
	FrameAnimation {
		running: root.visible && root.player && root.player.playbackState === MprisPlaybackState.Playing
		onTriggered: root.player.positionChanged();
	}

	Timer {
		interval: 100
		running: root.visible && root.player
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

	PlayerButton {
		anchors {
			top: parent.top
			right: parent.right
			margins: Style.lengths.small
		}
		z: 10
		iconSource: root.settingsOpen ? './icons/disc.svg' : './icons/mix.svg'
		onClicked: root.settingsOpen = !root.settingsOpen
	}

	StackLayout {
		anchors.fill: parent
		currentIndex: root.settingsOpen ? 0 : 1

		// {{{ audio settings page
		Item {
			Text {
				anchors.centerIn: parent
				text: 'TODO: Audio settings'
				color: Style.fgSubtle
			}
		}
		// }}}

		// {{{ music page
		Item {
			Text {
				anchors.centerIn: parent
				visible: root.player === null
				text: 'No music playing'
				color: Style.fgSubtle
			}

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: Style.lengths.small
				visible: root.player !== null

				GridLayout {
					Layout.fillWidth: true
					columns: 2
					rowSpacing: Style.lengths.small
					columnSpacing: Style.lengths.small

					// row 1, column 1 - album cover
					Image {
						Layout.preferredWidth: Style.musicPopup.albumArtSize
						Layout.preferredHeight: Style.musicPopup.albumArtSize
						fillMode: Image.PreserveAspectFit
						mipmap: true // smoother downscale
						source: root.player.trackArtUrl
					}

					// row 1, column 2 - info
					Column {
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

					// row 2, column 1 - buttons
					RowLayout {
						Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
						spacing: Style.lengths.mini

						PlayerButton {
							iconSource: './icons/previous.svg'
							onClicked: root.player.previous()
						}

						PlayerButton {
							iconSource: root.player.playbackState === MprisPlaybackState.Playing
								? './icons/pause.svg'
								: './icons/play.svg'
							onClicked: root.player.togglePlaying()
						}

						PlayerButton {
							iconSource: './icons/next.svg'
							onClicked: root.player.next()
						}
					}

					// row 2, column 2 - progress bar
					Item {
						Layout.fillWidth: true
						Layout.alignment: Qt.AlignVCenter
						Layout.preferredHeight: Style.musicPopup.barThickness
						Layout.rightMargin: Style.lengths.mini

						Slider {
							anchors.fill: parent

							vertical: false
							animate: false // we use FrameAnimation
							round: false // we want skipping from current pos, not quantization
							stepSize: root.player.lengthSupported
								? (5.0 / root.player.length) // 5 second step if possible
								: 0.02 // 2%

							value: root.player && root.player.length > 0
								? (root.player.position / root.player.length)
								: 0

							onMoved: value => {
								if (root.player && root.player.length > 0) {
									root.player.position = value * root.player.length;
								}
							}
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
					interactive: false

					highlightRangeMode: ListView.StrictlyEnforceRange
					preferredHighlightBegin: height / 2
					preferredHighlightEnd: height / 2
					highlightMoveDuration: 150

					delegate: Text {
						required property int index
						required property string lyricText

						width: ListView.view.width
						horizontalAlignment: Text.AlignHCenter
						text: lyricText
						color: ListView.isCurrentItem ? Style.fg : Style.fgSubtle
						font.bold: ListView.isCurrentItem

						Behavior on color { ColorAnimation { duration: 150 } }
					}

					Text {
						anchors.centerIn: parent
						visible: parent.count == 0
						text: 'No lyrics available'
						color: Style.fgSubtle
					}

					Rectangle {
						visible: parent.count != 0
						anchors.top: parent.top
						anchors.left: parent.left
						anchors.right: parent.right
						height: Style.lengths.medium
						gradient: Gradient {
							GradientStop { position: 0.0; color: Style.bgPopup }
							GradientStop { position: 1.0; color: 'transparent' }
						}
					}

					Rectangle {
						visible: parent.count != 0
						anchors.bottom: parent.bottom
						anchors.left: parent.left
						anchors.right: parent.right
						height: Style.lengths.medium
						gradient: Gradient {
							GradientStop { position: 0.0; color: 'transparent' }
							GradientStop { position: 1.0; color: Style.bgPopup }
						}
					}
				}
			}
		}
		// }}}
	}
}
