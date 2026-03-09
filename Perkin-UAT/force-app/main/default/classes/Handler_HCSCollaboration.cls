public class Handler_HCSCollaboration{
    public List<HCS_HTS_Mapping__mdt> HCS_HTSList{get;set;}
    public Map<String,HCS_HTS_Mapping__mdt> hcs_hts_map;
    public map<String,User> Hts_usermap;
    public map<Id,String> acc_map;
    public Map<Id,String> Ownermap;
    public List<Opportunity> Opp_List;
    public Handler_HCSCollaboration(List<Opportunity> Triggernew, Map<Id,Opportunity> OldMap,Boolean isInsert,Boolean isUpdate){
        Hts_usermap = new map<String,user>();
        hcs_hts_map = new Map<String,HCS_HTS_Mapping__mdt>();
        List<String> HTS_Reps = new List<String>();
        List<String> FAPCLR_Reps = new List<String>();
        Set<id> acc_Ids = new Set<id>();
        Set<Id> OwnerIds = new Set<Id>();
        acc_map = new map<Id,String>();
        Ownermap = new Map<Id,String>();
        Opp_List = new List<Opportunity>();
        /* Get all mappings from custom metadata */
         HCS_HTSList = [select State__c,HTS_Rep__c,HCS_Rep__c,FAPCLR_Rep__c From HCS_HTS_Mapping__mdt];
         for(HCS_HTS_Mapping__mdt h: HCS_HTSList){
            hcs_hts_map.put(h.HCS_Rep__c + h.State__c,h);
            HTS_Reps.add(h.HTS_Rep__c);
            FAPCLR_Reps.add(h.FAPCLR_Rep__c);
        }
        /* Build a map of HTS Users */
        for(User u: [Select UserName,Id from User Where username in :HTS_Reps or userName in :FAPCLR_Reps]){
            Hts_usermap.put(u.UserName,u);
        }
        /* Get Account Shipping State details and Owner Username details  from Opps */
        for(Opportunity o: Triggernew){
          acc_ids.add(o.Accountid);
          OwnerIds .add(O.OwnerId);
        }
        /*  Query the Account Shipping State */
        List<Account> acc_list = [select Id,ShippingState From Account Where id in :acc_ids];
        for(Account a: acc_List){
            acc_map.put(a.Id,a.ShippingState);
        }
        /* Query the Owner details */
        for(User u: [Select UserName,Id from User Where Id in :OwnerIds ]){
            Ownermap.put(u.id,u.UserName);
        }
        /* Choose applicable opportunities */
       
        if(isInsert){
         Opp_List.addAll(Triggernew);
        }
        else{
         for(Opportunity o: Triggernew){
           If(isUpdate && (OldMap.get(O.Id).Ownerid != O.OwnerId)){
            Opp_List.add(o);
           }
         }
        }
    }
    Public void populateHTSRep(){
     
         for(opportunity o: Opp_List){
          if(hcs_hts_map.get(Ownermap.get(O.OwnerId)+ acc_map.get(O.AccountId)) != null){
           if(hcs_hts_map.get(Ownermap.get(O.OwnerId) + acc_map.get(O.AccountId)).State__c == acc_map.get(O.AccountId)){
             if(Hts_usermap.get(hcs_hts_map.get(Ownermap.get(O.OwnerId) + acc_map.get(O.AccountId)).HTS_Rep__c) != null)
               o.Hts_Rep__c = Hts_usermap.get(hcs_hts_map.get(Ownermap.get(O.OwnerId) + acc_map.get(O.AccountId)).HTS_Rep__c).id;
             if(Hts_usermap.get(hcs_hts_map.get(Ownermap.get(O.OwnerId) + acc_map.get(O.AccountId)).FAPCLR_Rep__c) != null)
              o.FAPCLR_Rep__c = Hts_usermap.get(hcs_hts_map.get(Ownermap.get(O.OwnerId) + acc_map.get(O.AccountId)).FAPCLR_Rep__c).id;
           }
         }
      }
    }

}