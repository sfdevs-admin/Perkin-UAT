public class UpdateCasehandler {
    List<Case> casetoUpd = new List<Case>();
    public void updateCaseonTeamInsert(map<id,List<Case>> acccasemap,  list<AccountTeamMember> accteammap){
        for(AccountTeamMember a: accteammap){
            if(a.TeamMemberRole == 'Account Manager' && acccasemap.get(a.AccountId) != null){
            for(Case c:acccasemap.get(a.AccountId)){
                c.Account_Owner__c = (c.Account_Owner__c != null)?c.Account_Owner__c +',' + a.User.Name:a.User.Name;
                casetoUpd.add(c);
        }
      }
    }
      update casetoUpd;
    }
	public void updateCaseonTeamUpdate(map<id,List<Case>> acccasemap,  List<AccountTeamMember> accteammap,Map<Id,AccountTeamMember> accteamoldmap){
        for(AccountTeamMember a: accteammap){
            if(a.TeamMemberRole != accteamoldmap.get(a.id).TeammemberRole){
            for(Case c: acccasemap.get(a.AccountId)){
               c.Account_Owner__c = (a.TeamMemberRole == 'Account Manager')?(c.Account_Owner__c != null)?c.Account_Owner__c + ',' + a.User.Name:a.User.Name
                   :c.Account_Owner__c.replace(a.User.Name,''); 
               casetoUpd.add(c);
            }
           }  
        }
      update casetoUpd;
    }
    public void updateCaseonTeamDelete(map<id,List<Case>> acccasemap,  List<AccountTeamMember> accteammap){
        for(AccountTeamMember a: accteammap){
            system.debug('team role' + a.TeamMemberRole);
            if(a.TeamMemberRole == 'Account Manager'){
            for(Case c: acccasemap.get(a.AccountId)){
                c.Account_Owner__c = c.Account_Owner__c.replace(a.User.Name, '');
                system.debug('Acc own' + c.Account_Owner__c);
                casetoUpd.add(c);
            }
         }
      }
      update casetoUpd;
    }
}