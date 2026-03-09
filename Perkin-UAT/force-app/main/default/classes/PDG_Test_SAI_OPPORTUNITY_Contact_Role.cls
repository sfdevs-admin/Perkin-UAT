@isTest
public class PDG_Test_SAI_OPPORTUNITY_Contact_Role {
    
    @testSetup static void setup() {
        List<User> nUser = new List<User>();
        List <Opportunity> Opp_List = new List <Opportunity>();
        List <Id> Opp_ListId = new List <Id>();
        List <Contact> Con_List = new List <Contact>();
        
        
        
        
        Account z = new Account();
        z.Name = 'testing in test method';
        
        insert z;        
        
        for(integer i = 0; i<=19; i++){ 
            Contact Con = new Contact();
            Con.FirstName = 'TestUser: '+i;
            Con.LastName  = 'Class: '+i;
            Con.Title     =  'aUnitTest'+i;
            Con.MailingCountry = 'US';
            Con.Email = 'usertest-class-'+i+'@test.com';
            Con_List.add(Con);
        }
        insert Con_List;
        
        for(integer i = 0; i<=19; i++){
            Opportunity Opp = new Opportunity();                
            Opp.Name = 'Test_Opp' + i;
            Opp.StageName = 'Stage 1 - Create/Plan';
            Opp.CloseDate = date.today() + 1;
            Opp.Solution_Area_of_Interest__c = 'Pre-Clinical Studies';
            Opp_List.add(Opp);
        }
        
        insert Opp_List;
        system.debug(Opp_List);
        
        
    }
    
    @isTest static void CheckOpps(){
        List <Id> Opp_ListId = new List <Id>();
        List <Contact> f = [Select id from Contact where Title Like 'aUnitTest%'];
        List <Opportunity> g = [Select id from Opportunity where name Like 'Test_Opp%'];
        List <Id> ConId = new List <Id>();
        //Profile profileId = [SELECT Id FROM Profile WHERE Name = 'LDR Demand Gen' LIMIT 1];
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'system administrator' LIMIT 1];

        system.debug('LDR===' + profileId);
        User e = [Select Id, Name from User where ProfileId = :profileId.id and isActive = true Limit 1];
        
        system.debug('*******' + g);
        system.debug('*******' + f);
        System.runAs(e){
            for(integer i = 0; i<=0; i++){
                Opportunity Opp = new Opportunity();                
                Opp.Name = 'wTest_Opp' + i;
                Opp.StageName = 'Zero Stage';
                Opp.CreatedById = e.id;
                Opp.OwnerId = e.id;
                Opp.CloseDate = date.today() + 1;
                Opp.Solution_Area_of_Interest__c = 'Air';
                insert Opp;        
            }
        }
        
        
        String [] SAIValues = new List <String>{'Air','Applied Genomics','Cannabis','Chemicals','Clinical Studies','Digital Lab','Disease Research','Drug Discovery','Energy','Food','Forensics and Security','Geochemistry, Mining and Metals','Material','Maternal Fetal Health','Newborn Screening','Pre-Clinical Studies','QA/QC Drug Manufacturing Process','Soil/Solids','Strategic Services','Water'};
            
            // Opportunity Contact Role
            List <OpportunityContactRole> OCR = new List <OpportunityContactRole>();
        for(integer i = 0; i<=19; i++){
            OpportunityContactRole TestContactRole = new OpportunityContactRole();
            TestContactRole.ContactId = f[i].Id;
            TestContactRole.OpportunityId = g[i].Id;
            TestContactRole.IsPrimary = True;
            OCR.add(TestContactRole);
            system.debug(TestContactRole);
            Opp_ListId.add(g[i].Id);
            ConId.add(f[i].Id);

        }
        insert OCR;
        
        List<OpportunityContactRole> OCRList = [Select Id from OpportunityContactRole where opportunityId IN: Opp_ListId];
        List <Opportunity> a = [Select id, OwnerId from Opportunity where id IN:Opp_ListId];
        integer i=0;
        for(Opportunity c : a){
            c.OwnerId = e.id;
            c.Solution_Area_Of_Interest__c = SAIValues[i];
            i++;
        }
        PDG_Opp_LDR_Conversion.is_First = true;
        update a;
        PDG_Opp_LDR_Conversion.is_First = true;
        
        
        PDG_Test_SAI_OPPORTUNITY_Contact_Role object_Con = new PDG_Test_SAI_OPPORTUNITY_Contact_Role();
        object_Con.OOPwithCon(OCRList);

    }      
    static void Lead_Owner_Sales(String a, id b){
        Contact d = [Select id, Lead_Owner_Sales__c from Contact where Title = 'UnitTest0' Limit 1];
        system.debug('Class <PDG_Test_Opportunity_Owner_Stamp> Lead Owner Sales field should equal: ' + a);         
        system.debug('Class <PDG_Test_Opportunity_Owner_Stamp> Lead Owner Sales : ' + d.Lead_Owner_Sales__c);         
        system.assert(d.Lead_Owner_Sales__c != null, 'Lead Owner Sales field is wrong. Expected : ' + a);
    }
    
   public void OOPwithCon(List <OpportunityContactRole> OCR){
       OppsWithContacts object_name = new OppsWithContacts();
      // object_name.ParamValueFromJavaScript = f[0] + ',' + f[1] + ',' + f[2] + ',' + f[3] + ',' + f[4] + ',' + f[5] + ',' + f[6] + ',' + f[7] + ',' + f[8] + ',' + f[9] + ',' + f[10] + ',' + f[11] + ',' + f[12] + ',' + f[13] + ',' + f[14] + ',' + f[15] + ',' + f[16];
        object_name.ParamValueFromJavaScript = OCR[0].id + ',' + OCR[1].id + ',' + OCR[2].id + ',' + OCR[3].id + ',' + OCR[4].id + ',' + OCR[5].id + ',' + OCR[6].id + ',' + OCR[7].id + ',' + OCR[8].id + ',' + OCR[9].id + ',' + OCR[10].id + ',' + OCR[11].id + ',' + OCR[12].id + ',' + OCR[13].id + ',' + OCR[14].id + ',' + OCR[15].id + ',' + OCR[16].id;
       object_name.say();
    }
    
    
}