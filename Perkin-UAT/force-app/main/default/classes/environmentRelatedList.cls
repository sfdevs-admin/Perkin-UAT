public class environmentRelatedList{
private List<INFEnvironmentalData__c> envdata ;
private Case cases;

public environmentRelatedList(ApexPages.StandardController controller){
this.cases = (Case)controller.getRecord();
}
 
public List<INFEnvironmentalData__c> getenvrs(){
case caserecords = [select id,AccountId from Case where Id = :cases.Id];
if(caserecords.Accountid == NULL){
    return null;
}
envdata = [select id,Name from INFEnvironmentalData__c where Account__c = : caserecords.AccountId];
return envdata;
}

public pageReference openPage() 
    {
        pageReference pg = new pageReference('/a6O/o');
        pg.setRedirect(true);
        return pg;
    }   

}