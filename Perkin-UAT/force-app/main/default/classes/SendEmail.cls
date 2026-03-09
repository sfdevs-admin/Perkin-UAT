public class SendEmail {
    
        public String body {get;set;}
        public String subject {get;set;}
        public String text2 {get;set;}
        private final Opportunity MyLead;
    public String theId{get;set;}
    public SendEmail(ApexPages.StandardController controller)
    {
    
        text2 = ApexPages.currentPage().getParameters().get('oopOwner');
        body= ApexPages.currentPage().getParameters().get('body');

        this.MyLead=(Opportunity)controller.getRecord();
    } 
   
             
    public void send() {
         theId = ApexPages.currentPage().getParameters().get('oppId');
    String theOwner = ApexPages.currentPage().getParameters().get('oopOwner');

   //create a mail object to send email 


        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAdd = new String[] {theOwner};
         mail.setToAddresses(toAdd);
         mail.setSubject('Your order has been rejected');
         mail.setWhatId(theId);
         mail.saveAsActivity = false;
        
        mail.setHtmlBody(body + '<br></br> Opportunity Link: https://login.salesforce.com/'+ theId); 
                 

               
        // send the email
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

for (Opportunity o:[select id, StageName,OwnerId from Opportunity where id =:theId]) 
{
            o.StageName = 'Stage 5 - Negotiation';
           update o;
        
 }
       
} 
    
 public PageReference navigateToRecord()
 {
   
     return new PageReference('/'+theId);
 }
   
}