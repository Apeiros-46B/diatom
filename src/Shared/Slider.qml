import QtQuick

Item {
	id: root

	property real value: 0.0 // 0-1
	property real stepSize: 0.05 // 0-1
	property bool round: true // whether to round scrolling to increments
	property bool vertical: false
	property bool animate: true
	property color fillColor: Style.genericSlider.fill
	property color trackColor: Style.genericSlider.track

	final property real stepCount: 1.0 / stepSize

	signal moved(real value)

	Rectangle {
		id: track
		anchors.fill: parent
		color: root.trackColor
	}

	Rectangle {
		id: fill
		anchors.left: root.vertical ? undefined : parent.left
		anchors.bottom: parent.bottom
		anchors.right: root.vertical ? parent.right : undefined

		width: root.vertical ? parent.width : parent.width * root.value
		height: root.vertical ? parent.height * root.value : parent.height
		color: root.fillColor
		radius: track.radius

		Behavior on color { ColorAnimation { duration: 100 } }
		Behavior on width {
			enabled: root.animate && !root.vertical
			NumberAnimation { duration: 100 }
		}
		Behavior on height {
			enabled: root.animate && root.vertical
			NumberAnimation { duration: 100 }
		}
	}

	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.LeftButton

		function emitValue(mousePos) {
			const p = root.vertical
				? 1.0 - (mousePos.y / root.height)
				: mousePos.x / root.width;
			let mapped = Math.max(0.0, Math.min(1.0, p));
			if (root.round) {
				mapped = Math.round(mapped * root.stepCount) / root.stepCount;
			}
			root.moved(mapped);
		}

		onPressed: (ev) => emitValue(ev)
		onPositionChanged: (ev) => {
			if (pressedButtons & Qt.LeftButton) emitValue(ev);
		}
		onWheel: (ev) => {
			const delta = (ev.angleDelta.y > 0) ? root.stepSize : -root.stepSize;
			var mapped = Math.max(0.0, Math.min(1.0, root.value + delta))
			if (root.round) {
				mapped = Math.round(mapped * root.stepCount) / root.stepCount;
			}
			root.moved(mapped);
		}
	}
}
