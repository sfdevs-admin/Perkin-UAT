/**
* @File Name : B2BGTMOrderConfCont.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : March 3, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 3, 2025 |   | Initial Version
**/

public class B2BGTMOrderConfCont {
	@AuraEnabled(cacheable=true)
    public static Order getOrderWithItems(Id orderId) {
        // Query the standard Order object.
        // Adjust these fields as necessary:
        //   - OrderNumber, TotalAmount, CurrencyIsoCode, etc.
        //   - Make sure you have the relationships correct for your B2B setup.
        //   - "OrderItems" is the standard relationship from Order to OrderItem.
        Order b2bOrder = [
            SELECT Id,
                   OrderNumber,
                   TotalAmount,
                   CurrencyIsoCode,
                   (SELECT Id,
                           PricebookEntry.Product2Id,
                           PricebookEntry.Product2.Name,
                           Quantity,
                           UnitPrice
                      FROM OrderItems
                   )
              FROM Order
             WHERE Id = :orderId
             LIMIT 1
        ];

        return b2bOrder;
    }
}