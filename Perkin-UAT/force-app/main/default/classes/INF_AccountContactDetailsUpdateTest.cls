@Istest(SeeAllData=true)
public class INF_AccountContactDetailsUpdateTest{

    static testMethod void BatchTest(){ 
        
        Account Ac = new Account();
        Ac.Name = 'Test acc';
        Ac.Industry__c ='Commercial';
        Ac.BillingStreet='kon';
        Ac.BillingCity='cochin';
        Ac.BillingPostalCode='54545';
        Ac.BillingCountry='india';
        Ac.BillingState='kerala';
        Ac.ShippingStreet='fdsfdsf';
        Ac.ShippingCountry='fdfdsf';
        //testAccount.CurrencyIsoCode='trt';
        insert Ac;
        
        Contact cn = new Contact();
        
        cn.AccountId = Ac.Id;
        cn.FirstName = 'request';
        cn.LastName= 'cont';
        cn.Email= 'xyz@gmail.com';
        cn.Phone='9845789568';
        cn.MailingStreet ='Kakkanada';
        cn.MailingCity ='Ernakulam';
        cn.MailingState ='Kerala';
        cn.MailingPostalCode ='584235';
        cn.MailingCountry ='India';
        
        insert cn;
        
        Opportunity op = new Opportunity();
        op.Name = 'optyname';
        //optytest.Account = 'Test acc';
        op.AccountId = Ac.Id;
        op.Account_Type_INF__c='Academic';
        //optytest.CurrencyIsoCode = 'ggg';
        op.CloseDate = system.today();
        op.StageName ='Stage 7 - Submit Order';
        op.Renewal_Required_INF__c ='Yes';
        op.Primary_Contact__c=cn.Id;
        //optytest.RecordTypeId ='opportunity_Informatics';
        op.Order_Processing_Status_INF__c = 'Revenue Review Required';
        op.Solution_Area_of_Interest__c='Energy';
        insert op;
        
        List<INF_Contracts_Req__c> cr = new List<INF_Contracts_Req__c>();
        
        for(Integer i=0;i <100; i++)
        {
            cr.add(new INF_Contracts_Req__c(Name='Cr Test'+i,Opportunity_Name_INF__c=op.Id));
            
        }
            
        insert cr;
        cr[0].Company_Details__c='kon';
         cr[0].Contact_Details__c='xyz@gmail.com';
        update cr;     
          
    } 
    
    
}