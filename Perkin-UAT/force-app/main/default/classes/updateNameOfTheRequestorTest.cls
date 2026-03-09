@isTest
public class updateNameOfTheRequestorTest{
    
    //Test method for trigger on Request 
    static testMethod void testnameUpdate(){
        
        //Create new user using profile from Standard User profile
        
        
        Requests__c  newReq= new Requests__c( Affected_PKI_Application__c='QuoteStudio',
                                                            Request_Summary__c='test 1'
                                                         );
        //Code runs as user "u"
        //System.runAs(u){
    
            //Start the test by creating and inserting the Request
            Test.startTest();
                insert newReq;
        
                
            //after inserting the Request and checking that the field has been updated, stop the test
            Test.stopTest();
        }
}