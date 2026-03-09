//Description - Send an Email notification to th customer for b2b subscription before 7 days the order is placed.
//Test class - B2BSubscriptionReminderEmailTest
public class B2BSubscriptionReminderEmail  implements Database.Batchable<sObject>,Schedulable{
    Set<Id> b2bSubscriptionIdSet = new Set<Id>();
    
    String query = '';
    public B2BSubscriptionReminderEmail(){}
    public B2BSubscriptionReminderEmail(String queryVal){
        this.query = queryVal;
    }
    public B2BSubscriptionReminderEmail(Set<Id> b2bSubscriptionIdSetVal){
        this.b2bSubscriptionIdSet = b2bSubscriptionIdSetVal;
    }
    //Schedule 's Execute method to call batch
    public void execute(SchedulableContext sc){
        //new B2BSubscriptionReminderEmail()
        Database.executeBatch(this,Integer.valueOf(Label.SubscriptionBatchSize));
    }
    
    /* Start of batch */
    public Iterable<sObject> start(Database.BatchableContext bc){
        Date nextBillingDate = System.today().addDays(Integer.valueOf(Label.ReminderDays));
        List<B2B_Subscriptions__c> b2bSubscriptionList = new List<B2B_Subscriptions__c>();
        // collect the batches of records or objects to be passed to execute
        // 00Xbc000001JimLEAS
        
        if(String.isBlank(query)){
            String baseQuery = 'SELECT Id,Subscription_Name__c,B2B_Status__c,B2B_Total_Amount__c,CurrencyIsoCode,'+
                'B2B_Next_Billing_Date__c,B2B_Contact__r.FirstName,B2B_Contact__r.LastName,'+
                'B2B_Contact__r.Email,(SELECT Id,B2B_Product__r.Name,'+
                'B2B_Product__r.B2B_Part_Number__c,B2B_Unit_Price__c, B2B_Quantity__c,B2B_Total_Price__c,CurrencyIsoCode FROM B2B_Subscription_Items__r)'+
                'FROM B2B_Subscriptions__c ';
            String whereClause = !b2bSubscriptionIdSet.isEmpty() ? ' WHERE Id IN: b2bSubscriptionIdSet ' :
            'WHERE B2B_Next_Billing_Date__c  =: nextBillingDate AND B2B_Contact__r.Email != null AND B2B_Status__c = \'Active\'';
            query = baseQuery + whereClause;
            
        }
        return Database.getQueryLocator(query);
    }
    
    /* Execute of batch */
    public void execute(Database.BatchableContext bc, List<B2B_Subscriptions__c> records){
        //try-catch
        try{
            processRecords(records);
        }catch(Exception e){
            Custom_Exception__c exc = new Custom_Exception__c();
            exc.Name = 'B2BSubscriptionReminderEmail Exceptions';
            exc.Exception_Messages__c =  e.getMessage();
            exc.Exception_Type__c = e.getTypeName();
            insert exc;
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
    
    private static void processRecords(List<B2B_Subscriptions__c> records){
        
        EmailTemplate emailtemplate = [SELECT Id,HTMLValue,Subject
                                       FROM EMailTemplate
                                       WHERE DeveloperName = 'B2B_Subscription_Reminder_Email'];
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<OrgWideEmailAddress> orgWideEmailAddressList = [SELECT Id FROM OrgWideEmailAddress 
                                                             WHERE Address =: Label.SupportAdminEmailAddress];
        if(emailtemplate != null){
            //sunscriptionDetails
            for(B2B_Subscriptions__c subscription : records){
                //construct html
                String htmlValue = emailtemplate.htmlValue;
                htmlValue = htmlValue.replace('{LogoUrl}',Label.PerkinElmer_Logo_Url);
                htmlValue = htmlValue.replace('{B2B_PerkinElmer}',Label.B2B_PerkinElmer);
                htmlValue = htmlValue.replace('{sunscriptionDetails}',B2BSubscriptionHtmlGenerator.getSubscriptionDetails(subscription));
                htmlValue = htmlValue.replace('{summaryTable}',B2BSubscriptionHtmlGenerator.getSummary(subscription));
                String itemHtml = '';
                
                //iterate on lineitems
                for(B2B_Subscription_Items__c subscriptionItem : subscription.B2B_Subscription_Items__r){
                    itemHtml += B2BSubscriptionHtmlGenerator.getItemRow(subscriptionItem);
                }
                htmlValue = htmlValue.replace('{table}',itemHtml);
                
                //prepare mail instance
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();            
                mail.setHtmlBody(htmlValue);
                mail.setSubject(emailtemplate.Subject);
                if(!orgWideEmailAddressList.isEmpty()){
                    mail.setOrgWideEmailAddressId(orgWideEmailAddressList[0].Id);
                }
                mail.setToAddresses(new List<String>{subscription.B2B_Contact__r.Email});            
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