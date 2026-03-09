public with sharing class GSP_targetAssignmentHelper
{
	private static Map<Integer, String> monthToStringMap = new Map<Integer, String>{ 1 => '01-Jan', 2 => '02-Feb', 3 => '03-Mar', 4 => '04-Apr', 5 => '05-May',
		6 => '06-Jun', 7 => '07-Jul', 8 => '08-Aug', 9 => '09-Sep', 10 => '10-Oct', 11 => '11-Nov', 12 => '12-Dec' };
	
	private static Map<String, Integer> stringToMonthMap = new Map<String, Integer>{ '01-Jan' => 1, '02-Feb' => 2, '03-Mar' => 3, '04-Apr' => 4, '05-May' => 5,
		'06-Jun' => 6, '07-Jul' => 7, '08-Aug' => 8, '09-Sep' => 9, '10-Oct' => 10, '11-Nov' => 11, '12-Dec' => 12 };
		
	public static void AssignOpportunityTargets(List<Opportunity> opportunityList)
	{
		Set<String> monthSet = new Set<String>();
		Set<String> yearSet = new Set<String>();
		Set<Id> ownerSet = new Set<Id>();
		Set<String> territorySet = new Set<String>();
		Map<Id, Opportunity> opportunityCacheMap = new Map<Id, Opportunity>();
		Map<Id, Map<Integer, Map<Integer, Month_Rep_Target__c>>> monthRepTargetMap = new Map<Id, Map<Integer, Map<Integer, Month_Rep_Target__c>>>();
		Map<String, Map<Integer, Map<Integer, Month_Territory_Target__c>>> monthTerritoryTargetMap = new Map<String, Map<Integer, Map<Integer, Month_Territory_Target__c>>>();  
		
		for (Opportunity opportunity : opportunityList)
		{
			monthSet.add(monthToStringMap.get(opportunity.CloseDate.Month()));
			yearSet.add(String.valueOf(opportunity.CloseDate.Year()));
			ownerSet.add(opportunity.OwnerId);
			territorySet.add(opportunity.Territory2.Name);System.debug('\n\nTERR: ' + opportunity.Territory2.Name + '\n\n');
		}
		
		for (Month_Territory_Target__c monthTerritoryTarget : [
			SELECT
				Id,
				Month__c,
				Year__c,
				Territory_Name__c
			FROM
				Month_Territory_Target__c
			WHERE
				Month__c IN :monthSet
			AND
				Year__c IN :yearSet
			AND
				Territory_Name__c IN :territorySet])
		{
			if (!monthTerritoryTargetMap.containsKey(monthTerritoryTarget.Territory_Name__c))
			{
				monthTerritoryTargetMap.put(monthTerritoryTarget.Territory_Name__c, new Map<Integer, Map<Integer, Month_Territory_Target__c>>());
			}
			
			if (!monthTerritoryTargetMap.get(monthTerritoryTarget.Territory_Name__c).containsKey(Integer.valueOf(monthTerritoryTarget.Year__c)))
			{
				monthTerritoryTargetMap.get(monthTerritoryTarget.Territory_Name__c).put(Integer.valueOf(monthTerritoryTarget.Year__c),
					new Map<Integer, Month_Territory_Target__c>());
			}
			monthTerritoryTargetMap.get(monthTerritoryTarget.Territory_Name__c).get(Integer.valueOf(monthTerritoryTarget.Year__c)).
				put(stringToMonthMap.get(monthTerritoryTarget.Month__c), monthTerritoryTarget);
		}
				
		
		for (Month_Rep_Target__c monthRepTarget : [
			SELECT
				Id,
				Month__c,
				Year__c,
				Sales_Person__c
			FROM
				Month_Rep_Target__c
			WHERE
				Month__c IN :monthSet
			AND
				Year__c IN :yearSet
			AND
				Sales_Person__c IN :ownerSet])
		{
			if (!monthRepTargetMap.containsKey(monthRepTarget.Sales_Person__c))
			{
				monthRepTargetMap.put(monthRepTarget.Sales_Person__c, new Map<Integer, Map<Integer, Month_Rep_Target__c>>());
			}
			if (!monthRepTargetMap.get(monthRepTarget.Sales_Person__c).containsKey(Integer.valueOf(monthRepTarget.Year__c)))
			{
				monthRepTargetMap.get(monthRepTarget.Sales_Person__c).put(Integer.valueOf(monthRepTarget.Year__c), new Map<Integer, Month_Rep_Target__c>());
			}
			monthRepTargetMap.get(monthRepTarget.Sales_Person__c).get(Integer.valueOf(monthRepTarget.Year__c)).put(stringToMonthMap.get(monthRepTarget.Month__c), monthRepTarget);
		}
		
		for (Opportunity opportunity : opportunityList)
		{
			if (monthRepTargetMap.containsKey(opportunity.OwnerId))
			{
				Map<Integer, Map<Integer, Month_Rep_Target__c>> map1 = monthRepTargetMap.get(opportunity.OwnerId);
				if (map1.containsKey(opportunity.CloseDate.Year()))
				{
					Map<Integer, Month_Rep_Target__c> map2 = map1.get(opportunity.CloseDate.Year());
					if (map2.containsKey(opportunity.CloseDate.Month()))
					{
						opportunity.Month_Rep_Target__c = map2.get(opportunity.CloseDate.Month()).Id;
						opportunityCacheMap.put(opportunity.Id, opportunity);
					}
				}
			}
			
			if (monthTerritoryTargetMap.containsKey(opportunity.Territory2.Name))
			{
				Map<Integer, Map<Integer, Month_Territory_Target__c>> map1 = monthTerritoryTargetMap.get(opportunity.Territory2.Name);
				if (map1.containsKey(opportunity.CloseDate.Year()))
				{
					 Map<Integer, Month_Territory_Target__c> map2 = map1.get(opportunity.CloseDate.Year());
					 if (map2.containsKey(opportunity.CloseDate.Month()))
					 {
					 	opportunity.Month_Territory_Target__c = map2.get(opportunity.CloseDate.Month()).Id;
					 	opportunityCacheMap.put(opportunity.Id, opportunity);
					 }
				}
			}
		}
		if (!opportunityCacheMap.isEmpty())
		{
			update opportunityCacheMap.values();
		}
	}
	
	public static void AssignOpportunityLineItemTargets(List<OpportunityLineItem> opportunityLineItemList)
	{
		Set<Id> ownerSet = new Set<Id>();
		Set<String> monthSet = new Set<String>();
		Set<String> yearSet = new Set<String>();
		Set<String> productLineSet = new Set<String>();
		Set<String> regionSet = new Set<String>();
		Map<Id, OpportunityLineItem> opportunityLineItemCacheMap = new Map<Id, OpportunityLineItem>();
		// Map => UserId => Product Line => Year => Month => Rep_Product_Line_Target__c
		Map<Id, Map<String, Map<Integer, Map<Integer, Rep_Product_Line_Target__c>>>> repProductLineTargetMap =
			new Map<Id, Map<String, Map<Integer, Map<Integer, Rep_Product_Line_Target__c>>>>();
		// Map => Product Line => Region => Year => Month
		Map<String, Map<String, Map<Integer, Map<Integer, Region_Product_Line_Target__c>>>> regionProductLineTargetMap =
			new Map<String, Map<String, Map<Integer, Map<Integer, Region_Product_Line_Target__c>>>>();
			
		for (OpportunityLineItem opportunityLineItem : opportunityLineItemList)
		{
			ownerSet.add(opportunityLineItem.Opportunity.OwnerId);
			productLineSet.add(opportunityLineItem.Product_Line__c);
			monthSet.add(monthToStringMap.get(opportunityLineItem.Opportunity.CloseDate.Month()));
			yearSet.add(String.valueOf(opportunityLineItem.Opportunity.CloseDate.Year()));
			regionSet.add(opportunityLineItem.Opportunity.Global_Region__c);
		}
		
		for (Rep_Product_Line_Target__c repProductLineTarget : [
			SELECT
				Id,
				Month__c,
				Year__c,
				Sales_Person__c,
				Product_Line__c
			FROM
				Rep_Product_Line_Target__c
			WHERE
				Month__c IN :monthSet
			AND
				Year__c IN :yearSet
			AND
				Sales_Person__c IN :ownerSet
			AND
				Product_Line__c IN :productLineSet])
		{
			if (!repProductLineTargetMap.containsKey(repProductLineTarget.Sales_Person__c))
			{
				repProductLineTargetMap.put(repProductLineTarget.Sales_Person__c, new Map<String, Map<Integer, Map<Integer, Rep_Product_Line_Target__c>>>());
			}
			if (!repProductLineTargetMap.get(repProductLineTarget.Sales_Person__c).containsKey(repProductLineTarget.Product_Line__c))
			{
				repProductLineTargetMap.get(repProductLineTarget.Sales_Person__c).put(repProductLineTarget.Product_Line__c,
					new  Map<Integer, Map<Integer, Rep_Product_Line_Target__c>>());
			}
			if (!repProductLineTargetMap.get(repProductLineTarget.Sales_Person__c).get(repProductLineTarget.Product_Line__c).
				containsKey(Integer.valueOf(repProductLineTarget.Year__c)))
			{
				repProductLineTargetMap.get(repProductLineTarget.Sales_Person__c).get(repProductLineTarget.Product_Line__c).
					put(Integer.valueOf(repProductLineTarget.Year__c), new Map<Integer, Rep_Product_Line_Target__c>());
			}
			repProductLineTargetMap.get(repProductLineTarget.Sales_Person__c).get(repProductLineTarget.Product_Line__c).
					get(Integer.valueOf(repProductLineTarget.Year__c)).put(stringToMonthMap.get(repProductLineTarget.Month__c), repProductLineTarget);
		}

		for (Region_Product_Line_Target__c regionProductLineTarget : [
			SELECT
				Id,
				Month__c,
				Year__c,
				Region__c,
				Product_Line__c
			FROM
				Region_Product_Line_Target__c
			WHERE
				Month__c IN :monthSet
			AND
				Year__c IN :yearSet
			AND
				Product_Line__c IN :productLineSet
			AND
				Region__c IN :regionSet])
		{
			if (!regionProductLineTargetMap.containsKey(regionProductLineTarget.Product_Line__c))
			{
				regionProductLineTargetMap.put(regionProductLineTarget.Product_Line__c, new Map<String, Map<Integer, Map<Integer, Region_Product_Line_Target__c>>>());
			}
			if (!regionProductLineTargetMap.get(regionProductLineTarget.Product_Line__c).containsKey(regionProductLineTarget.Region__c))
			{
				regionProductLineTargetMap.get(regionProductLineTarget.Product_Line__c).
					put(regionProductLineTarget.Region__c, new Map<Integer, Map<Integer, Region_Product_Line_Target__c>>());
			}
			if (!regionProductLineTargetMap.get(regionProductLineTarget.Product_Line__c).get(regionProductLineTarget.Region__c).
				containsKey(Integer.valueOf(regionProductLineTarget.Year__c)))
			{
				regionProductLineTargetMap.get(regionProductLineTarget.Product_Line__c).get(regionProductLineTarget.Region__c).
					put(Integer.valueOf(regionProductLineTarget.Year__c), new Map<Integer, Region_Product_Line_Target__c>());
			}
			regionProductLineTargetMap.get(regionProductLineTarget.Product_Line__c).get(regionProductLineTarget.Region__c).
				get(Integer.valueOf(regionProductLineTarget.Year__c)).put(stringToMonthMap.get(regionProductLineTarget.Month__c), regionProductLineTarget);
		}
		
		for (OpportunityLineItem opportunityLineItem : opportunityLineItemList)
		{
			if (repProductLineTargetMap.containsKey(opportunityLineItem.Opportunity.OwnerId))
			{
				Map<String, Map<Integer, Map<Integer, Rep_Product_Line_Target__c>>> map1 = repProductLineTargetMap.get(opportunityLineItem.Opportunity.OwnerId);
				if (map1.containsKey(opportunityLineItem.Product_Line__c))
				{
					Map<Integer, Map<Integer, Rep_Product_Line_Target__c>> map2 = map1.get(opportunityLineItem.Product_Line__c);
					if (map2.containsKey(opportunityLineItem.Opportunity.CloseDate.Year()))
					{
						Map<Integer, Rep_Product_Line_Target__c> map3 = map2.get(opportunityLineItem.Opportunity.CloseDate.Year());
						if (map3.containsKey(opportunityLineItem.Opportunity.CloseDate.Month()))
						{
							opportunityLineItem.Rep_Product_Line_Target__c = map3.get(opportunityLineItem.Opportunity.CloseDate.Month()).Id;
							opportunityLineItemCacheMap.put(opportunityLineItem.Id, opportunityLineItem);
						}
					}
				}
			}
			
			if (regionProductLineTargetMap.containsKey(opportunityLineItem.Product_Line__c))
			{
				Map<String, Map<Integer, Map<Integer, Region_Product_Line_Target__c>>> map1 = regionProductLineTargetMap.get(opportunityLineItem.Product_Line__c);
				if (map1.containsKey(opportunityLineItem.Opportunity.Global_Region__c))
				{
					Map<Integer, Map<Integer, Region_Product_Line_Target__c>> map2 = map1.get(opportunityLineItem.Opportunity.Global_Region__c);
					if (map2.containsKey(opportunityLineItem.Opportunity.CloseDate.Year()))
					{
						 Map<Integer, Region_Product_Line_Target__c> map3 = map2.get(opportunityLineItem.Opportunity.CloseDate.Year());
						 if (map3.containsKey(opportunityLineItem.Opportunity.CloseDate.Month()))
						 {
						 	opportunityLineItem.Region_Product_Line_Target__c = map3.get(opportunityLineItem.Opportunity.CloseDate.Month()).Id;
						 	opportunityLineItemCacheMap.put(opportunityLineItem.Id, opportunityLineItem);
						 }
					}
				}
			}
		}
		if (!opportunityLineItemCacheMap.isEmpty())
		{
			update opportunityLineItemCacheMap.values();
		}
	}
	
	public static void AssignLeadTargets(List<Lead> leadList)
	{
		Set<String> productLineSet = new Set<String>();
		Set<String> monthSet = new Set<String>();
		Set<String> yearSet = new Set<String>();
		Set<String> regionSet = new Set<String>();
		List<Lead> leadCache = new List<Lead>();
		
		// Map Region => Product Line => Year => Month
		Map<String, Map<String, Map<Integer, Map<Integer, Region_Product_Line_Target_Leads__c>>>> regionProductLineTargetLeadMap =
			new Map<String, Map<String, Map<Integer, Map<Integer, Region_Product_Line_Target_Leads__c>>>>();
		
		for (Lead lead : leadList)
		{
			productLineSet.add(lead.Product_Line__c);
			regionSet.add(lead.Global_Region__c);
			monthSet.add(monthToStringMap.get(lead.CreatedDate.Month()));
			yearSet.add(String.valueOf(lead.CreatedDate.Year()));
		}
		
		for (Region_Product_Line_Target_Leads__c regionProductLineTargetLead : [
			SELECT
				Year__c,
				Month__c,
				Region__c,
				Product_Line__c
			FROM
				Region_Product_Line_Target_Leads__c
			WHERE
				Product_Line__c IN :productLineSet
			AND
				Region__c IN :regionSet
			AND
				Month__c IN :monthSet
			AND
				Year__c IN :yearSet])
		{
			if (!regionProductLineTargetLeadMap.containsKey(regionProductLineTargetLead.Region__c))
			{
				regionProductLineTargetLeadMap.put(regionProductLineTargetLead.Region__c, new Map<String, Map<Integer, Map<Integer, Region_Product_Line_Target_Leads__c>>>());
			}
			if (!regionProductLineTargetLeadMap.get(regionProductLineTargetLead.Region__c).containsKey(regionProductLineTargetLead.Product_Line__c))
			{
				regionProductLineTargetLeadMap.get(regionProductLineTargetLead.Region__c).put(regionProductLineTargetLead.Product_Line__c,
					new Map<Integer, Map<Integer, Region_Product_Line_Target_Leads__c>>());
			}
			if (!regionProductLineTargetLeadMap.get(regionProductLineTargetLead.Region__c).get(regionProductLineTargetLead.Product_Line__c).
				containsKey(Integer.valueOf(regionProductLineTargetLead.Year__c)))
			{
				regionProductLineTargetLeadMap.get(regionProductLineTargetLead.Region__c).get(regionProductLineTargetLead.Product_Line__c).
					put(Integer.valueOf(regionProductLineTargetLead.Year__c), new Map<Integer, Region_Product_Line_Target_Leads__c>());
			}
			regionProductLineTargetLeadMap.get(regionProductLineTargetLead.Region__c).get(regionProductLineTargetLead.Product_Line__c).
				get(Integer.valueOf(regionProductLineTargetLead.Year__c)).put(stringToMonthMap.get(regionProductLineTargetLead.Month__c), regionProductLineTargetLead);
		}
		
		for (Lead lead : leadList)
		{
			if (regionProductLineTargetLeadMap.containsKey(lead.Global_Region__c))
			{
				Map<String, Map<Integer, Map<Integer, Region_Product_Line_Target_Leads__c>>> map1 = regionProductLineTargetLeadMap.get(lead.Global_Region__c);
				if (map1.containsKey(lead.Product_Line__c))
				{
					Map<Integer, Map<Integer, Region_Product_Line_Target_Leads__c>> map2 = map1.get(lead.Product_Line__c.split(';')[0]);
					if (map2.containsKey(lead.CreatedDate.Year()))
					{
						Map<Integer, Region_Product_Line_Target_Leads__c> map3 = map2.get(lead.CreatedDate.Year());
						if (map3.containsKey(lead.CreatedDate.Month()))
						{
							lead.Region_Product_Line_Target_Lead__c = map3.get(lead.CreatedDate.Month()).Id;
							leadCache.add(lead);
						}
					}
				}
			}
		}
		if (!leadCache.isEmpty())
		{
			GSP_TriggerContext.DisableLeadTriggers = true;
			update leadCache;
			GSP_TriggerContext.DisableLeadTriggers = false;
		}	
	}
	
	public static void ZeroMonthRepTargets(List<Month_Rep_Target__c> monthRepTargetList)
	{
		for (Month_Rep_Target__c monthRepTarget : monthRepTargetList)
		{
			monthRepTarget.Won_Revenue__c =
			monthRepTarget.Pipeline_Opportunities__c =
			monthRepTarget.Commit_Opportunities__c =
			monthRepTarget.Commit_Amount__c =
			monthRepTarget.Closed_Won_Opportunities__c =
			monthRepTarget.Closed_Lost_Opportunities__c =
			monthRepTarget.Closed_Lost_Amount__c = 0;
		}
		update monthRepTargetList;
	}
	
	public static void ZeroMonthTerritoryTarget(List<Month_Territory_Target__c> monthTerritoryTargetList)
	{
		for (Month_Territory_Target__c monthTerritoryTarget : monthTerritoryTargetList)
		{
			monthTerritoryTarget.Won_Revenue__c =
			monthTerritoryTarget.Pipeline_Opportunities__c =
			monthTerritoryTarget.Commit_Amount__c = 
			monthTerritoryTarget.Closed_Won_Opportunities__c =
			monthTerritoryTarget.Closed_Lost_Opportunities__c =
			monthTerritoryTarget.Closed_Lost_Amount__c = 0;
		}
		update monthTerritoryTargetList;
	}
	
	public static void ZeroRepProductLineTarget(List<Rep_Product_Line_Target__c> repProductLineTargetList)
	{
		for (Rep_Product_Line_Target__c repProductLineTarget : repProductLineTargetList)
		{
			repProductLineTarget.Won_Revenue__c =
			repProductLineTarget.Won_Quantity__c =
			repProductLineTarget.Commit_Quantity__c =
			repProductLineTarget.Commit_Amount__c =
			repProductLineTarget.Closed_Lost_Amount__c = 0;
		}
		update repProductLineTargetList;
	}
	
	public static void ZeroRegionProductLineTarget(List<Region_Product_Line_Target__c> regionProductLineTargetList)
	{
		for (Region_Product_Line_Target__c regionProductLineTarget : regionProductLineTargetList)
		{
			regionProductLineTarget.Won_Revenue__c =
			regionProductLineTarget.Won_Quantity__c =
			regionProductLineTarget.Pipeline_Created__c =
			regionProductLineTarget.Pipeline_Created_Qty__c =
			regionProductLineTarget.Commit_Quantity__c =
			regionProductLineTarget.Commit_Amount__c =
			regionProductLineTarget.Closed_Lost_Quantity__c =
			regionProductLineTarget.Closed_Lost_Amount__c = 0;
		}
		update regionProductLineTargetList;
	}
	
	public static void ZeroRegionProductLineTargetLead(List<Region_Product_Line_Target_Leads__c> regionProductLineTargetLeadList)
	{
		for (Region_Product_Line_Target_Leads__c regionProductLineTargetLead : regionProductLineTargetLeadList)
		{
			regionProductLineTargetLead.Leads_Created__c = 0;
		}
		update regionProductLineTargetLeadList;
	}
	
	public static void SumOpportunityTargets(List<Opportunity> opportunityList)
	{
		Set<Id> monthlyRepTargetSet = new Set<Id>();
		Set<Id> monthTerritoryTargetSet = new Set<Id>();
		for (Opportunity opportunity : opportunityList)
		{
			monthlyRepTargetSet.add(opportunity.Month_Rep_Target__c);
			monthTerritoryTargetSet.add(opportunity.Month_Territory_Target__c);
		}
		
		Map<Id, Month_Rep_Target__c> monthlyRepTargetMap = new Map<Id, Month_Rep_Target__c>([
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
				Id IN :monthlyRepTargetSet]);
		
		Map<Id, Month_Territory_Target__c> monthTerritoryTargetMap = new Map<Id, Month_Territory_Target__c>([
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
				Id = :monthTerritoryTargetSet]);
		System.debug('\n\nMRT: ' + monthlyRepTargetMap + '\n\n');
		for (Opportunity opportunity : opportunityList)
		{
			if (opportunity.Amount == null)
			{
				opportunity.Amount = 0;
			}
			System.debug('\n\nMRT: ' + monthlyRepTargetMap + ' : ' + opportunity.Month_Rep_Target__c + '\n\n');
			if (monthlyRepTargetMap.containsKey(opportunity.Month_Rep_Target__c))
			{
				Month_Rep_Target__c monthlyRepTarget = monthlyRepTargetMap.get(opportunity.Month_Rep_Target__c);
				
				if (opportunity.IsClosed)
				{
					if (opportunity.IsWon)
					{
						monthlyRepTarget.Closed_Won_Opportunities__c++;
						monthlyRepTarget.Won_Revenue__c += opportunity.Amount;
					}
					else
					{
						monthlyRepTarget.Closed_Lost_Opportunities__c++;
						monthlyRepTarget.Closed_Lost_Amount__c += opportunity.Amount;
					}
				}
				else
				{System.debug('\n\nFC: ' + opportunity.ForecastCategoryName + '\n\n');
					monthlyRepTarget.Pipeline_Opportunities__c++;
					if (opportunity.ForecastCategoryName == 'Commit')
					{
						monthlyRepTarget.Commit_Amount__c += opportunity.Amount;
					}
				}
				if (opportunity.ForecastCategoryName == 'Commit')
				{
					monthlyRepTarget.Commit_Opportunities__c++;
				}
			}
			
			if (monthTerritoryTargetMap.containsKey(opportunity.Month_Territory_Target__c))
			{
				Month_Territory_Target__c monthTerritoryTarget = monthTerritoryTargetMap.get(opportunity.Month_Territory_Target__c);
				if (opportunity.IsClosed)
				{
					if (opportunity.IsWon)
					{
						monthTerritoryTarget.Closed_Won_Opportunities__c++;
						monthTerritoryTarget.Won_Revenue__c += opportunity.Amount;
					}
					else
					{
						monthTerritoryTarget.Closed_Lost_Opportunities__c++;
						monthTerritoryTarget.Closed_Lost_Amount__c += opportunity.Amount;
					}
				}
				else
				{
					monthTerritoryTarget.Pipeline_Opportunities__c++;
				}
				if (opportunity.ForecastCategoryName == 'Commit')
				{
					monthTerritoryTarget.Commit_Amount__c += opportunity.Amount;
				}
			}
		}
		if (!monthlyRepTargetMap.isEmpty())
		{
			update monthlyRepTargetMap.values();
		}
		if (!monthTerritoryTargetMap.isEmpty())
		{
			update monthTerritoryTargetMap.values();
		}
	}
	
	public static void SumProductLineTargets(List<OpportunityLineItem> opportunityLineItemList)
	{
		Set<Id> repProductLineTargetSet = new Set<Id>();
		Set<Id> regionProductLineTargetSet = new Set<Id>();
		for (OpportunityLineItem opportunityLineItem : opportunityLineItemList)
		{
			if (opportunityLineItem.Rep_Product_Line_Target__c != null)
			{
				repProductLineTargetSet.add(opportunityLineItem.Rep_Product_Line_Target__c);
			}
			if (opportunityLineItem.Region_Product_Line_Target__c != null)
			{
				regionProductLineTargetSet.add(opportunityLineItem.Region_Product_Line_Target__c);
			}
		}
		
		Map<Id, Rep_Product_Line_Target__c> repProductLineTargetMap = new Map<Id, Rep_Product_Line_Target__c>([
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
				Id IN :repProductLineTargetSet]);
		
		Map<Id, Region_Product_Line_Target__c> regionProductLineTargetMap = new Map<Id, Region_Product_Line_Target__c>([
			SELECT
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
				Id IN :regionProductLineTargetSet]);
				 
		
		for (OpportunityLineItem opportunityLineItem : opportunityLineItemList)
		{
			if (repProductLineTargetMap.containsKey(opportunityLineItem.Rep_Product_Line_Target__c))
			{
				Rep_Product_Line_Target__c repProductLineTarget = repProductLineTargetMap.get(opportunityLineItem.Rep_Product_Line_Target__c);
				if (opportunityLineItem.Opportunity.IsClosed)
				{
					if (opportunityLineItem.Opportunity.IsWon)
					{
						repProductLineTarget.Won_Revenue__c += opportunityLineItem.TotalPrice;
						if (opportunityLineItem.IGOR_PAC__c == '1')
						{
							repProductLineTarget.Won_Quantity__c++;
						}
							
					}
					else
					{
						repProductLineTarget.Closed_Lost_Amount__c = opportunityLineItem.TotalPrice;
					}
				}
				if (opportunityLineItem.Opportunity.ForecastCategoryName == 'Commit')
				{
					repProductLineTarget.Commit_Amount__c += opportunityLineItem.TotalPrice;
					if (opportunityLineItem.IGOR_PAC__c == '1')
					{
						repProductLineTarget.Commit_Quantity__c++;
					}
				}
			}
			if (regionProductLineTargetMap.containsKey(opportunityLineItem.Region_Product_Line_Target__c))
			{
				Region_Product_Line_Target__c regionProductLineTarget = regionProductLineTargetMap.get(opportunityLineItem.Region_Product_Line_Target__c);
				if (opportunityLineItem.Opportunity.IsClosed)
				{
					if (opportunityLineItem.Opportunity.IsWon)
					{
						regionProductLineTarget.Won_Revenue__c += opportunityLineItem.TotalPrice;
						if (opportunityLineItem.IGOR_PAC__c == '1')
						{
							regionProductLineTarget.Won_Quantity__c++;
						}
					}
					else
					{
						regionProductLineTarget.Closed_Lost_Amount__c += opportunityLineItem.TotalPrice;
						if (opportunityLineItem.IGOR_PAC__c == '1')
						{
							regionProductLineTarget.Closed_Lost_Quantity__c++;
						}
					}
				}
				if (opportunityLineItem.Opportunity.ForecastCategoryName == 'Commit')
				{
					regionProductLineTarget.Commit_Amount__c += opportunityLineItem.TotalPrice;
					if (opportunityLineItem.IGOR_PAC__c == '1')
					{
						regionProductLineTarget.Commit_Quantity__c++;
					}
				}
				regionProductLineTarget.Pipeline_Created__c += opportunityLineItem.TotalPrice;
				regionProductLineTarget.Pipeline_Created_Qty__c++;
			}
		}
		
		if (!repProductLineTargetMap.isEmpty())
		{
			update repProductLineTargetMap.values();
		}
		if (!regionProductLineTargetMap.isEmpty())
		{
			update regionProductLineTargetMap.values();
		}
	}
	
	public static void SumLeadTargets(List<Lead> leadList)
	{
		Set<Id> regionProductLineTargetLeadSet = new Set<Id>();
		for (Lead lead : leadList)
		{
			regionProductLineTargetLeadSet.add(lead.Region_Product_Line_Target_Lead__c);
		}
		
		Map<Id, Region_Product_Line_Target_Leads__c> regionProductLineTargetLeadMap = new Map<Id, Region_Product_Line_Target_Leads__c>([
			SELECT
				Id,
				Leads_Created__c
			FROM
				Region_Product_Line_Target_Leads__c
			WHERE
				Id IN :regionProductLineTargetLeadSet]);
				
		for (Lead lead : leadList)
		{
			if (regionProductLineTargetLeadMap.containsKey(lead.Region_Product_Line_Target_Lead__c))
			{
				Region_Product_Line_Target_Leads__c regionProductLineTargetLead = regionProductLineTargetLeadMap.get(lead.Region_Product_Line_Target_Lead__c);
				regionProductLineTargetLead.Leads_Created__c++;
			}
		}
		if (!regionProductLineTargetLeadMap.isEmpty())
		{
			update regionProductLineTargetLeadMap.values();
		}
	}
}