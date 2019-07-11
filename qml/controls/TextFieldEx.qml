import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtQuick.VirtualKeyboard.Settings 2.2

Item {
    id: localRoot
    Layout.alignment: Qt.AlignVCenter
    Layout.minimumWidth: tField.width
    height: parent.height

    // public interface
    property var validator
    onValidatorChanged: {
        tField.validator = validator
        if(isNumeric) {
            tField.inputMethodHints = Qt.ImhDigitsOnly
        }
        else {
            tField.inputMethodHints = Qt.ImhNoAutoUppercase
        }
    }
    property string text: "" // locale C
    onTextChanged: {
        tField.text = strToLocal(text)
    }
    property alias textField: tField
    property alias placeholderText: tField.placeholderText;
    property alias readOnly: tField.readOnly
    readonly property bool acceptableInput: hasValidInput()
    property bool changeOnFocusLost: true

    // overridable (return true: apply immediate)
    function doApplyInput(newText) {return true}

    // helpers
    // bit of a hack to check for IntValidator / DoubleValidator to detect a numeric field
    readonly property bool isNumeric: validator !== undefined && 'bottom' in validator && 'top' in validator
    readonly property bool isDouble: isNumeric && 'decimals' in validator
    property bool inApply: false
    property bool inFocusKill: false
    readonly property string localeName: VirtualKeyboardSettings.locale
    onLocaleNameChanged: {
        tField.text = strToLocal(text)
    }
    function strToCLocale(str) {
        if(isNumeric) {
            if(!isDouble) {
                return parseInt(str, 10)
            }
            else {
                return str.replace(",", ".")
            }
        }
        else {
            return str
        }
    }
    function strToLocal(str) {
        if(isNumeric) {
            if(!isDouble) {
                return parseInt(str)
            }
            else {
                return str.replace(Qt.locale(VirtualKeyboardSettings.locale).decimalPoint === "," ? "." : ",", Qt.locale(VirtualKeyboardSettings.locale).decimalPoint)
            }
        }
        else {
            return str
        }
    }
    function hasAlteredValue() {
        var altered = false
        // Numerical?
        if(isNumeric) {
            if(tField.text !== localRoot.text && (tField.text === "" || localRoot.text === "")) {
                altered = true
            }
            else if(isDouble) {
                altered = (Math.abs(parseFloat(strToCLocale(tField.text)) - parseFloat(text))) >= Math.pow(10, -localRoot.validator.decimals)
            }
            else {
                altered = parseInt(tField.text, 10) !== parseInt(text, 10)
            }
        }
        else {
            altered = tField.text !== localRoot.text
        }
        return altered
    }
    function applyInput() {
        if(strToCLocale(tField.text) !== localRoot.text && localRoot.hasValidInput()) {
            if(hasAlteredValue())
            {
                inApply = true
                var newText = strToCLocale(tField.text)
                if(doApplyInput(newText)) {
                    localRoot.text = newText
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
        if(tField.text !== localRoot.text) {
            tField.text = strToLocal(text)
        }
    }
    function hasValidInput() {
        var valid = tField.acceptableInput
        if (valid && localRoot.validator) {
            // IntValidator / DoubleValidator
            if(localRoot.isNumeric) {
                if(localRoot.isDouble) {
                    // Sometimes wrong decimal separator is accepted by DoubleValidator so check for it
                    if(Qt.locale(VirtualKeyboardSettings.locale).decimalPoint === "," ? tField.text.includes(".") : tField.text.includes(",")) {
                        valid = false
                    }
                    else {
                        valid = localRoot.validator.top>=parseFloat(strToCLocale(tField.text)) && localRoot.validator.bottom<=parseFloat(strToCLocale(tField.text))
                    }
                }
                else {
                    valid = localRoot.validator.top>=parseInt(tField.text, 10) && localRoot.validator.bottom<=parseInt(tField.text, 10)
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
    TextField {
        id: tField
        bottomPadding: 8

        mouseSelectionMode: TextInput.SelectWords
        selectByMouse: true
        inputMethodHints: Qt.ImhNoAutoUppercase
        onAccepted: {
            applyInput()
            inFocusKill = true
            focus = false
            inFocusKill = false
        }
        Keys.onEscapePressed: {
            discardInput()
            inFocusKill = true
            focus = false
            inFocusKill = false
        }
        /* Avoid QML magic: when the cursor is at start/end position,
        left/right keys are used to change tab. We don't want that */
        Keys.onLeftPressed: {
            if(cursorPosition > 0 || selectedText !== "") {
                event.accepted = false;
            }
        }
        Keys.onRightPressed: {
            if(cursorPosition < text.length || selectedText !== "") {
                event.accepted = false;
            }
        }

        onFocusChanged: {
            if(changeOnFocusLost && !inFocusKill && !focus) {
                if(localRoot.hasAlteredValue()) {
                    if(localRoot.hasValidInput()) {
                        applyInput()
                    }
                    else {
                        discardInput()
                    }
                }
                else {
                    discardInput()
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
            visible: localRoot.hasValidInput() === false && tField.enabled
        }
        Rectangle {
            anchors.fill: parent
            color: "green"
            opacity: 0.2
            visible: localRoot.hasValidInput() && tField.enabled && localRoot.hasAlteredValue()
        }
    }
}
