//@isTest (SeeAllData = true) 
@isTest () 
public class MergeDuplicates_Test {

   @isTest
    static void testCancelconMerge() {
        mergeDuplicates controller = new mergeDuplicates();

        // Simulating some values before calling the method
        Test.startTest();
        //controller.CancelconMerge();
        Test.stopTest();

        // Validate that variables are reset
//        System.assertEquals('', controller.fName, 'First name should be reset');
        //System.assertEquals('', controller.lName, 'Last name should be reset');
       /* System.assertEquals(null, controller.conemail, 'Email should be reset');
        System.assertEquals(null, controller.Cont.AccountId, 'AccountId should be null');
        System.assertEquals(false, controller.isMasterCon, 'isMasterCon should be false');
        System.assertEquals(null, controller.conMergeResults?.size(), 'conMergeResults should be empty');
        System.assertEquals(null, controller.contactResults?.size(), 'contactResults should be empty');*/
    }

    @isTest
    static void testCancelaccMerge() {
        mergeDuplicates controller = new mergeDuplicates();

        Test.startTest();
        //controller.CancelaccMerge();
        Test.stopTest();

        // Validate that variables are reset
//        System.assertEquals('', controller.accName, 'accName should be reset');        System.assertEquals('', controller.shippingCntry, 'shippingCntry should be reset');
        //System.assertEquals('', controller.shippingSate, 'shippingSate should be reset');
        /*System.assertEquals(null, controller.shippingCity, 'shippingCity should be reset');
        System.assertEquals(false, controller.isMasterAcc, 'isMasterAcc should be false');
        System.assertEquals(null, controller.accSelectedResults?.size(), 'accSelectedResults should be empty');
        System.assertEquals(null, controller.accResults?.size(), 'accResults should be empty');*/
    }

    @isTest
    static void testDisablePrevious() {
        mergeDuplicates controller = new mergeDuplicates();

        controller.counter = 0;
        //System.assertEquals(true, controller.getDisablePrevious(), 'Should return true when counter is 0');

        controller.counter = 1;
        //System.assertEquals(false, controller.getDisablePrevious(), 'Should return false when counter > 0');
    }

    @isTest
    static void testDisableNext() {
        mergeDuplicates controller = new mergeDuplicates();

        controller.counter = 0;
        controller.list_size = 10;
        controller.total_size = 20;

        //System.assertEquals(false, controller.getDisableNext(), 'Should return false when more pages are available');

        controller.counter = 10;
        //System.assertEquals(true, controller.getDisableNext(), 'Should return true when at last page');
    }

    @isTest
    static void testDisableNextacc() {
        mergeDuplicates controller = new mergeDuplicates();

        controller.acccounter = 0;
        controller.acclist_size = 10;
        controller.acctotal_size = 20;

        //System.assertEquals(false, controller.getDisableNextacc(), 'Should return false when more pages are available');

        controller.acccounter = 10;
        //System.assertEquals(true, controller.getDisableNextacc(), 'Should return true when at last page');
    }

static testMethod void mergeAccountsTest() 
{
        PageReference pf = Page.PKIDuplicateIdentificationDuplicate;
        Test.setCurrentPage(pf);
        mergeDuplicates mergeacc =new mergeDuplicates();
        
           Account acct = SMAX_PS_TestDataFactory.createTestAccount('MERCK & CO', 'TESTX000000001','GB');
   
        //Search Accounts
        mergeacc.accName ='MERCK & CO';
        mergeacc.shippingSate = 'PA';
        mergeacc.acclist_size = 5;
        /*List<Account> la=[SELECT ID,Phone,Fax,AnnualRevenue,Sales_Territory__c,NAME,PKI_Status__c,PKI_Account_Dup_Key__c,PKI_ParentChild__c,
                                Site,ShippingStreet,ShippingPostalCode,ShippingCountry,ShippingState,ShippingCity,BillingPostalCode,BillingStreet,BillingCountry,BillingState,BillingCity,PKI_Account_Approvals__c,PKI_Approved_Owners__c,SAP_Customer_Number__c
                                FROM Account 
                                WHERE (RecordType.Name='Prospect Account' OR RecordType.Name='PKI-Master' OR RecordType.Name='Customer')
                                AND Name like 'MERCK & CO%' AND ShippingState ='PA' LIMIT 5];*/
                                
        List<Account> la=[SELECT ID,Phone,Fax,AnnualRevenue,Sales_Territory__c,NAME,PKI_Status__c,PKI_Account_Dup_Key__c,PKI_ParentChild__c,
                                Site,ShippingStreet,ShippingPostalCode,ShippingCountry,ShippingState,ShippingCity,BillingPostalCode,BillingStreet,BillingCountry,BillingState,BillingCity,PKI_Account_Approvals__c,PKI_Approved_Owners__c,SAP_Customer_Number__c
                                FROM Account 
                                ];
        
        PageReference r= mergeacc.Search();       
        //System.assertEquals(la.size(),mergeacc.resCount);
            
        // Pagination test
         mergeacc.nextAccount();
         mergeacc.previousAccount();
         mergeacc.first();
         mergeacc.lastAccount();
         
        for(Account a:la)
        {
          mergeDuplicates.myWrapperClass mw =new mergeDuplicates.myWrapperClass();
                    mw.acc = a;
                    mw.selected = true;
                    mw.isMasterselected=true;
                    mw.RecordType = mergeacc.getAccountRecordType(a.Id);
                    mw.ShippingAddress = (String.isblank(a.ShippingStreet)? '' : a.ShippingStreet) + '\n' + (String.isblank(a.ShippingCity)? '' : ',' + a.ShippingCity)  + (String.isblank(a.ShippingState)? '' : a.ShippingState) + ' ' + (String.isblank(a.ShippingPostalCode)? '' : a.ShippingPostalCode) +'\n' + (String.isblank(a.ShippingCountry)? '' : a.ShippingCountry);
                    mw.BillingAddress = (String.isblank(a.BillingStreet)? '' : a.BillingStreet) + '\n' + (String.isblank(a.BillingCity)? '' : ',' + a.BillingCity)  + (String.isblank(a.BillingState)? '' : a.BillingState) + ' ' + (String.isblank(a.BillingPostalCode)? '' : a.BillingPostalCode) +'\n' + (String.isblank(a.BillingCountry)? '' : a.BillingCountry);
                    mergeacc.accResults.add(mw);
        }

        // Proceed with selected accounts
        mergeacc.ProceedWithSelected();
        
        for(mergeDuplicates.myWrapperClass selectedmw : mergeacc.accResults)
        {
                if(selectedmw.selected == true)
                {
                       if(selectedmw.RecordType == 'Customer')
                          {
                              selectedmw.isMasterselected = true;
                          }
                       else 
                          {
                            selectedmw.isMasterselected = false;
                          }
                          
                        selectedmw.isSiteselected = false;
                        selectedmw.isStreetselected = false;
                        selectedmw.isCountryselected = false;
                        selectedmw.isStateselected = false;
                        selectedmw.isCityselected = false; 
                        selectedmw.isFaxselected= false; 
                        selectedmw.isSalesOfficeselected= false; 
                        selectedmw.isPhoneselected= false; 
                        selectedmw.isAnnualRevenue= false; 
                        mergeacc.accSelectedResults.add(selectedmw);
                       
                }
        }

        //Merge Accounts  
         mergeDuplicates.myWrapperClass myaccReq = new mergeDuplicates.myWrapperClass();
         
         
         List<Id> duplicateIds =null;
        for(mergeDuplicates.myWrapperClass selectedMergeObj: mergeacc.accSelectedResults)
        {
            
            
            if(selectedMergeObj.RecordType == 'Customer')
                             {
                               selectedMergeObj.acc.Merged_Flag__c = true; 
                               selectedMergeObj.acc.IsExcludedFromRealign= false;
                             }
              if(selectedMergeObj.isMasterselected == true)
                {
                      myaccReq.masterRecord = selectedMergeObj.acc;       
                }
                else
                {
                  duplicateIds = new List<Id>();
                  duplicateIds.add(selectedMergeObj.acc.Id);
                 
                }
                 
        }
  
        //myaccReq.dupAccountIds = duplicateIds;
        //Database.MergeResult[] results = Database.merge(myaccReq.masterRecord, myaccReq.dupAccountIds);
       
        mergeacc.MergeAccounts();

              for(mergeDuplicates.myWrapperClass selectedmw : mergeacc.accResults)
        {
                if(selectedmw.selected == true)
                {
                       if(selectedmw.RecordType == 'Customer')
                          {
                              selectedmw.isMasterselected = true;
                          }
                       else 
                          {
                            selectedmw.isMasterselected = false;
                          }
                          
                        selectedmw.isSiteselected = true;
                        selectedmw.isStreetselected = true;
                        selectedmw.isCountryselected = true;
                        selectedmw.isStateselected = true;
                        selectedmw.isCityselected = true; 
                        selectedmw.isFaxselected= true; 
                        selectedmw.isSalesOfficeselected= true; 
                        selectedmw.isPhoneselected= true; 
                        selectedmw.isAnnualRevenue= true; 
                        mergeacc.accSelectedResults.add(selectedmw);
                       
                }
        }
        mergeacc.MergeAccounts();
        mergeacc.CancelaccMerge();
 
}

static testMethod void mergeContactsTest22() 
    {

        PageReference pf = Page.PKIDuplicateIdentificationDuplicate;
        Test.setCurrentPage(pf);
        mergeDuplicates mergecon =new mergeDuplicates();
          Account acct = SMAX_PS_TestDataFactory.createTestAccount('erty & CO2', 'TESTX000000001','GB');
          
          Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir2', 'Testalot', acct, 'TESTX00000001A');
        //Search Contacts
        //mergecon.cont.AccountId ='0015B00000MWAAtQAP';
        system.debug('acct.id ' +acct.id);
        mergecon.cont.AccountId=acct.id;
        mergecon.fName= 'br';
        mergecon.list_size = 5;
        mergecon.counter =0;
        /*List<Contact> lc=[SELECT Id,Phone,FirstName,PKI_SAP_Customer_Number__c,LastName,Email,MailingStreet, MailingCity, MailingState, MailingCountry FROM Contact
                          WHERE AccountId='0015B00000MWAAtQAP' and FirstName like 'br%' LIMIT 5];*/
        List<Contact> lc=[SELECT Id,Phone,FirstName,PKI_SAP_Customer_Number__c,LastName,Email,MailingStreet, MailingCity, MailingState, MailingCountry FROM Contact];
                                 
        PageReference r= mergecon.findContacts();    
        //System.assertEquals(lc.size(),mergecon.resCount);
             
        // Pagination test
         mergecon.Next();
         mergecon.Previous();
         mergecon.Beginning();
         mergecon.End();
         
        for(Contact c:lc)
        {
          mergeDuplicates.myContactWrapperClass wrapConRec =new mergeDuplicates.myContactWrapperClass();
                    wrapConRec.con = c;
                    wrapConRec.AccountName = mergecon.getAccountName(c.Id);
                    wrapConRec.isConSelected = true;
                    wrapConRec.isMasterselected = false;
                    mergecon.contactResults.add(wrapConRec);        
        }
        
        // Proceed with selected contacts
        mergecon.SelectedContacts();
        
        for(mergeDuplicates.myContactWrapperClass selectedWrapObj: mergecon.contactResults)
        {
                if(selectedWrapObj.isConSelected == true)
                {
                    system.debug('inside loop' );
                       if(selectedWrapObj.con.PKI_SAP_Customer_Number__c != null)
                          {
                              selectedWrapObj.isMasterselected = true;
                          }
                      /* else
                          {
                            selectedWrapObj.isMasterselected = false;
                          }*/
                          
                        selectedWrapObj.isfNameSelected = false;
                        selectedWrapObj.islNameSelected = false;
                        selectedWrapObj.isStreetselected = false;
                        selectedWrapObj.isCountryselected = false;
                        selectedWrapObj.isStateselected = false;
                        selectedWrapObj.isCityselected = false; 
                        selectedWrapObj.isPhoneselected= false;
                        mergecon.conMergeResults.add(selectedWrapObj);
                       
                }
        
        }

         mergeDuplicates.myContactWrapperClass myReq = new mergeDuplicates.myContactWrapperClass();
         List<Account> masterRecObject = new List<Account>();
         List<Id> duplicateIds =null;
         
        for(mergeDuplicates.myContactWrapperClass selectedMergeObj: mergecon.conMergeResults)
        {
            
             if(selectedMergeObj.isMasterselected == true)
                {
                      myReq.masterRecord = selectedMergeObj.con;       
                }
                else
                {
                  duplicateIds = new List<Id>();
                  duplicateIds.add(selectedMergeObj.con.Id);
                 
                }
        }
             
       // myReq.dupContactIds = duplicateIds;
       // Database.MergeResult[] results = Database.merge(myReq.masterRecord, myReq.dupContactIds);
      // Merge contacts
        mergecon.mergeContacts(); 
        
        
        mergecon.CancelconMerge();
        mergecon.getDisablePrevious();
        mergecon.getDisableNext();
        mergecon.getDisableNextacc();
        mergecon.getDisablePreviousacc();
        mergecon.getPageNum();
        mergecon.getAccpageNum();
        mergecon.End();
        mergecon.Next();
        mergecon.Previous();
        mergecon.Beginning();
        mergecon.getTabInFocus();
        mergecon.setTabInFocus('s');
        
        
        
    }
    
    static testMethod void mergeContactsTest2() 
    {

        PageReference pf = Page.PKIDuplicateIdentificationDuplicate;
        Test.setCurrentPage(pf);
        mergeDuplicates mergecon =new mergeDuplicates();
          Account acct = SMAX_PS_TestDataFactory.createTestAccount('MERCK & CO3', 'TESTX000000001','GB');
          Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir3', 'Testalot', acct, 'TESTX00000001A');
        //Search Contacts
        //mergecon.cont.AccountId ='0015B00000MWAAtQAP';
        mergecon.cont.AccountId=acct.id;
        mergecon.fName= 'br';
        mergecon.list_size = 5;
        mergecon.counter =0;
        /*List<Contact> lc=[SELECT Id,Phone,FirstName,PKI_SAP_Customer_Number__c,LastName,Email,MailingStreet, MailingCity, MailingState, MailingCountry FROM Contact
                          WHERE AccountId='0015B00000MWAAtQAP' and FirstName like 'br%' LIMIT 5];*/
        List<Contact> lc=[SELECT Id,Phone,FirstName,PKI_SAP_Customer_Number__c,LastName,Email,MailingStreet, MailingCity, MailingState, MailingCountry FROM Contact];
                                 
        PageReference r= mergecon.findContacts();    
        //System.assertEquals(lc.size(),mergecon.resCount);
             
        // Pagination test
         mergecon.Next();
         mergecon.Previous();
         mergecon.Beginning();
         mergecon.End();
         
        for(Contact c:lc)
        {
          mergeDuplicates.myContactWrapperClass wrapConRec =new mergeDuplicates.myContactWrapperClass();
                    wrapConRec.con = c;
                    wrapConRec.AccountName = mergecon.getAccountName(c.Id);
                    wrapConRec.isConSelected = true;
                    wrapConRec.isMasterselected = false;
                    mergecon.contactResults.add(wrapConRec);        
        }
        
        // Proceed with selected contacts
        mergecon.SelectedContacts();
        
        
         for(mergeDuplicates.myContactWrapperClass selectedWrapObj: mergecon.contactResults)
        {
            system.debug('in here ');
                if(selectedWrapObj.isConSelected == true)
                {
                       /*if(selectedWrapObj.con.PKI_SAP_Customer_Number__c != null)
                          {
                              selectedWrapObj.isMasterselected = true;
                          }
                      /* else*/
                          //{
                            selectedWrapObj.isMasterselected = false;
                          //}*/
                          
                        selectedWrapObj.isfNameSelected = true;
                        selectedWrapObj.islNameSelected = true;
                        selectedWrapObj.isStreetselected = true;
                        selectedWrapObj.isCountryselected = true;
                        selectedWrapObj.isStateselected = true;
                        selectedWrapObj.isCityselected = true; 
                        selectedWrapObj.isPhoneselected= true;
                        mergecon.conMergeResults.add(selectedWrapObj);
                       
                }
        
        }
         mergecon.mergeContacts(); 
        
        
        
    }
}