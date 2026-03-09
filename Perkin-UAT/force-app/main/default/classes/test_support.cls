@isTest
private class test_support{ 
 static testMethod void testinsert() 
 {    //create opportunity         
  support__c test_o = new support__c();     
  
  //test_o.office_Location__c = 'a1GV0000000N4XBMA0';
  test_o.Business_Unit__c = 'ASLS';
  test_o.Problem_type__c = 'Business Relation';
  test_o.Subject__c = 'Test';
  test_o.Description__c = 'Test';
  
  insert test_o;  
 }
 }