/* 
   Created By : Lister Technologies
   Description: Test class for trigger trg_setAccountowner
*/
@isTest
private class Test_trg_setAccountowner {

    static testMethod void testMethod1() {
        Recordtype rt=[select id from recordtype where name='Prospect' and sobjecttype='Account'];
        Account testaccount=new Account(name='testacc');
        insert testaccount;
        
    }
}