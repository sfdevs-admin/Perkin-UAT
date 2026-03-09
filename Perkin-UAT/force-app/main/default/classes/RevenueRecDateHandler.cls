/********************************************************************************
* Class Name: RevenueRecDateHandler
* Created by: PwC/Sanjeev Singh
* Date Created: Feb 25, 2021
* Comment: This class will contain logic for updating Revenue rec date on Opportunity
* ********************************************************************************/
public inherited sharing class RevenueRecDateHandler {
    
    public RevenueRecDateHandler() {

    }

    public static void updateRevenueRecDate(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap, List<Opportunity> opptyList){
    
    Set<Id> recIds = new Set<Id>();
    Map<Id,String> rec_map = new map<id,String>();
    Map<Id,String> att_map = new map<id,String>();
    Set<id> Opp_ids = new Set<Id>();
    for(Opportunity o: opptyList){
  recIds.add(o.RecordTypeId);
  if( o.stageName == 'Closed Won' && !oldOppMap.get(o.id).StageName.contains('Stage 1')
              && !oldOppMap.get(o.id).StageName.contains('Stage 2')
              && !oldOppMap.get(o.id).StageName.contains('Stage 3'))
      Opp_ids.add(o.id);
 }
 if(Opp_ids.size() > 0){
 List<ContentDocumentLink> a = [SELECT ContentDocument.Title, LinkedEntityId FROM ContentDocumentLink where LinkedEntityId in :Opp_ids and ContentDocument.Title like '%Quote%' ];
 for(ContentDocumentLink at:a){
   att_map.put(at.LinkedEntityId ,'true');
     }
 List<Attachment> att = [Select Name,Id,ParentId From Attachment Where parentid in :opp_Ids and name like '%Quote%'];
 for(Attachment at: att){
   att_map.put(at.Parentid,'true');
     }
 }
 for (opportunity o: opptyList)
  {
      // if ( (o.Revenue_Rec_Date__c == null) || (o.Revenue_Rec_Date__c < o.CloseDate)&&( (o.recordtype.developername != 'Dx_EMEA_Record_Type') || (o.recordtype.developername != 'Informatics')) ) removing record type Dx_EMEA_Record_Type reference
   if ( (o.Revenue_Rec_Date__c == null) || (o.Revenue_Rec_Date__c < o.CloseDate)&&( o.recordtype.developername != 'Informatics') )
     { o.Revenue_Rec_Date__c = o.CloseDate + 5; }
     if( o.Dealer_Portal_Opp__c == true && o.StageName == 'Closed Won' && att_map.get(o.id)== null
      && Opp_ids.contains(o.id) == true && ( oldOppMap.get(o.id).StageName.contains('Stage 4')
              || oldOppMap.get(o.id).StageName.contains('Stage 5')
              || oldOppMap.get(o.id).StageName.contains('Stage 6'))){
        o.addError('Please attach the Quote Document to Close the Opportunity');
      }
    
    

        
        }
        

    }
    
    /*public static void isDealerPortalOpp(Set<Id> recIds,List<Opportunity> Trg_New){
        Map<Id,String> rec_map = new map<id,String>();
        List<RecordType> r = [Select Id,DeveloperName from RecordType Where Id in :recIds];
         for(RecordType RT: r){
         rec_map.put(RT.id,RT.DeveloperName);
         }
         for (opportunity o: Trg_New)
          {
           
           if(rec_map.get(o.recordTypeId).contains('Dx')){
             User u = [Select Profile.Name from User where id = :System.UserInfo.getUserId()];
             if (u.profile.Name == 'Dx Partner Community User' || u.Profile.name == 'Dx-EH Partner Community User')
             {
              o.Dealer_Portal_Opp__c = true;
             }
           }
         }
    
    }*/

    
 }