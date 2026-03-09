/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ATEAM-1556
  *
  * 2. Description - This class runs when SBX are created/Refreshed, and does:
  *   - Adds missing PKI Country from C.META 
  *   - Updates User Emails for Admin in PG_1000:Admin to remove “.invalid”
  *
  * 3. Objects referenced
  *   - PKI Country 
  *   - C_META_PKI_Countries__mdt (Custom Metadata)
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *
  * 5. Dependant Class(es):
  *    - None
  *
  * 6. Test Class Name: Test_sbx_activate
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - Aakash Pal (2022.01.07)
  *
*************************************************************/ 

global class sbx_activate implements SandboxPostCopy {
    global void runApexClass(SandboxContext context) {
        //list of all PKI Country records
        List<PKI_Country__c> pkiCountryList = [SELECT Id FROM PKI_Country__c];
        if(pkiCountryList.size() == 0) {
			List<C_META_PKI_Countries__mdt> metaPKICountriesList = [SELECT id, CountryISOAlpha2__c, CountryISOAlpha3__c, 
                                                                    CountryISOCode__c, Description__c, Country__c, SubTerritory__c, 
                                                                    Territory__c, GlobalTerritory__c, SuperTerritory__c, Inactive__c, 
                                                                    CurrencyISOCode__c FROM C_META_PKI_Countries__mdt 
                                                                    WHERE Inactive__c = false];
            if(!metaPKICountriesList.isEmpty()) {
                //traversing over Meta PKI Countries to create PKI Country records
				for(C_META_PKI_Countries__mdt metaPKICountry : metaPKICountriesList) {
                    PKI_Country__c pkiCountry = new PKI_Country__c();
                    pkiCountry.Country_ISO_Alpha_2__c = metaPKICountry.CountryISOAlpha2__c;
                    pkiCountry.Country_ISO_Alpha_3__c = metaPKICountry.CountryISOAlpha3__c;
                    pkiCountry.Country_ISO_Code__c = metaPKICountry.CountryISOCode__c;
                    pkiCountry.Description__c = metaPKICountry.Description__c;
                    pkiCountry.Name = metaPKICountry.Country__c;
                    pkiCountry.Sub_Territory__c = metaPKICountry.SubTerritory__c;
                    pkiCountry.Territory__c = metaPKICountry.Territory__c;
                    pkiCountry.Global_Territory__c = metaPKICountry.GlobalTerritory__c;
                    pkiCountry.Super_Territory__c = metaPKICountry.SuperTerritory__c;
                    pkiCountry.Inactive__c = metaPKICountry.Inactive__c;
                    pkiCountry.CurrencyIsoCode = metaPKICountry.CurrencyISOCode__c;
                    pkiCountryList.add(pkiCountry);
                }
                if(pkiCountryList.size() > 0) {
                    insert pkiCountryList;
                }
            }
        }
        
        //List of all users from PG_1000: SFDC Admin group
        List<User> userList = [SELECT Id, Name, Email, IsActive, Do_Not_Deactivate__c FROM User where Id IN 
    								(SELECT userorgroupid FROM groupmember WHERE group.Name = 'PG_1000: SFDC Admin')]; 
        List<User> usersToUpdateList = new List<User>();
        if(!userList.isEmpty()) {
            //activating users post SBX refresh/creation
            for(User uc : userList) { 
                uc.Email = uc.Email.contains('.invalid') ? uc.Email.replace('.invalid','') : uc.Email; 
                uc.IsActive = true;
                uc.Do_Not_Deactivate__c = true;
                usersToUpdateList.add(uc);
            }
        }
         
		if(usersToUpdateList.size() > 0) { 
			Update usersToUpdateList;
        } 
    } 
}