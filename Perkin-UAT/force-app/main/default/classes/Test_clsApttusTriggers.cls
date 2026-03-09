/*************************************
Created By : Lister Technologies
Version    : 1.0 - Test Class creation for all Apttus related triggers handled.
Version    : 1.01 - Added Exception handling
****************************************/
@isTest(SeeAllData=true)// Test class
public class Test_clsApttusTriggers{
   /*  static PageReference pref;
    //Method 1 : to ensure populateTerritorySelectionForPrinting and populateDistributorProductListForPrinting are covered
    static testMethod void runCases_populateTerritorySelectionForPrinting () {
       
        //Querying System Administrator profile
        Profile sysAdmin_Prof = [select Id from profile where Name='System Administrator'];
        
        //Creating the test user
        User objUsr_INF = new User(alias = 'sUser', Business__c = 'Informatics' , Home_Country__c = 'US', email='standarduserPKIINF@perkinelmerAPTTUS.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = sysAdmin_Prof.Id,timezonesidkey='America/Los_Angeles', username='standarduser12343432@perkinelmerPKITESTAPTTUS.com');
        insert objUsr_INF;
        
        System.runAs(objUsr_INF){
        
        try{
                //Creating Account Details
                Account testAcc = new Account();
                testAcc.Name = 'TestAcc';
                testAcc.BillingCountry ='US';
                testAcc.ShippingCountry ='US';
                Database.insert(testAcc);
                
                //Creating Agreement Test Record
               Apttus__APTS_Agreement__c iterting_ApttusAgreement = new Apttus__APTS_Agreement__c();
                iterting_ApttusAgreement.Apttus__Account__c = testAcc.Id;
                iterting_ApttusAgreement.Apts_Distributor_Product_List__c = 'ATOMIC ABSORPTION SPECTROSCOPY (AA);APPLICATION SYSTEMS (APS)';
                Database.insert(iterting_ApttusAgreement);
                
              Group testGroupA = new Group();
                testGroupA.Name='TestGroup A';
                insert testGroupA;
                GroupMember memberA= new GroupMember();
                memberA.GroupId=testGroupA.Id;
                memberA.UserOrGroupId=objUsr_INF.Id;
                insert memberA;
                
                 Apttus__APTS_Agreement__c apttusAgreement1 = new Apttus__APTS_Agreement__c();
                 apttusAgreement1.Apts_Distributor_Product_List__c = 'ATOMIC ABSORPTION SPECTROSCOPY (AA);APPLICATION SYSTEMS (APS)';
                apttusAgreement1.Strategic_Business_Element_SBE__c = 'Intellectual Property';
                insert apttusAgreement1 ;                
                //Creating Territory Selection Record
                Territory_Selection__c selTerritory = new Territory_Selection__c();
                selTerritory.Agreement__c = iterting_ApttusAgreement.Id;
                selTerritory.Americas_Countries__c = 'ARGENTINA;BRAZIL';
                selTerritory.Asia_Countries__c = 'CHINA;FIJI;INDIA';
                selTerritory.Europe_Countries_1__c = 'BELGIUM;BOTSWANA';
                selTerritory.Europe_Countries_2__c = 'MOROCCO;NAMIBIA';
                Database.insert(selTerritory);
        }
        catch(DMLException e){
           System.debug('message=' + e.getMessage());
        }
            
        }
    }
    //Method 2 : to ensure populateSalesVolumeProductListForPrinting is covered
    static testMethod void runCases_populateSalesVolumeProductListForPrinting () {
        //Querying System Administrator profile
        Profile sysAdmin_Prof = [select Id from profile where Name='System Administrator'];
        
        //Creating the test user
        User objUsr_INF = new User(alias = 'sUser', Business__c = 'Informatics' , Home_Country__c = 'US', email='standarduserPKIINF@perkinelmerAPTTUS.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = sysAdmin_Prof.Id,timezonesidkey='America/Los_Angeles', username='standarduser12343432@perkinelmerPKITESTAPTTUS.com');
        insert objUsr_INF;
        
        System.runAs(objUsr_INF){
        
            try{
                //Creating Account Test Record
                Account testAcc = new Account();
                testAcc.Name = 'TestAcc';
                testAcc.BillingCountry ='US';
                testAcc.ShippingCountry ='US';
                Database.insert(testAcc);
                
                //Creating Agreement Test Record
                Apttus__APTS_Agreement__c iterting_ApttusAgreement = new Apttus__APTS_Agreement__c();
                iterting_ApttusAgreement.Apttus__Account__c = testAcc.Id;
                iterting_ApttusAgreement.Apts_Distributor_Product_List__c = 'ATOMIC ABSORPTION SPECTROSCOPY (AA);APPLICATION SYSTEMS (APS)';
                Database.insert(iterting_ApttusAgreement);
                
                Apttus__APTS_Agreement__c apttusAgreement1 = new Apttus__APTS_Agreement__c();
                apttusAgreement1.Strategic_Business_Element_SBE__c = 'Intellectual Property';
                insert apttusAgreement1 ;
                
                //Creating Sales Volume Requirement Record
                Sales_Volume_Requirement__c svr = new Sales_Volume_Requirement__c();
                svr.Agreement__c = iterting_ApttusAgreement.Id;
                svr.Apts_Product_Line__c = 'ATOMIC ABSORPTION SPECTROSCOPY (AA);AUTOMATED WORKSTATIONS (AWS)';
                Database.insert(svr);
            }
            catch(DMLException e){
                     System.debug('message=' + e.getMessage());
            }
        }
    }
    
    static testMethod void runCases_populateEditablenandNonEditable () {
        
        //Creating Account Test Record
        Account testAcc = new Account();
        testAcc.Name = 'TestAcc';
        testAcc.BillingCountry ='US';
        testAcc.ShippingCountry ='US';
        Database.insert(testAcc);
        
        
        pref = Page.L_VF_entityNotBeDeletable;
        pref.getParameters().put('retURL',testAcc.id);
        pref.getParameters().put('id',testAcc.id);
        Test.setCurrentPage(pref);
        
        ApexPages.StandardController    con                              = new ApexPages.StandardController(testAcc);
        
        cls_entityNotBeDeletable        ocls_entityNotBeDeletable        = new cls_entityNotBeDeletable(con);
        
        pref = Page.L_VF_entityNotEditable;
        pref.getParameters().put('retURL',testAcc.id);
        pref.getParameters().put('id',testAcc.id);
        Test.setCurrentPage(pref);
        
        cls_entityNotEditable           ocls_entityNotEditable           = new cls_entityNotEditable(con);
        
        //Creating an employee
        Employee__c testEmp                                              = new Employee__c();
        testEmp.First_Name__c                                            = 'Test FN';
        testEmp.Last_Name__c                                             = 'Test LN';
        testEmp.Name                                                     = 'Test FN';
        testEmp.Job_Title__c                                             = 'Test Job Title';
        testEmp.Email__c                                                 = 'Test@test.com';
        Database.insert(testEmp);
        
        pref = Page.employeeNonOfficerDeletable;
        pref.getParameters().put('retURL',testEmp.id);
        pref.getParameters().put('id',testEmp.id);
        Test.setCurrentPage(pref);
        
        
        ApexPages.StandardController    con_Emp                          = new ApexPages.StandardController(testEmp);
        
        cls_employeeNonOfficerDeletable ocls_employeeNonOfficerDeletable = new cls_employeeNonOfficerDeletable(con_Emp);
    }*/
}