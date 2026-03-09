public class CompleteOrderController {
    public Opportunity currentRecord{get; set;}
    public boolean validate=false;
    public CompleteOrderController(ApexPages.StandardController controller) {
        currentRecord = [SELECT Id, Name, AccountId,Contract_Request__c,Renewal_Required_INF__c,StageName FROM Opportunity WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
        Profile p = [Select Name from Profile where Id =: userinfo.getProfileid()];
        String pname = p.name;
        if (currentRecord.StageName == 'Stage 6 - Implement (Closed)' && (pname=='Informatics Operations'|| pname=='System Administrator')){
           validate=true;
       }

    }
    Public void UpdateOpp(){
    if(validate==true){
    currentRecord.StageName='Closed Won';
    currentRecord.Order_Processing_Status_INF__c='Completed';
   try{ Update currentRecord;if(currentRecord.StageName=='Closed Won'){ ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Order Submitted Successfully.'));
       }
   }
   catch(Exception e){ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Error in Submission: '+e.getmessage()));}
}

}}