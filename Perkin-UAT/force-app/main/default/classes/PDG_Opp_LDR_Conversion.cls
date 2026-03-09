public with sharing class PDG_Opp_LDR_Conversion {

public static boolean is_First = true;

//  Create List to hold Contacts
map <Id,Contact> co = new map <Id,Contact>();
List <Contact> UpdateCon = new List <Contact>();


//  Create List to hold Opp   
map <Id, Id> Ids = new map<Id,Id>();
map <Id, Id> Ids2 = new map<Id,Id>();
List <Opportunity> newList = new List <Opportunity>();
Map <id, Opportunity> oldList = new Map <id, Opportunity>();
List <OpportunityContactRole> OppExist = new List <OpportunityContactRole>();
map <Id,Opportunity> oppOwnerIds = new map <Id,Opportunity>();
List <Opportunity> UpdateOpps = new List <Opportunity>();


Map <Id,Id> manager_Id = new Map <Id,Id>();

public PDG_Opp_LDR_Conversion(List<Opportunity> New_Opps, map <id,Opportunity> Old_Opps){
    newList = New_Opps;
    oldList = Old_Opps; 
}

public void LDR_Owner_Converison() {
    
    if(is_First){
        is_First = false;
        
        //  Add Opp to list     
        for(Opportunity b : newList) {
            if(b.Created_Date_Date_Only__c == Date.Today() && b.StageName == 'Zero Stage'){
                oppOwnerIds.put(b.Id, b);
            }
        }
        system.debug('Class <PDG_Opp_LDR_Conversion> oppOwnerIds: ' + oppOwnerIds);
        
        //  Get Primary Contacts from Opportunity Contact Role
        OppExist = [Select id, ContactId, Opportunity.OwnerId, IsPrimary
                    From OpportunityContactRole Where OpportunityId in :oppOwnerIds.keySet()
                    AND IsPrimary = true];  
        system.debug('Class <PDG_Opp_LDR_Conversion> ContactRole: ' + OppExist);
        
        for(OpportunityContactRole a : OppExist){
            Ids.put(a.ContactId, a.Opportunity.OwnerId);
        }
        
        // Get User managerId 
        Map <id, user> us2 = new Map <id, user>([select id, Name, managerId from user where id in:ids.values()]);
        
        system.debug('Class <PDG_Opp_LDR_Conversion> Users with ManagerId: ' + us2);
        
        for (User a : us2.values()){
            if(a.managerId != null){
                manager_Id.put(a.id,a.managerId);             
            }
        }
        
        system.debug('Class <PDG_Opp_LDR_Conversion> ManagerIds: ' + manager_Id);
        
        List <Opportunity> DataOpps = [Select OwnerId, OwnerManager__c From Opportunity where id in:oppOwnerIds.keySet()];
        
        // Get User email 
        Map <id,user> ManagerEmail = new Map <id,user>([select id, email, Name from user where id in:manager_Id.values()]);
        
        system.debug('Class <PDG_Opp_LDR_Conversion> Users with ManagerEmail: ' + ManagerEmail);
        
        for(Opportunity a : DataOpps){
            boolean isMatch = (manager_Id.get(a.OwnerId) != null) ? True : False;
            if(isMatch){
                a.OwnerManager__c = ManagerEmail.get(manager_Id.get(a.OwnerId)).email;
                UpdateOpps.add(a);
                
                system.debug('Class <PDG_Opp_LDR_Conversion> ManagerEmail: ' + a.OwnerManager__c + 
                             ' from user - ' +ManagerEmail.get(manager_Id.get(a.OwnerId)).Name);
            }
            else{
                a.OwnerManager__c = 'Toby.OConnor@PERKINELMER.COM';
                UpdateOpps.add(a);
            }
            
        }
        
        
        
        //  Pull Contacts whos Ids are in Map(Ids) 
        map <Id,Contact> con_rec = new map <Id, Contact>(
            [Select id,Name, Lead_Owner_LDR_Conversion__c
             From Contact Where id IN :Ids.keySet()
             AND Lead_Owner_LDR_Conversion__c = null]);
        
        
        //  Assign Owner to Contact field 'Lead_Owner_LDR_Conversion__c'
        for(Contact a : con_rec.values()){
            a.Lead_Owner_LDR_Conversion__c = us2.get(Ids.get(a.id)).Name; 
            UpdateCon.add(a);
        }  
        
        system.debug('Class <PDG_Opp_LDR_Conversion> List of Contacts to update' + UpdateCon);
        
        //  Update the Opps records 
        if(UpdateOpps.size() >0){
            Database.update (UpdateOpps,FALSE);
            
        }            
        //  Update the contact records 
        if(UpdateCon.size() >0){
            Database.update (UpdateCon,FALSE);
            
        }
    }
}

public void CheckContactRoleAndSAI(){
   String [] Stages = new List <String>{'Zero Stage','Stage 1 - Create/Plan','Stage 2 - Qualify','Stage 3 - Develop','Stage 4 - Prove','Stage 5 - Negotiation','Abandoned','Closed Lost','Closed Won'};
 Map <OpportunityContactRole,string> OppsForContactUpdate = new Map <OpportunityContactRole,string>();
 Map <id,Opportunity> OppsForSoql = new Map <id,Opportunity>();
system.debug('Line 120');
   for(Opportunity b : newList) {
     if(Stages.contains(b.StageName)){
       OppsForSoql.put(b.id, b); 
     }
 }
   if(OppsForSoql.size() > 0){
     List <OpportunityContactRole> ContactRoles = [Select ContactId, CreatedDate, OpportunityId, Opportunity.Solution_Area_of_Interest__c From OpportunityContactRole where OpportunityId IN:OppsForSoql.keySet() AND Opportunity.Solution_Area_of_Interest__c != null];
       system.debug(ContactRoles);

       for(OpportunityContactRole a : ContactRoles){
           Boolean NewContactRole = (OppsForSoql.containsKey(a.OpportunityId) && a.CreatedDate == Date.Today()) ? true : false;
           Boolean SAIFieldUpdated;
           if(trigger.isInsert){
           SAIFieldUpdated = (OppsForSoql.containsKey(a.OpportunityId)) ? true : false;
           } 
           else{
           SAIFieldUpdated = (OppsForSoql.containsKey(a.OpportunityId) && OppsForSoql.get(a.OpportunityId).Solution_Area_of_Interest__c != oldList.get(a.OpportunityId).Solution_Area_of_Interest__c) ? true : false;
           }
           
           if(NewContactRole || SAIFieldUpdated){
               system.debug('NewContactRole : ' + NewContactRole + ' & SAIFieldUpdated : ' + SAIFieldUpdated);
               OppsForContactUpdate.put(a,OppsForSoql.get(a.OpportunityId).Solution_Area_of_Interest__c);
           }
          
       }
   }
   if(OppsForContactUpdate.size() > 0){
   List<Opportunity_SAI_Mapping__mdt> OppSAIMap =[SELECT Opportunity_SAI_Value__c,Contact_SAI_Status_API_Name__c FROM Opportunity_SAI_Mapping__mdt WHERE Opportunity_SAI_Value__c IN :OppsForContactUpdate.Values()]; 
Map<id,Contact> Con_To_Update = new Map <id,Contact>();
system.debug('&&&& ' +OppsForContactUpdate);
for(OpportunityContactRole a : OppsForContactUpdate.KeySet()){
 String sa;
 for(Opportunity_SAI_Mapping__mdt oppSAI : OppSAIMap){
            if(OppsForContactUpdate.get(a) == oppSAI.Opportunity_SAI_Value__c){
               sa = oppSAI.Contact_SAI_Status_API_Name__c;
               Contact updateCon = new Contact();
               updateCon.id = a.ContactId;
               updateCon.Has_Opportunity__c = true;
               updateCon.put(sa , 'Converted to Opportunity'); 
               Con_To_Update.put(updateCon.id,updateCon);              
            }
    }

} 
try{
    update Con_To_Update.values();
}
Catch(Exception e){
    system.debug('Exception in Class PDG_Opp_LDR_Conversion' + e);
}
 
   }
}


public void LDR_Owner_Change() {
    if(is_First){
        is_First = false;
        
        for(Opportunity b : newList){
            boolean IsDifferentOwner = (b.ownerId != oldList.get(b.id).ownerId && b.stageName == 'Zero Stage') ? True : False;
            
            system.debug('Class <PDG_Opp_LDR_Conversion> New Owner: (' + b.ownerId + ') Old Owner: ('+oldList.get(b.id).ownerId+')');
            
            if(b.stageName == 'Zero Stage'){
                if(IsDifferentOwner){
                    b.First_Owner_Changed__c = true;
                    system.debug('Class <PDG_Opp_LDR_Conversion> First Owner has changed: ' + IsDifferentOwner);
                    oppOwnerIds.put(b.Id, b);
                    system.debug('OwnerId =' + b.OwnerId);
                }
            }
        }
        
        //  Get Primary Contacts from Opportunity Contact Role
        OppExist = [Select id, OpportunityId, ContactId, Opportunity.OwnerId, IsPrimary
                    From OpportunityContactRole Where OpportunityId in :oppOwnerIds.keySet()
                    AND IsPrimary = true];  
        
        system.debug('Class <PDG_Opp_LDR_Conversion> ContactRole -2: ' + OppExist);
        
        for(OpportunityContactRole a : OppExist){
            Ids.put(a.OpportunityId, a.ContactId);
        }
        
        for(Id a : oppOwnerIds.keyset()){
            if(Ids.ContainsKey(a)){
                Ids2.put(Ids.get(a), oppOwnerIds.get(a).OwnerId); 
            }
        }
        
        //  Pull Contacts whos Ids are in Map(Ids) 
        map <Id,Contact> con_rec = new map <Id, Contact>(
            [Select id,Name, Lead_Owner_Sales__c
             From Contact Where id IN :Ids.values()
             AND Lead_Owner_Sales__c = null]);
        
        
        map <Id, User> us = new map <Id, User>([Select id, Name From User where id=:Ids2.values()]);
        
        
        //  Assign Owner to Contact field 'Lead_Owner_LDR_Conversion__c'
        for(Contact a : con_rec.values()){
            a.Lead_Owner_Sales__c = us.get(Ids2.get(a.id)).Name; 
            UpdateCon.add(a);
            
        }  
        
        system.debug('Class <PDG_Opp_LDR_Conversion> List of Contacts to update' + UpdateCon);
        
        //  Update the contact records 
        if(UpdateCon.size() >0){
            Database.update (UpdateCon,FALSE);                
        }
    }
}

}