/**
 * Created by mgaska001 on 13.11.2025.
 */

public with sharing class ChangeUtil {

    /**
     * @description Helper method prices check including proper test to blank amounts
     */
    public static Boolean isPriceChanged(Decimal oldPrice, Decimal newPrice) {
        if (oldPrice == null && newPrice == null) {
            return false;
        } else if (oldPrice == null || newPrice == null) {
            return true;
        } else {
            return oldPrice != newPrice;
        }
    }

    /**
     * @description Helper method text fields check including proper test to blanks texts
     */
    public static Boolean isTextChanged(String oldText, String newText) {
        if (oldText == null && newText == null) {
            return false;
        } else if (oldText == null || newText == null) {
            return true;
        } else {
            return oldText != newText;
        }
    }

    /**
     * @description Helper method date fields check including proper test of to blanks dates
     */
    public static Boolean isDateChanged(Date oldDate, Date newDate) {
        if (oldDate == null && newDate == null) {
            return false;
        } else if (oldDate == null || newDate == null) {
            return true;
        } else {
            return oldDate != newDate;
        }
    }

}