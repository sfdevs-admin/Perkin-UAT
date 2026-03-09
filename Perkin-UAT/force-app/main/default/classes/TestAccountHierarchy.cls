@isTest(seeAllData=true)
public class TestAccountHierarchy {
    public static AccountHierarchyController controller;
    public static Account testAccountOne;
    public static AccountHierarchyCSVCreator csvCreator;
    @isTest
    public static void testOne(){
        testAccountOne =  new Account(Name='Test Account One');
        insert testAccountOne;
        Account testAccountTwo =  new Account(Name='Test Account two',ParentId=testAccountOne.id);
        insert testAccountTwo;
        Account testAccountThree =  new Account(Name='Test Account three',ParentId=testAccountTwo.id);
        insert testAccountThree;
        Account testAccountFour =  new Account(Name='Test Account four',ParentId=testAccountThree.id);
        insert testAccountFour;
         
        Contact contactOneAccountOne = new Contact(FirstName='Test Contact One',LastName='Account One',AccountId=testAccountOne.id);
        insert contactOneAccountOne;
        Contact contactTwoAccountTwo = new Contact(FirstName='Test Contact Two',LastName='Account Two',AccountId=testAccountTwo.id);
        insert contactTwoAccountTwo;
        Contact contactThreeAccountThree = new Contact(FirstName='Test Contact Three',LastName='Account Three',AccountId=testAccountThree.id);
        insert contactThreeAccountThree;
        Contact contactFourAccountFour = new Contact(FirstName='Test Contact Four',LastName='Account Four',AccountId=testAccountFour.id);
        insert contactFourAccountFour;
        
        Asset assetOneAccountOne = new Asset(Name='Test Asset One',AccountId=testAccountOne.id);
        insert assetOneAccountOne;
        Asset assetTwoAccountTwo = new Asset(Name='Test Asset Two',AccountId=testAccountTwo.id);
        insert assetTwoAccountTwo;
        Asset assetThreeAccountThree = new Asset(Name='Test Asset Three',AccountId=testAccountThree.id);
        insert assetThreeAccountThree;
        Asset assetFourAccountFour = new Asset(Name='Test Asset Four',AccountId=testAccountFour.id);
        insert assetFourAccountFour;
        
        Account__c acc=new Account__c();
        acc.Tab_Name__c='Accounts';
        acc.Object_API_Name__c='Account';
        acc.Name='Account';
        acc.Field_List__c='Name,Type';
        acc.Sort_Order__c=1;
        insert acc;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testAccountOne);
        controller = new AccountHierarchyController(sc);
        
        List<Account__c> tabSetting = new List<Account__c>(); 
        tabSetting =  [SELECT Tab_Name__c,Field_List__c,Object_API_Name__c 
                                  FROM Account__c ];
       Pagereference pageRef = new PageReference('/Account_Hierarchy') ;
       pageRef.getParameters().put('id',testAccountOne.id);                          
       system.Test.setCurrentPage(pageRef);
       
       if(tabSetting.size() == 0){
           AccountHierarchyController.getDataList('Accounts',testAccountOne.id);
            controller.sortOrder = 'ASC';
            controller.sortColumn = '1';
            controller.sortBaseObject = 'Accounts';
            controller.exportToCSV();
           
       }
                                  
       for(Account__c setting:tabSetting){
            AccountHierarchyController.getDataList(setting.Tab_Name__c,testAccountOne.id);
            controller.sortOrder = 'ASC';
            controller.sortColumn = '1';
            controller.sortBaseObject = setting.Tab_Name__c;
            controller.exportToCSV();
        }  
      pageRef = new PageReference('/AccountHierarchyCSVPage') ;
        pageRef.getParameters().put('accName',testAccountOne.Name);
        pageRef.getParameters().put('accId',testAccountOne.id);
        for(Account__c setting:tabSetting){
            pageRef.getParameters().put('basObj',setting.Tab_Name__c);
            pageRef.getParameters().put('sortColumn',setting.Field_List__c.split(',')[Integer.ValueOf(controller.sortColumn)]);
            pageRef.getParameters().put('sortOrder','ASC');
            system.Test.setCurrentPage(pageRef);
            csvCreator = new AccountHierarchyCSVCreator();  
        }
        
                             
    }
    
    
}