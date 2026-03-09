public class CaseEditController {
 public final Case caserecord;
 public id caseId ;
 
    public CaseEditController(ApexPages.StandardController controller) {
    caseId  = ApexPages.currentPage().getParameters().get('id');
        caserecord = [SELECT Id, Description,OwnerId,Owner.Name FROM Case WHERE Id =:ApexPages.currentPage().getParameters().get('id')];
    }

    public Case getCase() {
        return caserecord;
    }

    public PageReference save() {
        update caserecord;
        return new Pagereference('/'+caseId);
    }
    
    public Pagereference cancel() {
        return new Pagereference('/'+caseId);
    }
}