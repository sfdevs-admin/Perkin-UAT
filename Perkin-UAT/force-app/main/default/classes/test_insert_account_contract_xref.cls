/* Name: test_insert_account_contract_xref (insert_account_contract_xref on Contract (after insert, after update)
*  Author(s): Umapathy Kalavagunta
*  Last Update : Sep 29th 2012
*  Description: Unit test for Contract Trigger
*/
@isTest
private class test_insert_account_contract_xref {
    static testMethod void test_insert_account_contract_xref () {
        /*Map<String, RecordType> RecTypeListMap = new Map<String, RecordType>();
        for (RecordType RecList : [select Id, Name from RecordType where SobjectType = 'Contract']) {
            RecTypeListMap.put(RecList.Name, RecList);
        }
        account a1 = new account(name='Sftest', shippingcountry='CA');
        insert a1;
        contract xreftest = new contract(Status = 'Draft',
        RecordTypeId = RecTypeListMap.get('Accountwide Contract').Id,
                                    Name='TestTrigger',
                                   //AccountId='00130000018SDtf',
                                   AccountId=a1.id,
                                   Accountwide_contract_status__c =  'PKI Review'
                                   );
          Insert xreftest;*/
}
}