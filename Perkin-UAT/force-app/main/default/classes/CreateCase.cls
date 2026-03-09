global class CreateCase{

  WebService static Id createcaserecord(Id Taskid) {   
      Task t = [select Id,Description,Type,Status,Whatid,Whoid,Subject,Ownerid,priority,account.name from Task t where Id =: Taskid]; 
      Contact c = [select email,phone,Id from contact  where id =:t.Whoid limit 1];
      Case casetoinsert = new Case(Subject = t.Subject,Origin='Phone',Status='New',Type = 'Email',
                               Contactid = c.id,
                               Ownerid = t.Ownerid,
                               priority='Medium',Description = t.Description,
                               RecordTypeId=Utility_Informatics.case_Informatics);   
    insert casetoinsert;
    Task tasktoupdate = new Task(Id = Taskid,Whatid = casetoinsert.id); 
    update tasktoupdate;
    return casetoinsert.id;
  } 
  
  
  WebService static Id createleadrecord(Id Caseid) { 
  
    Case caset = [select Id,Status,OwnerId,Contact.FirstName,Contact.Name,Contact.Lastname,Account.Name,
                         Contact.Phone,Contact.Email,RecordTypeId,Account.ShippingStreet,Account.ShippingCity,
                         Account.ShippingPostalCode,Account.ShippingState,Account.ShippingCountry,description
                from Case where Id =: Caseid and RecordTypeId=:Utility_Informatics.case_Informatics]; 
                
    List<INF_Case_Application__c> lapps = [Select Id,INF_Application_Name__c,INF_Application_Product_Line__c,INF_Business_Line__c
                                                  From INF_Case_Application__c where case__c =: Caseid];
                                                  
    String prdln='',prdfl='',bu='';
    for(INF_Case_Application__c a: lapps) {
        if(a.INF_Application_Product_Line__c != null && !prdln.contains(a.INF_Application_Product_Line__c ))
            prdln= a.INF_Application_Product_Line__c + ';'+ prdln;
        if(a.INF_Application_Name__c != null && !prdfl.contains(a.INF_Application_Name__c))
            prdfl = a.INF_Application_Name__c + ';' + prdfl;
        if(a.INF_Business_Line__c!= null && !bu.contains(a.INF_Business_Line__c))
            bu=a.INF_Business_Line__c + ';' + prdfl;
    }                                       
                
    Lead leadtoinsert = new Lead(FirstName=caset.Contact.FirstName,Lastname=caset.Contact.Lastname,Status = 'Open', 
                                 Company=caset.Account.Name,MobilePhone=caset.Contact.Phone,email=caset.Contact.Email,
                                 LeadSource='Customer Care',BE__c='INF',Lead_Type_INF__c='Other',
                                 Product_Line__c=prdln,
                                 Product_Family_INF__c=prdfl,
                                 BusinessLine_INF__c=bu,
                                 Street=caset.Account.ShippingStreet,
                                 City=caset.Account.ShippingCity,
                                 Postalcode = caset.Account.ShippingPostalCode,
                                 State = caset.Account.ShippingState,
                                 Country = caset.Account.ShippingCountry,
                                 Title = 'Customer Service Lead for'+ caset.Contact.Name,INF_Related_case__c = caset.id,
                                 Description=caset.description,RecordTypeId=Utility_Informatics.lead_Informatics);
                                 
      insert leadtoinsert;
      
      Case casetoupdate = new Case (Id=Caseid,Status='Closed',INF_Categories__c='Sales Lead',INF_Send_Survey__c=False); 
      update casetoupdate;
      
      return leadtoinsert.id;
  }
}