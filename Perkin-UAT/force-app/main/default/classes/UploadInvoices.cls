global class UploadInvoices
{  
    WebService static String GetOpportunityId(string OrderNum)  
    {  
      string Id='';
      string INFOrderNum = '%' + OrderNum + '%'; 
      List<Opportunity> opp=[select id,GP_OrderNum_INF__c from opportunity where GP_OrderNum_INF__c LIKE :INFOrderNum AND stageName = 'Closed Won']; 
      
      if(opp != null && opp.size() > 0)
      {
          Id = string.valueof(opp[0].id); 
      }
      return Id; 
    }
    
    WebService static String IsAttachmentExists(string fileName,string oppId)  
    {  
      string attId='';
      LIST<Attachment> lstAttachments =[SELECT id FROM Attachment WHERE parent.id =:oppId AND Name =:fileName]; 
      
      if(lstAttachments != null && lstAttachments.size() > 0)
      {
          attId = string.valueof(lstAttachments[0].id); 
      }
      return attId; 
    }

   WebService static string CreateAttachment(string OppId,Blob body,integer Size,string filename,string mimetype)  
    {  
       Attachment attach = new Attachment();    
        // add the user entered name
       attach.Name = filename;
       attach.ContentType = mimetype;
       attach.Body = body;
        // attach the pdf to the opportunity
       attach.ParentId = OppId;
       insert attach;
       string id = attach.id;
       return id;
    }
}