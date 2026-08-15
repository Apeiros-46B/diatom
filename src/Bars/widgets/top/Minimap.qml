pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Niri

import Shared

Row {
	id: root
	spacing: 0

	required property Niri niri
	required property ShellScreen output

	// track active workspace ID for this monitor
	property var activeWorkspaceId: null
	SortFilterProxyModel {
		id: activeWorkspaceProxy
		model: root.niri.workspaces
		filters: [
			ValueFilter {
				roleName: "output"
				value: root.output.name
			},
			ValueFilter {
				roleName: "isActive"
				value: true
			}
		]
	}
	Instantiator {
		model: activeWorkspaceProxy
		delegate: QtObject {
			required property var model
			Component.onCompleted: root.activeWorkspaceId = model.id
		}
	}

	Repeater {
		model: SortFilterProxyModel {
			model: root.niri.windows
			filters: [
				ValueFilter {
					roleName: "isFloating"
					value: false
				},
				ValueFilter {
					roleName: "workspaceId"
					value: root.activeWorkspaceId
				}
			]
			sorters: [
				RoleSorter {
					roleName: "columnIndex"
					priority: 0
				},
				RoleSorter {
					roleName: "tileIndex"
					priority: 1
				}
			]
		}

		Item {
			id: winDeleg

			required property int index
			required property var model

			property real gapSize: index === 0
				? 0
				: model.tileIndex === 1
					? Style.minimap.spacingOuter
					: Style.minimap.spacingInner

			// technically there is also a wm gap, but i printed the calculations and
			// omitting the gaps is somehow more accurate
			property real propoWidth: Style.minimap.width
				* winDeleg.model.windowWidth / (root.output.width - Style.bar.thickness * 2)
				* winDeleg.model.windowHeight / (root.output.height - Style.bar.thickness * 2)

			width: gapSize + propoWidth
			height: Style.bar.thickness

			Behavior on width { NumberAnimation { duration: 100 } }

			Rectangle {
				id: win

				x: winDeleg.gapSize
				width: winDeleg.propoWidth
				height: winDeleg.height

				color: winDeleg.model.isFocused
					? Style.minimap.focused
					: isColumnFocused
						? Style.minimap.focusedCol
						: Style.minimap.unfocused

				property bool isColumnFocused: {
					const fw = root.niri.focusedWindow
					return fw !== null &&
						fw.workspaceId === winDeleg.model.workspaceId &&
						fw.columnIndex === winDeleg.model.columnIndex
				}

				Behavior on color { ColorAnimation { duration: 100 } }
				Behavior on width { NumberAnimation { duration: 100 } }

				Component.onCompleted: {
					console.log('a', winDeleg.width)
					console.log('b', win.width)
				}

				MouseArea {
					anchors.fill: parent
					acceptedButtons: Qt.LeftButton | Qt.MiddleButton
					cursorShape: Qt.PointingHandCursor
					onClicked: evt => {
						if (evt.button === Qt.LeftButton) {
							root.niri.focusWindow(winDeleg.model.id)
						} else if (evt.button === Qt.MiddleButton) {
							root.niri.closeWindow(winDeleg.model.id)
						}
					}
				}
			}
		}
	}
}
