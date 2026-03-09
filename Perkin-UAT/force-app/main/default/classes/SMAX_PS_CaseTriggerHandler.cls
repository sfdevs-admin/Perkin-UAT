public with sharing class SMAX_PS_CaseTriggerHandler implements SMAX_PS_Utility.ITriggerHandler {
    public SMAX_PS_CaseTriggerHandler() {
    }

    /*      ITriggerHandler methods     */

    public void beforeInsert()
    {
        List<Case> newList = Trigger.new;
        copyRelatedData(newList, null);
        createOrUpdateContact(newList, null);
    }
    public void afterInsert() {}
    public void beforeUpdate() 
    {
        List<Case> newList = Trigger.new;
        Map<Id, Case> oldMap = (Map<Id, Case>) Trigger.oldMap;
        copyRelatedData(newList, oldMap);
        createOrUpdateContact(newList, oldMap);
        checkRefTxnSoldToAcct(newList, oldMap);
    }
    public void afterUpdate() {}
    public void beforeDelete() {}
    public void afterDelete() {}
    public void afterUndelete() {}   

    /*      Custom Business Logic methods       */

    // JIRA SVMXCFG-606 / SVMXCFG-621 - Add Trigger to Case to populate IP Data 
    public static void copyRelatedData(List<Case> caseList, Map<Id, Case> oldMap)
    {
        Set<Id> ipIds = new Set<Id>();
        List<Case> casesToUpdateIP = new List<Case>();
        Set<Id> prodIds = new Set<Id>();
        List<Case> casesToUpdateProduct = new List<Case>();
        Set<Id> acctIds = new Set<Id>();
        List<Case> casesToUpdateAcctFunction = new List<Case>();
        for (Case cs : caseList)
        {
            Case old = (oldMap == null) ? null : oldMap.get(cs.Id);
            if (cs.SVMXC__Component__c != null && (old == null || old.SVMXC__Component__c != cs.SVMXC__Component__c))
            {
                ipIds.add(cs.SVMXC__Component__c);
                casesToUpdateIP.add(cs);
                // SC-38 Wipe out fields to make sure they get replaced from IP / Location..
                cs.SVMXC__Site__c = null;
                cs.Ship_To__c = null;
                cs.Bill_To__c = null;
                cs.Pay_To__c = null;
                cs.SMAX_PS_Local_Language_Bill_To__c = null;
                cs.SMAX_PS_Local_Language_Ship_To__c = null;
            }
            else if (cs.SVMXC__Product__c != null && cs.SVMXC__Component__c == null
                && (old == null || old.SVMXC__Product__c != cs.SVMXC__Product__c))
            {
                prodIds.add(cs.SVMXC__Product__c);
                casesToUpdateProduct.add(cs);
            }

            if (cs.SVMXC__Component__c == null && cs.AccountId != null
                && (old == null || cs.AccountId != old.AccountId))
            {
                acctIds.add(cs.AccountId);
                casesToUpdateAcctFunction.add(cs);
                cs.Ship_To__c = null;
                cs.Bill_To__c = null;
                cs.Pay_To__c = null;
                cs.SMAX_PS_Local_Language_Bill_To__c = null;
                cs.SMAX_PS_Local_Language_Ship_To__c = null;
            }
        }

        Set<Id> caseErrors = new Set<Id>();
        if (!ipIds.isEmpty())
        {
            Map<Id, SVMXC__Installed_Product__c> ipMap = new Map<Id, SVMXC__Installed_Product__c>(
                [SELECT Id, Name, SVMXC__Product__c,
                    SVMXC__Product__r.SMAX_PS_Super_Business_Unit__c,
                    SVMXC__Product__r.product_line__c,
                    SVMXC__Company__c, SVMXC__Company__r.Id, SVMXC__Company__r.PKI_SAP_Customer_Number__c,
                    SMAX_PS_SoldTo_Account__c, SMAX_PS_SoldTo_Account__r.Id, SMAX_PS_SoldTo_Account__r.PKI_SAP_Customer_Number__c,
                    SMAX_PS_ShipTo_Account__c, SMAX_PS_BillTo_Account__c, SMAX_PS_Payer_Account__c,
                    SMAX_PS_LL_BillTo_Account__c, SMAX_PS_LL_ShipTo_Account__c,
                    SVMXC__Site__c
                FROM SVMXC__Installed_Product__c WHERE Id IN :ipIds]);
            for (Case cs : casesToUpdateIP)
            {
                SVMXC__Installed_Product__c ip = ipMap.get(cs.SVMXC__Component__c);
                if (ip.SVMXC__Product__r != null)
                {
                    cs.SVMXC__Product__c = ip.SVMXC__Product__c;
                    cs.SMAX_PS_IP_Business_Unit__c = ip.SVMXC__Product__r.SMAX_PS_Super_Business_Unit__c;
                    cs.SMAX_PS_IP_Product_Line__c = ip.SVMXC__Product__r.product_line__c;

                    if (cs.SVMXC__Site__c == null)
                    {
                        cs.SVMXC__Site__c = ip.SVMXC__Site__c;
                    }

                    // SC-38 : Use IP Customer Master Lookups first
                    //Account ipAcct = (ip.SMAX_PS_SoldTo_Account__c != null) ? 
                    //  ip.SMAX_PS_SoldTo_Account__r : ip.SVMXC__Company__r;
                    //if (ipAcct != null && ipAcct.Id != cs.AccountId)
                    Boolean mainAccountMatches = ip.SVMXC__Company__c != null && ip.SVMXC__Company__c == cs.AccountId;
                    Boolean soldToMatches = ip.SMAX_PS_SoldTo_Account__c != null && ip.SMAX_PS_SoldTo_Account__c == cs.AccountId;
                    if (mainAccountMatches == FALSE && soldToMatches == FALSE)
                    {
                        // SC-38: Throw an error if not matching
                        caseErrors.add(cs.Id);
                        cs.addError('The Account of the Installed Product  does not match the Account on the Case. '
                            + 'Please either select a different Installed Product, or change the Case Account first.');
                    }
                    else
                    {
                        if (ip.SMAX_PS_SoldTo_Account__c != null)
                        {
                            cs.AccountId = ip.SMAX_PS_SoldTo_Account__c;
                        }
                        if (ip.SMAX_PS_ShipTo_Account__c != null)
                        {
                            cs.Ship_To__c = ip.SMAX_PS_ShipTo_Account__c;
                        }
                        if (ip.SMAX_PS_BillTo_Account__c != null)
                        {
                            cs.Bill_To__c = ip.SMAX_PS_BillTo_Account__c;
                        }
                        if (ip.SMAX_PS_Payer_Account__c != null)
                        {
                            cs.Pay_To__c = ip.SMAX_PS_Payer_Account__c;
                        }
                        // SC-77 Copy Local Language Accounts to Case
                        if (ip.SMAX_PS_LL_BillTo_Account__c != null)
                        {
                            cs.SMAX_PS_Local_Language_Bill_To__c = ip.SMAX_PS_LL_BillTo_Account__c;
                        }
                        if (ip.SMAX_PS_LL_ShipTo_Account__c != null)
                        {
                            cs.SMAX_PS_Local_Language_Ship_To__c = ip.SMAX_PS_LL_ShipTo_Account__c;
                        }
                    }
                }
            }
        }

        if (!prodIds.isEmpty())
        {
            Map<Id, Product2> prodMap = new Map<Id, Product2>(
                [SELECT Id, Name, ProductCode, 
                    SMAX_PS_Super_Business_Unit__c, product_line__c
                FROM Product2 WHERE Id IN :prodIds]);
            for (Case cs : casesToUpdateProduct)
            {
                Product2 prod = prodMap.get(cs.SVMXC__Product__c);
                cs.SMAX_PS_IP_Business_Unit__c = prod.SMAX_PS_Super_Business_Unit__c;
                cs.SMAX_PS_IP_Product_Line__c = prod.product_line__c;
            }
        }

        // Second pass.. Locations (might have been filled in during first pass)
        Set<Id> locIds = new Set<Id>();
        List<Case> casesToUpdateLoc = new List<Case>();
        for (Case cs : caseList)
        {
            if (caseErrors.contains(cs.Id))
            {
                continue;
            }

            if (cs.SVMXC__Site__c != null && (cs.Ship_To__c == null || cs.Bill_To__c == null || cs.Pay_To__c == null))
            {
                locIds.add(cs.SVMXC__Site__c);
                casesToUpdateLoc.add(cs);
            }
        }

        if (!locIds.isEmpty())
        {
            Map<Id, SVMXC__Site__c> locMap = new Map<Id, SVMXC__Site__c>([SELECT Id, Name,
                SVMXC__Account__c, SMAX_PS_BillTo__c, SMAX_PS_Payer__c, SMAX_PS_ShipTo__c,
                SMAX_PS_LL_BillTo__c, SMAX_PS_LL_ShipTo__c
                FROM SVMXC__Site__c WHERE Id IN :locIds]);

            for (Case cs : casesToUpdateLoc)
            {
                SVMXC__Site__c loc = (locMap == null) ? null : locMap.get(cs.SVMXC__Site__c);
                if (loc != null)
                {
                    // SC-38 : Use Location Customer Master Lookups second
                    if (cs.Ship_To__c == null)
                    {
                        cs.Ship_To__c = loc.SMAX_PS_ShipTo__c;
                    }
                    if (cs.Bill_To__c == null)
                    {
                        cs.Bill_To__c = loc.SMAX_PS_BillTo__c;
                    }
                    if (cs.Pay_To__c == null)
                    {
                        cs.Pay_To__c = loc.SMAX_PS_Payer__c;
                    }
                    // SC-77 Copy Local Language Accounts to Case
                    if (cs.SMAX_PS_Local_Language_Bill_To__c == null)
                    {
                        cs.SMAX_PS_Local_Language_Bill_To__c = loc.SMAX_PS_LL_BillTo__c;
                    }
                    if (cs.SMAX_PS_Local_Language_Ship_To__c == null)
                    {
                        cs.SMAX_PS_Local_Language_Ship_To__c = loc.SMAX_PS_LL_ShipTo__c;
                    }
                }
            }
        }

        if (!acctIds.isEmpty())
        {
            Map<Id, List<Account_Function__c>> acctFuncMap = new Map<Id, List<Account_Function__c>>();
            List<Account_Function__c> allAcctFunctions = [SELECT Id, Name, Source_Account__c, Target_Account__c,
                    PKI_SAP_Partner_Type__c, PKI_SAP_Partner_Type_Name__c, PKI_SAP_Sales_Org__c
            FROM Account_Function__c WHERE Source_Account__c IN :acctIds];
            for (Account_Function__c af : allAcctFunctions)
            {
                if (!acctFuncMap.containsKey(af.Source_Account__c))
                    acctFuncMap.put(af.Source_Account__c, new List<Account_Function__c>());
                acctFuncMap.get(af.Source_Account__c).add(af);
            }

            Set<Id> payerAcctIds = new Set<Id>();
            List<Case> casesToUpdateAcctFunctionAgain = new List<Case>();
            for (Case cs : casesToUpdateAcctFunction)
            {
                List<Account_Function__c> afList = acctFuncMap.get(cs.AccountId);
                if (afList == null || afList.isEmpty())
                    continue;

                Account_Function__c shipTo = findPartner(afList, 'Ship To', 'WE');
                if (shipTo != null)
                    cs.Ship_To__c = shipTo.Target_Account__c;

                Account_Function__c billTo = findPartner(afList, 'Bill To', 'RE');
                if (billTo != null)
                    cs.Bill_To__c = billTo.Target_Account__c;

                Account_Function__c payer = findPartner(afList, 'Payer', 'RG');
                if (payer != null)
                    cs.Pay_To__c = payer.Target_Account__c;

                // SC-77 Copy Local Language Accounts to Case
                Account_Function__c localShipTo = findPartner(afList, 'Local Language Ship To', 'YB');
                if (localShipTo != null)
                    cs.SMAX_PS_Local_Language_Ship_To__c = localShipTo.Target_Account__c;

                Account_Function__c localBillTo = findPartner(afList, 'Local Language Bill To', 'YA');
                if (localBillTo != null)
                    cs.SMAX_PS_Local_Language_Bill_To__c = localBillTo.Target_Account__c;

                if (cs.Pay_To__c != null && (cs.Bill_To__c == null || cs.SMAX_PS_Local_Language_Bill_To__c == null))
                {
                    payerAcctIds.add(cs.Pay_To__c);
                    casesToUpdateAcctFunctionAgain.add(cs);
                }
            }

            if (!payerAcctIds.isEmpty())
            {
                acctFuncMap = new Map<Id, List<Account_Function__c>>();
                allAcctFunctions = [SELECT Id, Name, Source_Account__c, Target_Account__c,
                        PKI_SAP_Partner_Type__c, PKI_SAP_Partner_Type_Name__c, PKI_SAP_Sales_Org__c
                FROM Account_Function__c WHERE Source_Account__c IN :payerAcctIds];
                for (Account_Function__c af : allAcctFunctions)
                {
                    if (!acctFuncMap.containsKey(af.Source_Account__c))
                        acctFuncMap.put(af.Source_Account__c, new List<Account_Function__c>());
                    acctFuncMap.get(af.Source_Account__c).add(af);
                }

                for (Case cs : casesToUpdateAcctFunctionAgain) {
                    List<Account_Function__c> afList = acctFuncMap.get(cs.Pay_To__c);
                    if (afList == null || afList.isEmpty())
                        continue;

                    Account_Function__c billTo = findPartner(afList, 'Bill To', 'RE');
                    if (billTo != null)
                        cs.Bill_To__c = billTo.Target_Account__c;

                    Account_Function__c localBillTo = findPartner(afList, 'Local Language Bill To', 'YA');
                    if (localBillTo != null)
                        cs.SMAX_PS_Local_Language_Bill_To__c = localBillTo.Target_Account__c;
                }
            }
        }
    }

    private static Account_Function__c findPartner(List<Account_Function__c> afList, String functionName, String partnerType)
    {
        Account_Function__c result = null;
        for (Account_Function__c af : afList)
        {
            if (af.PKI_SAP_Partner_Type__c == partnerType)
            {
                if (result == null)
                    result = af; // Found one.. hold on and keep going
                else
                        return null; // Found more than one!
            }
            else if (af.PKI_SAP_Partner_Type_Name__c == functionName)
            {
                if (result == null)
                    result = af; // Found one.. hold on and keep going
                else
                        return null; // Found more than one!
            }
        }
        return result;
    }

    public void createOrUpdateContact(List<Case> caseList, Map<Id, Case> oldMap)
    {
        // ITSFDC-1389 - Added Salutation and Suffix to all sections below

        List<Contact> newContacts = new List<Contact>();
        List<Case> newContactCases = new List<Case>();
        Map<Id, Case> contactCaseMap = new Map<Id, Case>();
        Set<Id> contactsToCopy = new Set<Id>();
        List<Case> casesToCopy = new List<Case>();
        for (Case cs : caseList)
        {
            Boolean contactFieldsPopulated = (cs.BD_Contact_Last_Name__c != null);
            Case old = (oldMap == null) ? null : oldMap.get(cs.Id);
            if (cs.BD_Create_New_Contact__c == TRUE && contactFieldsPopulated && cs.ContactId == null)
            {
                // Try to create Contact
                Contact c = new Contact();
                c.AccountId = cs.AccountId;
                c.Salutation = cs.Salutation__c;
                c.FirstName = cs.BD_Contact_First_Name__c;
                c.LastName = cs.BD_Contact_Last_Name__c;
                c.Suffix__c = cs.Suffix__c;
              //c.Job_Function__c = cs.Job_Function__c;
                c.Email = cs.BD_New_Contact_Email__c;
                c.Phone = cs.BD_New_Contact_Business_Phone__c;
                c.MobilePhone = cs.BD_New_Contact_Mobile_Phone__c;
                c.SVMX_PS_Active__c = TRUE;
                c.PKI_SAP_Language__c = 'EN'; // Just a default.. can be updated by user later
              //c.Title = cs.Title__c;
                newContacts.add(c);
                newContactCases.add(cs);

                cs.BD_Create_New_Contact__c = FALSE; // Set back to FALSE so it doesnt run again
            }
            else if (cs.BD_Create_New_Contact__c == TRUE && contactFieldsPopulated && cs.ContactId != null)
            {
                // Compare Contact fields and possibly update Contact
                contactCaseMap.put(cs.ContactId, cs);

                cs.BD_Create_New_Contact__c = FALSE; // Set back to FALSE so it doesnt run again
            }
            else if (cs.BD_Create_New_Contact__c == FALSE && cs.ContactId != null
                && (old == null || contactFieldsPopulated == FALSE || cs.ContactId != old.ContactId))
            {
                contactsToCopy.add(cs.ContactId);
                casesToCopy.add(cs);
            }
        }

        if (!newContacts.isEmpty())
        {
            insert newContacts;

            for (Integer i = 0; i < newContacts.size(); i++)
            {
                Contact c = newContacts[i];
                Case cs = newContactCases[i];
                cs.ContactId = c.Id;
            }
        }

        if (!contactCaseMap.isEmpty())
        {
            Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, 
                FirstName, LastName, Email, Phone, MobilePhone, Salutation, Suffix__c
                FROM Contact WHERE Id IN :contactCaseMap.keySet()]);

            Map<Id, Contact> updatedContactMap = new Map<Id, Contact>();
            for (Id contactId : contactCaseMap.keySet())
            {
                Case cs = contactCaseMap.get(contactId);
                Contact c = contactMap.get(contactId);
                
                if (c.Salutation != cs.Salutation__c)
                {
                    c.Salutation = cs.Salutation__c;
                    updatedContactMap.put(c.Id, c);
                }
                if (c.FirstName != cs.BD_Contact_First_Name__c)
                {
                    c.FirstName = cs.BD_Contact_First_Name__c;
                    updatedContactMap.put(c.Id, c);
                }
                if (c.LastName != cs.BD_Contact_Last_Name__c)
                {
                    c.LastName = cs.BD_Contact_Last_Name__c;
                    updatedContactMap.put(c.Id, c);
                }
                if (c.Suffix__c != cs.Suffix__c)
                {
                    c.Suffix__c = cs.Suffix__c;
                    updatedContactMap.put(c.Id, c); 
                 }       
                             
          /*    if (c.Job_Function__c != cs.Job_Function__c)
                {
                    c.Job_Function__c = cs.Job_Function__c;
                    updatedContactMap.put(c.Id, c);
                 }
                 
                 if (c.Title != cs.Title__c) 
                {
                    c.Title = cs.Title__c;    
                    updatedContactMap.put(c.Id, c);
                 }
          */
                if (c.Email != cs.BD_New_Contact_Email__c)
                {
                    c.Email = cs.BD_New_Contact_Email__c;
                    updatedContactMap.put(c.Id, c);
                }
                if (c.Phone != cs.BD_New_Contact_Business_Phone__c)
                {
                    c.Phone = cs.BD_New_Contact_Business_Phone__c;
                    updatedContactMap.put(c.Id, c);
                }
                if (c.MobilePhone != cs.BD_New_Contact_Mobile_Phone__c)
                {
                    c.MobilePhone = cs.BD_New_Contact_Mobile_Phone__c;
                    updatedContactMap.put(c.Id, c);
                }

                if (updatedContactMap.containsKey(c.Id))
                    System.debug('UPDATING CONTACT: ' + updatedContactMap.get(c.Id));
            }

            if (!updatedContactMap.isEmpty())
            {
                update updatedContactMap.values();
            }
        }

        if (!contactsToCopy.isEmpty())
        {
            Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, 
                FirstName, LastName, Email, Phone, MobilePhone, Salutation, Suffix__c
                FROM Contact WHERE Id IN :contactsToCopy]);
            for (Case cs : casesToCopy)
            {
                Contact c = contactMap.get(cs.ContactId);
                cs.Salutation__c = c.Salutation;
                cs.BD_Contact_First_Name__c = c.FirstName;
                cs.BD_Contact_Last_Name__c = c.LastName;
                cs.Suffix__c = c.Suffix__c;
                cs.BD_New_Contact_Email__c = c.Email;
                cs.BD_New_Contact_Business_Phone__c = c.Phone;
                cs.BD_New_Contact_Mobile_Phone__c = c.MobilePhone;
            }
        }
    }

    public static void checkRefTxnSoldToAcct(List<Case> caseList, Map<Id, Case> oldMap)
    {
        Set<Id> acctIds = new Set<Id>();
        List<Case> casesToCheck = new List<Case>();
        for (Case cs : caseList)
        {
            Case old = (oldMap == null) ? null : oldMap.get(cs.Id);
            if (cs.SAP_Reference_Transaction_SoldTo__c != null && cs.AccountId != null
                && (old == null || cs.AccountId != old.AccountId
                    || cs.SAP_Reference_Transaction_SoldTo__c != old.SAP_Reference_Transaction_SoldTo__c))
            {
                casesToCheck.add(cs);
                acctIds.add(cs.AccountId);
            }
        }

        if (casesToCheck.isEmpty())
            return;

        Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id, Name, PKI_SAP_Customer_Number__c
            FROM Account WHERE Id IN :acctIds]);

        for (Case cs : casesToCheck)
        {
            Account acct = acctMap.get(cs.AccountId);
            if (acct == null || acct.PKI_SAP_Customer_Number__c != cs.SAP_Reference_Transaction_SoldTo__c)
            {
                cs.BD_Warning__c = 'The Sold-To Account does not match the account of the Case [' + acct.PKI_SAP_Customer_Number__c + ']';
            }
            else
            {
                cs.BD_Warning__c = null;
            }           
        }
    }   
}