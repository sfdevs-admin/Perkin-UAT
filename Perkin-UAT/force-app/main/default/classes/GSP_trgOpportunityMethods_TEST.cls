@isTest
public with sharing class GSP_trgOpportunityMethods_TEST
{
    private static Map<Integer, String> monthToStringMap = new Map<Integer, String>{ 1 => '1 - Jan', 2 => '2 - Feb', 3 => '3 => Mar', 4 => '4 - Apr', 5 => '5 - May',
        6 => '6 - Jun', 7 => '7 - Jul', 8 => '8 - Aug', 9 => '9 - Sept', 10 => '10 - Oct', 11 => '11 - Nov', 12 => '12 - Dec' };
    private static String PRODUCT_LINE = 'SOS';
    
    @isTest(seeAllData=true)
    public static void test_UpdateTargets()
    {
        User user = [select Id FROM User where IsActive = true LIMIT 1];
        Territory2 territory;
        System.runAs(user)
        {
        
            territory = new Territory2(
                Name = 'Apex Test Territory');
       //     insert territory;
            System.assertNotEquals(territory2.Id, null);
        }  
        
        
        Month_Rep_Target__c monthRepTarget = new Month_Rep_Target__c(
            Month__c = monthToStringMap.get(Date.today().month()),
            Year__c = String.valueOf(Date.today().year()),
            Sales_Person__c = UserInfo.getUserId());
        insert monthRepTarget;
        System.assertNotEquals(monthRepTarget.Id, null);
        
        Month_Territory_Target__c monthTerritoryTarget = new Month_Territory_Target__c(
            Year__c = String.valueOf(Date.today().year()),
            Start_Date__c = Date.today().toStartOfMonth(),
            Month__c = monthToStringMap.get(Date.today().month()),
            Unique_Field__c = 'Apex Test Territory');
        insert monthTerritoryTarget;
        System.assertNotEquals(monthTerritoryTarget.Id, null);
        
        Account account = new Account(
            Name = 'Apex Test Account',
            ShippingCountry = 'US');
        insert account;
        System.assertNotEquals(account.Id, null);
        
        Opportunity opportunity = new Opportunity(
            Name = 'Apex Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting',
            AccountId = account.Id,
        //    Territory2 = territory2.Id,
            Month_Territory_Target__c = monthTerritoryTarget.Id,
            Month_Rep_Target__c = monthRepTarget.Id,
            Solution_Area_of_Interest__c='Energy');
        insert opportunity;
        System.assertNotEquals(opportunity.Id, null);
        
        Pricebook2 standardPricebook,
            customPricebook;
        List<Pricebook2> pricebooks = new List<Pricebook2>([
            SELECT
                Id,
                Name,
                IsStandard,
                IsActive
            FROM
                Pricebook2
            WHERE
                IsStandard = true
            OR
                (IsActive = true
            AND
                IsStandard = false)
            ORDER BY
                IsStandard DESC
            LIMIT 2]);System.debug(pricebooks);
        System.assert(pricebooks.size() > 0);
        for (Pricebook2 pricebook : pricebooks)
        {
            if (pricebook.IsStandard)
            {
                standardPricebook = pricebook;
            }
            else
            {
                System.assertEquals(pricebook.IsActive, true);
                customPricebook = pricebook;
            }
        }
        System.assertNotEquals(standardPricebook, null);
        if (!standardPricebook.IsActive)
        {
            System.assertNotEquals(customPricebook, null, 'No pricebooks defined, unable to continue.');
        }
        
        List<Product2> productCache = new List<Product2>();
        for (Integer i = 0; i < 3; i++)
        {
            Product2 product = new Product2(
                Name = 'Apex Test Product ' + i,
                IsActive = true,
                Product_Line__c = PRODUCT_LINE);
            productCache.add(product);
        }
        insert productCache;
        
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
        List<PricebookEntry> customPricebookEntryCache = new List<PricebookEntry>();
        List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();
        for (Integer i = 0; i < productCache.size(); i++)
        {
            Product2 product = productCache.get(i);
            PricebookEntry standardPricebookEntry = new PricebookEntry(
                Product2Id = product.Id,
                Pricebook2Id = standardPricebook.Id,
                UnitPrice = (i + 1) * 1000,
                IsActive = true);
            standardPricebookEntryCache.add(standardPricebookEntry);
            if (!standardPricebook.IsActive)
            {
                PricebookEntry customPricebookEntry = new PricebookEntry(
                Product2Id = product.Id,
                Pricebook2Id = customPricebook.Id,
                UnitPrice = (i + 1) * 1000,
                IsActive = true);
                customPricebookEntryCache.add(customPricebookEntry);
            }
        }
        insert standardPricebookEntryCache;
        if (!customPricebookEntryCache.isEmpty())
        {
            insert customPricebookEntryCache;
            pricebookEntries = customPricebookEntryCache;
        }
        else
        {
            pricebookEntries = standardPricebookEntryCache;
        }
        
        for (Integer i = 0; i < pricebookEntries.size(); i++)
        {
            PricebookEntry pricebookEntry = pricebookEntries.get(i);
            OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
                PricebookEntryId = pricebookEntry.Id,
                Quantity = 3,
                UnitPrice = (i + 1) * 1000,
                OpportunityId = opportunity.Id);
            opportunityLineItemCache.add(opportunityLineItem);
        }
        insert opportunityLineItemCache;
        
        opportunity.CloseDate = Date.today().addMonths(1);
        update opportunity;
    }
}