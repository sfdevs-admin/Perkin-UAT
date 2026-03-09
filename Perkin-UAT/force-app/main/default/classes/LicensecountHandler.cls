public class LicensecountHandler {
    
    public static List<UserLicense> userlicensecount =new List<UserLicense> ();
    public static Map<String,UserLicense> licensetypeTolicense = new Map<String,UserLicense>();
    public static List<Salesforce_License_Count__c> objToInsert = new List<Salesforce_License_Count__c>();
    
   
    @future
    public static void insertlicenseObj(Set<Id> licensechange,Set<Id> activated,Set<Id> userDeactivated,Boolean isupdate,Boolean isInsert,Set<Id> userids_insert)
    {
        userlicensecount=[SELECT LicenseDefinitionKey,MasterLabel,Name,Status,TotalLicenses,UsedLicenses,UsedLicensesLastUpdated FROM UserLicense];
        
        for(UserLicense us : userlicensecount)
        {
            licensetypeTolicense.put(us.Name,us);
        }
        
        system.debug(' licensetypeTolicense '+licensetypeTolicense);
        
        List<Id> userids = new List<Id>();
        
        //while updating the user record (activating/license change)
        if(isupdate==true)
        {
            if(licensechange.size()>0 || activated.size()>0 || userDeactivated.size()>0)
            {
                userids.addAll(licensechange);
                userids.addAll(activated);
                userids.addAll(userDeactivated);
                
                List<User> userList = [select id,CreatedById,LastModifiedById ,License_type__c from User where id in: userids];
                
                system.debug('inisde object creation-update');
                for(User us: userList)
                {
                    Salesforce_License_Count__c lc = new Salesforce_License_Count__c();
                    lc.Activated_By__c = us.LastModifiedById ;
                    
                    if(activated.contains(us.Id))
                        lc.Created_or_Activated__c = 'Activated';
                    else if(licensechange.contains(us.Id))
                        lc.Created_or_Activated__c = 'License modified';
                    else if(userDeactivated.contains(us.Id))
                        lc.Created_or_Activated__c = 'Deactivated';
                    
                    lc.User_Created_Activated__c = us.Id;
                    lc.Type_of_license__c = us.License_type__c;
                    UserLicense userlicen = licensetypeTolicense.get(us.License_type__c);
                    system.debug('userlicen '+userlicen+' map is '+licensetypeTolicense);
                    if(userlicen!=null)
                    {
                        system.debug('value of userlicen.TotalLicenses'+userlicen.TotalLicenses);
                        lc.Total_salesforce_license__c = userlicen.TotalLicenses;
                        lc.Remaining_Salesforce_License__c = (userlicen.TotalLicenses - userlicen.UsedLicenses);
                    }
                    objToInsert.add(lc);
                    system.debug('object aded to list');
                }
                
            }
        }
        
        else if(isInsert==true)
        {
            if(userids_insert.size()>0)
            {
                List<User> userList = [select id,CreatedById,License_type__c from User where id in: userids_insert];
                
                for(User u: userList)
                {
                    Salesforce_License_Count__c lc = new Salesforce_License_Count__c();
                    lc.Activated_By__c = u.CreatedById;
                    lc.Created_or_Activated__c = 'Created';
                    lc.User_Created_Activated__c = u.Id;
                    lc.Type_of_license__c = u.License_type__c;
                    UserLicense userlicen = licensetypeTolicense.get(u.License_type__c);
                    if(userlicen!=null)
                    {
                        lc.Total_salesforce_license__c = userlicen.TotalLicenses;
                        lc.Remaining_Salesforce_License__c = (userlicen.TotalLicenses - userlicen.UsedLicenses);
                    }
                    objToInsert.add(lc);
                }
            }
            
        }
        if(objToInsert.size()>0)
        {
            if(!test.isRunningTest())
            insert objToInsert;
            else
                upsert objToInsert;
        }
    }



}