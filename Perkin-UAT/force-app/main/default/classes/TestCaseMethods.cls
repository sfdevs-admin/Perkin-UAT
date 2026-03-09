@isTest(seeAllData=true)
public class TestCaseMethods {
    @isTest
    public static void test(){
        RecordType rt= [Select Name,id from RecordType where Name='Informatics' and sobjecttype='Case' limit 1];
        
        Account a = CT_TestDataSetupUtility.createTestAccount('TEST1','77778','Test');
        insert a;
        
        Contact c = CT_TestDataSetupUtility.createTestContact(a.id,'test123','test4','test1234@test.com');
        insert c;
        
        RecordType rt1= [Select Name,id from RecordType where Name='LST Support & Service' and sobjecttype='Case' limit 1];
        RecordType rt2= [Select Name,id from RecordType where DeveloperName='LST_Quality' limit 1];
        
       
        Test.startTest();
        Attachment attach=new Attachment();     
        attach.Name='Support Special Handling';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=a.id;
        insert attach;
        
        Attachment attachTwo=new Attachment();     
        attachTwo.Name='Support Special Handling';
        bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attachTwo.body=bodyBlob;
        attachTwo.parentId=a.id;
        insert attachTwo;
        
        Note n = new Note(Title='Support Special Handling',parentid=a.id);
        insert n;
        Note nOne = new Note(Title='Support Special Handling',parentid=a.id);
        insert nOne;
        
         
        
        Case testCaseTwo = new Case(subject='Test',status='InProgress:Escalated',recordtypeid=rt.id,contactid = c.id,accountid=a.id,INF_Categories__c='Activation',INF_Time_Spent__c=11);
        insert testCaseTwo;
        setBoolean();
        testCaseTwo.status ='New';// 'Closed:Pending Customer';
        update testCaseTwo;
        
        testCaseTwo.INF_Send_Survey__c=true;
        testCaseTwo.status ='New';// 'Closed';
        setBoolean();
        update testCaseTwo;
        
        system.debug('BOOLEANS '+Trigger_RecursionHandler.stopRun);
        Case testCaseOne = new Case(subject='Test',status='New',recordtypeid=rt.id,contactid = c.id);
        insert testCaseOne;
        setBoolean();
        
        Case testCaseThree = new Case(subject='Test',status='InProgress:Escalated',recordtypeid=rt.id,contactid = c.id,accountid=a.id,INF_Categories__c='Activation',INF_Time_Spent__c=11);
        insert testCaseThree;
        setBoolean();
        
       Test.stopTest();
    }
    @isTest
    public static void test2(){
        RecordType rt= [Select Name,id from RecordType where Name='Informatics' and sobjecttype='Case' limit 1];
        
        Account a = CT_TestDataSetupUtility.createTestAccount('TEST1','77778','Test');
        insert a;
        
        Contact c = CT_TestDataSetupUtility.createTestContact(a.id,'test123','test4','test1234@test.com');
        insert c;
        
        RecordType rt1= [Select Name,id from RecordType where Name='LST Support & Service' and sobjecttype='Case' limit 1];
        RecordType rt2= [Select Name,id from RecordType where DeveloperName='LST_Quality' limit 1];
        
       
        
        Attachment attach=new Attachment();     
        attach.Name='Support Special Handling';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=a.id;
        insert attach;
        
        Attachment attachTwo=new Attachment();     
        attachTwo.Name='Support Special Handling';
        bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attachTwo.body=bodyBlob;
        attachTwo.parentId=a.id;
        insert attachTwo;
        
        Note n = new Note(Title='Support Special Handling',parentid=a.id);
        insert n;
        Note nOne = new Note(Title='Support Special Handling',parentid=a.id);
        insert nOne;
        
         Test.startTest();
        
         Asset testAsset = new Asset(Name='test',Accountid=a.id);
        insert testAsset;
        
        setBoolean();
        Case testCaseFour = new Case(subject='Test',status='Closed',INF_Categories__c='Activation',recordtypeid=rt1.id,Type='Field Service',Sub_Type__c='Installation',Functional__c='0% - Major field replacements',Completeness__c='0% - 2+ components missing',Packaging__c='0% - Neither',Assetid=testAsset.id,INF_Time_Spent__c=11);
        insert testCaseFour;
        setBoolean();
        
        system.debug('RECORD TYPE '+rt2.Name);
        
        Case testCaseFive = new Case(subject='test',status='New',recordtypeid=rt2.id,Service_Case__c=testCaseFour.id,INF_Time_Spent__c=11);
        insert testCaseFive;
        setBoolean();
        testCaseFive.Type='Quality Failure';
        testCaseFive.Q_Severity__c = 'Serious';
        update testCaseFive;
        setBoolean();
        
        Case testCaseSix = new Case(subject='Test',status='New',recordtypeid=rt2.id,Type='Out of Box Failure',Q_Priority_Override__c='No',INF_Time_Spent__c=11);
        insert testCaseSix;
        
        testCaseSix.Type='Quality Failure';
        testCaseSix.Q_Severity__c = 'Serious';
        
        update testCaseSix;
        setBoolean();
        Test.stopTest();
    }
    public static void testServiceCase() {
        Map<String, RecordType> RecTypeListMap = new Map<String, RecordType>();
        for (RecordType RecList : [select Id, Name from RecordType where SobjectType = 'Case']) {
            RecTypeListMap.put(RecList.Name, RecList);
        }
        StaticVariables.AfterTgrEventsCase = false;
        
        //1 create matching config
        QI_Case_Copy_Config__c config = new QI_Case_Copy_Config__c( Case_Status__c = 'Closed',
                                                                   Service_Case_Type__c = 'Field Service', 
                                                                   Service_Case_Sub_Type__c = 'Installation Request', 
                                                                   Resolution_Code_3__c = '100% - Professional AND Protected', 
                                                                   Resolution_Code_2__c = '100% - No components missing', 
                                                                   Resolution_Code_1__c = '50% - Only Minor field replacements', 
                                                                   Quality_Case_Status__c = 'New', 
                                                                   Quality_Case_Type__c = 'Out of Box Failure',
                                                                   Quality_Case_Sub_Type__c = '' 
                                                                   
                                                                  );
        insert config;
        system.debug('config-->'+config);
        StaticVariables.afterInsertCase = false;
        StaticVariables.beforeInsertUpdateCase = false;
        //2 create Service case
        Case srvCase = new Case ( Status = 'New',
                                 Subject = 'Test Service Case',
                                 Description = 'Test Service Case',
                                 Origin = 'Phone',
                                 //AssetId = '02iR0000000cg9G',
                                 RecordTypeId = RecTypeListMap.get('LST Support & Service').Id,
                                 Type = 'Field Service',
                                 Sub_Type__c = 'Installation Request',
                                 Packaging__c   = '100% - Professional AND Protected', 
                                 Completeness__c = '100% - No components missing', 
                                 Functional__c = '50% - Only Minor field replacements'
                                );
        insert srvCase;
        
        StaticVariables.beforeInsertUpdateCase = true;
        //3 update case status to match config
        srvCase.Status = 'Closed';
        update srvCase; 
    }
    
    public static void setBoolean(){
        CaseMethods.runAfterInsert = true;
        CaseMethods.runAfterUpdate = true;
        CaseMethods.runBeforeInsert = true;
        CaseMethods.runBeforeUpdate = true;
        Trigger_RecursionHandler.stopRun = false;
        StaticVariables.beforeInsertUpdateCase = true;
        StaticVariables.afterInsertCase = true;
    }
    
    public static testMethod void testCaseCustomAudit(){
 //       RecordType rt = [Select Id FROM RecordType WHERE sobjectType = 'Case' AND Name = 'Dx_Software_Services' LIMIT 1];
        Case objCase = new Case(Subject='Test Case',Status='New', Typeofcase__C = 'Anomaly',DX_CR_Status__c='Requirements Gathering'/*,RecordTypeId=rt.Id*/);
        insert objCase;
/*        Custom_Case_Audit__c caseRec = [Select Field__c from Custom_Case_Audit__c where CaseRef__c =: objCase.Id];
        system.assertEquals('CR Status', caseRec.Field__c); */
        
        objCase.Status='New';
        objCase.DX_CR_Status__c='Pending Customer Approval';
        CaseMethods.runAfterUpdate = True;
        Update objCase; 
        
        //Custom_Case_Audit__c caseRec1 = [Select Field__c,Value__c from Custom_Case_Audit__c where CaseRef__c =: objCase.Id ];
        //system.assertEquals('2-Pending Customer Approval', caseRec1.Value__c);
    }
    
    public static testMethod void testCaseSuppliedEmail(){
//        RecordType rt = [Select Id FROM RecordType WHERE sobjectType = 'Case' AND Name = 'Dx_Software_Services' LIMIT 1];
        Case objCase = new Case
            (Subject='Test Case',
             Status='New', 
             Typeofcase__C = 'Anomaly',
             DX_CR_Status__c='Requirements Gathering',
//             RecordTypeId=rt.Id,
             SuppliedEmail='test@gmail.com'
            );
        insert objCase;
        
      List<blackListEmails__c> blackListEmailsList = new List<blackListEmails__c>();
      blackListEmails__c newBlkEmailList = new blackListEmails__c();
      newBlkEmailList.isDomain__c = false;
      newBlkEmailList.Name = 'test';
      newBlkEmailList.Domain__c = 'gmail.com';
      newBlkEmailList.Email_Id__c = 'test@gmail.com';
      blackListEmailsList.add(newBlkEmailList);
      insert blackListEmailsList;
      
      /*
      List<blacklistSubject__c> blackListSubjectList = new List<blacklistSubject__c>();
      blacklistSubject__c newBlkSubjectList = new blacklistSubject__c();
      newBlkSubjectList.Subject__c = 'Test Subject';
      blackListSubjectList.add(newBlkSubjectList);
      insert blackListSubjectList;
	  */
      
      List<String> customEmailListStr = new List<String>();
      customEmailListStr.add(newBlkEmailList.Email_Id__c);
        
      List<blackListEmails__c> blackListDomainList = new List<blackListEmails__c>();
      blackListEmails__c newBlkDomainList = new blackListEmails__c();
      newBlkDomainList.isDomain__c = true;
      newBlkDomainList.Name = 'gmail.com';
      newBlkDomainList.Domain__c = 'gmail.com';
      newBlkDomainList.Email_Id__c = 'test@gmail.com';
      blackListDomainList.add(newBlkDomainList);
      
      insert blackListDomainList;
      
      List<String> customDomainListStr = new List<String>();
      customDomainListStr.add(newBlkDomainList.Domain__c);
    }
}