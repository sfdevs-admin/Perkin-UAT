public with sharing class OppsWithContacts{
public OppsWithContacts(ApexPages.StandardController controller) {

}

public OppsWithContacts(){

}

public String ParamValueFromJavaScript {get;set;}
public PageReference say(){
List <Contact> ContactsToUpdateCheckbox = new List<Contact>();
List <Id> ContactsToQuery = new List<Id>();    
List <Id> OppsToQuery = new List<Id>();    
system.debug('ParamValueFromJavaScript::::' + ParamValueFromJavaScript);
String [] getList = ParamValueFromJavaScript.split(',');
List <OpportunityContactRole> ContactsWithContactRole = 
    [Select ContactId, CreatedDate, OpportunityId,Opportunity.Solution_Area_of_Interest__c,Opportunity.StageName From OpportunityContactRole where Id IN:getList AND Opportunity.Solution_Area_of_Interest__c != null];

system.debug(ContactsWithContactRole);

if(!ContactsWithContactRole.isEmpty()){
   CheckContactRoleAndSAI(ContactsWithContactRole);
   }  
    /*for(OpportunityContactRole a : ContactsWithContactRole){
        ContactsToQuery.add(a.ContactId);
        OppsToQuery.add(a.OpportunityId);
        system.debug('Line 27');
    }
    
}

if(!OppsToQuery.isEmpty()){
    List <Opportunity> OppsFromQuery = [Select id, StageName, Solution_Area_of_Interest__c From Opportunity where id IN:OppsToQuery];
    
    CheckContactRoleAndSAI(OppsFromQuery, ContactsWithContactRole, getList);
}*/

return null;
}

public void CheckContactRoleAndSAI(List <OpportunityContactRole> ContactRoles){
String [] Stages = new List <String>{'Zero Stage','Stage 1 - Create/Plan','Stage 2 - Qualify','Stage 3 - Develop','Stage 4 - Prove','Stage 5 - Negotiation','Abandoned','Closed Lost','Closed Won'};
Map <OpportunityContactRole,string> OppsForContactUpdate = new Map <OpportunityContactRole,string>();
Map <id,Opportunity> OppsForSoql = new Map <id,Opportunity>();
system.debug('Line 45 This is the new script');
for(OpportunityContactRole a : ContactRoles){
    if(Stages.contains(a.Opportunity.StageName)){
        OppsForContactUpdate.put(a,a.Opportunity.Solution_Area_of_Interest__c); 
    }
}
/* if(OppsForSoql.size() > 0){
    system.debug(ContactRoles);
    
    for(OpportunityContactRole a : ContactRoles){
        Boolean NewContactRole = (OppsForSoql.containsKey(a.OpportunityId) && a.CreatedDate == Date.Today()) ? true : false;
        Boolean SAIFieldUpdated;
        SAIFieldUpdated = (OppsForSoql.containsKey(a.OpportunityId)) ? true : false;
        
        
        
        if(NewContactRole || SAIFieldUpdated){
            system.debug('NewContactRole : ' + NewContactRole + ' & SAIFieldUpdated : ' + SAIFieldUpdated);
            OppsForContactUpdate.put(a.ContactId,OppsForSoql.get(a.OpportunityId).Solution_Area_of_Interest__c);
        }
        
    }
}*/

if(OppsForContactUpdate.size() > 0){
List<Opportunity_SAI_Mapping__mdt> OppSAIMap =[SELECT Opportunity_SAI_Value__c,Contact_SAI_Status_API_Name__c FROM Opportunity_SAI_Mapping__mdt WHERE Opportunity_SAI_Value__c IN :OppsForContactUpdate.Values()]; 
    Map<id,Contact> Con_To_Update = new Map <id,Contact>();
    system.debug('&&&& ' +OppsForContactUpdate);
    for(OpportunityContactRole a : ContactRoles){
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
       
        
      /*  Contact updateCon = new Contact();
        updateCon.id = a.ContactId;
        updateCon.Has_Opportunity__c = true;
       // updateCon.put(sa , 'Converted to Opportunity');
       system.debug('sa '+ sa);
        system.debug('IDS = ' + updateCon.id);
        
        Switch on sa{
            when 'Status_Air__c'{
                updateCon.Status_Air__c = 'Converted to Opportunity';  
            }
            when 'Status_Applied_Genomics__c'{
                updateCon.Status_Applied_Genomics__c = 'Converted to Opportunity';  
            }
            when 'Status_Chemicals__c'{
                updateCon.Status_Chemicals__c = 'Converted to Opportunity';  
            }
            when 'Status_Clinical_Studies__c'{
                updateCon.Status_Clinical_Studies__c = 'Converted to Opportunity';  
            }
            when 'Status_Digital_Lab__c'{
                updateCon.Status_Digital_Lab__c = 'Converted to Opportunity';  
            }
            when 'Status_Disease_Research__c'{
                updateCon.Status_Disease_Research__c = 'Converted to Opportunity';  
            }
            when 'Status_Drug_Discovery__c'{
                updateCon.Status_Drug_Discovery__c = 'Converted to Opportunity';  
            }
            when 'Status_Energy__c'{
                updateCon.Status_Energy__c = 'Converted to Opportunity';  
            }
            when 'Status_Food_Quality__c'{
                updateCon.Status_Food_Quality__c = 'Converted to Opportunity';  
            }
            when 'Status_Food_Safety__c'{
                updateCon.Status_Food_Safety__c = 'Converted to Opportunity';  
            }
            when 'Status_Forensics_and_Security__c'{
                updateCon.Status_Forensics_and_Security__c = 'Converted to Opportunity';  
            }
            when 'Status_Geochemistry_Mining_and_Metals__c'{
                updateCon.Status_Geochemistry_Mining_and_Metals__c = 'Converted to Opportunity';  
            }
            when 'Status_Material__c'{
                updateCon.Status_Material__c = 'Converted to Opportunity';  
            }
            when 'Status_Maternal_Fetal_Health__c'{
                updateCon.Status_Maternal_Fetal_Health__c = 'Converted to Opportunity';  
            }
            when 'Status_Newborn_Screening__c'{
                updateCon.Status_Newborn_Screening__c = 'Converted to Opportunity';  
            }
            when 'Status_Pre_Clinical_Studies__c'{
                updateCon.Status_Pre_Clinical_Studies__c = 'Converted to Opportunity';  
            }
            when 'Status_QA_QC_Drug_Manufacturing_Process__c'{
                updateCon.Status_QA_QC_Drug_Manufacturing_Process__c = 'Converted to Opportunity';  
            }
            when 'Status_Soil_Solids__c'{
                updateCon.Status_Soil_Solids__c = 'Converted to Opportunity';  
            }
            when 'Status_Strategic_Services__c'{
                updateCon.Status_Strategic_Services__c = 'Converted to Opportunity';  
            }
            when 'Status_Water__c'{
                updateCon.Status_Water__c = 'Converted to Opportunity';  
            }
        } 
        Con_To_Update.put(updateCon.id,updateCon);*/
    } 

    update Con_To_Update.values();
    
    
}
}
}