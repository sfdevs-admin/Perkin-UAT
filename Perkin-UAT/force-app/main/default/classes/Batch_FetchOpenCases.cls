public class Batch_FetchOpenCases implements Database.Batchable<sObject>
{
    public String queryString;
    List<Cases_snapshot__c> casesToInsert = new List<Cases_snapshot__c>();
    Map<Id ,Open_cases_Count_Report__mdt> MapRecIds= new Map<Id,Open_cases_Count_Report__mdt>();
    
    List<String> ids=new List<String>();
    
    public Batch_FetchOpenCases()
    {
        For (Open_cases_Count_Report__mdt objCaseAud : [select Id,Record_Type__c,Record_Type_ID__c from Open_cases_Count_Report__mdt]){
            
            MapRecIds.put(objCaseAud.Id,objCaseAud);
            
        } 
        for(Id i:MapRecIds.keyset())
        {
          string[] recordTypeID = MapRecIds.get(i).Record_Type_ID__c.split(',');  
          ids.addAll(recordTypeID); 
            system.debug('ids is '+ids);
        }
       if(test.isRunningTest())
       queryString = 'Select id,CreatedDate,ClosedDate,Ownerid,DX_Change_Request__c,PKI_GLB_Duplicate_Case__c,External_Email_Inbox__c,Status from Case order by createddate desc limit 1';
        else
       queryString = 'Select id,Ownerid,DX_Change_Request__c,Owner.Name,PKI_GLB_Duplicate_Case__c,External_Email_Inbox__c,CreatedDate,ClosedDate,Status from Case where Status IN (\'Active\',\'Waiting for Customer Response\') and Owner.Name NOT IN (\'TRASH CASES\',\'DX Software Services - Akron\') and External_Email_Inbox__c IN (\'specimengatesupportfi@perkinelmer.com\',\'specimen.gate.support.fi@perkinelmer.com\') and PKI_GLB_Duplicate_Case__c = false and RecordTypeid in :ids'; 
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC)
    {         
        return Database.getQueryLocator(queryString);
    }
    
     public void execute(Database.BatchableContext BC,List<Case> scope)
     {
         for(Case c:scope)
         {
             Cases_snapshot__c caseRec = new Cases_snapshot__c();
             caseRec.CaseRef__c = c.Id;
             if(String.isNotBlank(c.Status) && String.isNotEmpty(c.Status))
             {
                 if(c.Status!='Closed')
                   caseRec.Case_Status__c = 'Open';
                 else
                     caseRec.Case_Status__c ='Closed';
             }
             caseRec.Date_Time_Open__c = c.CreatedDate;
             if(c.ClosedDate!=null)
                 caseRec.Date_Time_Closed__c = c.ClosedDate;
             casesToInsert.add(caseRec);
         }
         
         if(casesToInsert.size()>0)
         {
             insert casesToInsert;            
         }
             
     }
    
    public  void finish(Database.BatchableContext BC)
    {
        
    }

}