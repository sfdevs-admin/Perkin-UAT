@isTest(SeeAllData=true)
private class Lead_Methods_Test {
    
    @isTest static void testContructor()
    {
        List<Lead> listLeads = new List<Lead>();
        List<Lead> listupdateLeads = new List <Lead>();
        List<User> UserContainer = new List <User>();
        
        for(integer i=0; i<=8; i++){
            User al = new User(FirstName = 'aUser'+i,
                               Username = 'testxuser'+i+'@test.com', 
                               LastName = 'Test', 
                               Email = 'auser'+i+'@test.com', 
                               Alias = 'auser'+i+'@', 
                               CommunityNickname = 'user'+i+'@', 
                               TimeZoneSidKey = 'America/New_York',
                               LocaleSidKey = 'en_US',
                               EmailEncodingKey = 'ISO-8859-1',             
                               ProfileId = [Select id from Profile where name = 'System administrator' limit 1].id, 
                               LanguageLocaleKey = 'en_US');
            UserContainer.add(al);
        }
        insert UserContainer;
        
        
        for(integer i=0; i<=10; i++){
            Lead LeadRecord = new Lead();
            LeadRecord.FirstName = 'TestUser: '+i;
            LeadRecord.LastName  = 'Class: '+i;
            LeadRecord.Title     =  'UnitTest'+i;
            LeadRecord.Street = '225 Blvd';
            LeadRecord.City  = 'Montgomery';                
            LeadRecord.Status = 'Open';
            LeadRecord.Country = 'US';  
            LeadRecord.Company = 'Test';
            
            if(i == 0){
                LeadRecord.Email = 'usertest-class-'+i+'@test.com';
                LeadRecord.BE__c = 'Dx';
            }
            else if(i == 1){
                LeadRecord.Email = 'usertest-class-'+i+'@test.com';
                LeadRecord.Solution_Area_of_Interest__c = 'Applied Genomics';
                LeadRecord.Topic_INF__c = '12345';
                LeadRecord.BusinessLine_INF__c = 'Personal Applications';
                LeadRecord.Product_Interest_INF__c = 'Signals';
                LeadRecord.Product_Family_INF__c = 'ChemOffice';
                LeadRecord.RecordTypeId = Utility_Informatics.lead_Informatics;
            }
            else if(i==2){
                LeadRecord.Email = 'usertest-class-'+i+'@test.com';
                LeadRecord.GBL_GBL_Eloqua_Owner__c = UserContainer[1].id;
            }
            else if(i == 3){
                LeadRecord.Email = 'usertest-class-'+i+'@test.com';
                LeadRecord.Employee_Email__c  = 'usertest-class-'+i+'@test.com';
                LeadRecord.Product_Line__c='BTX';
                LeadRecord.PostalCode='12345';
            }
            else if(i>=4){
                LeadRecord.Email = 'usertest-class-'+i+'@test.com';
                LeadRecord.BE__c = 'Dx';
            }
            listLeads.add(LeadRecord);
        }        
        
        test.startTest();
        insert listLeads;
        test.stopTest();
        
        for (Lead l: listLeads)
        {
            if(l.BE__c=='Dx'){
                l.OwnerId=UserContainer[0].id;
                l.Lead_Assignment__c = false;
                l.Lead_Auto_Assign__c = false;
                l.GBL_GBL_Eloqua_Owner__c = null;
                l.Non_Qualified__c=true;
                listUpdateLeads.add(l);
            }
        }
        
        Utility_Recursive_Check.run = true;
        update listUpdateLeads;
        listUpdateLeads.clear();
    }
}