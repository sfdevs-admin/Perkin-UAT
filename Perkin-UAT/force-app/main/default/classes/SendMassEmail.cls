global class SendMassEmail
{
    webService static void SendEmail(String contactids, String emailtempId){
    Messaging.MassEmailMessage mail = new Messaging.MassEmailMessage();
    List<id> conids = new List<id>();
    List<String> contactid= contactids.split(',');
    for(String s : contactid){
    conids.add(s);
    }
       mail.setTargetObjectIds(conids);
       mail.setTemplateId(emailtempId);
       mail.replyTo = 'noreply@salesforce.com';
       Messaging.sendEmail(new Messaging.MassEmailMessage[] { mail });
    }               
}