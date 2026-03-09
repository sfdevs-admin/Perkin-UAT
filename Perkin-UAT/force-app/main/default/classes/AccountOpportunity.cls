global class AccountOpportunity
{      
    webservice static LIST<Opportunity> getAccOppDetails(string accountName)  
        {  
            LIST<Opportunity> lstOpportunities;
            string accName =  accountName + '%'; 
            lstOpportunities = [SELECT Id,StageName,Probability,Name,AccountId,Primary_Contact__r.FirstName,Primary_Contact__r.LastName,Primary_Contact__r.Email,Primary_Contact__r.name,Primary_Contact__r.Phone,Primary_Contact__r.MailingStreet,Primary_Contact__r.MailingCity,Primary_Contact__r.MailingState,Primary_Contact__r.MailingPostalCode,Primary_Contact__r.MailingCountry,opportunity.account.name,GP_OrderNum_INF__c,Primary_Contact__c,opportunity.owner.name,opportunity.owner.email,opportunity.owner.firstname,opportunity.owner.lastname FROM Opportunity where RecordTypeId =: Utility_Informatics.opportunity_Informatics AND opportunity.account.name LIKE :accName ORDER BY Name DESC LIMIT 50];
            return lstOpportunities;
        }
        
        webservice static Opportunity getAccOppDetailsByOrderNum(string orderNumber)  
        {  
            Opportunity oppdetails;
            
            oppdetails = [SELECT Id,StageName,Probability,Name,AccountId,Primary_Contact__r.FirstName,Primary_Contact__r.LastName,Primary_Contact__r.Email,Primary_Contact__r.name,Primary_Contact__r.Phone,Primary_Contact__r.MailingStreet,Primary_Contact__r.MailingCity,Primary_Contact__r.MailingState,Primary_Contact__r.MailingPostalCode,Primary_Contact__r.MailingCountry,opportunity.account.name,GP_OrderNum_INF__c,Primary_Contact__c,opportunity.owner.name,opportunity.owner.email,opportunity.owner.firstname,opportunity.owner.lastname FROM Opportunity where RecordTypeId =: Utility_Informatics.opportunity_Informatics AND GP_OrderNum_INF__c =:orderNumber AND StageName = 'Closed Won' ORDER BY Name DESC LIMIT 1];
            return oppdetails;
        }
        
        webservice static boolean UpdateOrderNumber(Opportunity opp)  
        {  
            for(Opportunity o : [Select Id,Probability,GP_OrderNum_INF__c From Opportunity o where Id =: opp.Id])
            {
                o.GP_OrderNum_INF__c =opp.GP_OrderNum_INF__c;
                o.Probability = opp.Probability;
                update o;
                
            }
           return true;
        }
        
}