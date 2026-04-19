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

	final property bool settingsOpen: false

	// {{{ music page
	component MusicPage: Item {
		id: musicRoot

		property string preferredPlayer: 'io.github.quodlibet.QuodLibet'
		final property MprisPlayer player: {
			for (const candidate of Mpris.players.values) {
				if (candidate.desktopEntry === preferredPlayer) {
					return candidate;
				}
			}
			return null;
		}

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

		// {{{ lyric loading
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
		// }}}

		// {{{ update lyrics and progress
		Connections {
			target: musicRoot.player

			function onMetadataChanged() {
				if (musicRoot.player && musicRoot.player.metadata) {
					musicRoot.loadLyrics(musicRoot.player.metadata["xesam:url"]);
				}
			}
		}

		// to smoothly update progress bar
		FrameAnimation {
			running: root.visible && musicRoot.player && musicRoot.player.playbackState === MprisPlaybackState.Playing
			onTriggered: musicRoot.player.positionChanged();
		}

		Timer {
			interval: 100
			running: root.visible && musicRoot.player
			repeat: true
			onTriggered: {
				if (musicRoot.needsLyricsLoad) {
					musicRoot.needsLyricsLoad = false;
					if (musicRoot.player && musicRoot.player.metadata) {
						musicRoot.loadLyrics(musicRoot.player.metadata["xesam:url"]);
					}
				}
				musicRoot.updateCurrentLyric();
			}
		}
		// }}}

		// {{{ background art
		Image {
			id: bgArt
			source: musicRoot.player ? musicRoot.player.trackArtUrl : ''
			anchors.fill: parent
			fillMode: Image.PreserveAspectCrop
			visible: false
		}

		MultiEffect {
			source: bgArt
			anchors.fill: bgArt
			visible: musicRoot.player !== null
			blurEnabled: true
			blur: 1.0
			blurMax: 48
			saturation: -1.0
			opacity: 0.1
		}
		// }}}

		// {{{ ui
		// fallback for no players
		Text {
			anchors.centerIn: parent
			visible: musicRoot.player === null
			text: 'No music playing'
			color: Style.fgSubtle
		}

		ColumnLayout {
			anchors.fill: parent
			anchors.margins: Style.lengths.small
			visible: musicRoot.player !== null

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
					source: musicRoot.player.trackArtUrl
				}

				// row 1, column 2 - info
				Column {
					Text {
						color: Style.fg
						text: musicRoot.player.trackTitle
						font {
							bold: true
							pointSize: 11
						}
					}

					Text {
						color: Style.fg
						text: musicRoot.player.trackAlbum
					}

					Text {
						color: Style.fg
						text: musicRoot.player.trackArtist
					}
				}

				// row 2, column 1 - buttons
				RowLayout {
					Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
					spacing: Style.lengths.mini

					ImageButton {
						iconSource: Qt.resolvedUrl('./icons/previous.svg')
						onClicked: musicRoot.player.previous()
					}

					ImageButton {
						iconSource: musicRoot.player.playbackState === MprisPlaybackState.Playing
							? Qt.resolvedUrl('./icons/pause.svg')
							: Qt.resolvedUrl('./icons/play.svg')
						onClicked: musicRoot.player.togglePlaying()
					}

					ImageButton {
						iconSource: Qt.resolvedUrl('./icons/next.svg')
						onClicked: musicRoot.player.next()
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
						stepSize: musicRoot.player.lengthSupported
							? (5.0 / musicRoot.player.length) // 5 second step if possible
							: 0.02 // 2%

						trackColor: Style.bgRaised

						value: musicRoot.player && musicRoot.player.length > 0
							? (musicRoot.player.position / musicRoot.player.length)
							: 0

						onMoved: value => {
							if (musicRoot.player && musicRoot.player.length > 0) {
								musicRoot.player.position = value * musicRoot.player.length;
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
					id: lyricListMask
					anchors.fill: parent
					visible: false
					layer.enabled: true
					gradient: Gradient {
						orientation: Gradient.Vertical
						GradientStop { position: 0.0; color: 'transparent' }
						GradientStop { position: 0.5; color: 'white' }
						GradientStop { position: 0.65; color: 'white' }
						GradientStop { position: 1.0; color: 'transparent' }
					}
				}

				layer.enabled: true
				layer.effect: MultiEffect {
					maskEnabled: true
					maskSource: lyricListMask
					maskSpreadAtMin: 1.0
					maskThresholdMin: 0.4
				}
			}
		}
		// }}}
	}
	// }}}

	// switch pages
	ImageButton {
		anchors {
			top: parent.top
			right: parent.right
			margins: Style.lengths.small
		}
		z: 10
		iconSource: root.settingsOpen
			? Qt.resolvedUrl('./icons/disc.svg')
			: Qt.resolvedUrl('./icons/mix.svg')
		onClicked: root.settingsOpen = !root.settingsOpen
	}

	StackLayout {
		anchors.fill: parent
		currentIndex: root.settingsOpen ? 0 : 1

		Item {
			Text {
				anchors.centerIn: parent
				text: 'TODO: Audio settings'
				color: Style.fgSubtle
			}
		}

		MusicPage {}
	}
}
