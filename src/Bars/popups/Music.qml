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
	implicitWidth: Style.volume.height * 2
	implicitHeight: Style.volume.height
	color: Style.bgPopup

	required property PanelWindow bar

	final property bool settingsOpen: false

	// {{{ music page
	component MusicPage: Item {
		id: musicRoot

		property string preferredPlayer: "io.github.quodlibet.QuodLibet"
		final readonly property MprisPlayer player: {
			for (const candidate of Mpris.players.values) {
				if (candidate.desktopEntry === preferredPlayer) {
					return candidate;
				}
			}
			return null;
		}

		// for slider, updated by FrameAnimation
		final property real visualPosition: 0.0
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

			if (!audioUrl || !audioUrl.startsWith("file://")) return;

			const xhr = new XMLHttpRequest();
			xhr.open("GET", audioUrl.substring(0, audioUrl.lastIndexOf(".")) + ".lrc");
			xhr.onreadystatechange = function() {
				if (xhr.readyState !== XMLHttpRequest.DONE) return;
				if (xhr.status === 200 || xhr.status === 0) {
					parseLrc(xhr.responseText);
				}
			}
			xhr.send();
		}

		function parseLrc(text) {
			const lines = text.split("\n");
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
					var lyricText = line.replace(timeRegex, "").trim();
					if (lyricText === "") {
						lyricText = "♪";
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
		// }}}

		// {{{ update lyrics and progress
		FrameAnimation {
			running: root.visible && musicRoot.player && musicRoot.player.playbackState === MprisPlaybackState.Playing
			onTriggered: {
				if (musicRoot.player) {
					musicRoot.visualPosition = musicRoot.player.position;
				}
			}
		}

		Connections {
			target: root

			function onVisibleChanged() {
				if (root.visible && musicRoot.player) {
					// re-sync lyrics because the timers were not active when the popup was closed
					musicRoot.updateCurrentLyric();
					musicRoot.visualPosition = musicRoot.player.position;
				}
			}
		}

		Connections {
			target: musicRoot.player

			function onMetadataChanged() {
				musicRoot.needsLyricsLoad = true;
				musicRoot.updateCurrentLyric();
			}

			function onPlaybackStateChanged() {
				if (musicRoot.player && musicRoot.player.playbackState === MprisPlaybackState.Playing) {
					musicRoot.updateCurrentLyric();
				} else {
					lyricTimer.stop();
				}
			}

			function onPositionChanged() {
				musicRoot.updateCurrentLyric();
			}
		}

		Timer {
			id: lyricTimer
			repeat: false
			onTriggered: {
				// advance the index and schedule the next line immediately
				if (musicRoot.activeLyricIndex + 1 < lyricModel.count) {
					musicRoot.activeLyricIndex++;
					musicRoot.scheduleNextLyric();
				}
			}
		}

		function updateCurrentLyric() {
			if (musicRoot.needsLyricsLoad) {
				musicRoot.needsLyricsLoad = false;
				if (musicRoot.player && musicRoot.player.metadata) {
					musicRoot.loadLyrics(musicRoot.player.metadata["xesam:url"]);
				}
			}

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
			scheduleNextLyric();
		}

		function scheduleNextLyric() {
			lyricTimer.stop();
			if (!player || player.playbackState !== MprisPlaybackState.Playing) return;
			if (lyricModel.count === 0 || activeLyricIndex + 1 >= lyricModel.count) return;

			const nextTime = lyricModel.get(activeLyricIndex + 1).time;
			const deltaMs = (nextTime - player.position) * 1000;

			if (deltaMs > 0) {
				lyricTimer.interval = deltaMs;
				lyricTimer.start();
			} else {
				// fallback if the calculation yields a negative delta
				updateCurrentLyric();
			}
		}
		// }}}

		// {{{ background art
		Image {
			id: bgArt
			source: musicRoot.player ? musicRoot.player.trackArtUrl : ""
			anchors.fill: parent
			fillMode: Image.PreserveAspectCrop
			visible: false
		}

		MultiEffect {
			id: bgArtProcessed
			source: bgArt
			anchors.fill: bgArt
			visible: false
			layer.enabled: true

			blurEnabled: true
			blurMax: 42
			blur: 1.0
			contrast: 1.5
		}

		ShaderEffect {
			anchors.fill: bgArtProcessed
			visible: musicRoot.player !== null

			opacity: Style.musicPopup.bgArtOpacity

			property variant source: bgArtProcessed
			property color colorDark: Style.musicPopup.bgArtDark
			property color colorLight: Style.musicPopup.bgArtLight

			fragmentShader: "./shaders/image_ramp.frag.qsb"
		}
		// }}}

		// {{{ ui
		// fallback for no players
		Text {
			anchors.centerIn: parent
			visible: musicRoot.player === null
			text: "No music playing"
			color: Style.fg
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
						iconSource: Qt.resolvedUrl("./icons/previous.svg")
						onClicked: musicRoot.player.previous()
					}

					ImageButton {
						iconSource: musicRoot.player.playbackState === MprisPlaybackState.Playing
							? Qt.resolvedUrl("./icons/pause.svg")
							: Qt.resolvedUrl("./icons/play.svg")
						onClicked: musicRoot.player.togglePlaying()
					}

					ImageButton {
						iconSource: Qt.resolvedUrl("./icons/next.svg")
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

						fillColor: Style.musicPopup.progressFill
						trackColor: Style.musicPopup.progressTrack

						value: musicRoot.player && musicRoot.player.length > 0
							? (musicRoot.visualPosition / musicRoot.player.length)
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
				Layout.bottomMargin: Style.lengths.small

				model: lyricModel
				snapMode: ListView.SnapToItem
				clip: true
				interactive: false

				highlightRangeMode: ListView.StrictlyEnforceRange
				preferredHighlightBegin: height / 2 - (currentItem ? currentItem.height / 2 : 0)
				preferredHighlightEnd: height / 2 + (currentItem ? currentItem.height / 2 : 0)
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
					text: "No lyrics available"
					color: Style.fgSubtle
				}

				Rectangle {
					id: lyricListMask
					anchors.fill: parent
					visible: false
					layer.enabled: true
					gradient: Gradient {
						orientation: Gradient.Vertical
						GradientStop { position: 0.05; color: "transparent" }
						GradientStop { position: 0.45; color: "white" }
						GradientStop { position: 0.55; color: "white" }
						GradientStop { position: 0.95; color: "transparent" }
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
			? Qt.resolvedUrl("./icons/disc.svg")
			: Qt.resolvedUrl("./icons/mix.svg")
		onClicked: root.settingsOpen = !root.settingsOpen
	}

	StackLayout {
		anchors.fill: parent
		currentIndex: root.settingsOpen ? 0 : 1

		Item {
			Text {
				anchors.centerIn: parent
				text: "TODO: Audio settings"
				color: Style.fgSubtle
			}
		}

		MusicPage {}
	}
}
