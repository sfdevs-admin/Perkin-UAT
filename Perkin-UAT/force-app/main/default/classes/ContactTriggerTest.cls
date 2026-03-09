@isTest
public class ContactTriggerTest {
    
    static testMethod void TestCase1(){
        Contact ct2 = new Contact(FirstName='Test',LastName='Contact 2',Email='testemail@emailtest.com',PKI_SAP_Customer_Number__c = '123456');
        Contact ct1 = new Contact(FirstName='Test',LastName='Contact 2',Email='testemail@emailtest.com');
        List<Contact> lc = new List<Contact>();
        lc.add(ct1);
        lc.add(ct2);
        insert lc;
        delete ct1;
    }
}