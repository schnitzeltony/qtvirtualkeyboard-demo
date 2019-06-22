import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.VirtualKeyboard 2.4
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import QtQuick.VirtualKeyboard.Settings 2.2

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
            duration: 300
            id: flickableAnimation
        }
        // Select language
        ComboBox {
            id: langCombo
            width: 200
            model: [ "en_GB", "de_DE" ]
            onCurrentTextChanged: {
                VirtualKeyboardSettings.locale = langCombo.currentText
            }
            Component.onCompleted: {
                VirtualKeyboardSettings.locale = langCombo.currentText
            }
        }
        // Dummy test content
        ListView{
            id: listViewControls
            anchors.top: langCombo.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            model: 11
            interactive: false
            delegate: RowLayout {
                height: 40
                Button {
                    id: button
                    text: "Button"
                }
                TextField {
                    id: textInputAlNum
                    text: "AlphaNum" + modelData
                    Keys.onEscapePressed: {
                      focus = false
                    }
                }
                TextField {
                    id: textInputNum
                    text: "Num" + modelData
                    Keys.onEscapePressed: {
                      focus = false
                    }
                    inputMethodHints: Qt.ImhDigitsOnly
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
         visible: textEntered
         opacity: 0
         NumberAnimation on opacity
         {
             id: keyboardAnimation
             onStarted: {
                 if(to === 1)
                    inputPanel.visible = inputPanel.textEntered
             }
             onFinished: {
                 if(to === 0)
                    inputPanel.visible = inputPanel.textEntered
             }
         }
         onTextEnteredChanged: {
             var rectInput = Qt.inputMethod.anchorRectangle
             if (inputPanel.textEntered)
             {
                if(rectInput.bottom > inputPanel.y)
                {
                    flickableAnimation.to = rectInput.bottom - inputPanel.y + 10
                    flickableAnimation.start()
                }
                keyboardAnimation.to = 1
                keyboardAnimation.duration = 500
                keyboardAnimation.start()
             }
             else
             {
                 if(flickable.contentY !== 0)
                 {
                     flickableAnimation.to = 0
                     flickableAnimation.start()
                 }
                 keyboardAnimation.to = 0
                 keyboardAnimation.duration = 0
                 keyboardAnimation.start()
             }
         }
    }
}
