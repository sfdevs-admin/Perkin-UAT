@IsTest
public class FormatDateInLanguageTest {

    @IsTest
    static void testFormatDateWithExistingTranslation() {

        FormatDateInLanguage.Input input = new FormatDateInLanguage.Input();
        input.inputDate = Date.newInstance(2025, 10, 31);
        input.localeCode = 'en_US';

        List<FormatDateInLanguage.Input> inputs = new List<FormatDateInLanguage.Input>{
            input
        };

        Test.startTest();
        List<FormatDateInLanguage.Output> results = FormatDateInLanguage.formatDate(inputs);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be one result');
        System.assert(results[0].formattedDate.contains('2025'), 'The date should contain the year');
        System.assert(results[0].formattedDate.contains('31'), 'The date should contain the day');
        System.assert(results[0].formattedDate.contains('-'), 'The format should contain hyphens');
    }

    @IsTest
    static void testFormatDateWithFallbackToEnglish() {

        FormatDateInLanguage.Input input = new FormatDateInLanguage.Input();
        input.inputDate = Date.newInstance(2025, 1, 15);
        input.localeCode = 'xx_XX';

        List<FormatDateInLanguage.Input> inputs = new List<FormatDateInLanguage.Input>{
            input
        };

        Test.startTest();
        List<FormatDateInLanguage.Output> results = FormatDateInLanguage.formatDate(inputs);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be one result');
        System.assert(results[0].formattedDate.endsWith('-2025'), 'The format should end with the year');
        System.assert(results[0].formattedDate.contains('Jan') || results[0].formattedDate.contains('Month_Abbreviation_January'),
            'It should use the English translation or label');
    }

    @IsTest
    static void testMultipleInputs() {

        FormatDateInLanguage.Input input1 = new FormatDateInLanguage.Input();
        input1.inputDate = Date.newInstance(2025, 12, 24);
        input1.localeCode = 'pl_PL';

        FormatDateInLanguage.Input input2 = new FormatDateInLanguage.Input();
        input2.inputDate = Date.newInstance(2025, 6, 1);
        input2.localeCode = 'en_US';

        List<FormatDateInLanguage.Input> inputs = new List<FormatDateInLanguage.Input>{
            input1, input2
        };

        Test.startTest();
        List<FormatDateInLanguage.Output> results = FormatDateInLanguage.formatDate(inputs);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'There should be two results');
        System.assert(results[0].formattedDate.contains('2025'), 'The first result should contain the year');
        System.assert(results[1].formattedDate.contains('2025'), 'The second result should contain the year');
    }

    @IsTest
    static void testInputsWithNullDate() {

        FormatDateInLanguage.Input input1 = new FormatDateInLanguage.Input();
        input1.inputDate = null;
        input1.localeCode = 'Test value';

        List<FormatDateInLanguage.Input> inputs = new List<FormatDateInLanguage.Input>{
            input1
        };

        Test.startTest();
        List<FormatDateInLanguage.Output> results = FormatDateInLanguage.formatDate(inputs);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be one result');
        System.assert(String.isBlank(results[0].formattedDate), 'Formatted date should be blank');
    }

    @IsTest
    static void testInputsWithNullLanguageCode() {

        FormatDateInLanguage.Input input1 = new FormatDateInLanguage.Input();
        input1.inputDate = Date.newInstance(2025, 1, 1);
        input1.localeCode = 'Test value';

        List<FormatDateInLanguage.Input> inputs = new List<FormatDateInLanguage.Input>{
            input1
        };

        Test.startTest();
        List<FormatDateInLanguage.Output> results = FormatDateInLanguage.formatDate(inputs);
        Test.stopTest();
        System.debug(results[0].formattedDate.contains('Jan'));

        System.assertEquals(1, results.size(), 'There should be one result');
        System.assert(results[0].formattedDate.contains('Jan'), 'The first result should contain en_US translation by default');
    }

}