/*
    Test Class for  SMAX_PS_ComplaintManager
    Client      :   PerkinElmer
    Created by  :   Veerendra on 2017-10-11
*/
@isTest(seeAllData=false)
public class SMAX_PS_Complaint_UT
{         
    static testMethod void createComplaintTestData()
    {   

        //Insert Product
        product2 prod = new product2(
                            Name='Test Product');
        insert prod;

        // Insert Complaint
        SMAX_PS_Complaint__c compl = new SMAX_PS_Complaint__c();
        insert compl;

        // Insert Complaint Part
        SMAX_PS_ComplaintPart__c cPart = new SMAX_PS_ComplaintPart__c(
                            SMAX_PS_Complaint__c=compl.Id,
                            SMAX_PS_Part__c=prod.Id);
        insert cPart;

        // Insert Complaint Fault Code
        SMAX_PS_ComplaintFaultCode__c cFault = new SMAX_PS_ComplaintFaultCode__c(
                            SMAX_PS_Complaint__c=compl.Id);
        insert cFault;

        // Insert Complaint Task
        SMAX_PS_ComplaintTask__c cTask = new SMAX_PS_ComplaintTask__c(
                            SMAX_PS_Complaint__c=compl.Id);
        insert cTask;

        compl.SMAX_PS_CompletedTxnNum__c='ABC';
        update compl;
    }       
}