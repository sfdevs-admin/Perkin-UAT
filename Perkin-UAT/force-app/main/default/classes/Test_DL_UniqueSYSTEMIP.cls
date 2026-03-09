@IsTest
public class Test_DL_UniqueSYSTEMIP {
    static TestMethod void DemoLogTestMethod(){
        List<Demo_Log__c> demoList = new List<Demo_Log__c>();
        
        Demo_Log__c demoRec = new Demo_Log__c();
        demoRec.Primary_Product_INF__c = 'Attivio';
        demoRec.System_s_IP__c = '1213';
        demoList.add(demoRec);
        
        Demo_Log__c demologRec = new Demo_Log__c();
        demologRec.Primary_Product_INF__c = 'Attivio';
        demologRec.System_s_IP__c = '12134';
        demoList.add(demologRec);
        
        Demo_Log__c demoLogRecord = new Demo_Log__c();
        demoLogRecord.Primary_Product_INF__c = 'Attivio';
        demoList.add(demoLogRecord);
        
        Insert demoList;
        
        demoList[2].System_s_IP__c = '1213';
        try{
            update demoList[2];
        }catch(exception exp){
            
        }
    }
}