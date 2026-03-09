/**************************************************************
* 1. Jira Ticket(s) that relates to this class
     - ITSFDC-5032
     - ATEAM- 1881
*
* 2. Description - This class pulls the common territories from opportunity's account & opportunity's owner and displays in the component- lwc_Opporunity_territory.
*
*
*
* 3. Objects referenced
*    -Opportunity
*    -Territory2
*    -UserTerritory2Association
*    -ObjectTerritory2Association
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
     - None
*
* 6. Test Class Name: lwc_opp_terr_lkup_cntlr_Test
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Sumit Sourav & Updated Date(2021.09.27)
*    - Avinash Kumar & Updated Date(2023.02.06)
*************************************************************/
public without sharing class lwc_opp_terr_lkup_cntlr {
    //Function to fetch opportunity's owner and opportunity's account territory
    @AuraEnabled(cacheable=true)
    public static List<TerritoryWrapper> getTerritoryName(String currentOpportunityId){
        system.debug('currentOpportunityId=='+currentOpportunityId);
        // Get the active territory model Id
            Id activeModelId = getActiveModelId();
        try {
            //Query to fetch ownerid and account id of current opportunityid.
            Opportunity currentOptydetails = [Select id,ownerid,accountid from Opportunity where id=:currentOpportunityId limit 1];
            //Query to fetch current opportunity's owner's assigned territory.
            List<UserTerritory2Association> optyownerterritory=[SELECT UserId, Territory2Id,Territory2.Name, IsActive, Id, RoleInTerritory2 FROM UserTerritory2Association where UserId=:currentOptydetails.ownerId AND Territory2.Territory2ModelId = :activeModelId]; 
            //Query to fetch current opportunity's accounts's assigned territory.
            List<ObjectTerritory2Association> optyrelatedAccountterritory=[SELECT Id, ObjectId, Territory2Id,Territory2.Name, SobjectType, IsDeleted FROM ObjectTerritory2Association where objectid=:currentOptydetails.accountid AND Territory2.Territory2ModelId = :activeModelId]; 
            //This is to store territories which is a intersection of opportunity account territory and opportunity owner teritory.
            List<TerritoryWrapper> matchedTerritory=new List<TerritoryWrapper>();
            set<Id> optyownerterritoryIdSet=new set<Id>();
             
             list<GroupMember> grpMbrList =[SELECT UserOrGroupId, GroupId, Id FROM GroupMember Where group.developerName='PG_8000_DLR_Territory_Admin'];
               boolean notfromGrp=true;
                for(GroupMember grpm:grpMbrList){
                    if(grpm.UserOrGroupId==userInfo.getUserId()){
                        notfromGrp=false;
                        break;
                    }
                }
                
            if(optyownerterritory.size()>0 && optyrelatedAccountterritory.size()>0 && notfromGrp){
                //storing opportunity owner's territory id in set.
                for(UserTerritory2Association ua:optyownerterritory){
                    optyownerterritoryIdSet.add(ua.Territory2Id);
                }
                
            }
            
                Set<string> matchedter= new Set<string>();
                //matching opportunity owner territory with opportunity account territory.
                if(optyrelatedAccountterritory != null && !optyrelatedAccountterritory.isEmpty()){
                for(ObjectTerritory2Association oa:optyrelatedAccountterritory){
                    if(optyownerterritoryIdSet.contains(oa.Territory2Id) && !matchedter.contains(oa.Territory2Id) && notfromGrp){
                        matchedter.add(oa.Territory2Id);
                        TerritoryWrapper tw=new TerritoryWrapper();
                        tw.tid= oa.Territory2Id;
                        tw.tname=oa.Territory2.Name;
                        matchedTerritory.add(tw);
                        
                    }else if(!notfromGrp){
                        matchedter.add(oa.Territory2Id);
                        TerritoryWrapper tw=new TerritoryWrapper();
                        tw.tid= oa.Territory2Id;
                        tw.tname=oa.Territory2.Name;
                        matchedTerritory.add(tw);
                    }
                }
            }
            
            system.debug('matchedTerritory==>'+matchedTerritory);
            return matchedTerritory;
        } catch (Exception e) {
            system.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    } 
	public static Id getActiveModelId() {
		List<Territory2Model> models = [Select Id from Territory2Model where State = 'Active'];
		Id activeModelId;
		if(models.size() == 1){
			activeModelId = models.get(0).Id;
		}
		return activeModelId;
	}	
    //Wrapper to store territory id and territory name.
    public class TerritoryWrapper{
        
        @AuraEnabled public String tid ;
        @AuraEnabled public String tname;
    }
    //Function to update opportunity territory
    @AuraEnabled(cacheable=false)
    public static void updateTerritoryonOpty(String Territory,String currentoppId ){
        system.debug('Territory & oppId='+Territory+currentoppId);
        try {
            //fetch current opportunity detail to update territory.
            Opportunity curopp=[select id,territory2Id from opportunity where id=:currentoppId];
            curopp.territory2Id=Territory;
            update curopp;
        } catch (Exception e) {
            system.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
}