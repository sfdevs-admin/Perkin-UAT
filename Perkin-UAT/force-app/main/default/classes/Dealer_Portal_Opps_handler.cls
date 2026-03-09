Public Class Dealer_Portal_Opps_handler{
    public void isDealerPortalOpp(Set<Id> recIds,List<Opportunity> Trg_New){
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
    
    }


}