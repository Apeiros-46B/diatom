import QtQuick
import QtQuick.Effects

Item {
	id: btnRoot

	required property url iconSource
	property color color: Style.fgSubtle

	signal clicked()

	width: Style.musicPopup.buttonSize
	height: Style.musicPopup.buttonSize

	Image {
		id: rawIcon
		source: btnRoot.iconSource
		anchors.fill: parent
		sourceSize: Qt.size(width, height)
		visible: false
	}

	MultiEffect {
		source: rawIcon
		anchors.fill: rawIcon
		colorization: 1.0
		colorizationColor: btnRoot.color
	}

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: btnRoot.clicked()
	}
}
