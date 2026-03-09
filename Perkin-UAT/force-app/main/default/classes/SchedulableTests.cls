/*This class is meant to test all of the schedulable classes written for the 2017 SAP integration
 * Last Modified by Tony Tran on June 16, 2017
 */

@istest
class SchedulableTests {
    
    public static testMethod void Main(){

        Integer numRecords = 20;
        List<Account> ListAccounts = new List<Account>();
    	List<SalesOrg__c> ListSOs = new List<SalesOrg__c>();
    	List<Account_Function__c> ListFunctions = new List<Account_Function__c>();
    	List<SalesOrgJunction__c> ListSOJs = new List<SalesOrgJunction__c>();

        //Get RecordType IDs
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Account; 
		Map<String,Schema.RecordTypeInfo> AccountRecordTypeInfo = cfrSchema.getRecordTypeInfosByName(); 
		Id rtId = AccountRecordTypeInfo.get('Customer').getRecordTypeId();
        
        //Create Hierarchy Accounts, have SAP Customer Numbers in the range of 0 - 199
        for(Integer i = 0; i < numRecords; i++){
            Account a = new Account();

            a = new Account(Name = 'Hierarchy Account' + i,
                            PKI_SAP_Customer_Number__c = String.valueOf(i),
                            //PKI_SAP_Function__c = 'Hierarchy',
                            recordtypeid = AccountRecordTypeInfo.get('Customer').getRecordTypeId());

            ListAccounts.add(a);
        }

        //Create Sold-To Accounts, Have SAP Customer Numbers in the range of 200 - 399
        for(Integer i = 0; i < numRecords; i++){
            Account a = new Account();
            if(i == 0)
                a = new Account(Name = 'Default for SAP Integration',
                                PKI_SAP_Customer_Number__c = String.valueOf(numRecords + i),
                                PKI_SAP_Customer_Base_Number__c = String.valueOf(i),
                                recordtypeid = AccountRecordTypeInfo.get('Customer').getRecordTypeId());
            else
            	a = new Account(Name = 'TestAccount' + i,
                                PKI_SAP_Customer_Number__c = String.valueOf(numRecords + i),
                                PKI_SAP_Customer_Base_Number__c = String.valueOf(i),
                                recordtypeid = AccountRecordTypeInfo.get('Customer').getRecordTypeId());
            
            ListAccounts.add(a);
        }
        
		//Create Partner Account records, Have SAP Customer Numbers in the range of 400 - 599
        for(Integer i = 0; i < numRecords; i++){
            Account a = new Account();
            if(i == 0)
                a = new Account(Name = 'Default for SAP Integration',
                    //PKI_SAP_Function__c = 'Payer/Bill-To (Not Europe)',
                    PKI_SAP_Customer_Number__c = String.valueOf((numRecords*2) + i));
            else
            	a = new Account(Name = 'TestPS' + i,
                    //PKI_SAP_Function__c = 'Payer/Bill-To (Not Europe)',
                    PKI_SAP_Customer_Number__c = String.valueOf((numRecords*2) + i));
            
            ListAccounts.add(a);
        }
        
        insert ListAccounts;
        
        //Create Function records, there will be 199 records since the first records for the Account and Partner Site
        //were used to create the Default records.
        for(Integer i = 1; i < 200; i++){
            Account_Function__c a = new Account_Function__c();
            a = new Account_Function__c(PKI_SAP_Partner_Type__c = 'RG',
                                PKI_SAP_Source_Account_Number__c = String.valueOf(numRecords + i),
                                PKI_SAP_Target_Account_Number__c = String.valueOf((numRecords*2) + i),
                                Source_Account__c = ListAccounts[0].id,
                                Target_Account__c = ListAccounts[0].id);
            
            ListFunctions.add(a);
        }
        
        insert ListFunctions;


        //Create Sales Org records
        for(Integer i = 0; i < numRecords; i++){
            SalesOrg__c a = new SalesOrg__c();
            if(i == 0)
            	a = new SalesOrg__c(PKISAPSalesOrg__c = 'Default');
            else
                a = new SalesOrg__c(PKISAPSalesOrg__c = String.valueOf(i));
            
            ListSOs.add(a);
        }
        
        insert ListSOs;        
        
        //Create Sales Org Junction records, there will be 199 records since the first records for the Account and
        //Sales Org were used to create the Default records.
        for(Integer i = 1; i < numRecords; i++){
            SalesOrgJunction__c a = new SalesOrgJunction__c();
            a = new SalesOrgJunction__c(PKI_SAP_Partner_Type__c = 'RE',
                                        PKI_SAP_Customer_Number__c = String.valueOf(numRecords + i),
                                		PKI_SAP_Sales_Org__c = String.valueOf(i),
                                		Related_Accounts__c = ListAccounts[0].id,
                                		Related_Sales_Orgs__c = ListSOs[0].id,
                                        SOJ_Key__c = String.valueOf(numRecords + i) + String.valueOf(i) + 'RE');
            
            ListSOJs.add(a);
        }
        
        insert ListSOJs;
        
        //Run Tests
        test.startTest();
        
        SAP_Account_UpdateParent_Batch test1 = new SAP_Account_UpdateParent_Batch();
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        system.schedule('Test on SAP_Account_UpdateParent_Batch', CRON_EXP, test1);
    
        SAP_Functions_UpdateAccountPS_Batch test2 = new SAP_Functions_UpdateAccountPS_Batch();
        Datetime dt2 = Datetime.now().addMinutes(1);
        String CRON_EXP2 = '0 '+ dt2.minute() + ' * ' + dt2.day() + ' ' + dt2.month() + ' ? ' + dt2.year();
        system.schedule('Test on SAP_Functions_UpdateAccountPS_Batch', CRON_EXP2, test2);      
        
        SAP_SOJ_UpdateAccountSalesOrg_Batch test3 = new SAP_SOJ_UpdateAccountSalesOrg_Batch();
        Datetime dt3 = Datetime.now().addMinutes(1);
        String CRON_EXP3 = '0 '+ dt3.minute() + ' * ' + dt3.day() + ' ' + dt3.month() + ' ? ' + dt3.year();
        system.schedule('Test on SAP_SOJ_UpdateAccountSalesOrg_Batch', CRON_EXP3, test3 ); 
        
        test.stopTest();
        
        //Asserts
        
    }
}