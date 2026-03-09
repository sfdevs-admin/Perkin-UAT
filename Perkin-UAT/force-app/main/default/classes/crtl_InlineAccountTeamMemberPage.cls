/*
Created By : Lister Technologies
Purpose : Extenstion class for inline page InlineAccountTeamMemberPage which gives the user opportunity to remove,add or change role for account team member. 
Test Class : Test_crtl_InlineAccountTeamMemberPage 
Modified By : 
*/
global without sharing class crtl_InlineAccountTeamMemberPage{
    global boolean isAccountTeamMember{get;set;} 
    global string pageMessage{get;set;}
    global static account account{get;set;}
    global static List<AccountTeamMember> accountTeamMemberList{get;set;}
    global static AccountTeamMember accountTeamMember{get;set;}
    global string urlbase{get;set;}
    global string accid{get;set;}
    global string selectedrole{get;set;}
     global static string selectedrolenew{get;set;}
    global static string accid2{get;set;}
    public crtl_InlineAccountTeamMemberPage(ApexPages.StandardController stdController){
        account=(Account)stdController.getRecord();
        urlbase=URL.getSalesforceBaseUrl().toExternalForm();
        accid=account.id;
        accid2 = account.Id;
        accountTeamMember=new AccountTeamMember();
        
        //checking if the logged is user is already added to account teammember
        accountTeamMemberList=[select id,UserId,TeamMemberRole from AccountTeamMember where AccountId=:account.id and userid=:UserInfo.getUserId()];
        if(accountTeamMemberList.size()>0){
            isAccountTeamMember=true;
            pageMessage='You are currently an Account Team member with '+accountTeamMemberList[0].TeamMemberRole+' role. You could change your role or remove yourself from the Account.';
            selectedrolenew=accountTeamMemberList[0].TeamMemberRole;
        }
        else{
            isAccountTeamMember=false;
            accountTeamMember.TeamMemberRole='Account Manager';
            selectedrolenew='Account Manager';
            pageMessage='You are currently not an Account Team member. Please choose your role and click add.';
        }
        

    }
    @RemoteAction
    global static PageReference removeMembership( string x){
        
        AccountTeamMember toupdate=[select id,UserId,TeamMemberRole from AccountTeamMember where AccountId=:x and userid=:UserInfo.getUserId() Limit 1];
        AccountShare todeleteaccshare=[select id from AccountShare where AccountId=:x and UserOrGroupId=:UserInfo.getUserId() Limit 1]; 
        delete todeleteaccshare;
        delete toupdate;
        
        PageReference pg=new PageReference('/'+x);
        pg.setRedirect(true);
          return Pg;
    }
    @RemoteAction
    global static PageReference addMembership(string x, string y){
        AccountTeamMember  temp=new AccountTeamMember ();
        temp.AccountId=x;
        temp.UserId=[Select Id FROM User WHERE IsActive=TRUE AND USERType = 'Standard' LIMIT 1].id; //temp.UserId=UserInfo.getUserId();
        temp.TeamMemberRole=y;
        AccountShare accshare=new AccountShare(AccountId=x,CaseAccessLevel='Read',UserOrGroupId=temp.UserId /*UserInfo.getUserId()*/,AccountAccessLevel='Edit',OpportunityAccessLevel='Read');
        
        insert temp;
        insert accshare;
        system.debug('selectedrole'+selectedrolenew);
        PageReference pg=new PageReference('/'+x);
        pg.setRedirect(true);
          return Pg;
    }
    @RemoteAction 
    global static PageReference changeMembershipRole(string x,string y){
        system.debug('>>>>>>>>>>>>>>>>inside change '+accountTeamMemberList + ' ' + x+'     '+y);
        system.debug('selectedrole'+selectedrolenew+'yyyy'+y);
        AccountTeamMember toupdate=[select id,UserId,TeamMemberRole from AccountTeamMember where AccountId=:x and userid=:UserInfo.getUserId() Limit 1];
        toupdate.TeamMemberRole=y;
        AccountShare accshare=new AccountShare(AccountId=x,CaseAccessLevel='Read',UserOrGroupId=UserInfo.getUserId(),AccountAccessLevel='Edit',OpportunityAccessLevel='Read');
        
        
        
        update toupdate;
        insert accshare;
        PageReference pg=new PageReference('/'+x);
        pg.setRedirect(true);
          return Pg;
    }     


global list<SelectOption> getalloptions()
   {
      AccountTeamMember temp=new AccountTeamMember();
            list<SelectOption> options = new list<SelectOption>();
            
      // Get the object type of the SObject.
      Schema.sObjectType objType = temp.getSObjectType(); 
      // Describe the SObject using its object type.
      Schema.DescribeSObjectResult objDescribe = objType.getDescribe();       
      // Get a map of fields for the SObject
      map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap(); 
      // Get the list of picklist values for this field.
      list<Schema.PicklistEntry> values =fieldMap.get('TeamMemberRole').getDescribe().getPickListValues();
      // Add these values to the selectoption list.
      for (Schema.PicklistEntry a : values)
      { 
         options.add(new SelectOption(a.getLabel(), a.getValue())); 
      }
      return options;
   }


}