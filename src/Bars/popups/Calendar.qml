pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

import Shared

PopupWindow {
	id: root
	anchor {
		window: bar
		rect.x: Style.bar.popupGap
		rect.y: bar.height - height - Style.lengths.small
	}
	implicitWidth: implicitHeight
	implicitHeight: Style.clock.barHeight * 12
		+ Style.clock.spacing * 8
		+ Style.clock.spacingBig * 3
		- Style.lengths.small
	color: Style.bgPopup

	required property PanelWindow bar

	final property date selectedDate: new Date()

	SystemClock {
		id: clock
		enabled: root.visible
		precision: SystemClock.Minutes
	}

	Connections {
		target: root

		function onVisibleChanged() {
			if (root.visible) {
				root.selectedDate = new Date();
			}
		}
	}

	ColumnLayout {
		anchors.fill: parent

		Text {
			Layout.topMargin: Style.lengths.small
			Layout.leftMargin: Style.lengths.small

			// for some reason Qt.formatDate on clock.date does not update automatically
			text: `${clock.hours.toString().padStart(2, '0')}:${clock.minutes.toString().padStart(2, '0')}`
			color: Style.fg
			font {
				pixelSize: 24
				bold: true
			}
		}

		RowLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true

			Layout.leftMargin: Style.lengths.small
			Layout.rightMargin: Style.lengths.small
			Layout.bottomMargin: Style.lengths.small

			// {{{ calendar
			ColumnLayout {
				Layout.fillHeight: true
				Layout.maximumWidth: 210
				spacing: Style.lengths.mini

				Text {
					text: Qt.formatDateTime(root.selectedDate, "MMMM yyyy")
					color: Style.fg
					font.bold: true
					horizontalAlignment: Text.AlignHCenter
				}

				// calendar
				MonthGrid {
					id: monthGrid
					Layout.fillWidth: true
					Layout.maximumWidth: 200
					Layout.preferredHeight: (width / 7) * 6

					month: root.selectedDate.getMonth()
					year: root.selectedDate.getFullYear()

					spacing: 0

					delegate: Rectangle {
						id: dayRoot
						required property var model;

						readonly property bool isCurrentMonth: model.month === monthGrid.month
						readonly property bool isToday: model.date.toDateString() === clock.date.toDateString()
						readonly property bool isSelected: model.date.toDateString() === root.selectedDate.toDateString()

						implicitWidth: monthGrid.width / 7
						implicitHeight: implicitWidth

						color: {
							if (isSelected) return Style.accent;
							if (isCurrentMonth) return Style.bgPopup2;
							return "transparent";
						}

						Text {
							anchors.centerIn: parent
							text: dayRoot.model.day
							font.bold: dayRoot.isToday || dayRoot.isSelected

							color: {
								if (dayRoot.isSelected) return Style.bg;
								if (dayRoot.isToday) return Style.accent;
								if (dayRoot.isCurrentMonth) return Style.fg;
								return Style.fgSubtle; // spilled days
							}
						}

						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: root.selectedDate = dayRoot.model.date
						}
					}

					// scroll to change month
					MouseArea {
						anchors.fill: parent
						onWheel: (ev) => {
							const delta = ev.angleDelta.y > 0 ? -1 : 1;
							root.selectedDate.setMonth(root.selectedDate.getMonth() + delta)
						}
					}
				}

				Item {
					Layout.fillHeight: true
				}
			}
			// }}}

			// {{{ events
			ColumnLayout {
				Layout.fillWidth: true
				Layout.fillHeight: true
				spacing: Style.lengths.mini

				Text {
					text: "Events"
					color: Style.fg
					font.bold: true
				}

				ListView {
					Layout.fillWidth: true
					Layout.fillHeight: true
					clip: true
					spacing: Style.lengths.small

					// TODO: actually link to a backend
					model: []

					delegate: ColumnLayout {
						id: eventRoot

						required property string desc
						required property string time

						width: ListView.view.width
						spacing: 0

						Text {
							text: eventRoot.time
							color: Style.accent
							font.bold: true
						}
						Text {
							text: eventRoot.desc
							color: Style.fg
							elide: Text.ElideRight
							Layout.fillWidth: true
						}
					}

					Text {
						visible: parent.count == 0
						text: "No events"
						color: Style.fgSubtle
					}
				}
			}
			// }}}
		}

		// {{{ world clocks
		Rectangle {
			id: worldClocks

			Layout.fillWidth: true
			Layout.preferredHeight: 64
			color: Style.bgPopup2

			// tick param exists to make qml tick this function every minute
			function formatWorldTime(offsetHours, tick) {
				const now = new Date();
				const shifted = new Date(now.getTime() + (offsetHours * 3600000));

				// read with UTC getters to ignore system timezone
				let h = shifted.getUTCHours().toString().padStart(2, "0");
				const m = shifted.getUTCMinutes().toString().padStart(2, "0");

				return h + ":" + m;
			}

			RowLayout {
				anchors.fill: parent
				anchors.margins: Style.lengths.small
				spacing: Style.lengths.small

				Repeater {
					model: [
						{ city: "Vancouver", offset: -7 },
						{ city: "Berlin", offset: 2 },
						{ city: "Beijing", offset: 8 }
					]

					delegate: ColumnLayout {
						id: clockRoot
						required property var modelData

						// Force equal distribution regardless of text width
						Layout.fillWidth: true
						Layout.preferredWidth: 1
						Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
						spacing: 2

						Text {
							text: worldClocks.formatWorldTime(clockRoot.modelData.offset, clock.minutes)
							color: Style.fg
							font.bold: true
							horizontalAlignment: Text.AlignHCenter
							Layout.fillWidth: true
						}

						Text {
							text: clockRoot.modelData.city
							color: Style.fgSubtle
							font.pixelSize: 10
							horizontalAlignment: Text.AlignHCenter
							Layout.fillWidth: true
						}
					}
				}
			}
		}
		// }}}
	}
}
