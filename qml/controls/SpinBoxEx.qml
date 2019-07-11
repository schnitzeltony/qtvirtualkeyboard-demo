import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtQuick.VirtualKeyboard.Settings 2.2
import "qrc:/qml/helpers" as HELPERS

Item {
    Layout.alignment: Qt.AlignVCenter
    Layout.minimumWidth: sBox.width
    height: parent.height

    // public interface
    property alias spinBox: sBox
    property alias from: sBox.from
    property alias to: sBox.to
    property bool readOnly: false
    onReadOnlyChanged: {
        sBox.editable = !readOnly
    }

    property var validator
    onValidatorChanged: {
        sBox.validator = validator
        if(isNumeric) {
            sBox.inputMethodHints = Qt.ImhDigitsOnly
        }
        else {
            sBox.inputMethodHints = Qt.ImhNoAutoUppercase
        }
    }
    property string text: "" // locale C
    onTextChanged: {
        tField.text = tHelper.strToLocal(text)
    }
    readonly property bool acceptableInput: hasValidInput()
    property bool changeOnFocusLost: true

    // overridable (return true: apply immediate)
    function doApplyInput(newText) {return true}

    // helpers
    HELPERS.TextHelper {
        id: tHelper
    }
    function hasAlteredValue() {
        var decimals = isDouble ? validator.decimals : 0
        return tHelper.hasAlteredValue(isNumeric, isDouble, decimals, tField.text, text)
    }
    function hasValidInput() {
        var bottom = isNumeric ? validator.bottom : 0
        var top = isNumeric ? validator.top : 0
        return tHelper.hasValidInput(isNumeric, isDouble, validator !== undefined, bottom, top, tField.acceptableInput, tField.text)
    }

    property var tField: sBox.children[2]

    // bit of a hack to check for IntValidator / DoubleValidator to detect a numeric field
    readonly property bool isNumeric: validator !== undefined && 'bottom' in tField.validator && 'top' in tField.validator
    readonly property bool isDouble: isNumeric && 'decimals' in tField.validator
    property bool inApply: false
    readonly property string localeName: VirtualKeyboardSettings.locale
    onLocaleNameChanged: {
        tField.text = tHelper.strToLocal(text)
    }
    function applyInput() {
        if(tHelper.strToCLocale(tField.text) !== text && hasValidInput()) {
            if(hasAlteredValue())
            {
                inApply = true
                var newText = tHelper.strToCLocale(tField.text)
                if(doApplyInput(newText)) {
                    text = newText
                }
                inApply = false
            }
            // we changed text but did not change value
            else {
                discardInput()
            }
        }
    }
    function discardInput() {
        if(tField.text !== text) {
            tField.text = tHelper.strToLocal(text)
        }
    }

    // controls
    SpinBox {
        id: sBox
        height: parent.height
        bottomPadding: 8
        editable: true

        inputMethodHints: Qt.ImhDigitsOnly

        Keys.onReturnPressed: {
            if(hasValidInput())
                applyInput()
            else
                discardInput()
            event.accepted = false;
            focus = false
        }
        Keys.onEscapePressed: {
            discardInput()
            focus = false
        }
        /* Avoid QML magic: when the cursor is at start/end position,
        left/right keys are used to change tab. We don't want that */
        Keys.onLeftPressed: {
            if(cursorPosition > 0 || selectedText !== "") {
                event.accepted = false;
            }
        }
        Keys.onRightPressed: {
            if(cursorPosition < displayText.length || selectedText !== "") {
                event.accepted = false;
            }
        }
        onValueModified: {
            // TODO Text spins
            tField.text = tHelper.strToLocal(value)
            if(!sBox.focus)
                applyInput()
        }

        onFocusChanged: {
            if(changeOnFocusLost && !focus) {
                if(hasAlteredValue()) {
                    if(hasValidInput()) {
                        applyInput()
                    }
                    else {
                        discardInput()
                    }
                }
            }
            // Hmm - maybe we should add an option for this...
            /*else {
                selectAll()
            }*/
        }
        Rectangle {
            anchors.fill: tField
            anchors.bottomMargin: -4
            color: "red"
            opacity: 0.2
            visible: hasValidInput() === false && !readOnly
        }
        Rectangle {
            anchors.fill: tField
            anchors.bottomMargin: -4
            color: "green"
            opacity: 0.2
            visible: hasValidInput() && !readOnly && hasAlteredValue()
        }

    }
}
