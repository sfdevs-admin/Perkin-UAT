@isTest
private class SMAX_PS_Case_UT {
    
    @isTest static void testCaseIP() 
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Map<String, Account> acctMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(acct);

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        pd.SMAX_PS_Super_Business_Unit__c = 'DAS';
        pd.product_line__c = 'TST1';
        update pd;

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.SMAX_PS_ShipTo__c = acctMap.get('ShipTo').Id;
        loc.SMAX_PS_BillTo__c = acctMap.get('BillTo').Id;
        loc.SMAX_PS_Payer__c = acctMap.get('Payer').Id;
        loc.SMAX_PS_LL_BillTo__c = acctMap.get('LocalLangBillTo').Id;
        loc.SMAX_PS_LL_ShipTo__c = acctMap.get('LocalLangShipTo').Id;
        update loc;
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);

        Id rtId = SMAX_PS_Utility.getRecordType('Case', 'Tech_Support').Id;
        Case cs = new Case(Subject = 'Test Case for IP', Origin = 'Web', Status = 'New',
            AccountId = acct.Id, ContactId = cont.Id, OwnerId = Userinfo.getUserId(), Priority = 'Medium',
            Description = 'test',RecordTypeId = rtId, SVMXC__Component__c = ip.Id);
        insert cs;

        Case result = [SELECT Id, Subject, CaseNumber, SMAX_PS_IP_Business_Unit__c, SMAX_PS_IP_Product_Line__c,
            Ship_To__c, Bill_To__c, Pay_To__c, SMAX_PS_Local_Language_Bill_To__c, SMAX_PS_Local_Language_Ship_To__c
            FROM Case WHERE Id = :cs.Id];
        /*System.assertEquals(pd.SMAX_PS_Super_Business_Unit__c, result.SMAX_PS_IP_Business_Unit__c);
        System.assertEquals(pd.product_line__c, result.SMAX_PS_IP_Product_Line__c);

        System.assertEquals(loc.SMAX_PS_ShipTo__c, result.Ship_To__c);
        System.assertEquals(loc.SMAX_PS_BillTo__c, result.Bill_To__c);
        System.assertEquals(loc.SMAX_PS_Payer__c, result.Pay_To__c);
        System.assertEquals(loc.SMAX_PS_LL_ShipTo__c, result.SMAX_PS_Local_Language_Ship_To__c);
        System.assertEquals(loc.SMAX_PS_LL_BillTo__c, result.SMAX_PS_Local_Language_Bill_To__c);*/

        result.Subject = 'Changed...';
        update result;
    }

    static testMethod void testCaseIP_AccountOverrides()
    {   
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');

        Account soldTo = SMAX_PS_TestDataFactory.createTestAccount('IP Partner Test', 'TESTX00FF001','GB');
        Map<String, Account> acctMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(soldTo);

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');

        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct,loc,'5545333',pd);
        ip.SMAX_PS_SoldTo_ExtId__c = soldTo.PKI_SAP_Customer_Number__c;
        ip.SMAX_PS_ShipTo_ExtId__c = acctMap.get('ShipTo').PKI_SAP_Customer_Number__c;
        ip.SMAX_PS_BillTo_ExtId__c = acctMap.get('BillTo').PKI_SAP_Customer_Number__c;
        ip.SMAX_PS_Payer_ExtId__c = acctMap.get('Payer').PKI_SAP_Customer_Number__c;
        ip.SMAX_PS_LL_ShipTo_ExtId__c = acctMap.get('LocalLangShipTo').PKI_SAP_Customer_Number__c;
        ip.SMAX_PS_LL_BillTo_ExtId__c = acctMap.get('LocalLangBillTo').PKI_SAP_Customer_Number__c;
        update ip;

        ip = [SELECT Id, Name, SMAX_PS_SoldTo_Account__c, SMAX_PS_ShipTo_Account__c, SMAX_PS_BillTo_Account__c,
                SMAX_PS_Payer_Account__c, SMAX_PS_LL_BillTo_Account__c, SMAX_PS_LL_ShipTo_Account__c
            FROM SVMXC__Installed_Product__c WHERE Id = :ip.Id];
        //System.assertNotEquals(null, ip.SMAX_PS_SoldTo_Account__c);

        Id rtId = SMAX_PS_Utility.getRecordType('Case', 'Tech_Support').Id;
        Case cs = new Case(Subject = 'Test Case for IP', Origin = 'Web', Status = 'New',
            AccountId = acct.Id, ContactId = cont.Id, OwnerId = Userinfo.getUserId(), Priority = 'Medium',
            Description = 'test',RecordTypeId = rtId, SVMXC__Component__c = ip.Id);
        insert cs;

       /* Case result = [SELECT Id, Subject, CaseNumber, AccountId, Ship_To__c, Bill_To__c, Pay_To__c,
                SMAX_PS_Local_Language_Bill_To__c, SMAX_PS_Local_Language_Ship_To__c
            FROM Case WHERE Id = :cs.Id];

        System.assertEquals(ip.SMAX_PS_SoldTo_Account__c, result.AccountId);
        System.assertEquals(ip.SMAX_PS_ShipTo_Account__c, result.Ship_To__c);
        System.assertEquals(ip.SMAX_PS_BillTo_Account__c, result.Bill_To__c);
        System.assertEquals(ip.SMAX_PS_Payer_Account__c, result.Pay_To__c);

        System.assertEquals(ip.SMAX_PS_LL_ShipTo_Account__c, result.SMAX_PS_Local_Language_Ship_To__c);
        System.assertEquals(ip.SMAX_PS_LL_BillTo_Account__c, result.SMAX_PS_Local_Language_Bill_To__c);*/
    }

    @isTest static void testCaseIP_Negative() 
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Map<String, Account> acctMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(acct);

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        pd.SMAX_PS_Super_Business_Unit__c = 'DAS';
        pd.product_line__c = 'TST1';
        update pd;

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');
        loc.SMAX_PS_ShipTo__c = acctMap.get('ShipTo').Id;
        loc.SMAX_PS_BillTo__c = acctMap.get('BillTo').Id;
        loc.SMAX_PS_Payer__c = acctMap.get('Payer').Id;
        update loc;

        Account acct2 = SMAX_PS_TestDataFactory.createTestAccount('PkiTest2', 'TESTX000000002','GB');
        SVMXC__Installed_Product__c ip = SMAX_PS_TestDataFactory.createIP('123456',acct2,loc,'5545333',pd);

        Id rtId = SMAX_PS_Utility.getRecordType('Case', 'Tech_Support').Id;
        Case cs = new Case(Subject = 'Test Case for IP', Origin = 'Web', Status = 'New',
            AccountId = acct.Id, ContactId = cont.Id, OwnerId = Userinfo.getUserId(), Priority = 'Medium',
            Description = 'test',RecordTypeId = rtId, SVMXC__Component__c = ip.Id);
        try
        {
            insert cs;
            //System.assert(false); // Shouldn't get here.. IP on different Account from Case
        }
        catch (Exception e1)
        {
            System.debug('~~~ Caught expected Exception on Case Create: ' + e1);
        }
    }

    @isTest static void testCaseProduct() 
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');
        pd.SMAX_PS_Super_Business_Unit__c = 'DAS';
        pd.product_line__c = 'TST1';
        update pd;

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');

        Id rtId = SMAX_PS_Utility.getRecordType('Case', 'Tech_Support').Id;
        Case cs = new Case(Subject = 'Test Case for Product', Origin = 'Web', Status = 'New',
            AccountId = acct.Id, ContactId = cont.Id, OwnerId = Userinfo.getUserId(), Priority = 'Medium',
            Description = 'test',RecordTypeId = rtId, SVMXC__Product__c = pd.Id);
        insert cs;

       /* Case result = [SELECT Id, Subject, CaseNumber, SMAX_PS_IP_Business_Unit__c, SMAX_PS_IP_Product_Line__c FROM Case WHERE Id = :cs.Id];
        System.assertEquals(pd.SMAX_PS_Super_Business_Unit__c, result.SMAX_PS_IP_Business_Unit__c);
        System.assertEquals(pd.product_line__c, result.SMAX_PS_IP_Product_Line__c);

        result.Subject = 'Changed...';
        update result;*/
    }
    
    @isTest static void testCaseContact()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');

        SVMXC__Site__c loc = SMAX_PS_TestDataFactory.createTestLocation(acct,'TestLocationSite', '121212','LOC123');

        Id rtId = SMAX_PS_Utility.getRecordType('Case', 'Tech_Support').Id;
        Case cs = new Case(Subject = 'Test Case for Contact', Origin = 'Web', Status = 'New',
            AccountId = acct.Id, //ContactId = cont.Id, 
            OwnerId = Userinfo.getUserId(), Priority = 'Medium',
            Description = 'test',RecordTypeId = rtId, SVMXC__Product__c = pd.Id);
        cs.BD_Create_New_Contact__c = TRUE;
        cs.BD_Contact_First_Name__c = 'Joe';
        cs.BD_Contact_Last_Name__c = 'Test';
        cs.BD_New_Contact_Email__c = 'joe.test@testing.perkinelmer.com';
        cs.BD_New_Contact_Business_Phone__c = '5558675309';
        cs.BD_New_Contact_Mobile_Phone__c = '8138675309';
        cs.Salutation__c = '0012'; // Dr.
        cs.Suffix__c = '0006'; // PhD
        insert cs;

        Case result = [SELECT Id, Subject, CaseNumber, ContactId FROM Case WHERE Id = :cs.Id];
        //System.assertNotEquals(null, result.ContactId);

        //Contact c = [SELECT Id, FirstName, LastName, Email, Phone, MobilePhone
        //  FROM Contact WHERE Id = :result.ContactId];

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        cs.BD_Create_New_Contact__c = TRUE;
        cs.ContactId = cont.Id;
        cs.BD_Contact_First_Name__c = 'Joe';
        cs.BD_Contact_Last_Name__c = 'Testalittle';
        cs.BD_New_Contact_Email__c = 'joe.testalittle@testing.perkinelmer.com';
        cs.BD_New_Contact_Business_Phone__c = '4078675309';
        cs.BD_New_Contact_Mobile_Phone__c = '5558675309';
        cs.Salutation__c = '0024'; // Mr.
        cs.Suffix__c = '0001'; // Jr.
        update cs;

        /*Contact cResult = [SELECT Id, FirstName, LastName, Email, Phone, MobilePhone, Salutation, Suffix__c
            FROM Contact WHERE Id = :cont.Id];
        System.assertEquals(cs.BD_Contact_First_Name__c, cResult.FirstName);
        System.assertEquals(cs.BD_Contact_Last_Name__c, cResult.LastName);
        System.assertEquals(cs.Salutation__c, cResult.Salutation);
        System.assertEquals(cs.Suffix__c, cResult.Suffix__c);*/

        // Make sure the Contact fields copy over as well...
        Case cs2 = new Case(Subject = 'Test Case for Contact Copy', Origin = 'Web', Status = 'New',
            AccountId = acct.Id, ContactId = cont.Id, 
            OwnerId = Userinfo.getUserId(), Priority = 'Medium',
            Description = 'test',RecordTypeId = rtId, SVMXC__Product__c = pd.Id);
        insert cs2;

        /*Case copyResult = [SELECT Id, Subject, CaseNumber, 
            BD_Contact_First_Name__c, BD_Contact_Last_Name__c, BD_New_Contact_Email__c 
            FROM Case WHERE Id = :cs2.Id];
        System.assertEquals(cResult.FirstName, copyResult.BD_Contact_First_Name__c);
        System.assertEquals(cResult.LastName, copyResult.BD_Contact_Last_Name__c);
        System.assertEquals(cResult.Email, copyResult.BD_New_Contact_Email__c);*/
    }

    static testMethod void testCaseAccountFunctions()
    {   
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');

        //Account soldTo = SMAX_PS_TestDataFactory.createTestAccount('IP Partner Test', 'TESTX00FF001','GB');
        Map<String, Account> acctMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(acct);

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');

        Id rtId = SMAX_PS_Utility.getRecordType('Case', 'Customer_Care_General').Id;
        Case cs = new Case(Subject = 'Test Case for Acct Function', Origin = 'Web', Status = 'New',
            AccountId = acct.Id, ContactId = cont.Id, OwnerId = Userinfo.getUserId(), Priority = 'Medium',
            Description = 'test',RecordTypeId = rtId);
        insert cs;

        /*Case result = [SELECT Id, Subject, CaseNumber, AccountId, Ship_To__c, Bill_To__c, Pay_To__c FROM Case WHERE Id = :cs.Id];

        System.assertEquals(acct.Id, result.AccountId);
        System.assertEquals(acctMap.get('ShipTo').Id, result.Ship_To__c);
        System.assertEquals(acctMap.get('BillTo').Id, result.Bill_To__c);
        System.assertEquals(acctMap.get('Payer').Id, result.Pay_To__c);*/
    }

    static testMethod void textCaseRefTxnWarning()
    {
        Account acct = SMAX_PS_TestDataFactory.createTestAccount('PkiTest', 'TESTX000000001','GB');

        //Account soldTo = SMAX_PS_TestDataFactory.createTestAccount('IP Partner Test', 'TESTX00FF001','GB');
        Map<String, Account> acctMap = SMAX_PS_TestDataFactory.createTestPartnerAccounts(acct);

        Contact cont = SMAX_PS_TestDataFactory.createTestContact('Sir', 'Testalot', acct, 'TESTX00000001A');
        Product2 pd = SMAX_PS_TestDataFactory.createTestProduct('TestProduct', '106018','TST');

        Id rtId = SMAX_PS_Utility.getRecordType('Case', 'Customer_Care_General').Id;
        Case cs = new Case(Subject = 'Test Case for Acct Function', Origin = 'Web', Status = 'New',
            AccountId = acct.Id, ContactId = cont.Id, OwnerId = Userinfo.getUserId(), Priority = 'Medium',
            Description = 'test',RecordTypeId = rtId);
        insert cs;

        cs.SAP_Reference_Transaction_SoldTo__c = 'TESTX000000002'; // Bad value;
        update cs;

        //Case result = [SELECT Id, Subject, CaseNumber, AccountId, BD_Warning__c FROM Case WHERE Id = :cs.Id];
        //System.assertNotEquals(null, result.BD_Warning__c);

        cs.SAP_Reference_Transaction_SoldTo__c = 'TESTX000000001'; // Bad value;
        update cs;

        //Case result2 = [SELECT Id, Subject, CaseNumber, AccountId, BD_Warning__c FROM Case WHERE Id = :cs.Id];
        //System.assertEquals(null, result2.BD_Warning__c);

    }

}