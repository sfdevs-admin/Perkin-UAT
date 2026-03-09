/**************************************************************
* 1. Jira Ticket(s) that relates to this class 
     - ITSFDC-5032
*
* 2. Description - This class is for the test coverage of LWC_Oppty_Territory_Controller.
*
*
*
* 3. Objects referenced
*    -Opportunity
*    -Territory2
*    -UserTerritory2Association
*    -ObjectTerritory2Association
*
* 4. Callouts to additional Components (including their methods) or None:- None
*
* 5. Dependant Class(es):LWC_Oppty_Territory_Controller
*
* 6. Test Class Name: 
*
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - Sumit Sourav & Updated Date(2021.09.27)
*
*************************************************************/
@isTest(SeeAllData=true)
public class lwc_opp_terr_lkup_cntlr_test {
   
    public static Id insertTestTerritory(Id acc1) {
        //Insert territory data
        List<Territory2Type> terriType   = [SELECT id, DeveloperName from Territory2Type LIMIT 1];
        List<Profile> adminProfile = [select id, name from Profile where  name = 'System Administrator'];
        
        List<Territory2Model> terrModel   = [SELECT id, DeveloperName,State from Territory2Model where State='Active' LIMIT 1];
        system.debug('terrModel.State '+terrModel[0].State);
        Territory2 objTerr = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId=terrModel[0].Id, Name='TestTerritory',Territory2TypeId=terriType[0].Id);
        insert objTerr;
        
        ObjectTerritory2Association objObjectTerritory2Association = new ObjectTerritory2Association(ObjectId = acc1, Territory2Id =objTerr.Id, AssociationCause='Territory2Manual' );
        insert objObjectTerritory2Association;
        
        UserTerritory2Association objUserTerritory2Association = new UserTerritory2Association(Territory2Id= objTerr.Id, UserId= userinfo.getUserId(), RoleInTerritory2='Sales / Marketing Manager');
        insert objUserTerritory2Association;
        return objTerr.Id;
    }
    
    private static testMethod void territorryAssignmentToAccountsByTrigger() {
        //Fetch current loggedin user.
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
        
        System.RunAs(usr) {
            //create test data for account
            Account acc1;
            ID RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
            acc1 = new Account();
            acc1.RecordtypeId = RecordtypeId;
            acc1.Name = 'test-1';
            acc1.ShippingPostalCode='600094';
            acc1.ShippingState='TN';
            acc1.ShippingStreet='MountRoad';
            insert acc1;
           
            // Create test data for opportunity
            Id PKIRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('PKI SPI Sales Process').getRecordTypeId();
            Opportunity opp1 = new Opportunity(Name='testopp1', CloseDate = System.today(), StageName = 'Stage 1 - Create/Plan',
                                               RecordTypeId = PKIRT, ForecastCategoryName = 'Omitted',ownerid=userinfo.getUserId(),accountid=acc1.Id,
                                               Owned_by_Company__c = 'LSDX');
            insert opp1;
            test.startTest();
            Id territoriesId=insertTestTerritory(acc1.Id);
            String terId=territoriesId;
            lwc_opp_terr_lkup_cntlr.getTerritoryName(opp1.Id);
            lwc_opp_terr_lkup_cntlr.updateTerritoryonOpty(terId,opp1.Id);
            test.stopTest();
        }
    }
    private static testMethod void territorryAssignmentToAccountsByTrigger2() {
        //Fetch current loggedin user.
        List<User> usr = [Select id from User Where Id IN(SELECT UserOrGroupId  FROM GroupMember Where group.developerName='PG_8000_DLR_Territory_Admin') limit 1];
        system.debug(usr);
      // Account acct = [select Id from Account limit 1];
        Account acct;
        ID RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        acct = new Account();
        acct.RecordtypeId = RecordtypeId;
        acct.Name = 'test-1';
        acct.ShippingPostalCode='600094';
        acct.ShippingState='TN';
        acct.ShippingStreet='MountRoad';
        insert acct;
       
        if(usr != null && !usr.isEmpty()){
            system.debug(usr);
            System.RunAs(usr[0])
            {
                // Create test data for opportunity
                Id PKIRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('PKI SPI Sales Process').getRecordTypeId();
                Opportunity opp1 = new Opportunity(Name='testopp1', CloseDate = System.today(), StageName = 'Stage 1 - Create/Plan',
                                                   RecordTypeId = PKIRT, ForecastCategoryName = 'Omitted',ownerid=userinfo.getUserId(),accountid=acct.Id,
                                                   Owned_by_Company__c = 'LSDX');
                insert opp1;
                test.startTest();
                Id territoriesId=insertTestTerritory(acct.Id);
                String terId=territoriesId;
                lwc_opp_terr_lkup_cntlr.getTerritoryName(opp1.Id);
                lwc_opp_terr_lkup_cntlr.updateTerritoryonOpty(terId,opp1.Id);
                test.stopTest();
           }
        }
    }
}