@IsTest
public with sharing class B2BLogCustomExceptionTest {
        //Comment to force git diff
    public class B2BCustomException extends Exception {}
    
	@isTest
    static void testLogExceptionWithoutRelatedToId() {
        // Create a new custom exception
        B2BCustomException testException = new B2BCustomException('Test exception message');
        
        // Call the LogException method
        Test.startTest();
        B2BLogCustomException.LogException(testException, 'TestCategory', 'TestSubcategory');
        Test.stopTest();
    }
}