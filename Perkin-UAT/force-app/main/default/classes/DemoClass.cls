global class DemoClass  
{  
    webservice static LIST<Opportunity> getAttachments()  
    {  
    LIST<Opportunity> lstAttachments;
        lstAttachments = [SELECT Project_ID_INF__c,(SELECT Id FROM Attachments) FROM Opportunity where Project_ID_INF__c != ''];
        return lstAttachments;
    }  
    
     webservice static LIST<Attachment> getOppAttachments(string attid)  
    {  
    LIST<Attachment> lstAttachments;
        lstAttachments = [SELECT Id,Name,ContentType,Body,BodyLength,parent.type FROM Attachment WHERE Id =:attid];
        return lstAttachments;
    }  

}