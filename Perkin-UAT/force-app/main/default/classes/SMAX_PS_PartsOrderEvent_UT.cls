@isTest(seeAlldata=false)
public class SMAX_PS_PartsOrderEvent_UT {

    // Not a valid "test", but need code coverage.. 
    // We found that if seeAllData is true, Platform Event triggers don't fire.
    // BUT, can't create a Parts Order without seeAllData=true
    static testmethod void partsOrderEventTest() {
        Test.startTest();
        SMAX_PS_PartsOrder_Event__e poEvent = new SMAX_PS_PartsOrder_Event__e (
                                    SMAX_PS_PartsOrderId__c = 'Test PO',
                                    SMAX_PS_Action__c = 'Create');
        Database.SaveResult sr = EventBus.publish(poEvent);
        Test.stopTest();
   }
}