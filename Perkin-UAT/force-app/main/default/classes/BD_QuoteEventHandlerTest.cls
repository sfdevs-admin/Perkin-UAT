@isTest
public class BD_QuoteEventHandlerTest {
	@testSetup
    static void createTestData() {
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;
        
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        
        for (Integer i = 0; i < 3; i++) {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = testAccount.Id
            );
            quotes.add(quote);
        }
        insert quotes;
       
    }
    
    @isTest
    static void testCreationOfPlatformEventLogs() {
        
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c LIMIT 3];
        
        List<BD_Quote_Event__e> quoteEvents = new List<BD_Quote_Event__e>();
        
        for (SBQQ__Quote__c quote : quotes) {
                BD_Quote_Event__e event = new BD_Quote_Event__e();
                event.BD_Quote_Id__c = quote.Id;
                event.BD_Action__c = 'CREATE';
            quoteEvents.add(event);
        }
        Test.startTest();
        EventBus.publish(quoteEvents);
        Test.stopTest();
        
        List<SMAX_PS_Platform_Event_Log__c> logs = [SELECT Id, SMAX_PS_Related_Element_Id__c 
                                                    FROM SMAX_PS_Platform_Event_Log__c];
        
        Assert.areEqual(3, logs.size(), 'Expected 3 Platform Event Log records');
    }
}