import QtQuick

Item {
	id: root

	property real value: 0.0 // 0-1
	property bool vertical: false
	property bool animate: true
	property color fillColor: Style.genericSlider.fill
	property color trackColor: Style.genericSlider.track

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
			const mapped = Math.max(0.0, Math.min(1.0, p));
			root.moved(mapped);
		}

		onPressed: (ev) => emitValue(ev)
		onPositionChanged: (ev) => {
			if (pressedButtons & Qt.LeftButton) emitValue(ev);
		}
		onWheel: (ev) => {
			const delta = (ev.angleDelta.y > 0) ? 0.05 : -0.05;
			const p = Math.round((root.value + delta) * 20) / 20;
			root.moved(Math.max(0.0, Math.min(1.0, p)));
		}
	}
}
