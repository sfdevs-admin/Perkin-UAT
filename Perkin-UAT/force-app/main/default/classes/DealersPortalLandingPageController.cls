public class DealersPortalLandingPageController {

    public string Photolink{get;set;}
    public List<CollaborationGroupMember> ChatterGroups{get;set;}
    public List<Opportunity>  opp{get;set;}
    public List<Opportunity>  overdueOpp{get;set;}
    public List<Opportunity>  cc_opp{get;set;}
    public List<ContentVersion> articles{get;set;}
    public List<SelectOption> oppOptions {get;set;}
    public String selectedValue{get;set;}
    public boolean showOpenOpp{get;set;}
    public boolean showOverdueOpp{get;set;}
    public boolean show_CFQ_Committed_Opp{get;set;}
    public DealersPortalLandingPageController(){
        Id currentUserId = Userinfo.getUserid();
        User u = [Select u.SmallPhotoUrl, u.FullPhotoUrl, u.Name From User u where u.id=:currentUserId];
        Photolink = u.SmallPhotoUrl; 
        
        ChatterGroups = [Select id,CollaborationGroup.Name,CollaborationGroup.id,CollaborationGroup.SmallPhotoUrl from CollaborationGroupMember where MemberId=:UserInfo.getUserId()];
        
        opp = [SELECT id,Amount,StageName,Name,CloseDate FROM Opportunity where 
              StageName!='Closed Won' AND StageName!='Closed Won Reagent' AND 
              StageName!='Closed Lost' AND StageName!='Abandoned' AND 
              StageName!='Stage 6 - Implement (Closed)' AND StageName!='Order won' AND 
              StageName!='Order lost' AND StageName!='Order deferred' AND 
              StageName!='E-Launch - Closed/Won/Monitor - 100%' AND StageName!='Closed Lost (E-Com & E-Proc)' AND 
              StageName!='Abandoned (E-Com & E-Proc)'  AND 
              OwnerId = :UserInfo.getUserId() 
              ORDER by Amount DESC NULLS Last LIMIT 10];
        
        overdueOpp = [SELECT id,Amount,StageName,Name,CloseDate,AccountId,Account.Name FROM Opportunity where 
              CloseDate<:Date.today() AND OwnerId = :UserInfo.getUserId() and 
              StageName!='Closed Won' and StageName!='Closed Won Reagent' and 
              StageName!='Closed Lost' and StageName!='Abandoned'
              ORDER by Amount DESC NULLS Last LIMIT 10];
        
        //query users Territory
        List<UserTerritory2Association> userTerritoryList = [SELECT Id, UserId, Territory2Id FROM UserTerritory2Association WHERE UserId =:currentUserId];
        system.debug('::::userTerritoryList'+userTerritoryList.size());
        Set<Id> territoryIds = new Set<Id>();
		for(UserTerritory2Association terr : userTerritoryList) {
        	territoryIds.add(terr.Territory2Id);
		}
        Opportunity opp = new Opportunity();
        
        cc_opp = [SELECT id,Amount,StageName,Name,CloseDate,AccountId,Account.Name FROM Opportunity where 
                (ForecastCategoryName = 'Commit' OR ForecastCategoryName = 'Closed') AND Territory2Id in :territoryIds AND
                 Revenue_Rec_Date__c > 2017-12-31 AND Revenue_Rec_Date__c < 2018-04-02
                ORDER by Amount DESC NULLS Last LIMIT 10];
        
        List<AggregateResult> mostViewed = [select contentVersionId from ContentVersionHistory where createdById = :UserInfo.getUserId()
                                                         and field = 'contentVersionViewed' group by contentVersionId order by COUNT(Id) desc limit 1000];
        List<String> contentversionids = new List<String>();
        
        system.debug('MOST VIEWED '+mostViewed);
        for(AggregateResult a:mostViewed){
            contentversionids.add(String.valueOf(a.get('contentVersionId')));
        }
        articles = [select id,ContentDocumentId,ContentDocument.title from ContentVersion where id=:contentversionids];
        
        oppOptions = new List<SelectOption>(oppOptions); 
        oppOptions.add(new SelectOption('Open Opportunities','Open Opportunities'));
        oppOptions.add(new SelectOption('Overdue Opportunities','Overdue Opportunities'));
        oppOptions.add(new SelectOption('My CFQ Committed Opportunities','My CFQ Committed Opportunities'));
        showOpenOpp = true;
        showOverdueOpp = false;
        show_CFQ_Committed_Opp = false;
    }
    public void setOppTable(){
      
      if(selectedValue == 'Open Opportunities'){
        showOpenOpp = true;
        showOverdueOpp = false;
        show_CFQ_Committed_Opp = false;
      }
      else if(selectedValue == 'Overdue Opportunities'){
        showOpenOpp = false;
        showOverdueOpp = true;
        show_CFQ_Committed_Opp = false;
      }
      else if(selectedValue == 'My CFQ Committed Opportunities'){
        showOpenOpp = false;
        showOverdueOpp = false;
        show_CFQ_Committed_Opp = true;
      }
      system.debug('SELECTED VALUE '+selectedValue+' SHOW OPP '+showOpenOpp+' SHOW OVERDUE OPP '+showOverdueOpp);
        
    }
    
       
}