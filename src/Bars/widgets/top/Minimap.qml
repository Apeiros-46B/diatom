// niri minimap
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

	property var activeWorkspaceId: null
	property var activeWindowId: null
	property int activeColumnIndex: -1

	// track active workspace ID
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
			property var wsId: model.id
			property var winId: model.activeWindowId
			onWsIdChanged: root.activeWorkspaceId = wsId
			onWinIdChanged: root.activeWindowId = winId
		}
	}

	// track active column index, even when in the overview
	SortFilterProxyModel {
		id: activeWindowProxy
		model: root.niri.windows
		filters: [
			ValueFilter {
				roleName: "id"
				value: root.activeWindowId
			}
		]
	}
	Instantiator {
		model: activeWindowProxy
		delegate: QtObject {
			required property var model
			property int colIndex: model.columnIndex
			onColIndexChanged: root.activeColumnIndex = colIndex
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

			property real propoWidth: Math.round(Style.minimap.width
				* winDeleg.model.windowWidth / (root.output.width - Style.bar.thickness * 4)
				* winDeleg.model.windowHeight / (root.output.height - Style.bar.thickness * 3))

			width: gapSize + propoWidth
			height: Style.bar.thickness

			Behavior on width { NumberAnimation { duration: 75 } }

			Rectangle {
				id: win
				property bool isWinFocused: winDeleg.model.id === root.activeWindowId
				property bool isColumnFocused: winDeleg.model.columnIndex === root.activeColumnIndex

				x: winDeleg.gapSize
				width: winDeleg.propoWidth
				height: winDeleg.height

				color: {
					if (winDeleg.model.isUrgent) return Style.minimap.urgent
					if (isWinFocused) return Style.minimap.focused
					if (isColumnFocused) return Style.minimap.focusedCol
					return Style.minimap.unfocused
				}

				Behavior on color { ColorAnimation { duration: 100 } }
				Behavior on width { NumberAnimation { duration: 75 } }

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
