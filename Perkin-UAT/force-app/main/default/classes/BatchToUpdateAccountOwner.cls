global without sharing class BatchToUpdateAccountOwner implements Database.Batchable<SObject>,Database.Stateful{
    global User defaultAccountOwner;
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        defaultAccountOwner=[select id from user where Username='test.admin@perkinelmer.com'];
        Id ownerId = defaultAccountOwner.Id; 
        String Query='select id,Ownerid from account where owner.isactive = true and OwnerId <>:ownerId';
        //String Query='select id,Ownerid from account where id = \'001Q000000usYJZ\'';//name=\'Polsa Ltd\'';
        return  Database.getQueryLocator(Query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> sObjectsFromStart) 
    {
        List<AccountTeamMember> accTeamMemberListToInsert=new List<AccountTeamMember>();
        List<Account> accountListToUpdate=new List<Account>();
        List<AccountShare> listtoinsertaccountshare=new List<AccountShare>();
        for(Account iter: sObjectsFromStart){
                AccountTeamMember accTeamMember=new AccountTeamMember();
                accTeamMember.AccountId=iter.id;
                accTeamMember.TeamMemberRole='Account Manager';
                accTeamMember.UserId=iter.ownerid;
                accTeamMemberListToInsert.add(accTeamMember);
                AccountShare accshare=new AccountShare(AccountId=iter.id,CaseAccessLevel='Read',UserOrGroupId=iter.ownerid,AccountAccessLevel='Edit',OpportunityAccessLevel='Read');
                listtoinsertaccountshare.add(accshare);                
                iter.Ownerid=defaultAccountOwner.id;
                accountListToUpdate.add(iter);

        }
        update accountListToUpdate;
        insert   accTeamMemberListToInsert;
        insert listtoinsertaccountshare;
    }
    
    global void finish(Database.BatchableContext BC) {
    
    }
}