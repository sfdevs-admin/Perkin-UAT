@isTest(seeAllData=true)
public class PDG_Test_Opportunity_Owner_Stamp {
    
      
    
    @isTest static void Route_Lead(){
        List<User> nUser = new List<User>();
        //SAI_Lead_Routing_Values__c cc = new SAI_Lead_Routing_Values__c();
        //cc.SAI_Values__c = 'Applied Genomics,Maternal Fetal Health,Newborn Screening';
        List <Opportunity> Opp_List = new List <Opportunity>();
        List <Contact> Con_List = new List <Contact>();
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'LDR Demand Gen' LIMIT 1];
        Profile profileId2 = [SELECT Id FROM Profile WHERE Name = 'PKI Service Account' LIMIT 1];
        
        system.debug(profileId.id);
        
        for(integer i=0; i<=1; i++){
        User usr = new User();
            if(i==0){
            usr.LastName = 'Test';
            usr.FirstName='aUser';
            usr.Alias = 'aUserT';
            usr.Email = 'auser.test@test.com';
            usr.Username = 'auser.test@test.com';
            usr.ProfileId = profileId.id;
            usr.TimeZoneSidKey = 'GMT';
            usr.LanguageLocaleKey = 'en_US';
            usr.EmailEncodingKey = 'UTF-8';
            usr.LocaleSidKey = 'en_US';
            }
            if(i==1){
            usr.LastName = 'Test';
            usr.FirstName='bUser';
            usr.Alias = 'bUserT';
            usr.Email = 'buser.test@test.com';
            usr.Username = 'buser.test@test.com';
            usr.ProfileId = profileId.id;
            usr.TimeZoneSidKey = 'GMT';
            usr.LanguageLocaleKey = 'en_US';
            usr.EmailEncodingKey = 'UTF-8';
            usr.LocaleSidKey = 'en_US';
            }
         nUser.add(usr);   
        }
                
        Account z = new Account();
        z.Name = 'testing in test method';
        z.ShippingCity = 'City 1';
        z.ShippingState = 'State 1';
        z.ShippingStreet = 'Street 1';
        z.ShippingCountry = 'US';
        z.ShippingPostalCode = '12345';
        
        insert z;        
        insert nUser;
       // insert cc;
        system.debug(nUser);
        
        System.runAs(nUser[0]){
            for(integer i = 0; i<=0; i++){
                Opportunity Opp = new Opportunity();                
                Opp.Name = 'Test_Opp' + i;
                Opp.StageName = 'Zero Stage';
                Opp.Solution_Area_of_Interest__c = 'Air';
                Opp.CreatedById = nUser[0].id;
                Opp.OwnerId = nUser[0].id;
                Opp.CloseDate = date.today() + 1;
                Opp.Product_Line_Name__c = 'AA';
                Opp_List.add(Opp);
            }
            
            insert Opp_List;
            Opportunity Opp1 = new Opportunity();                
                Opp1.Name = 'Test_Opp1';
                Opp1.StageName = 'Zero Stage';
                Opp1.Solution_Area_of_Interest__c = 'Air';
                Opp1.CreatedById = nUser[0].id;
                Opp1.OwnerId = nUser[0].id;
                Opp1.CloseDate = date.today() + 1;
                Opp1.Product_Line_Name__c = 'AA';
                insert opp1;
                opp1.StageName = 'Abandoned';
            update opp1;
            

        }
        for(integer i = 0; i<=0; i++){ 
            Contact Con = new Contact();
            Con.FirstName = 'TestUser: '+i;
            Con.LastName  = 'Class: '+i;
            Con.Title     =  'UnitTest'+i;
            Con.MailingCountry = 'US';
            Con.OwnerId = nUser[0].id;
            Con.Email = 'usertest-class-'+i+'@test.com';
            Con_List.add(Con);
        }
        insert Con_List;
        
        Contact f = [Select id from Contact where Title = 'UnitTest0' Limit 1];
        Opportunity g = [Select id from Opportunity where name = 'Test_Opp0' Limit 1];
        
        
        // Opportunity Contact Role
        OpportunityContactRole TestContactRole = new OpportunityContactRole();
        TestContactRole.ContactId = f.Id;
        TestContactRole.OpportunityId = g.id;
        TestContactRole.IsPrimary = True;
        insert TestContactRole;
        system.debug(TestContactRole);
        
    
  		
    
        User c = [Select Id, Name from User where email = 'buser.test@test.com' Limit 1];
        Opportunity a = [Select id, OwnerId from Opportunity where Name = 'Test_Opp0' Limit 1];
        Contact d = [Select id, Lead_Owner_Sales__c from Contact where Title = 'UnitTest0' Limit 1];
        system.debug('***** User' + c.id); 
        a.OwnerId = c.id;
        PDG_Opp_LDR_Conversion.is_First = true;
        update a;
        PDG_Opp_LDR_Conversion.is_First = true;

        Lead_Owner_Sales(c.Name ,c.id);

    }      
    
    static void Lead_Owner_Sales(String a, id b){
        Contact d = [Select id, Lead_Owner_Sales__c from Contact where Title = 'UnitTest0' Limit 1];
        system.debug('Class <PDG_Test_Opportunity_Owner_Stamp> Lead Owner Sales field should equal: ' + a);         
        system.debug('Class <PDG_Test_Opportunity_Owner_Stamp> Lead Owner Sales : ' + d.Lead_Owner_Sales__c);         
        //system.assert(d.Lead_Owner_Sales__c != null, 'Lead Owner Sales field is wrong. Expected : ' + a);
    }
    
    
    
    
}