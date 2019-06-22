import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Item {
    id: root
    Layout.alignment: Qt.AlignVCenter
    Layout.minimumWidth: textField.width
    height: parent.height

    // interface
    property string text: ""
    property alias textField: textField
    property alias inputMethodHints: textField.inputMethodHints;
    property alias placeholderText: textField.placeholderText;
    property alias readOnly: textField.readOnly

    onTextChanged: {
        textField.text = text
    }

    TextField {
        id: textField
        bottomPadding: 8
        onAccepted: {
            root.text = text
            focus = false
        }
        Keys.onEscapePressed: {
            text = root.text
            focus = false
        }
    }

    Rectangle {
        anchors.fill: textField
        color: "red"
        opacity: 0.2
        visible: root.text !== textField.text
    }
}
