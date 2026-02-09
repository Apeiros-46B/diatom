import QtQuick
import Niri

import Shared

Column {
	id: root
	required property Niri niri

	anchors {
		top: parent.top
	}
	spacing: Style.workspace.spacing

	Repeater {
		model: root.niri.workspaces

		Rectangle {
			width: Style.bar.width
			height: Style.workspace.height
			color: model.isFocused || model.isActive ? Style.workspace.focused : model.activeWindowId != 0 ? Style.workspace.unfocused : Style.workspace.empty

			MouseArea {
				anchors.fill: parent
				onClicked: root.niri.focusWorkspaceById(model.id)
				cursorShape: Qt.PointingHandCursor
			}
		}
	}
}
