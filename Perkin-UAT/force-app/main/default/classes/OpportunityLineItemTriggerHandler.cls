public class OpportunityLineItemTriggerHandler{
    
    public static void updateProdLinesOnOpp(List<OpportunityLineItem> listOfOppLineItems){
        Set<Id> OpportunityIds= new Set<ID>();
        for(OpportunityLineItem iterOppItem : listOfOppLineItems){
            OpportunityIds.add(iterOppItem.OpportunityId);       
        }
        
        Map<Id, String> mapOfOppIdtoProdLine = new Map<Id, String>();        
        Set<String> productLines = new Set<String>();
        for(OpportunityLineItem  iterProd : [select Id, Product_Line__c,OpportunityId from OpportunityLineItem where OpportunityId in: OpportunityIds ORDER BY Product_Line__c]){
            system.debug('iterProddddd '+iterProd.Product_Line__c);
            system.debug('mapOfOppIdtoProdLineeeee '+mapOfOppIdtoProdLine);
            if(mapOfOppIdtoProdLine.containsKey(iterProd.OpportunityId)){
                if(!productLines.contains(iterProd.OpportunityId+'-'+iterProd.Product_Line__c)){
                    //prodLine +=  mapOfOppIdtoProdLine.get(iterProd.OpportunityId) +';';
                    mapOfOppIdtoProdLine.put(iterProd.OpportunityId,mapOfOppIdtoProdLine.get(iterProd.OpportunityId) +iterProd.Product_Line__c+';');
                    productLines.add(iterProd.OpportunityId+'-'+iterProd.Product_Line__c);
                }
            }
            else{
                productLines.add(iterProd.OpportunityId+'-'+iterProd.Product_Line__c);
                mapOfOppIdtoProdLine.put(iterProd.OpportunityId,iterProd.Product_Line__c + ';');
            }   
        }
        
        List<Opportunity> listOfOpp = new List<Opportunity>();
        for(Opportunity iterOpp : [select Id, Product_Line_Name__c from Opportunity where Id in: OpportunityIds ]){            
            iterOpp.Product_Line_Name__c = mapOfOppIdtoProdLine.get(iterOpp.Id);
            listOfOpp.add(iterOpp);           
        }
        
        update listOfOpp;
        
    }
}