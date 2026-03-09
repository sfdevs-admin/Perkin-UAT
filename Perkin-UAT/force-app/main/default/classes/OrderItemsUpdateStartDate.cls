public class OrderItemsUpdateStartDate {
    
    @InvocableMethod
    public static void updateOrderItems(List<Id> orderIds)
    {
        Set<Id> failedOrderProducts = new Set<Id>();
        System.debug('OrderProduct updating for order'+ orderIds);
        List<orderItem> orderItemsToUpdate = new List<orderItem>();
        List<OrderItem> orderItemsList =[Select Id,ServiceDate /*,SBQQ__QuoteLine__r.Name,
                                         SBQQ__QuoteLine__r.CPQ_Product_Service_Start_Date__c,SBQQ__QuoteLine__r.SBQQ__Quote__c */ From OrderItem 
                                         Where /*SBQQ__QuoteLine__r.CPQ_Product_Service_Start_Date__c !=null and */ OrderId IN:orderIds /*and SBQQ__SegmentKey__c = NULL*/
                                        ];
        for(OrderItem ordItm : orderItemsList )
        {
           // if(ordItm.ServiceDate != ordItm.SBQQ__QuoteLine__r.CPQ_Product_Service_Start_Date__c)
            {
              //  ordItm.ServiceDate=ordItm.SBQQ__QuoteLine__r.CPQ_Product_Service_Start_Date__c;
                orderItemsToUpdate.add(ordItm);
            }
        }
        System.debug('OrderProduct updating for order'+ orderItemsToUpdate.size());
        if(orderItemsToUpdate.size() > 0 )
        {   
            List<Database.SaveResult> updateResults = Database.update(orderItemsToUpdate, false);
            for(Integer i=0;i<updateResults.size();i++){
                if (!updateResults.get(i).isSuccess()){
                    // DML operation failed
                   // failedOrderProducts.add(orderItemsToUpdate.get(i).SBQQ__QuoteLine__r.SBQQ__Quote__c);
                }
            }
        }
            
           /* List<Order> orderList=[Select SBQQ__Quote__c From Order Where Id IN : orderIds];
            Set<Id> QuoteIds = new Set<Id>();
            for(Order ord : orderList)
            {
                QuoteIds.add(ord.SBQQ__Quote__c);
            }
            List<SBQQ__Quote__c> quoteList= [Select Id,Order_Dates_Status__c From SBQQ__Quote__c Where Id IN: QuoteIds and Order_Dates_Status__c !='Completed' ];
            for(SBQQ__Quote__c quote :  quoteList)
            {
                if(failedOrderProducts !=null && failedOrderProducts.contains(quote.Id))
                   {
                       quote.Order_Dates_Status__c='Failed';
                   }
                   else
                   {
                    quote.Order_Dates_Status__c='Completed';
                   }
            }
            
            if(null  !=quoteList  && quoteList.size() > 0 )
            {
                update quoteList;
            }*/
        }
    }