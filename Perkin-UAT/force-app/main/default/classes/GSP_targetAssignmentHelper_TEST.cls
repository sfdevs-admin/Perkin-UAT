@isTest
private class GSP_targetAssignmentHelper_TEST
{
	private static Map<Integer, String> monthToStringMap = new Map<Integer, String>{ 1 => '01-Jan', 2 => '02-Feb', 3 => '03-Mar', 4 => '04-Apr', 5 => '05-May',
		6 => '06-Jun', 7 => '07-Jul', 8 => '08-Aug', 9 => '09-Sep', 10 => '10-Oct', 11 => '11-Nov', 12 => '12-Dec' };
	private static String PRODUCT_LINE = 'SOS';
		
	@isTest
	private static void test_GSP_batchTargetAssignmentHelper_Lead()
	{
		Batch_Target_Settings__c batchSettings = new Batch_Target_Settings__c(
			Name = 'Default',
			Lead_Metrics_Batch_Size__c					= 100,
			Lead_Target_Batch_Size__c					= 100,
			Line_Item_Target_Batch_Size__c				= 100,
			Opportunity_Metrics_Batch_Size__c			= 100,
			Opportunity_Target_Batch_Size__c			= 100,
			Product_Line_Metrics_Batch_Size__c			= 100,
			Rgn_Product_Line_Metrics_Batch_Size__c		= 100,
			Zero_Month_Rep_Target_Batch_Size__c			= 1000,
			Zero_Month_Territory_Target_Batch_Size__c	= 100,
			Zero_Product_Lead_Batch_Size__c				= 1000,
			Zero_Rep_Product_Line_Target_Batch_Size__c	= 1000,
			Zero_Rgn_Product_Line_Target_Batch_Size__c	= 1000);
		insert batchSettings;
		System.assertNotEquals(batchSettings.Id, null);
		
		Region_Product_Line_Target_Leads__c regionProductLineTargetLead = new Region_Product_Line_Target_Leads__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Region__c = 'Americas',
			Product_Line__c = PRODUCT_LINE,
			Start_Date__c = Date.today().toStartOfMonth());
		insert regionProductLineTargetLead;
		System.assertNotEquals(regionProductLineTargetLead.Id, null);
		
		Lead lead = new Lead(
			LastName = 'Apex Test Lead',
			Product_Line__c = PRODUCT_LINE,
			Country = 'US',
			Company = 'Apex Test Company',
        	Street='265 North Street',
        	City='Boston');
		insert lead;
		System.assertNotEquals(lead.Id, null);
		
		Lead proxyLead = [
			SELECT
				Id,
				Product_Line__c,
				Global_Region__c,
				CreatedDate,
				Region_Product_Line_Target_Lead__c
			FROM
				Lead
			WHERE
				Id = :lead.Id LIMIT 1];
		
		GSP_targetAssignmentHelper.AssignLeadTargets(new List<Lead>{ proxyLead });
		
		List<Lead> testLeads = new List<Lead>([
			SELECT
				Id,
				Region_Product_Line_Target_Lead__c
			FROM
				Lead
			WHERE
				Id = :lead.Id]);
		System.assertEquals(testLeads.size(), 1);
		Lead testLead = testLeads.get(0);
		System.assertEquals(testLead.Region_Product_Line_Target_Lead__c, regionProductLineTargetLead.Id);
	}
	
	@isTest
	private static void test_GSP_batchTargetAssignmentHelper_Opportunity()
	{
		Batch_Target_Settings__c batchSettings = new Batch_Target_Settings__c(
			Name = 'Default',
			Lead_Metrics_Batch_Size__c					= 100,
			Lead_Target_Batch_Size__c					= 100,
			Line_Item_Target_Batch_Size__c				= 100,
			Opportunity_Metrics_Batch_Size__c			= 100,
			Opportunity_Target_Batch_Size__c			= 100,
			Product_Line_Metrics_Batch_Size__c			= 100,
			Rgn_Product_Line_Metrics_Batch_Size__c		= 100,
			Zero_Month_Rep_Target_Batch_Size__c			= 1000,
			Zero_Month_Territory_Target_Batch_Size__c	= 100,
			Zero_Product_Lead_Batch_Size__c				= 1000,
			Zero_Rep_Product_Line_Target_Batch_Size__c	= 1000,
			Zero_Rgn_Product_Line_Target_Batch_Size__c	= 1000);
		insert batchSettings;
		System.assertNotEquals(batchSettings.Id, null);
		
		Month_Territory_Target__c monthTerritoryTarget = new Month_Territory_Target__c(
			Year__c = String.valueOf(Date.today().year()),
			Start_Date__c = Date.today().toStartOfMonth(),
			Month__c = monthToStringMap.get(Date.today().month()),
			Unique_Field__c = 'Apex Test Territory',
			Territory__c = 'Apex Test Territory');
		insert monthTerritoryTarget;
		System.assertNotEquals(monthTerritoryTarget.Id, null);
		
		Month_Rep_Target__c monthRepTarget = new Month_Rep_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Sales_Person__c = UserInfo.getUserId());
		insert monthRepTarget;
		System.assertNotEquals(monthRepTarget.Id, null);
		
		User user = [select Id FROM User where IsActive = true LIMIT 1];
		Territory2 territory;
		System.runAs(user)
		{
            Territory2Model tm = [Select id from Territory2Model limit 1];                
            Territory2Type ty = [Select id from Territory2type limit 1];
            
			territory = new Territory2(
				Name = 'Apex Test Territory', 
            	Territory2ModelId = tm.id, 
            	developerName = 'test',
            	territory2Typeid = ty.id);
			insert territory;
			System.assertNotEquals(territory.Id, null);
		}
		
		Account account = new Account(
			Name = 'Apex Test Account');
		insert account;
		System.assertNotEquals(account.Id, null);
		
		Contact contact = new Contact(
			FirstName = 'Apex',
			LastName = 'Tester',
			Email = 'test@testing.com',
			AccountId = account.Id);
		insert contact;
		System.assertNotEquals(contact.Id, null);
		
		Opportunity opportunity = new Opportunity(
			Name = 'Apex Test Opportunity',
			CloseDate = Date.today(),
			StageName = 'Stage 5 - Negotiation',
			AccountId = account.Id,
			Territory2Id = territory.Id,
			Primary_Contact__c = contact.Id,
        	Solution_Area_of_Interest__c='Energy');
		insert opportunity;

		Opportunity proxyOpportunity = [
			SELECT
				Id,
				OwnerId,
				CloseDate,
				Month_Rep_Target__c,
				Territory2.Name
			FROM
				Opportunity
			WHERE
				Id = :opportunity.Id
			LIMIT 1];
		System.debug('\n\nASSIGN\n\n');
		GSP_targetAssignmentHelper.AssignOpportunityTargets(new List<Opportunity>{ proxyOpportunity });
		
		List<Opportunity> testOpportunities = new List<Opportunity>([
			SELECT
				Id, 
				Month_Rep_Target__c,
				Month_Territory_Target__c
			FROM
				Opportunity
			WHERE
				Id = :opportunity.Id]);
		System.assertEquals(testOpportunities.size(), 1);
		Opportunity testOpportunity = testOpportunities.get(0);
		System.assertEquals(testOpportunity.Month_Rep_Target__c, monthRepTarget.Id);
		System.assertEquals(testOpportunity.Month_Territory_Target__c, monthTerritoryTarget.Id);
	}
	
	@isTest(seeAllData=true)
	private static void test_GSP_batchTargetAssignmentHelper_ProductLine()
	{
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
		List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
		List<PricebookEntry> customPricebookEntryCache = new List<PricebookEntry>();
		List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();
		Set<Id> opportunityLineItemSet = new Set<Id>();
		
		User user = [select Id FROM User where IsActive = true LIMIT 1];
		Territory2 territory;
		System.runAs(user)
		{
		
            Territory2Model tm = [Select id from Territory2Model limit 1];                
            Territory2Type ty = [Select id from Territory2type limit 1];
            
			territory = new Territory2(
				Name = 'Apex Test Territory', 
            	Territory2ModelId = tm.id, 
            	developerName = 'test',
            	territory2Typeid = ty.id);
			insert territory;
			System.assertNotEquals(territory.Id, null);
        }
		
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
			Territory2Id = territory.Id,
        	Solution_Area_of_Interest__c='Energy');
		insert opportunity;
		System.assertNotEquals(opportunity.Id, null);
		
		Rep_Product_Line_Target__c repProductLineTarget = new Rep_Product_Line_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Sales_Person__c = UserInfo.GetUserId(),
			Product_Line__c = PRODUCT_LINE);
		insert repProductLineTarget;
		System.assertNotEquals(repProductLineTarget.Id, null);
		
		Region_Product_Line_Target__c regionProductLineTarget = new Region_Product_Line_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Region__c = 'Americas',
			Product_Line__c = PRODUCT_LINE);
		insert regionProductLineTarget;
		System.assertNotEquals(regionProductLineTarget.Id, null);
		
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
		
		
		for (OpportunityLineItem opportunityLineItem : opportunityLineItemCache)
		{
			opportunityLineItemSet.add(opportunityLineItem.Id);
		}
		
		List<OpportunityLineItem> proxyOpportunityLineItems = new List<OpportunityLineItem>([
			SELECT
				Id,
				Product_Line__c,
				Rep_Product_Line_Target__c,
				Region_Product_Line_Target__c,
				Opportunity.OwnerId,
				Opportunity.CloseDate,
				Opportunity.Global_Region__c
			FROM
				OpportunityLineItem
			WHERE
				Id IN :opportunityLineItemSet]);
		
		GSP_targetAssignmentHelper.AssignOpportunityLineItemTargets(proxyOpportunityLineItems);
		
		List<OpportunityLineItem> testOpportunityLineItems = new List<OpportunityLineItem>([
			SELECT
				Id,
				Rep_Product_Line_Target__c,
				Region_Product_Line_Target__c
			FROM
				OpportunityLineItem
			WHERE
				Id IN :opportunityLineItemSet]);
		System.assertEquals(testOpportunityLineItems.size(), 3);
		for (OpportunityLineItem testOpportunityLineItem : testOpportunityLineItems)
		{
			System.assertEquals(testOpportunityLineItem.Rep_Product_Line_Target__c, repProductLineTarget.Id);
			System.assertEquals(testOpportunityLineItem.Region_Product_Line_Target__c, regionProductLineTarget.Id);
		}
	}
	
	@isTest
	private static void test_ZeroMonthRepTargets()
	{
		Month_Rep_Target__c monthRepTarget = new Month_Rep_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Sales_Person__c = UserInfo.getUserId(),
			Won_Revenue__c = 1000,
			Pipeline_Opportunities__c = 1000,
			Commit_Opportunities__c = 1000,
			Commit_Amount__c = 1000,
			Closed_Won_Opportunities__c = 1000,
			Closed_Lost_Opportunities__c = 1000,
			Closed_Lost_Amount__c = 1000);
		insert monthRepTarget;
		
		GSP_targetAssignmentHelper.ZeroMonthRepTargets(new List<Month_Rep_Target__c>{ monthRepTarget });
		
		List<Month_Rep_Target__c> testMonthRepTargets = new List<Month_Rep_Target__c>([
			SELECT
				Id,
				Won_Revenue__c,
				Pipeline_Opportunities__c,
				Commit_Opportunities__c,
				Commit_Amount__c,
				Closed_Won_Opportunities__c,
				Closed_Lost_Opportunities__c,
				Closed_Lost_Amount__c
			FROM
				Month_Rep_Target__c
			WHERE
				Id = :monthRepTarget.Id]);
		System.assertEquals(testMonthRepTargets.size(), 1);
		
		Month_Rep_Target__c testMonthRepTarget = testMonthRepTargets.get(0);
		System.assertEquals(testMonthRepTarget.Won_Revenue__c, 0);
		System.assertEquals(testMonthRepTarget.Pipeline_Opportunities__c, 0);
		System.assertEquals(testMonthRepTarget.Commit_Opportunities__c, 0);
		System.assertEquals(testMonthRepTarget.Commit_Amount__c, 0);
		System.assertEquals(testMonthRepTarget.Closed_Won_Opportunities__c, 0);
		System.assertEquals(testMonthRepTarget.Closed_Lost_Opportunities__c, 0);
		System.assertEquals(testMonthRepTarget.Closed_Lost_Amount__c, 0);
	}
	
	@isTest
	private static void test_ZeroMonthTerritoryTarget()
	{
		Month_Territory_Target__c monthTerritoryTarget = new Month_Territory_Target__c(
			Year__c = String.valueOf(Date.today().year()),
			Start_Date__c = Date.today().toStartOfMonth(),
			Month__c = monthToStringMap.get(Date.today().month()),
			Unique_Field__c = 'Apex Test Territory',
			Won_Revenue__c = 1000,
			Pipeline_Opportunities__c = 1000,
			Commit_Amount__c = 1000,
			Closed_Won_Opportunities__c = 1000,
			Closed_Lost_Opportunities__c = 1000,
			Closed_Lost_Amount__c = 1000);
		insert monthTerritoryTarget;
		System.assertNotEquals(monthTerritoryTarget.Id, null);
		
		GSP_targetAssignmentHelper.ZeroMonthTerritoryTarget(new List<Month_Territory_Target__c>{ monthTerritoryTarget });
		
		List<Month_Territory_Target__c> testMonthTerritoryTargets = new List<Month_Territory_Target__c>([
			SELECT
				Id,
				Won_Revenue__c,
				Pipeline_Opportunities__c,
				Commit_Amount__c,
				Closed_Won_Opportunities__c,
				Closed_Lost_Opportunities__c,
				Closed_Lost_Amount__c
			FROM
				Month_Territory_Target__c
			WHERE
				Id = :monthTerritoryTarget.Id]);
		System.assertEquals(testMonthTerritoryTargets.size(), 1);
		Month_Territory_Target__c testMonthTerritoryTarget = testMonthTerritoryTargets.get(0);
		System.assertEquals(testMonthTerritoryTarget.Won_Revenue__c, 0);
		System.assertEquals(testMonthTerritoryTarget.Pipeline_Opportunities__c, 0);
		System.assertEquals(testMonthTerritoryTarget.Commit_Amount__c, 0);
		System.assertEquals(testMonthTerritoryTarget.Closed_Won_Opportunities__c, 0);
		System.assertEquals(testMonthTerritoryTarget.Closed_Lost_Opportunities__c, 0);
		System.assertEquals(testMonthTerritoryTarget.Closed_Lost_Amount__c, 0);
	}
	
	@isTest
	private static void test_ZeroRepProductLineTarget()
	{
		Rep_Product_Line_Target__c repProductLineTarget = new Rep_Product_Line_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Sales_Person__c = UserInfo.GetUserId(),
			Product_Line__c = PRODUCT_LINE,
			Won_Revenue__c = 1000,
			Won_Quantity__c = 1000,
			Commit_Quantity__c = 1000,
			Commit_Amount__c = 1000,
			Closed_Lost_Amount__c = 1000);
		insert repProductLineTarget;
		System.assertNotEquals(repProductLineTarget.Id, null);
		
		GSP_targetAssignmentHelper.ZeroRepProductLineTarget(new List<Rep_Product_Line_Target__c>{ repProductLineTarget });
		
		List<Rep_Product_Line_Target__c> testRepProductLineTargets = new List<Rep_Product_Line_Target__c>([
			SELECT
				Id,
				Won_Revenue__c,
				Won_Quantity__c,
				Commit_Quantity__c,
				Commit_Amount__c,
				Closed_Lost_Amount__c
			FROM
				Rep_Product_Line_Target__c
			WHERE
				Id = :repProductLineTarget.Id]);
		System.assertEquals(testRepProductLineTargets.size(), 1);
		Rep_Product_Line_Target__c testRepProductLineTarget = testRepProductLineTargets.get(0);
		System.assertEquals(testRepProductLineTarget.Won_Revenue__c, 0);
		System.assertEquals(testRepProductLineTarget.Won_Quantity__c, 0);
		System.assertEquals(testRepProductLineTarget.Commit_Quantity__c, 0);
		System.assertEquals(testRepProductLineTarget.Commit_Amount__c, 0);
		System.assertEquals(testRepProductLineTarget.Closed_Lost_Amount__c, 0);
	}
	
	@isTest
	private static void test_ZeroRegionProductLineTarget()
	{
		Region_Product_Line_Target__c regionProductLineTarget = new Region_Product_Line_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Region__c = 'Americas',
			Product_Line__c = PRODUCT_LINE,
			Won_Revenue__c = 1000,
			Won_Quantity__c = 1000,
			Pipeline_Created__c = 1000,
			Pipeline_Created_Qty__c = 1000,
			Commit_Quantity__c = 1000,
			Commit_Amount__c = 1000,
			Closed_Lost_Quantity__c = 1000,
			Closed_Lost_Amount__c = 1000);
		insert regionProductLineTarget;
		System.assertNotEquals(regionProductLineTarget.Id, null);
		
		GSP_targetAssignmentHelper.ZeroRegionProductLineTarget( new List<Region_Product_Line_Target__c>{ regionProductLineTarget });
		
		List<Region_Product_Line_Target__c> testRegionProductLineTargets = new List<Region_Product_Line_Target__c>([
			SELECT
				Id,
				Won_Revenue__c,
				Won_Quantity__c,
				Pipeline_Created__c,
				Pipeline_Created_Qty__c,
				Commit_Quantity__c,
				Commit_Amount__c,
				Closed_Lost_Quantity__c,
				Closed_Lost_Amount__c
			FROM
				Region_Product_Line_Target__c
			WHERE
				Id = :regionProductLineTarget.Id]);
		System.assertEquals(testRegionProductLineTargets.size(), 1);
		Region_Product_Line_Target__c testRegionProductLineTarget = testRegionProductLineTargets.get(0);
		System.assertEquals(testRegionProductLineTarget.Won_Revenue__c, 0);
		System.assertEquals(testRegionProductLineTarget.Won_Quantity__c, 0);
		System.assertEquals(testRegionProductLineTarget.Pipeline_Created__c, 0);
		System.assertEquals(testRegionProductLineTarget.Pipeline_Created_Qty__c, 0);
		System.assertEquals(testRegionProductLineTarget.Commit_Quantity__c, 0);
		System.assertEquals(testRegionProductLineTarget.Commit_Amount__c, 0);
		System.assertEquals(testRegionProductLineTarget.Closed_Lost_Quantity__c, 0);
		System.assertEquals(testRegionProductLineTarget.Closed_Lost_Amount__c, 0);
	}
	
	@isTest
	private static void test_ZeroRegionProductLineTargetLead()
	{
		Region_Product_Line_Target_Leads__c regionProductLineTargetLead = new Region_Product_Line_Target_Leads__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Start_Date__c = Date.today().toStartOfMonth(), 
			Region__c = 'Americas',
			Product_Line__c = PRODUCT_LINE,
			Leads_Created__c = 1000);
		insert regionProductLineTargetLead;
		System.assertNotEquals(regionProductLineTargetLead.Id, null);
		
		GSP_targetAssignmentHelper.ZeroRegionProductLineTargetLead(new List<Region_Product_Line_Target_Leads__c>{ regionProductLineTargetLead });
		
		List<Region_Product_Line_Target_Leads__c> testRegionProductLineTargetLeads = new List<Region_Product_Line_Target_Leads__c>([
			SELECT
				Id,
				Leads_Created__c
			FROM
				Region_Product_Line_Target_Leads__c
			WHERE
				Id = :regionProductLineTargetLead.Id]);
		System.assertEquals(testRegionProductLineTargetLeads.size(), 1);
		Region_Product_Line_Target_Leads__c testRegionProductLineTargetLead = testRegionProductLineTargetLeads.get(0);
		System.assertEquals(testRegionProductLineTargetLead.Leads_Created__c, 0);
	}
	
	@isTest(seeAllData=true)
	private static void test_SumOpportunityTargets()
	{
		Map<Integer, String> stageNameMap = new Map<Integer, String>{ 0 => 'Order won', 1 => 'Contract negotiation', 2 => 'Closed Lost' };
		Pricebook2 standardPricebook,
			customPricebook;
		List<Opportunity> opportunityCache = new List<Opportunity>();
		List<Product2> productCache = new List<Product2>();
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
		List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
		List<PricebookEntry> customPricebookEntryCache = new List<PricebookEntry>();
		List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();
		Set<Id> opportunityLineItemSet = new Set<Id>();
		Set<Id> opportunitySet = new Set<Id>();
		
		User user = [select Id FROM User where IsActive = true LIMIT 1];
		Territory2 territory;
		System.runAs(user)
		{
		
            Territory2Model tm = [Select id from Territory2Model limit 1];                
            Territory2Type ty = [Select id from Territory2type limit 1];
            
			territory = new Territory2(
				Name = 'Apex Test Territory', 
            	Territory2ModelId = tm.id, 
            	developerName = 'test',
            	territory2Typeid = ty.id);
			insert territory;
			System.assertNotEquals(territory.Id, null);
        }
		
		Account account = new Account(
			Name = 'Apex Test Account',
			ShippingCountry = 'US');
		insert account;
		System.assertNotEquals(account.Id, null);
		
		for (Integer i = 0; i < 3; i++)
		{
			Opportunity opportunity = new Opportunity(
				Name = 'Apex Test Opportunity',
				CloseDate = Date.today(),
				StageName = stageNameMap.get(i),
				AccountId = account.Id,
				Territory2Id = territory.Id,
				Reason_Lost__c = 'Test Reason',
				Reason_Lost_Detail__c = 'Test Reason Lost Detail',
            	Solution_Area_of_Interest__c='Energy');
			opportunityCache.add(opportunity);
		}
		
		insert opportunityCache;
		
		Rep_Product_Line_Target__c repProductLineTarget = new Rep_Product_Line_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Sales_Person__c = UserInfo.GetUserId(),
			Product_Line__c = PRODUCT_LINE,
			Won_Revenue__c = 0,
			Won_Quantity__c = 0,
			Commit_Quantity__c = 0,
			Commit_Amount__c = 0,
			Closed_Lost_Amount__c = 0);
		insert repProductLineTarget;
		System.assertNotEquals(repProductLineTarget.Id, null);
		
		Region_Product_Line_Target__c regionProductLineTarget = new Region_Product_Line_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Region__c = 'Americas',
			Product_Line__c = PRODUCT_LINE,
			Won_Revenue__c = 0,
			Won_Quantity__c = 0,
			Pipeline_Created__c = 0,
			Pipeline_Created_Qty__c = 0,
			Commit_Quantity__c = 0,
			Commit_Amount__c = 0,
			Closed_Lost_Quantity__c = 0,
			Closed_Lost_Amount__c = 0);
		insert regionProductLineTarget;
		
		Month_Territory_Target__c monthTerritoryTarget = new Month_Territory_Target__c(
			Year__c = String.valueOf(Date.today().year()),
			Start_Date__c = Date.today().toStartOfMonth(),
			Month__c = monthToStringMap.get(Date.today().month()),
			Territory__c = 'Apex Test Territory',
			Won_Revenue__c = 0,
			Pipeline_Opportunities__c = 0,
			Commit_Amount__c = 0,
			Closed_Won_Opportunities__c = 0,
			Closed_Lost_Opportunities__c = 0,
			Closed_Lost_Amount__c = 0);
		insert monthTerritoryTarget;
		System.assertNotEquals(monthTerritoryTarget.Id, null);
		
		Month_Rep_Target__c monthRepTarget = new Month_Rep_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Sales_Person__c = UserInfo.getUserId(),
			Won_Revenue__c = 0,
			Pipeline_Opportunities__c = 0,
			Commit_Opportunities__c = 0,
			Commit_Amount__c = 0,
			Closed_Won_Opportunities__c = 0,
			Closed_Lost_Opportunities__c = 0,
			Closed_Lost_Amount__c = 0);
		insert monthRepTarget;
		System.assertNotEquals(monthRepTarget.Id, null);
		
		
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
		
		
		for (Integer i = 0; i < 3; i++)
		{
			Product2 product = new Product2(
				Name = 'Apex Test Product ' + i,
				IsActive = true,
				Product_Line__c = PRODUCT_LINE);
			productCache.add(product);
		}
		insert productCache;
		
		
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
		
		for (Opportunity opportunity : opportunityCache)
		{
			opportunitySet.add(opportunity.Id);
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
		}
		insert opportunityLineItemCache;
		
		List<Opportunity> proxyOpportunities = new List<Opportunity>([
			SELECT
				Id,
				OwnerId,
				ForecastCategory,
				CloseDate,
				Month_Rep_Target__c,
				Territory2.Name,
				ForecastCategoryName
			FROM
				Opportunity
			WHERE
				Id IN :opportunitySet]);
		
		GSP_targetAssignmentHelper.AssignOpportunityTargets(proxyOpportunities);
		
		List<Opportunity> testOpportunities = new List<Opportunity>([
			SELECT
				Id, 
				Month_Rep_Target__c,
				Month_Territory_Target__c
			FROM
				Opportunity
			WHERE
				Id IN :opportunitySet]);
		System.assertEquals(testOpportunities.size(), 3);
		for (Opportunity testOpportunity : testOpportunities)
		{
			System.assertEquals(testOpportunity.Month_Rep_Target__c, monthRepTarget.Id);
			System.assertEquals(testOpportunity.Month_Territory_Target__c, monthTerritoryTarget.Id);
		}
		
		
		List<Opportunity> opportunities = new List<Opportunity>([
			SELECT
				Id,
				IsClosed,
				IsWon,
				ForecastCategory,
				ForecastCategoryName,
				Month_Rep_Target__c,
				Month_Territory_Target__c,
				Amount,
				StageName
			FROM
				Opportunity
			WHERE
				Id IN :opportunitySet]);

		GSP_targetAssignmentHelper.SumOpportunityTargets(opportunities);
		
		List<Month_Rep_Target__c> testMonthRepTargets = new List<Month_Rep_Target__c>([
			SELECT
				Id,
				Won_Revenue__c,
				Pipeline_Opportunities__c,
				Commit_Opportunities__c,
				Commit_Amount__c,
				Closed_Won_Opportunities__c,
				Closed_Lost_Opportunities__c,
				Closed_Lost_Amount__c
			FROM
				Month_Rep_Target__c
			WHERE
				Id = :monthRepTarget.Id]);

		System.assertEquals(testMonthRepTargets.size(), 1);
		Month_Rep_Target__c testMonthRepTarget = testMonthRepTargets.get(0);
		system.debug('\n\nMRT: ' + testMonthRepTarget + '\n\n');
		
		List<Month_Territory_Target__c> testMonthTerritoryTargets = new List<Month_Territory_Target__c>([
			SELECT
				Id,
				Won_Revenue__c,
				Pipeline_Opportunities__c,
				Commit_Amount__c,
				Closed_Won_Opportunities__c,
				Closed_Lost_Opportunities__c,
				Closed_Lost_Amount__c
			FROM
				Month_Territory_Target__c
			WHERE
				Id = :monthTerritoryTarget.Id]);
		System.assertEquals(testMonthTerritoryTargets.size(), 1);
		Month_Territory_Target__c testMonthTerritoryTarget = testMonthTerritoryTargets.get(0);
		System.debug('\n\nMTT: ' + testMonthTerritoryTarget + '\n\n');
	}
	
	@isTest(seeAllData=true)
	private static void test_SumProductLineTargets()
	{
		Map<Integer, String> stageNameMap = new Map<Integer, String>{ 0 => 'Order won', 1 => 'Contract negotiation', 2 => 'Closed Lost' };
		Pricebook2 standardPricebook,
			customPricebook;
		List<Opportunity> opportunityCache = new List<Opportunity>();
		List<Product2> productCache = new List<Product2>();
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
		List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
		List<PricebookEntry> customPricebookEntryCache = new List<PricebookEntry>();
		List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();
		Set<Id> opportunityLineItemSet = new Set<Id>();
		Set<Id> opportunitySet = new Set<Id>();
		
		User user = [select Id FROM User where IsActive = true LIMIT 1];
		Territory2 territory;
		System.runAs(user)
		{
		
            Territory2Model tm = [Select id from Territory2Model limit 1];                
            Territory2Type ty = [Select id from Territory2type limit 1];
            
			territory = new Territory2(
				Name = 'Apex Test Territory', 
            	Territory2ModelId = tm.id, 
            	developerName = 'test',
            	territory2Typeid = ty.id);
			insert territory;
			System.assertNotEquals(territory.Id, null);
        }
		
		Account account = new Account(
			Name = 'Apex Test Account',
			ShippingCountry = 'US');
		insert account;
		System.assertNotEquals(account.Id, null);
		
		for (Integer i = 0; i < 3; i++)
		{
			Opportunity opportunity = new Opportunity(
				Name = 'Apex Test Opportunity',
				CloseDate = Date.today(),
				StageName = stageNameMap.get(i),
				AccountId = account.Id,
				Territory2Id = territory.Id,
				Reason_Lost__c = 'Test Reason',
				Reason_Lost_Detail__c = 'Test Reason Lost Detail',
            	Solution_Area_of_Interest__c='Energy');
			opportunityCache.add(opportunity);
		}
		insert opportunityCache;
		
		Rep_Product_Line_Target__c repProductLineTarget = new Rep_Product_Line_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Sales_Person__c = UserInfo.GetUserId(),
			Product_Line__c = PRODUCT_LINE,
			Won_Revenue__c = 0,
			Won_Quantity__c = 0,
			Commit_Quantity__c = 0,
			Commit_Amount__c = 0,
			Closed_Lost_Amount__c = 0);
		insert repProductLineTarget;
		System.assertNotEquals(repProductLineTarget.Id, null);
		
		Region_Product_Line_Target__c regionProductLineTarget = new Region_Product_Line_Target__c(
			Month__c = monthToStringMap.get(Date.today().month()),
			Year__c = String.valueOf(Date.today().year()),
			Region__c = 'Americas',
			Product_Line__c = PRODUCT_LINE,
			Won_Revenue__c = 0,
			Won_Quantity__c = 0,
			Pipeline_Created__c = 0,
			Pipeline_Created_Qty__c = 0,
			Commit_Quantity__c = 0,
			Commit_Amount__c = 0,
			Closed_Lost_Quantity__c = 0,
			Closed_Lost_Amount__c = 0);
		insert regionProductLineTarget;		
		
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
		
		
		for (Integer i = 0; i < 3; i++)
		{
			Product2 product = new Product2(
				Name = 'Apex Test Product ' + i,
				IsActive = true,
				Product_Line__c = PRODUCT_LINE,
				IGOR_PAC__c = '1');
			productCache.add(product);
		}
		insert productCache;
		
		
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
		
		for (Opportunity opportunity : opportunityCache)
		{
			opportunitySet.add(opportunity.Id);
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
		}
		insert opportunityLineItemCache;
		
		for (OpportunityLineItem opportunityLineItem : opportunityLineItemCache)
		{
			opportunityLineItemSet.add(opportunityLineItem.Id);
		}
		
		List<OpportunityLineItem> proxyOpportunityLineItems = new List<OpportunityLineItem>([
			SELECT
				Id,
				Product_Line__c,
				Rep_Product_Line_Target__c,
				Region_Product_Line_Target__c,
				Opportunity.OwnerId,
				Opportunity.CloseDate,
				Opportunity.Global_Region__c
			FROM
				OpportunityLineItem
			WHERE
				Id IN :opportunityLineItemSet]);
		
		GSP_targetAssignmentHelper.AssignOpportunityLineItemTargets(proxyOpportunityLineItems);
		
		List<OpportunityLineItem> testOpportunityLineItems = new List<OpportunityLineItem>([
			SELECT
				Id,
				TotalPrice,
				Opportunity.Forecastcategory,
				Opportunity.ForecastCategoryName,
				IGOR_PAC__c,
				Rep_Product_Line_Target__c,
				Region_Product_Line_Target__c,
				Opportunity.IsWon,
				Opportunity.IsClosed
			FROM
				OpportunityLineItem
			WHERE
				Id IN :opportunityLineItemSet]);
		System.assertEquals(testOpportunityLineItems.size(), 9);			// 3 x 3 opportunities
		for (OpportunityLineItem testOpportunityLineItem : testOpportunityLineItems)
		{
			System.assertEquals(testOpportunityLineItem.Rep_Product_Line_Target__c, repProductLineTarget.Id);
			System.assertEquals(testOpportunityLineItem.Region_Product_Line_Target__c, regionProductLineTarget.Id);
		}
		
		GSP_targetAssignmentHelper.SumProductLineTargets(testOpportunityLineItems);
		
		List<Rep_Product_Line_Target__c> testRepProductLineTargets = new List<Rep_Product_Line_Target__c>([
			SELECT
				Id,
				Won_Revenue__c,
				Won_Quantity__c,
				Commit_Quantity__c,
				Commit_Amount__c,
				Closed_Lost_Amount__c
			FROM
				Rep_Product_Line_Target__c
			WHERE
				Id = :repProductLineTarget.Id]);
		System.assertEquals(testRepProductLineTargets.size(), 1);
		Rep_Product_Line_Target__c testRepProductLineTarget = testRepProductLineTargets.get(0);
		
		List<Region_Product_Line_Target__c> testRegionProductLineTargets = new List<Region_Product_Line_Target__c>([
			SELECT
				Id,
				Won_Revenue__c,
				Won_Quantity__c,
				Pipeline_Created__c,
				Pipeline_Created_Qty__c,
				Commit_Quantity__c,
				Commit_Amount__c,
				Closed_Lost_Quantity__c,
				Closed_Lost_Amount__c
			FROM
				Region_Product_Line_Target__c
			WHERE
				Id = :regionProductLineTarget.Id]);
		System.assertEquals(testRegionProductLineTargets.size(), 1);
		Region_Product_Line_Target__c testRegionProductLineTarget = testRegionProductLineTargets.get(0);
		
		System.debug('\n\nTRPLT: ' + testRegionProductLineTarget + '\n\n');
	}
}