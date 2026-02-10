pragma ComponentBehavior: Bound
import QtQuick

import Shared

Item {
	id: root
	width: Style.bar.width
	height: 12 * Style.clock.barHeight + 8 * Style.clock.spacing + 3 * Style.clock.spacingBig

	property int hour: 0
	property int min: 0

	function updateTime() {
		var d = new Date();
		hour = d.getHours() % 12;
		min = d.getMinutes();
	}

	Timer {
		interval: 10000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: parent.updateTime()
	}

	Column {
		anchors.centerIn: parent
		spacing: Style.clock.spacingBig

		Repeater {
			model: 4

			Column {
				id: group
				spacing: Style.clock.spacing

				required property int index
				readonly property int idx: index

				Repeater {
					model: 3

					ClockBar {
						required property int index

						hour: root.hour
						min: root.min
						idx: 11 - ((group.idx * 3) + index)
					}
				}
			}
		}
	}

	component ClockBar: Rectangle {
		id: bar
		width: Style.bar.width
		height: Style.clock.barHeight
		color: Style.clock.trough

		required property int hour
		required property int min
		required property int idx

		Rectangle {
			anchors {
				bottom: parent.bottom
				left: parent.left
				right: parent.right
			}
			color: Style.clock.fill
			height: {
				if (bar.idx < bar.hour) {
					return parent.height;
				} else if (bar.idx === bar.hour) {
					return parent.height * (bar.min / 60.0);
				} else {
					return 0;
				}
			}
		}
	}
}
