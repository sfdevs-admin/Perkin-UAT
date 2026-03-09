/* Change Log
* 
Developer           Date        Description
Tony Tran           01/24/17    Removed commented code, removed code that set defunct CRM Address fields
* 
* 
* 
*/ 

public class AccountMethods
{
    public static boolean run = true;
    public static boolean runUpdate = true;
    public Map<id,account> accountDetailsMap;
    //These variables store Trigger.oldMap and Trigger.newMap, respectively
    Map<Id, Account> oldAccountMap;
    Map<Id, Account> newAccountMap;
    
    //Trigger.Old
    List <Account> oldAccountsList;
    
    //Trigger.New
    List <Account> newAccountsList;
    List <Account> listAccountsToUpdate;
    
    public static void runOnceInsert()
    {
        if(run)
            run=false;
    }
    
    public static void runOnceUpdate()
    {
        if(runUpdate)
            runUpdate=false;
    }
    
    //Constructor
    public AccountMethods (Map <Id, Account> mapOfOldAccounts, List<Account> OldAccounts, Map <Id, Account> mapOfNewAccounts, List<Account> newAccounts){
        oldAccountMap = mapOfOldAccounts;
        newAccountMap = mapOfNewAccounts;
        oldAccountsList = oldAccounts;
        newAccountsList = newAccounts;
        
        System.debug('Constructor completed');
    }
    
    public void setAccountOwner(){
        User defaultAccountOwner=[select name,id from user where FirstName='PerkinElmer' AND LastName = 'Inc.'];
        if(defaultAccountOwner!=null){
            for (account o: newAccountsList){
                o.Ownerid = defaultAccountOwner.id;
            }
            /*List<AccountTeamMember> accTeamMemberListToInsert=new List<AccountTeamMember>();
            List<Account> accountListToUpdate=new List<Account>();
            List<AccountShare> listtoinsertaccountshare=new List<AccountShare>();
            
            accountListToUpdate=[select id,Ownerid from account where id in :newAccountsList];
            for(Account iter : accountListToUpdate){
                AccountTeamMember accTeamMember=new AccountTeamMember();
                accTeamMember.AccountId=iter.id;
                accTeamMember.TeamMemberRole='Account Manager';
                accTeamMember.UserId=iter.ownerid;
                accTeamMemberListToInsert.add(accTeamMember);
                iter.Ownerid=defaultAccountOwner.id;
                AccountShare accshare=new AccountShare(AccountId=iter.id,CaseAccessLevel='Read',UserOrGroupId=accTeamMember.UserId,AccountAccessLevel='Edit',OpportunityAccessLevel='Read');
                listtoinsertaccountshare.add(accshare);
            }
            
            update accountListToUpdate;
            insert accTeamMemberListToInsert;
            insert listtoinsertaccountshare;*/
        } 
    }
    
    public void changeTopParent(boolean isInsert){
        List<Account> listofAccountsToUpdate = new List<Account>();
        
        List<Account> accountList = [Select Id,ParentId,Top_Parent_Account__c,Parent.Top_Parent_Account__c from Account where id=:newAccountsList];
        
        Set<id> accountHierarchyList = new Set<id>();
        
        accountDetailsMap = new Map<id,account>();
        for(Account a:accountList){
            //system.debug('ACCOUNTS PAARENT'+a.Parent);
            //system.debug('TOP PARENT'+a.Parent.Top_Parent_Account__c);
            //system.debug('oldAccoun'+oldAccountMap.containsKEY(a.ID));
            //ystem.debug('OLD '+oldAccountMap);
            if(oldAccountMap!=null && newAccountMap!=null){
                if((isInsert && a.ParentId!=null) || oldAccountMap.get(a.id).ParentId != newAccountMap.get(a.id).ParentId || (oldAccountMap.get(a.id).Update_Top_Parent__c!=newAccountMap.get(a.id).Update_Top_Parent__c && newAccountMap.get(a.id).Update_Top_Parent__c == true)){
                    
                    id currentParentid=a.ParentId;
                    Account temp = new Account();
                    while(currentParentid!=null){
                        
                        String queryOne = 'Select id,ParentId,Top_Parent_Account__c from Account where id =: currentParentid';
                        temp = Database.query(queryOne);
                        currentParentid = temp.ParentId;
                        system.debug('**'+currentParentid);
                    }
                    
                    a.Top_Parent_Account__c = temp.id;
                    
                    
                    accountHierarchyList = findChildren(a.id);
                    for(id i:accountHierarchyList){
                        Account acc = accountDetailsMap.get(i);
                        if(a.Parent!=null)
                            acc.Top_Parent_Account__c = temp.id;
                        else
                            acc.Top_Parent_Account__c = a.id;
                        listofAccountsToUpdate.add(acc);
                    }
                    a.Update_Top_Parent__c = false;
                    listofAccountsToUpdate.add(a);
                }
            }
            
        }
        
        //system.debug('LISST OF IDS '+accountHierarchyList);
        
        update listofAccountsToUpdate;
    }
    
    public Set<id> findChildren(id parentid){
        accountDetailsMap.clear();
        Set<id> accountHierarchyList = new Set<id>();
        
        try{
            Boolean endTraversing = false;
            Integer accountLevel = 0;                                                                                                      
            String query;
            List<Account> acctList = new List<Account>(); 
            List<id> parentIdList = new List<id>();
            
            Map<id,List<Account>> parentChildLinkedListMap = new Map<id,List<Account>>();
            
            while(!endTraversing) {
                // observe closely at the WHERE clause, that's the key
                if(accountLevel == 0)
                    query = 'select Id, Name, ParentId, Top_Parent_Account__c from Account WHERE ParentId =:parentid';
                
                else
                    query = 'select Id, Name, ParentId, Top_Parent_Account__c from Account WHERE ParentId IN :parentIdList';
                
                acctList = Database.query(query);
                system.debug('acctList '+acctList);
                if(acctlist!=null){
                    if(acctList.size() == 0 )
                        endTraversing = true;
                    
                    else{
                        parentIdList.clear();
                        acctList.sort();
                        Account a;
                        for(Integer i = 0; i < acctList.size(); i++ ){
                            a = acctList.get(i);
                            parentIdList.add(a.Id);
                            
                            accountDetailsMap.put(a.Id, a);
                            
                            if(parentChildLinkedListMap.get(a.ParentId) == null)
                                parentChildLinkedListMap.put(a.ParentId, new List<Account>()); 
                            
                            parentChildLinkedListMap.get(a.ParentId).add(a);
                            parentChildLinkedListMap.get(a.ParentId).sort();
                        }
                        
                        accountLevel++;
                    }
                }
            }
            
            for(List<Account> accList : parentChildLinkedListMap.values()){
                for(Account act : accList){
                    if(!accountHierarchyList.contains(act.id)){
                        accountHierarchyList.add(act.id);
                        
                    }
                }
            } 
        }catch(exception e){
            system.debug('exception '+e.getStackTraceString());
        }
        
        return accountHierarchyList;
        
    }   
    
    public void updateAccountvalues(){
        Map<Id, RecordType> recType  = new Map<ID, RecordType>([select id,Name from RecordType where Developername = 'Customer' AND sobjecttype = 'Account' AND IsActive = TRUE ]);
        
        for (account o: newAccountsList) {
            if ( (o.Account_Category__c == null) || (o.Account_Category__c != null)) { 
                o.Account_Category_Calc__c = o.Account_Category__c;
            }
            
            if ( (o.Account_Incorporated_Country__c == null) || (o.Account_Incorporated_Country__c != null)) { 
                o.Country_of_Incorporation_Calc__c = o.Account_Incorporated_Country__c; 
            }
            
            if ( (o.Account_Incorporated_State__c == null) || (o.Account_Incorporated_State__c != null)) { 
                o.State_of_Incorporation_Calc__c = o.Account_Incorporated_State__c; 
            }
            
            if ( (o.Account_Sub_Category__c == null) || (o.Account_Sub_Category__c != null)) { 
                o.Account_Sub_Category_Calc__c = o.Account_Sub_Category__c; 
            } 
            if(o.Merged_Flag__c==true && rectype.containsKey(o.RecordTypeId)) {
                o.IsExcludedFromRealign = false;
            }
        }
    }
    
    public void preventDeleteBasedOnRecordType(){
        List<string> allowedProfiles = new List<String>();
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String MyProfileName = PROFILE[0].Name;
        Boolean isProfileAllowed = false; 
        Map<Id, RecordType> recType  = new Map<ID, RecordType >([select id,Name from RecordType where Developername = 'PerkinElmer_Entities' AND sobjecttype = 'Account' AND IsActive = TRUE ]);
        
        if(MyProfileName == 'System Administrator' ){
            isProfileAllowed = true;
        }
        
        if(!recType.isempty()){
            //String RecordTypeAid = rectype[0].id;
            if(!isProfileAllowed){
                for(Account acc: oldAccountsList){
                    if(rectype.containsKey(acc.RecordTypeId)){
                        acc.addError('You are not permitted to delete an account of these record types - "PKI Entity"');
                    }
                }
            }
        }
    }
    
    public void validatesobjectvalues(string objName)
    {
        //system.debug('object Name '+objName);
        User curruser = [select id,profileid,profile.Name,Username from User where id =:UserInfo.getuserId()];
        Custom_Validation_Setup__c cusSetup = new Custom_Validation_Setup__c();
        Boolean came = false;
        
        for(Custom_Validation_Setup__c cusval:[SELECT Id, Object_API_Name__c,User_Profile__c, Mandatory_Fields__c, Username_Profile_name__c, Non_Changeable_Fields__c FROM Custom_Validation_Setup__c where (Username_Profile_name__c = :curruser.Username or Username_Profile_name__c = :curruser.profile.Name or Username_Profile_name__c = 'All') and Object_API_Name__c =: objName])
        {
            if(cusval.User_Profile__c == 'User')
            {
                cusSetup = cusval;
                came = true;
            }
            if(cusval.User_Profile__c == 'Profile' && !came)
            {
                cusSetup = cusval;
                came = true;
            }
            if(cusval.User_Profile__c == 'Profile' && cusval.Username_Profile_name__c == 'All' && !came)
                cusSetup = cusval;
        }
        List<String> Mandatoryfields = new List<String>();
        List<String> nonchangablefields = new List<String>();
        
        if(cusSetup.Id !=null)
        {
            if(cusSetup.Mandatory_Fields__c !=null)
                Mandatoryfields = cusSetup.Mandatory_Fields__c.split(',');
            if(cusSetup.Non_Changeable_Fields__c!=null)
                nonchangablefields = cusSetup.Non_Changeable_Fields__c.split(',');            
        }
        Schema.SObjectType schemaMap = Schema.getGlobalDescribe().get(objName);
        Map<String, Schema.SObjectField> fieldMap = schemaMap.getDescribe().fields.getMap();
        
        for (SObject cobj: newAccountsList)
        {
            String mandfieldserr = 'Please fill the following mandatory fields'+'<br/>';
            Integer count = 1;
            Boolean errorthere = false;
            
            String changefieldserr = 'The following fields cannot be changed'+'<br/>';
            Integer count1 = 1;
            Boolean changethere = false;
            for(String s:Mandatoryfields)
            {
                if(cobj.get(s) == null && fieldMap.get(s)!=null)
                {
                    mandfieldserr = mandfieldserr + count+'. '+fieldMap.get(s).getDescribe().getLabel()+'<br/>';
                    errorthere = true;
                    count = count+1;
                }                   
            }
            for(String s:nonchangablefields)
            {
                if(oldAccountMap !=null && cobj.get(s) != oldAccountMap.get(cobj.Id).get(s) && fieldMap.get(s)!=null)
                {
                    changefieldserr = changefieldserr + count1+'. '+fieldMap.get(s).getDescribe().getLabel()+'<br/>';
                    changethere = true;
                    count1 = count1+1;
                }
            }
            if(errorthere){
                system.debug('madatory fields error');
                cobj.addError(mandfieldserr,false);
            }
            else if(changethere){
                system.debug('change fields error');
                cobj.adderror(changefieldserr,false);
            }
            
        }
    }
}