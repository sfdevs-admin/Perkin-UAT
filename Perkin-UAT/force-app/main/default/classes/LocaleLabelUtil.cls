/**
 * Created by mgaska001 on 13.11.2025.
 */

public with sharing class LocaleLabelUtil {

    /**
     * @description Helper method to resolve proper label for given locale code
     */
    public static String getLabel(String labelName, String localeCode) {
        if (String.isBlank(localeCode) || !Label.translationExists('', labelName, localeCode)) {
            localeCode = 'en_US';
        }
        return Label.get('', labelName, localeCode);
    }

}