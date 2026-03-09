/* Change Log
 * 
  Developer			Date		Description
  Tony Tran			01/24/17	Removed references to defunct CRM Address fields
								Note: need to revise this test class to include assertions to make tests more robust
 * 
 * 
 * 
*/ 
@isTest(seeAllData=true)
public class TestAccountMethods {
    @isTest
    public static void testOne(){
        
        List<Account> accountsToInsert= new List<Account>();
        List<Account> accountsToUpdate= new List<Account>();
        List<Account> accountsToInsertTwo = new List<Account>();
        
        RecordType rt= [Select Name,id from RecordType where Name=:'Prospect'];
        RecordType rtPKI= rt;
        
       	Industry_Code__c indCode = new Industry_Code__c(Industry_Code__c='abc',Industry_Code_Level__c='1st Level');
        insert indCode;
            
        Account acc1 = new Account(Name = 'Test Account 1',RecordType=rt,Competitor_Systems_Owned__c='Berthold',Industry_Desc_1st_Level__c=indCode.id);
        accountsToInsert.add(acc1);
            
        Account acc2 = new Account(Name = 'Test Account 2',RecordType=rt,Competitor_Systems_Owned__c='Berthold',Industry_Desc_1st_Level__c=indCode.id);
        accountsToInsert.add(acc2);
            
        Account acc3 = new Account(Name = 'Test Account 3',RecordType=rt,Competitor_Systems_Owned__c='Berthold',Industry_Desc_1st_Level__c=indCode.id);
        accountsToInsert.add(acc3);
            
        Account acc4 = new Account(Name = 'Test Account 4',RecordType=rt,Competitor_Systems_Owned__c='Berthold',Industry_Desc_1st_Level__c=indCode.id);
        accountsToInsert.add(acc4);
            
        Account acc5 = new Account(Name = 'Test Account 5',RecordType=rt,Competitor_Systems_Owned__c='Berthold',Industry_Desc_1st_Level__c=indCode.id);
        accountsToInsert.add(acc5);
 
        Account acc = new Account(Name = 'test pki account',RecordType=rtPKI,Competitor_Systems_Owned__c='Berthold',Industry_Desc_1st_Level__c=indCode.id);      
        accountsToInsert.add(acc);
        
        insert accountsToInsert;
        
        Account a1 = new Account(Name='Test 1',Parentid=acc5.id);
        accountsToInsertTwo.add(a1);
        	
        Account b = new Account(Name='Test 2',Parentid=a1.id);
        accountsToInsertTwo.add(b);
        
        Account c = new Account(Name='Test 3',Parentid=b.id);
        accountsToInsertTwo.add(c);
        	
      	insert accountsToInsertTwo;
        
        AccountMethods.runUpdate = true;
        id parentid = accountsToInsert[0].id;
        
        for(Account a :accountsToInsert){
            a.Account_Category__c = 'Commercial';
            a.Account_Incorporated_Country__c = 'India';
            a.Account_Incorporated_State__c = 'Washington';
            a.Account_Sub_Category__c= 'State Agencies';   
            
            if(a.Name == 'Test Account 5')
                a.Parentid = parentid;
            
            accountsToUpdate.add(a);
        }
        
        system.debug('accounts to update '+accountsToUpdate);
        update accountsToUpdate;
        
        //Need assertions to check if update performed as expected
        
        delete acc;        
        //Need assertions to check if delete performed as expected
    }
}