import Quickshell
import QtQuick
import Niri

import Bars

ShellRoot {
	Niri {
		id: niriInstance
		Component.onCompleted: {
			connect()
			niriInstance.workspaces.maxCount = 10
		}

		onConnected: console.log("Connected to niri")
		onErrorOccurred: function(err) {
			console.error("Niri error:", err)
		}
	}

	LeftBar {
		niri: niriInstance
	}
}
