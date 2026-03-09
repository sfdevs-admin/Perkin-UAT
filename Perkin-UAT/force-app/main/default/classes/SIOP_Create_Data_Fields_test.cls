/**
 * Class:SIOP_Create_Data_Fields_test
 * Author: (PWC)Vishwas
 * Created Date:29 july,2020
 * Functionality: test class for scheduler and batch apex class schedule_SIOP_Create_Data_Fields, SIOP_Create_Data_Fields respectively:ticket No.ITSFDC-2405
 */
@isTest 
public class SIOP_Create_Data_Fields_test {

    @testSetup static void setup() {
        // SELECT Id, Name, CutoffDate__c FROM SIOP_Model_Cutoff__c
        SIOP_Model_Cutoff__c SMC = new SIOP_Model_Cutoff__c();
        SMC.CutoffDate__c=Date.newInstance(Date.today().year(), Date.today().Month(), 5);
        insert SMC;
        // Create common test SIOP_Model_Master__c
        list<SIOP_Model_Master__c> mlist = new list<SIOP_Model_Master__c>();
        for(integer i=0;i<10;i++){
          SIOP_Model_Master__c testSIOPMaster = new SIOP_Model_Master__c();
		testSIOPMaster.name='test Master'+i;
		testSIOPMaster.Product_Line__c='test product line'+i;
		testSIOPMaster.Product_Line_Description__c='test Product Line Description'+i; 
            mlist.add(testSIOPMaster);
        }
        
		insert mlist;
        list<string> regions= new list<string>{'EMEAI','APAC','AMERICAS'};
        list<SIOP_Model_Data__c> dlist = new List<SIOP_Model_Data__c>();
        for(SIOP_Model_Master__c testSIOPMaster:mlist){
            for(string str:regions){
		SIOP_Model_Data__c testSIOPData = new SIOP_Model_Data__c();
		testSIOPData.name='07,2020.Actual.EMEAI.test Master';
		testSIOPData.Type__c='Actual';
		testSIOPData.Region__c=str;
		testSIOPData.Date__c=Date.newInstance(Date.today().year(), Date.today().addMonths(1).Month(), 27); 
		testSIOPData.SIOP_Model_Master__c=testSIOPMaster.id;
        dlist.add(testSIOPData);
       SIOP_Model_Data__c testSIOPData1 = new SIOP_Model_Data__c();
		testSIOPData1.name='07,2020.Region Ask-Orders.EMEAI.test Master';
		testSIOPData1.Type__c='Region Ask-Orders';
		testSIOPData1.Region__c=str;
		testSIOPData1.Date__c=Date.newInstance(Date.today().year(), Date.today().addMonths(1).Month(), 27); 
		testSIOPData1.SIOP_Model_Master__c=testSIOPMaster.id;
       dlist.add(testSIOPData1);
        SIOP_Model_Data__c testSIOPData0 = new SIOP_Model_Data__c();
		testSIOPData0.name='07,2020.Region Ask-Shipment.EMEAI.test Master';
		testSIOPData0.Type__c='Region Ask-Shipment';
		testSIOPData0.Region__c=str;
		testSIOPData0.Date__c=Date.newInstance(Date.today().year(), Date.today().addMonths(1).Month(), 27); 
		testSIOPData0.SIOP_Model_Master__c=testSIOPMaster.id;
       dlist.add(testSIOPData0);         
        SIOP_Model_Data__c testSIOPData2 = new SIOP_Model_Data__c();
		testSIOPData2.name='07,2020.PM Ask.EMEAI.test Master';
		testSIOPData2.Type__c='PM Ask';
		testSIOPData2.Region__c=str;
		testSIOPData2.Date__c=Date.newInstance(Date.today().year(),Date.today().addMonths(1).Month(), 27); 
		testSIOPData2.SIOP_Model_Master__c=testSIOPMaster.id;
        dlist.add(testSIOPData2);
        SIOP_Model_Data__c testSIOPData3 = new SIOP_Model_Data__c();
		testSIOPData3.name='07,2020.Final SIOP.EMEAI.test Master';
		testSIOPData3.Type__c='Final SIOP';
		testSIOPData3.Region__c=str;
		testSIOPData3.Date__c=Date.newInstance(Date.today().year(), Date.today().addMonths(1).Month(), 27); 
		testSIOPData3.SIOP_Model_Master__c=testSIOPMaster.id;
       dlist.add(testSIOPData3); 
        }
     }
        insert dlist;
    }


    static testMethod void testMethod1(){
        Test.startTest();
           // SIOP_Create_Data_Fields obj = new SIOP_Create_Data_Fields();
           //  DataBase.executeBatch(obj);
           schedule_SIOP_Create_Data_Fields obj = new schedule_SIOP_Create_Data_Fields();
            String sch = '0 0 20 * * ?';
          String jobID = system.schedule('Merge Job', sch, obj); 
            
        Test.stopTest();
    }
}