@isTest
public class PDG_Test_PKI_Status_Updates {

    public static string OwnerChangeId;
    @testSetup static void setup() {
        profile p = [Select id from profile where name = 'System Administrator' limit 1];
        id userId = [Select id from User where profileId =: p.id and isActive = true limit 1].id;
        
        List <Lead> LeadContainer = new List <Lead>();
        List <Contact> ConContainer = new List <Contact>();
        List <User> UserContainer = new List <User>();

   
        for(integer i=0; i<=19; i++){
            Lead LeadRecord = new Lead();
            Contact ConRecord = new Contact();            
            LeadRecord.FirstName = 'TestUser: '+i;
            LeadRecord.LastName  = 'Class: '+i;
            LeadRecord.Title     =  'UnitTest'+i;
            LeadRecord.Street = '225 Blvd';
            LeadRecord.City  = 'Montgomery';
            LeadRecord.Status = 'Open';
            LeadRecord.Country = 'US';  
            LeadRecord.Company = 'Test';
            LeadRecord.OwnerId = userId;
            ConRecord.FirstName = 'TestUser: '+i;
            ConRecord.LastName  = 'Class: '+i;
            ConRecord.Title     =  'UnitTest'+i;
            ConRecord.MailingCountry = 'US';
            ConRecord.OwnerId = userId;
            
            system.debug('[][][] :' + ConRecord.OwnerId);
            
                  
            LeadContainer.add(LeadRecord);
            ConContainer.add(ConRecord);            
        }        
        Insert LeadContainer;
        /*
        PDG_Routing_Class.is_First = true;
        multi_Interaction_logic.is_First = true;
        Insert ConContainer;
        PDG_Routing_Class.is_First = true;
        multi_Interaction_logic.is_First = true;
       */
    }
    
    @isTest static void Route_Lead(){
        profile p = [Select id from profile where name = 'System Administrator' limit 1];
        User EloquaUser = [Select id from User where profileId =: p.id and isActive = true Limit 1];
         System.runAs(EloquaUser) {
        List <Lead> Container = new List <Lead>();
        List <Contact> ConContainer = new List <Contact>();
        
        List <id> Container_Test = new List <id>();
        List <id> Container_Test2 = new List <id>();
        
        
       /*  map <id, Lead> LeadMap =  new map <id, Lead>([
            Select Id,FirstName,ManagerEmail__c,LQS_Water__c,LQS_Strategic_Services__c,LQS_Soil_Solids__c,LQS_QA_QC_Drug_Manufacturing_Process__c,LQS_Pre_Clinical_Studies__c,LQS_Newborn_Screening__c,LQS_Maternal_Fetal_Health__c,LQS_Material__c,LQS_Geochemistry_Mining_and_Metals__c,LQS_Forensics_and_Security__c,LQS_Food_Safety__c,LQS_Food_Quality__c,LQS_Energy__c,LQS_Drug_Discovery__c,LQS_Disease_Research__c, LQS_Digital_Lab__c,LQS_Clinical_Studies__c,LQS_Chemicals__c,LQS_Applied_Genomics__c,LQS_Air__c, Description, Qualified_Lead_Warm_Date__c, Status_Chemicals__c, Qualified_Lead_Hot_Date__c, BE__c, Title, Email, Name, Ownerid, Country, Solution_Area_Of_Interest__c From Lead Where Title like '%Unit%' ORDER BY Title]);   
        */
        
        map <id, Lead> LeadMap =  new map <id, Lead>([
            Select Id,FirstName,LQS_Water__c,LQS_Strategic_Services__c,LQS_Soil_Solids__c,LQS_QA_QC_Drug_Manufacturing_Process__c,LQS_Pre_Clinical_Studies__c,LQS_Newborn_Screening__c,LQS_Maternal_Fetal_Health__c,LQS_Material__c,LQS_Geochemistry_Mining_and_Metals__c,LQS_Forensics_and_Security__c,LQS_Food_Safety__c,LQS_Food_Quality__c,LQS_Energy__c,LQS_Drug_Discovery__c,LQS_Disease_Research__c, LQS_Digital_Lab__c,LQS_Clinical_Studies__c,LQS_Chemicals__c,LQS_Applied_Genomics__c,LQS_Air__c, Description, Qualified_Lead_Warm_Date__c, Status_Chemicals__c, Qualified_Lead_Hot_Date__c, BE__c, Title, Email, Name, Ownerid, Country, Solution_Area_Of_Interest__c From Lead Where Title like '%Unit%' ORDER BY Title]);   
        
        map <id, Contact> ConMap =  new map <id, Contact>([
            Select Id,FirstName,LQS_Water__c,LQS_Strategic_Services__c,LQS_Soil_Solids__c,LQS_QA_QC_Drug_Manufacturing_Process__c,LQS_Pre_Clinical_Studies__c,LQS_Newborn_Screening__c,LQS_Maternal_Fetal_Health__c,LQS_Material__c,LQS_Geochemistry_Mining_and_Metals__c,LQS_Forensics_and_Security__c,LQS_Food_Safety__c,LQS_Food_Quality__c,LQS_Energy__c,LQS_Drug_Discovery__c,LQS_Disease_Research__c, LQS_Digital_Lab__c,LQS_Clinical_Studies__c,LQS_Chemicals__c,LQS_Applied_Genomics__c,LQS_Air__c, Converted_QL__c,ConvertedRecordId__c, Description, Qualified_Lead_Warm_Date__c, Status_Chemicals__c, Qualified_Lead_Hot_Date__c, BU__c, Title, Email, Name, Ownerid, Country__c, Solution_Area_Of_Interest__c From Contact Where Title like '%Unit%' ORDER BY Title]);   
        
        
        for(Lead Record : LeadMap.values()){
            if(Record.title == 'UnitTest0'){
                Record.LQS_Air__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest1'){
                Record.LQS_Applied_Genomics__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest2'){
                Record.LQS_Chemicals__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest3'){
                Record.LQS_Clinical_Studies__c= 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest4'){
                Record.LQS_Digital_Lab__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest5'){
                Record.LQS_Disease_Research__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest6'){
                Record.LQS_Drug_Discovery__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest7'){
                Record.LQS_Energy__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest8'){
                Record.LQS_Food_Quality__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest9'){
                Record.LQS_Food_Safety__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest10'){
                Record.LQS_Forensics_and_Security__c = 'Qualified Lead - Warm';
            } 
            if(Record.title == 'UnitTest11'){
                Record.LQS_Geochemistry_Mining_and_Metals__c = 'Qualified Lead - Warm';
            } 
            if(Record.title == 'UnitTest12'){
                Record.LQS_Material__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest13'){
                Record.LQS_Maternal_Fetal_Health__c = 'Qualified Lead - Warm';
            } 
            if(Record.title == 'UnitTest14'){
                Record.LQS_Newborn_Screening__c = 'Qualified Lead - Warm';

            }
            if(Record.title == 'UnitTest15'){
               Record.LQS_Pre_Clinical_Studies__c = 'Qualified Lead - Warm';

            } 
            if(Record.title == 'UnitTest16'){
               Record.LQS_QA_QC_Drug_Manufacturing_Process__c = 'Qualified Lead - Warm';

            }  
            if(Record.title == 'UnitTest17'){
               Record.LQS_Soil_Solids__c = 'Qualified Lead - Warm';

            }  
            if(Record.title == 'UnitTest18'){
               Record.LQS_Strategic_Services__c = 'Qualified Lead - Warm';

            }  
            if(Record.title == 'UnitTest19'){
               Record.LQS_Water__c = 'Qualified Lead - Warm';

            }  
            
            Container.add(Record);
            Container_Test.add(Record.id);    
        }
        
        for(Contact Record : ConMap.values()){
            if(Record.title == 'UnitTest0'){
                Record.LQS_Air__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest1'){
                Record.LQS_Applied_Genomics__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest2'){
                Record.LQS_Chemicals__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest3'){
                Record.LQS_Clinical_Studies__c= 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest4'){
                Record.LQS_Digital_Lab__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest5'){
                Record.LQS_Disease_Research__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest6'){
                Record.LQS_Drug_Discovery__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest7'){
                Record.LQS_Energy__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest8'){
                Record.LQS_Food_Quality__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest9'){
                Record.LQS_Food_Safety__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest10'){
                Record.LQS_Forensics_and_Security__c = 'Qualified Lead - Warm';
            } 
            if(Record.title == 'UnitTest11'){
                Record.LQS_Geochemistry_Mining_and_Metals__c = 'Qualified Lead - Warm';
            } 
            if(Record.title == 'UnitTest12'){
                Record.LQS_Material__c = 'Qualified Lead - Warm';
            }
            if(Record.title == 'UnitTest13'){
                Record.LQS_Maternal_Fetal_Health__c = 'Qualified Lead - Warm';
            } 
            if(Record.title == 'UnitTest14'){
                Record.LQS_Newborn_Screening__c = 'Qualified Lead - Warm';

            }
            if(Record.title == 'UnitTest15'){
               Record.LQS_Pre_Clinical_Studies__c = 'Qualified Lead - Warm';

            } 
            if(Record.title == 'UnitTest16'){
               Record.LQS_QA_QC_Drug_Manufacturing_Process__c = 'Qualified Lead - Warm';

            }  
            if(Record.title == 'UnitTest17'){
               Record.LQS_Soil_Solids__c = 'Qualified Lead - Warm';

            }  
            if(Record.title == 'UnitTest18'){
               Record.LQS_Strategic_Services__c = 'Qualified Lead - Warm';

            }  
            if(Record.title == 'UnitTest19'){
               Record.LQS_Water__c = 'Qualified Lead - Warm';

            }                 
            
            ConContainer.add(Record);
            Container_Test2.add(Record.id);    
        }


        update Container; 
        //PDG_Routing_Class.is_First = true;
        //multi_Interaction_logic.is_First = true;

        update ConContainer; 
		//PDG_Routing_Class.is_First = true;
        //multi_Interaction_logic.is_First = true; 
         }
    }
     
}