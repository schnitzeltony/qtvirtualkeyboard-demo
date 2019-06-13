import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.VirtualKeyboard 2.4
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

ApplicationWindow {
    id: window
    visible: true
    width: 640
    height: 480
    title: qsTr("Virtual Keyboard Example")

    Material.theme: Material.Dark
    Material.accent: Material.color(Material.Green)

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: parent.width;
        contentHeight: parent.height+inputPanel.realHeight
        boundsBehavior: Flickable.StopAtBounds
        interactive: false
        NumberAnimation on contentY
        {
            id: flickableAnimation
            duration: 300
        }

        // Dummy test content
        ListView{
            id: listView
            anchors.fill: parent
            model: 11
            interactive: false
            delegate: RowLayout {
                height: 40
                Button {
                    id: button
                    text: "Button"
                }
                TextField {
                    id: textInput
                    text: "TextInput" + modelData
                }
            }
        }
    }
    InputPanel {
         id: inputPanel
         anchors.left: parent.left
         anchors.right: parent.right
         anchors.bottom: parent.bottom
         property bool textEntered: Qt.inputMethod.visible
         // Hmm - why is this necessary?
         property real realHeight: height/1.65
         visible: textEntered // remove??
         onTextEnteredChanged: {
             var rectInput = Qt.inputMethod.anchorRectangle
             if (inputPanel.textEntered)
             {
                if(rectInput.bottom > inputPanel.y)
                {
                    flickableAnimation.to = rectInput.bottom - inputPanel.y + 5
                    flickableAnimation.start()
                 }
             }
             else
             {
                 if(flickable.contentY !== 0)
                 {
                     flickableAnimation.to = 0
                     flickableAnimation.start()
                  }
             }
         }
    }
}
