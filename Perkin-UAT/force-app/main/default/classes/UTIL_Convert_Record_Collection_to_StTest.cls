@isTest
private class UTIL_Convert_Record_Collection_to_StTest {

    @isTest
    static void testFlowCalledWithValidInputs() {
        // Step 1: Create test Accounts
        Account account1 = new Account(Name = 'Account 1');
        Account account2 = new Account(Name = 'Account 2');
        insert new List<Account>{ account1, account2 };

        // Step 2: Prepare FlowInputs with valid data
        UTIL_Convert_Record_Collection_to_String.FlowInputs flowInput = new UTIL_Convert_Record_Collection_to_String.FlowInputs();
        flowInput.sobjectList = [SELECT Id, Name FROM Account WHERE Name IN ('Account 1', 'Account 2')];
        flowInput.fieldApi = 'Name';

        // Step 3: Call the flowcalled method
        List<UTIL_Convert_Record_Collection_to_String.FlowOutputs> flowOutputs;
        Test.startTest();
        flowOutputs = UTIL_Convert_Record_Collection_to_String.flowcalled(new List<UTIL_Convert_Record_Collection_to_String.FlowInputs>{ flowInput });
        Test.stopTest();

        // Step 4: Assert that the output string is correct
        System.assertNotEquals(null, flowOutputs, 'The output list should not be null.');
        System.assertEquals(1, flowOutputs.size(), 'The output list should contain one item.');
        System.assertEquals('Account 1,Account 2', flowOutputs[0].varString, 'The output string should match the expected concatenated names.');
    }

    @isTest
    static void testFlowCalledWithEmptySObjectList() {
        // Step 1: Prepare FlowInputs with an empty SObject list
        UTIL_Convert_Record_Collection_to_String.FlowInputs flowInput = new UTIL_Convert_Record_Collection_to_String.FlowInputs();
        flowInput.sobjectList = new List<SObject>();
        flowInput.fieldApi = 'Name';

        // Step 2: Call the flowcalled method
        List<UTIL_Convert_Record_Collection_to_String.FlowOutputs> flowOutputs;
        Test.startTest();
        flowOutputs = UTIL_Convert_Record_Collection_to_String.flowcalled(new List<UTIL_Convert_Record_Collection_to_String.FlowInputs>{ flowInput });
        Test.stopTest();

        // Step 3: Assert that the output string is empty
        System.assertNotEquals(null, flowOutputs, 'The output list should not be null.');
        System.assertEquals(1, flowOutputs.size(), 'The output list should contain one item.');
        System.assertEquals('', flowOutputs[0].varString, 'The output string should be empty for an empty SObject list.');
    }

    @isTest
    static void testFlowCalledWithNullRequests() {
        // Step 1: Call the flowcalled method with null inputs
        List<UTIL_Convert_Record_Collection_to_String.FlowOutputs> flowOutputs;
        Test.startTest();
        flowOutputs = UTIL_Convert_Record_Collection_to_String.flowcalled(null);
        Test.stopTest();

        // Step 2: Assert that the output list is empty
        System.assertNotEquals(null, flowOutputs, 'The output list should not be null.');
        System.assertEquals(0, flowOutputs.size(), 'The output list should be empty when requests are null.');
    }

    @isTest
    static void testFlowCalledWithEmptyRequests() {
        // Step 1: Call the flowcalled method with an empty input list
        List<UTIL_Convert_Record_Collection_to_String.FlowOutputs> flowOutputs;
        Test.startTest();
        flowOutputs = UTIL_Convert_Record_Collection_to_String.flowcalled(new List<UTIL_Convert_Record_Collection_to_String.FlowInputs>());
        Test.stopTest();

        // Step 2: Assert that the output list is empty
        System.assertNotEquals(null, flowOutputs, 'The output list should not be null.');
        System.assertEquals(0, flowOutputs.size(), 'The output list should be empty when requests are empty.');
    }

    @isTest
    static void testFlowCalledWithInvalidFieldApi() {
        // Step 1: Create test Accounts
        Account account1 = new Account(Name = 'Account 1');
        insert account1;

        // Step 2: Prepare FlowInputs with an invalid field API name
        UTIL_Convert_Record_Collection_to_String.FlowInputs flowInput = new UTIL_Convert_Record_Collection_to_String.FlowInputs();
        flowInput.sobjectList = [SELECT Id FROM Account WHERE Name = 'Account 1'];
        flowInput.fieldApi = 'InvalidField';

        // Step 3: Call the flowcalled method and handle exception if any
        Test.startTest();
        
        try {
            List<UTIL_Convert_Record_Collection_to_String.FlowOutputs> flowOutputs =
                UTIL_Convert_Record_Collection_to_String.flowcalled(new List<UTIL_Convert_Record_Collection_to_String.FlowInputs>{flowInput});
            System.assert(false, 'An exception should have been thrown due to invalid field API.');
            
            // If no exception is thrown, assert that no data is returned.
            System.assertEquals('', flowOutputs[0].varString, 'The output string should be empty for an invalid field API.');
            
         } catch (Exception e) {
            System.assert(true, 'Exception was correctly thrown for invalid field API.');
         }
         
         Test.stopTest();
    }
}