import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtQuick.VirtualKeyboard.Settings 2.2

Item {
    id: localRoot

    Layout.alignment: Qt.AlignVCenter
    Layout.minimumWidth: sBox.width
    height: parent.height

    property alias from: sBox.from
    property alias to: sBox.to
    property alias editable: sBox.editable
    property alias textFromValue: sBox.textFromValue
    property alias valueFromText: sBox.valueFromText

    // public interface
    property var validator
    onValidatorChanged: {
        sBox.validator = validator
        if(isNumeric) {
            tField.inputMethodHints = Qt.ImhDigitsOnly
        }
        else {
            tField.inputMethodHints = Qt.ImhNoAutoUppercase
        }
    }
    property int value
    onValueChanged: {
        // TODO
    }
    property alias spinBox: sBox
    property bool changeOnFocusLost: true

    // overridable (return true: apply immediate)
    function doApplyInput(newText) {return true}

    // helpers
    property var textField: sBox.children[2]
    // bit of a hack to check for IntValidator / DoubleValidator to detect a numeric field
    readonly property bool isNumeric: textField.validator !== undefined && 'bottom' in textField.validator && 'top' in textField.validator
    readonly property bool isDouble: isNumeric && 'decimals' in textField.validator
    property bool inApply: false
    readonly property string localeName: VirtualKeyboardSettings.locale
    onLocaleNameChanged: {
        sBox.textFromValue(value, VirtualKeyboardSettings.locale)
    }
    /*function getInputCLocale() {
        return isDouble ? sBox.displayText.replace(",", ".") : sBox.displayText
    }*/
    function hasAlteredValue() {
        var altered = false
        if(sBox.displayText !== localRoot.textField.text) {
            altered = true
        }
        return altered
    }
    function applyInput() {
        if(getInputCLocale() !== localRoot.displayText && localRoot.hasValidInput()) {
            if(hasAlteredValue())
            {
                inApply = true
                var newText = getInputCLocale()
                if(doApplyInput(newText)) {
                    localRoot.text = newText
                }
                inApply = false
            }
            // we changed displayText but did not change value
            else {
                // discard changes
                discardInput()
            }
        }
    }
    function discardInput() {
        if(hasAlteredValue()) {
            localRoot.textField.text = sBox.displayText
        }
    }
    function hasValidInput() {
        var valid = !sBox.editable || textField.acceptableInput
        if (valid && localRoot.validator) {
            // IntValidator / DoubleValidator
            if(localRoot.isNumeric) {
                if(localRoot.isDouble) {
                    // Sometimes wrong decimal separator is accepted by DoubleValidator so check for it
                    if(Qt.locale(VirtualKeyboardSettings.locale).decimalPoint === "," ? sBox.displayText.includes(".") : sBox.displayText.includes(",")) {
                        valid = false
                    }
                    else {
                        valid = localRoot.validator.top>=parseFloat(getInputCLocale()) && localRoot.validator.bottom<=parseFloat(getInputCLocale())
                    }
                }
                else {
                    valid = localRoot.validator.top>=parseInt(sBox.displayText, 10) && localRoot.validator.bottom<=parseInt(sBox.displayText, 10)
                }
            }
            // RegExpValidator
            else {
            // TODO?
            }
        }
        return valid
    }

    // controls
    SpinBox {
        id: sBox
        height: parent.height
        bottomPadding: 8

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
            localRoot.discardInput()
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
            localRoot.value = value
        }

        onFocusChanged: {
            if(changeOnFocusLost && !focus) {
                if(localRoot.hasAlteredValue()) {
                    if(localRoot.hasValidInput()) {
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
            anchors.fill: parent
            color: "red"
            opacity: 0.2
            visible: localRoot.hasValidInput() === false && sBox.editable
        }
        Rectangle {
            anchors.fill: parent
            color: "green"
            opacity: 0.2
            visible: localRoot.hasValidInput() && sBox.editable && localRoot.hasAlteredValue()
        }

    }
}
