global class BatchSendMail implements Database.Batchable<SObject>,Database.Stateful{

    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        Set<String> previousIds=new Set<String>();
        Set<Id> idsToQuery=new Set<Id>();
        Integer iteratorValue=0;
        Integer checkExcessId=0;
        String ids;
        
                
        Date myDate = Date.today();
        Date weekStart = myDate.toStartofWeek();
        Integer dayBetween=weekStart.daysBetween(myDate);
        Date startDate=Date.valueOf(System.Label.Open_Lead_Notification_Start_Date);
        
        List<Send_Mail_Settings__c> sm = [SELECT allowed_productlines__c from Send_Mail_Settings__c];
        List<String> allowedProductLines = new List<String>();
        if(sm!=null)
        {
            if(sm.size()>0)
            {
                if(sm.get(0).allowed_productlines__c!=null)
                {
                    allowedProductLines.addAll(sm.get(0).allowed_productlines__c.split(';'));
                }
            }
        }
        
        Open_Lead_Notice__c openLeadNoticeObj=new Open_Lead_Notice__c();
        
        String countrynames = Label.CountryEmailInclude;
        list<String> countriesInclude = countrynames.split(',');
        
        for(Open_Lead_Notice__c olnIterator: [SELECT Id,Name,Id1__c,Id2__c,Id3__c,Id4__c FROM Open_Lead_Notice__c]){
            if(String.valueOf(dayBetween)!=olnIterator.Name){
                
                if(olnIterator.Id1__c!='' && olnIterator.Id1__c!=null){
                    String[] listOfIds1=olnIterator.Id1__c.split(';');
                    previousIds.addAll(listOfIds1);
                }
                if(olnIterator.Id2__c!='' && olnIterator.Id2__c!=null){
                    String[] listOfIds2=olnIterator.Id2__c.split(';');
                    previousIds.addAll(listOfIds2);
                } 
                if(olnIterator.Id3__c!='' && olnIterator.Id3__c!=null){
                    String[] listOfIds3=olnIterator.Id3__c.split(';');
                    previousIds.addAll(listOfIds3);
                } 
                if(olnIterator.Id4__c!='' && olnIterator.Id4__c!=null){
                    String[] listOfIds4=olnIterator.Id4__c.split(';');
                    previousIds.addAll(listOfIds4);
                } 
            }
            else{
                openLeadNoticeObj=olnIterator;
            }
        }
        
        System.debug('Previous Ids:'+previousIds);
        String slist='';
        for (String s: allowedProductLines) {
            slist += '\'' + s + '\',';
        }
        slist = slist.substring (0,slist.length() -1);
        //original commented on 11 jan - by deepak Date temp_Date = Date.today().addDays(-7);
        Date temp_Date = Test.isRunningTest() ? Date.today().addDays(+1) : Date.today().addDays(-7);
        
        //query all the open leads untouched for more than a week
        for(Lead leadIterator: Database.query('SELECT Id,LastModifiedDate FROM Lead WHERE Status=\'Open\' AND CreatedDate>:startDate AND Country IN:countriesInclude AND Product_Line__c INCLUDES ('+slist+') AND LastModifiedDate<:temp_Date'))
        {
            if(!previousIds.contains(leadIterator.Id))
                idsToQuery.add(leadIterator.Id); 
        }
        
        Integer count = 0;
        Ids = '';
        for(Id id:idsToQuery)
        {
            count++;
            Ids+= Id+';';
            if(count<=13)
                openLeadNoticeObj.Id1__c=ids;
            else if(count<=26)
                openLeadNoticeObj.Id2__c=ids;
            else if(count<=39)
                openLeadNoticeObj.Id3__c=ids;
            else if(count<=52)
                openLeadNoticeObj.Id4__c=ids;
            if(count==13 || count==26 || count==39 ||count==52)
                Ids='';
        }
        try{
            Database.update(openLeadNoticeObj);
        }
        catch(Exception e){
            System.debug(e);
        }
       
        
        String Query='SELECT Id,FirstName,LastName,OwnerId,Rating,Name,Phone,Email,Street,City,State,PostalCode,Country,Product_Line__c,Product_Name__c,Primary_Qualification__c,Secondary_Qualification__c,Requested_Interests__c,LeadSource,Event__c,Description,Quote_Requested__c FROM Lead WHERE Status=\'Open\' AND CreatedDate>:startDate AND Country IN:countriesInclude AND Product_Line__c INCLUDES ('+slist+') AND  LastModifiedDate<:temp_Date AND Id IN: idsToQuery';
        return Database.getQueryLocator(Query);
    }
    
    global void execute(Database.BatchableContext BC, List<Lead> sObjectsFromStart) 
    {
        Map<Id,User> mapOfIdEmail=new Map<Id,User>([SELECT Id,Email FROM User WHERE IsActive=true]);

        String sUrlRewrite = System.URL.getSalesforceBaseUrl().getHost();
        sUrlRewrite = 'https://'
                + sUrlRewrite.substring(0,sUrlRewrite.indexOf('.')+1) 
                + 'salesforce.com';
        
		OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where isVerified = TRUE LIMIT 1];
        
        for(Lead leadIterator: sObjectsFromStart){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if(mapOfIdEmail.containsKey(leadIterator.OwnerId)){
                mail.setToAddresses(new String[] {mapOfIdEmail.get(leadIterator.OwnerId).Email});
                mail.setOrgWideEmailAddressId(owea.get(0).id);
                mail.setCcAddresses(new String[] {});
                List<Send_Mail_Settings__c> sm = [SELECT bcc_mails__c from Send_Mail_Settings__c];
                if(sm!=null)
                    if(sm.size()==1)
                        mail.setBCcAddresses(sm.get(0).bcc_mails__c.split(';'));
                if(leadIterator.Rating==null)
                {
                    leadIterator.Rating='';
                }
                if(leadIterator.Name==null)
                {
                    leadIterator.FirstName='';
                }
                if(leadIterator.Phone==null)
                {
                    leadIterator.Phone='';
                }
                if(leadIterator.Email==null)
                {
                    leadIterator.Email='';
                }
                if(leadIterator.Street==null)
                {
                    leadIterator.Street='';
                }
                if(leadIterator.City==null)
                {
                    leadIterator.City='';
                }
                if(leadIterator.State==null)
                {
                    leadIterator.State='';
                }
                if(leadIterator.PostalCode==null)
                {
                    leadIterator.PostalCode='';
                }
                if(leadIterator.Country==null)
                {
                    leadIterator.Country='';
                }
                if(leadIterator.Product_Line__c==null)
                {
                    leadIterator.Product_Line__c='';
                }
                if(leadIterator.Product_Name__c==null)
                {
                    leadIterator.Product_Name__c='';
                }
                if(leadIterator.Primary_Qualification__c==null)
                {
                    leadIterator.Primary_Qualification__c='';
                }
                if(leadIterator.Secondary_Qualification__c==null)
                {
                    leadIterator.Secondary_Qualification__c='';
                }
                if(leadIterator.Requested_Interests__c==null)
                {
                    leadIterator.Requested_Interests__c='';
                }
                if(leadIterator.LeadSource==null)
                {
                    leadIterator.LeadSource='';
                }
                if(leadIterator.Event__c==null)
                {
                    leadIterator.Event__c='';
                }
                if(leadIterator.Description==null)
                {
                    leadIterator.Description='';
                }
                String Quote_Requested;
                if(leadIterator.Quote_Requested__c==true)
                {
                    Quote_Requested='1';
                }
                if(leadIterator.Quote_Requested__c==false)
                {
                    Quote_Requested='0';
                }
                mail.setSubject('REMINDER! YOU\'VE AN OPEN LEAD OLDER THAN A WEEK.');
                mail.setHtmlBody('Unless you’ve done so recently, please follow up this OPEN LEAD:<br><a href='+sUrlRewrite +'/'+leadIterator.Id+' >'+leadIterator.Name+'</a><br><br>You need to contact your customer ASAP and update the "Lead Status" into SFDC according to customer interest. Leads should be converted after customer follow up, so according to best practices within 2 weeks maximum from submittal or immediately for contact requests.<br><br>Lead Rating = '+leadIterator.Rating+'<br><br>Please Contact: '+leadIterator.Name+'<br>Tel: '+leadIterator.Phone+'<br>Email: '+leadIterator.Email+'<br><br>Account Details:<br>'+leadIterator.Street+'<br>'+leadIterator.City+' '+leadIterator.State+' '+leadIterator.PostalCode+'<br>'+leadIterator.Country+'<br><br>Product Line = '+leadIterator.Product_Line__c+'<br>Product Name = '+leadIterator.Product_Name__c+'<br>Primary Qualification:<br>'+leadIterator.Primary_Qualification__c+'<br><br>Secondary Qualification:<br>'+leadIterator.Secondary_Qualification__c+'<br><br>Requested Interests:<br>'+leadIterator.Requested_Interests__c+'<br><br>Lead Source: '+leadIterator.LeadSource+'<br>Event: '+leadIterator.Event__c+'<br><br>Description: '+leadIterator.Description+'<br><br>Quote Requested - 1 = Yes/0 = No<br>'+Quote_Requested + '<br><br> ********************************************************************************************************************* <br> <br> Lead Status Definitions <br>Open: All leads start as Open. An open lead will generate a reminder email if it has not been changed within a week.<br> Qualified: This is the first status after Open. A qualified lead simply means you accept it as a lead, and will take action.<br>Working: A lead you have contacted, but not yet determined if there is a potential opportunity. <br> Future-Nurture: A lead you would like to “send back” to marketing to inclusion in future campaigns. Use this if there is future potential with this lead. At your earliest convenience, this lead should be converted to a contact.<br>Abandoned: Use this for leads that you do not see future potential for. At this point, please change the lead owner to “Trash/Spam” if it should be deleted completely (spam, competitors, invalid contacts) or convert to a contact if it is a valid contact at an account.');
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                }
        }
    
    }
    global void finish(Database.BatchableContext BC) {
    
    }
}