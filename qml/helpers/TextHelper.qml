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
    function hasAlteredValue(isNumeric, isDouble, fieldText, text) {
        var altered = false
        // Numerical?
        if(isNumeric) {
            if(fieldText !== text && (fieldText === "" || text === "")) {
                altered = true
            }
            else if(isDouble) {
                altered = (Math.abs(parseFloat(tHelper.strToCLocale(fieldText)) - parseFloat(text))) >= Math.pow(10, -localRoot.validator.decimals)
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
}
