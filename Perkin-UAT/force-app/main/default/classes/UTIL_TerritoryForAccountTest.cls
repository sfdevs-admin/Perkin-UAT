/**************************************************************
  * 1. Jira Ticket(s) that relates to this class
  *    - ATEAM-1862
  *    - ITSFDC-####
  *
  * 2. Description - Put detailed description here of what this class is used for procedurally
  *    this will allow running Account Territories via Q.ACTION & M.ACTION which is otherwise not possible via native execution.
  *    This allows it to run as a system user so that default users do not need elevated permissions on accounts. (i.e. Public Read Only is all that is needed)
  *
  * 3. Objects referenced
  *    -Account
  *    -Object Name
  *    -Object Name
  *    -Object Name 
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - None
  *    - Component.Method  
  *    - Component.Method
  *
  * 5. Dependant Class(es):
  *    - UTIL_RunTerritoryRules
  *    - UTIL_TerritoryForAccount  (<--is Invocable)
  *    - UTIL_TerritoryForAccountMockTest
  *    - UTIL_TerritoryForAccountTest
  *
  * 6. Test Class Name: UTIL_TerritoryForAccountMockTest, UTIL_TerritoryForAccountTest
  *
  * 7. Is @Invocable (Yes or No):  No
  *
  * 8. Author Name(s): 
  *    - (KPMG)Yakup Garayev - 2022.12.12
  *    - First Last & Updated Date(YYYY.MM.DD)
  *    - First Last & Updated Date(YYYY.MM.DD)
  *
*************************************************************/ 
@isTest
public class UTIL_TerritoryForAccountTest {
    @isTest static void searchTest(){
       
        List<Account> accLst = new List<Account>();
         Account a = new Account();
        a.name = 'Test Account';
        a.ShippingCity = 'test city';
        a.ShippingCountry = 'US';
        a.ShippingPostalCode = '12345678';
        a.ShippingState = 'AX';
        a.ShippingStreet = 'Test Street';
        insert a;
        accLst.add(a);
        //Test.setMock(WebServiceMock.class, new UTIL_TerritoryForAccountMockTest());
         test.startTest();
          Test.setMock(WebServiceMock.class, new UTIL_TerritoryForAccountMockTest());
        List<List<Account>> accLstOfLst = new  List<List<Account>>();
        accLstOfLst.add(accLst);
        UTIL_TerritoryForAccount.getAccId(accLstOfLst);
        test.stopTest();
        
    }
}