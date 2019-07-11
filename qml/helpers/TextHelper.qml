import QtQuick 2.0
import QtQuick.VirtualKeyboard.Settings 2.2

Item {
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
    function hasAlteredValue(isNumeric, isDouble, decimals, fieldText, text) {
        var altered = false
        // Numerical?
        if(isNumeric) {
            if(fieldText !== text && (fieldText === "" || text === "")) {
                altered = true
            }
            else if(isDouble) {
                var expVal = Math.pow(10, decimals)
                var fieldVal = parseFloat(strToCLocale(fieldText)) * expVal
                var textVal = parseFloat(text) * expVal
                altered = Math.abs(fieldVal-textVal) > 0.1
            }
            else {
                altered = parseInt(fieldText, 10) !== parseInt(text, 10)
            }
        }
        else {
            altered = fieldText !== text
        }
        return altered
    }

    function hasValidInput(isNumeric, isDouble, hasValidator, bottom, top, valid, text) {
        if (valid && hasValidator) {
            // IntValidator / DoubleValidator
            if(isNumeric) {
                if(isDouble) {
                    // Sometimes wrong decimal separator is accepted by DoubleValidator so check for it
                    if(Qt.locale(VirtualKeyboardSettings.locale).decimalPoint === "," ? text.includes(".") : text.includes(",")) {
                        valid = false
                    }
                    else {
                        valid = top>=parseFloat(strToCLocale(text)) && bottom<=parseFloat(strToCLocale(text))
                    }
                }
                else {
                    valid = top>=parseInt(text, 10) && bottom<=parseInt(text, 10)
                }
            }
            // RegExpValidator
            else {
            // TODO?
            }
        }
        return valid
    }
}