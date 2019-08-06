import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtQuick.VirtualKeyboard.Settings 2.2
import "qrc:/qml/helpers" as HELPERS

Item {
    Layout.alignment: Qt.AlignVCenter
    Layout.minimumWidth: tField.width
    height: parent.height

    // public interface
    property var validator
    onValidatorChanged: {
        tField.validator = validator
        if(isNumeric) {
            tField.inputMethodHints = Qt.ImhFormattedNumbersOnly
        }
        else {
            tField.inputMethodHints = Qt.ImhNoAutoUppercase
        }
    }
    property string text: "" // locale C
    onTextChanged: {
        tField.text = tHelper.strToLocal(text)
    }
    property alias textField: tField
    property alias placeholderText: tField.placeholderText;
    property alias readOnly: tField.readOnly
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

    // bit of a hack to check for IntValidator / DoubleValidator to detect a numeric field
    readonly property bool isNumeric: validator !== undefined && 'bottom' in validator && 'top' in validator
    readonly property bool isDouble: isNumeric && 'decimals' in validator
    property bool inFocusKill: false
    readonly property string localeName: VirtualKeyboardSettings.locale
    onLocaleNameChanged: {
        tField.text = tHelper.strToLocal(text)
    }
    function applyInput() {
        if(tHelper.strToCLocale(tField.text) !== text) {
            if(hasValidInput())
            {
                if(hasAlteredValue())
                {
                    var newText = tHelper.strToCLocale(tField.text)
                    if(doApplyInput(newText)) {
                        text = newText
                    }
                }
                // we changed text but did not change value
                else {
                    discardInput()
                }
            }
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
                if(hasAlteredValue()) {
                    if(hasValidInput()) {
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
            visible: hasValidInput() === false && tField.enabled
        }
        Rectangle {
            anchors.fill: parent
            color: "green"
            opacity: 0.2
            visible: hasValidInput() && tField.enabled && hasAlteredValue()
        }
    }
}
