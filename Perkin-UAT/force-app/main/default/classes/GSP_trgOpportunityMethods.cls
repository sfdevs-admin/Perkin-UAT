public with sharing class GSP_trgOpportunityMethods
{
    public static void UpdateTargets(Map<Id, Opportunity> opportunityMap)
    {
        for (Opportunity opportunity : opportunityMap.values())
        {
            opportunity.Month_Territory_Target__c = null;
            opportunity.Month_Rep_Target__c = null;
        }
        
        List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>([
            SELECT
                Id,
                Region_Product_Line_Target__c,
                Rep_Product_Line_Target__c
            FROM
                OpportunityLineItem
            WHERE
                OpportunityId IN :opportunityMap.keySet()]);
        for (OpportunityLineItem opportunityLineItem : opportunityLineItems)
        {
            opportunityLineItem.Region_Product_Line_Target__c = null;
            opportunityLineItem.Rep_Product_Line_Target__c = null;
        }
        
        if (!opportunityLineItems.isEmpty())
        {
            update opportunityLineItems;
        }
    }
}