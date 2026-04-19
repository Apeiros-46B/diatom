pragma ComponentBehavior: Bound

import QtQuick

Item {
	id: root
	visible: false

	property var target

	property bool triggerHovered: false
	property bool targetHovered: false
	property bool pinned: false

	property int showDelay: 0
	property int hideDelay: 150

	property bool hoverTriggered: false
	readonly property bool isOpen: pinned || hoverTriggered

	function forceClose() {
		pinned = false;
		hoverTriggered = false;
	}

	onIsOpenChanged: {
		if (target) {
			target.visible = isOpen;
		}
	}

	Component.onCompleted: root.isOpenChanged()

	Timer {
		interval: root.showDelay
		running: root.triggerHovered && !root.isOpen
		onTriggered: root.hoverTriggered = true
	}

	Timer {
		interval: root.hideDelay
		running: !root.triggerHovered && !root.targetHovered && !root.pinned && root.isOpen
		onTriggered: root.hoverTriggered = false
	}
}
