//Test class - B2B_CartNotificationTest
public with sharing class B2B_CartNotification implements Database.Batchable<sObject>,Schedulable{
    Set<Id> cartIdSet = new Set<Id>();
    Integer daysAfter = Integer.valueOf(Label.CartReminder);
    
    String query = '';
    public B2B_CartNotification(){}
    public B2B_CartNotification(String queryVal){
        this.query = queryVal;
    }
    public B2B_CartNotification(Set<Id> cartIdSetVal){
        this.cartIdSet = cartIdSetVal;
    }
    public B2B_CartNotification(String queryVal,Set<Id> cartIdSetVal,Integer daysAfter){
        this.query = queryVal;
        this.cartIdSet = cartIdSetVal;
        if(daysAfter != null){
            this.daysAfter = daysAfter;
        }
    }
    //Schedule 's Execute method to call batch
    public void execute(SchedulableContext sc){
        //new B2B_CartNotification()
        Database.executeBatch(this,Integer.valueOf(Label.CartNotificationBatchSize));
    }
    
    /* Start of batch */
    public Iterable<sObject> start(Database.BatchableContext bc){
        List<String> statusList = new List<string>{'Active','Checkout'};
            system.debug('daysAfter '+daysAfter);
        Date lastModified = System.today().addDays(daysAfter); 
        if(String.isBlank(query)){
            String baseQuery = 'SELECT Id,Owner.FirstName,Owner.LastName,TotalProductAmount, '+
                ' Owner.Email,GrandTotalAmount,Currencyisocode,TotalTaxAmount,TotalChargeAmount,'+
                ' (SELECT Id,Product2.Name,Product2.B2B_Part_Number__c,Quantity,'+
                'SalesPrice,TotalPrice,Currencyisocode FROM CartItems WHERE TYPE != \'Charge\') FROM WebCart ';
            String whereClause = !cartIdSet.isEmpty() ? ' WHERE Id IN: cartIdSet' :
            'WHERE Day_ONLY(LastModifiedDate) =: lastModified '+
                ' and createdby.isportalenabled = true and Status IN: statusList AND UniqueProductCount > 0';
            query = baseQuery + whereClause;
            
        }
        return Database.getQueryLocator(query);
    }
    
    /* Execute of batch */
    public void execute(Database.BatchableContext bc, List<WebCart> records){
        //try-catch
        try{
            processRecords(records);
        }catch(Exception e){
            system.debug('e '+e.getMessage());
            Custom_Exception__c exc = new Custom_Exception__c();
            exc.Name = 'B2B_CartNotification Exceptions';
            exc.Exception_Messages__c =  e.getMessage();
            exc.Exception_Type__c = e.getTypeName();
            insert exc;
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
    
    public static void processRecords(List<WebCart> records){
        EmailTemplate emailtemplate = [SELECT Id,HTMLValue,Subject
                                       FROM EMailTemplate
                                       WHERE DeveloperName =: Label.AbandonedCartNotification];
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<OrgWideEmailAddress> orgWideEmailAddressList = [SELECT Id FROM OrgWideEmailAddress 
                                                             WHERE Address =: Label.SupportAdminEmailAddress];
        if(emailtemplate != null){
            //sunscriptionDetails
            for(WebCart cart : records){
                //construct html
                String htmlValue = emailtemplate.htmlValue;
                htmlValue = htmlValue.replace('{LogoUrl}',Label.PerkinElmer_Logo_Url);
                htmlValue = htmlValue.replace('{B2B_PerkinElmer}',Label.B2B_PerkinElmer);
                htmlValue = htmlValue.replace('{recipientName}',cart.Owner.FirstName+' '+ cart.Owner.LastName);
                htmlValue = htmlValue.replace('{cartUrl}',Label.CartUrl);
                
                //htmlValue = htmlValue.replace('{summaryTable}',B2B_CartNotificationHtmlGenerator.getSummary(cart));
                String itemHtml = '';
                
                //iterate on lineitems
                for(CartItem cartItem : cart.cartItems){
                    itemHtml += B2B_CartNotificationHtmlGenerator.getItemRow(cartItem);
                }
                htmlValue = htmlValue.replace('{table}',itemHtml);
                
                //prepare mail instance
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();            
                mail.setHtmlBody(htmlValue);
                mail.setSubject(emailtemplate.Subject);
                if(!orgWideEmailAddressList.isEmpty()){
                    mail.setOrgWideEmailAddressId(orgWideEmailAddressList[0].Id);
                }
                mail.setToAddresses(new List<String>{cart.Owner.Email});            
                emailList.add(mail);
                
                
            }
            if (!emailList.isEmpty()){
                //send mails
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList, false);
                System.debug('results ::' + results);
                for (Messaging.SendEmailResult result : results){
                    if (!result.isSuccess()){
                        system.debug('result ' + result);
                    }
                }
            }
            
        }
    }
    
    
}