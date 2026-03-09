@isTest (seeAllData=True)
public class PromptUserExtTest
{
    //create test data.
	public static testMethod void testPromptUserExt()
    {
        //PageReference pr = Page.Success();
        //Test.setCurrentPage(pr);
        
        Id dxSS = [Select id from RecordType where developername = 'Dx_Software_Services' LIMIT 1].id;
        
		Case caseTest = new Case();
        caseTest.RecordTypeId = dxSS;
        caseTest.Status = 'New';
        caseTest.Priority = 'Minor Case';
        caseTest.DX_Functional_Area__c = 'SG Lab';
        caseTest.TypeOfCase__c = 'Anomaly';
        caseTest.Case_Description__c = 'Test';
        caseTest.DX_Erroneous_Results_Reported__c = 'No';
        caseTest.DX_Risk_of_Death_or_Injury__c = 'No';
        caseTest.DX_Complaint_Justification__c = 'Unexpected customer use of product';
        caseTest.Resolution__c = 'Test';
        
        insert caseTest;

        Test.StartTest();
        
        //set a page reference to point to the VF page
        PageReference pr = Page.PromptUserForConfirmation;        
        //set scope to VF page
        Test.setCurrentPage(pr);
        
        //Pass the created test Case's ID
        pr.getParameters().put('Id', String.valueOf(caseTest.Id));        
        //set up the page with the case's information
        ApexPages.StandardController sc = new ApexPages.StandardController(caseTest);
        //instantiate the extension with the standard controller
        PromptUserExt pue = new PromptUserExt(sc);
    	pue.CancelAndReturn();
        pue.SaveAndReturn();
    	Test.StopTest();
    }
}