pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Niri

import Shared

Column {
	id: root
	spacing: Style.workspace.spacing

	required property Niri niri
	required property ShellScreen output

	Repeater {
		model: root.niri.workspaces

		Rectangle {
			id: ws
			required property var model

			visible: model.output === root.output.name

			width: Style.bar.thickness
			height: Style.workspace.height

			color: model.isFocused || model.isActive
				? Style.workspace.focused
				: model.activeWindowId != 0
					? Style.workspace.unfocused
					: Style.workspace.empty

			Behavior on color { ColorAnimation { duration: 100 } }

			MouseArea {
				anchors.fill: parent
				onClicked: root.niri.focusWorkspaceById(ws.model.id)
				cursorShape: Qt.PointingHandCursor
			}
		}
	}
}
