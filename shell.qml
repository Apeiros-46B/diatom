pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
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
			console.error("Niri error:", err);
		}
	}

	Variants {
		model: Quickshell.screens

		Scope {
			id: root
			property ShellScreen modelData

			TopBar {
				niri: niriInstance
				output: root.modelData
			}
			BottomBar {
				niri: niriInstance
			}
			LeftBar {
				niri: niriInstance
				output: root.modelData.name
			}
			RightBar {
				niri: niriInstance
			}
		}
	}
}
