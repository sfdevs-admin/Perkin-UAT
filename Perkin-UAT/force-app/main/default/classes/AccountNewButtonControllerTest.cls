@isTest
public class AccountNewButtonControllerTest {
    @testSetup static void setup() {
        // Create common test accounts
        List<Account> testAccts = new List<Account>();
        for(Integer i=0;i<2;i++) {
            testAccts.add(new Account(Name = 'TestAcct'+i));
        }
        insert testAccts; 
        
    }
    @isTest static void testaccountinfo() {
        AccountNewButtonController.fetchUserInfo();
    }
}