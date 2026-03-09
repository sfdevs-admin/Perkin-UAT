/* Change Log
 * 
  Developer      Date    Description
  Tony Tran      01/24/17  Removed references to defunct CRM Address fields
                Note: need to revise this test class to include assertions to make tests more robust
 * 
 * 
 * 
*/ 

@isTest(seeAllData=true)
public class TestViewAccountHierarchy {
    @isTest
    public static void testOne(){
      Account testAccountOne =  new Account(Name='Test Account One',Account_Alias__c='Test',BillingStreet='Test street');
      insert testAccountOne;
      Account testAccountTwo =  new Account(Name='Test Account two',ParentId=testAccountOne.id,Account_Alias__c='Test',BillingStreet='Test street');
      insert testAccountTwo;
      Account testAccountThree =  new Account(Name='Test Account three',ParentId=testAccountTwo.id,Account_Alias__c='Test',BillingStreet='Test street');
      insert testAccountThree;
      Account testAccountFour =  new Account(Name='Test Account four',ParentId=testAccountThree.id,Account_Alias__c='Test',BillingStreet='Test street');
      insert testAccountFour;
       Custom_Account_View_Hierarchy__c ss = new Custom_Account_View_Hierarchy__c();
      ss.Name='Test';
      ss.Field_List__c='Account_Alias__c,Enrolled_lives__c,Name';
      insert ss;
      
      ApexPages.StandardController sc = new ApexPages.StandardController(testAccountOne);
      ViewAccountHierarchyController controller = new ViewAccountHierarchyController(sc);
      
     
      
      Pagereference pageRef = new PageReference('/ViewAccountHierarchy') ;
       pageRef.getParameters().put('id',testAccountOne.id);                         
       system.Test.setCurrentPage(pageRef);
       
       sc = new ApexPages.StandardController(testAccountTwo);
      controller = new ViewAccountHierarchyController(sc);
      
      pageRef = new PageReference('/ViewAccountHierarchy') ;
       pageRef.getParameters().put('id',testAccountTwo.id);                          
       system.Test.setCurrentPage(pageRef);
       
       String s = controller.getLabel('Account','Name');
       
       controller.findChildren(testAccountOne.id);
       controller.sortedAccountList = new List<Account>();
       controller.recursiveSortAccountHierarchy(testAccountOne.id);
       
       ApexPages.StandardController sc2 = new ApexPages.standardController(testAccountOne);
        ViewAccountHierarchyController controllerclass=new ViewAccountHierarchyController(sc2);
    }
}