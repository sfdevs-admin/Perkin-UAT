/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 09-17-2025
 * @last modified by  : Swati Chilap
**/
@IsTest
public class B2BStripeTaxMock implements HttpCalloutMock {
    private CartExtension.Cart cart;
    private Order order;

    public B2BStripeTaxMock() {
    }

    public B2BStripeTaxMock(Order order) {
        this.order = order;
    }

    public B2BStripeTaxMock(CartExtension.Cart cart) {
        this.cart = cart;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        String jsonResponse;
        if(cart != null) {
            jsonResponse = buildMockStripeTaxResponse(cart);
        } else {
            jsonResponse = buildMockStripeTaxResponse(order);
        }
        response.setBody(jsonResponse);
        return response;
    }

    private static String buildMockStripeTaxResponse(CartExtension.Cart cart) {
        Map<String, Object> response = new Map<String, Object>();

        List<Map<String, Object>> lineItemsData = new List<Map<String, Object>>();
        Decimal totalAmount = 0;
        Decimal totalTaxAmount = 0;

        CartExtension.CartItemList cartItems = cart.getCartItems();
        for (Integer i = 0; i < cartItems.size(); i++) {
            CartExtension.CartItem item = cartItems.get(i);
            Decimal amount = item.getTotalLineAmount();
            Decimal taxAmount = (amount * 0.05).setScale(2); // 5% dummy tax
            totalAmount += amount;
            totalTaxAmount += taxAmount;

            Map<String, Object> lineItem = new Map<String, Object>{
                'id' => 'li_' + String.valueOf(Crypto.getRandomInteger()),
                'amount' => (amount * 100).setScale(0).intValue(),
                'amount_tax' => (taxAmount * 100).setScale(0).intValue(),
                'reference' => item.getId(),
                'tax_behavior' => 'exclusive',
                'tax_code' => 'txcd_99999999'
            };
            lineItemsData.add(lineItem);
        }


        response.put('amount_total', (totalAmount * 100).setScale(0).intValue());
        response.put('tax_amount_exclusive', totalTaxAmount);

        // Customer details (optional for completeness)
        Map<String, Object> address = new Map<String, Object>{
            'city' => 'Test City',
            'country' => 'US',
            'line1' => '123 Test St',
            'postal_code' => '12345',
            'state' => 'CA'
        };
        response.put('customer_details', new Map<String, Object>{
            'address' => address,
            'address_source' => 'shipping'
        });

        // Line items section
        response.put('line_items', new Map<String, Object>{
            'data' => lineItemsData
        });

        // Tax breakdown (simplified)
        response.put('tax_breakdown', new List<Map<String, Object>>{
            new Map<String, Object>{
                'amount' => totalTaxAmount,
                'inclusive' => false,
                'tax_rate_details' => new Map<String, Object>{
                    'country' => 'US',
                    'flat_amount' => null,
                    'percentage_decimal' => '5.00',
                    'rate_type' => 'standard',
                    'state' => 'CA',
                    'tax_type' => 'sales_tax'
                },
                'taxability_reason' => 'standard',
                'taxable_amount' => totalAmount
            }
        });

        return JSON.serialize(response);
    }

    private static String buildMockStripeTaxResponse(Order order) {
        Map<String, Object> response = new Map<String, Object>();

        List<Map<String, Object>> lineItemsData = new List<Map<String, Object>>();
        Decimal totalAmount = 0;
        Decimal totalTaxAmount = 0;

         List<OrderItem> orderItems = [
            SELECT Id, UnitPrice, Quantity, TotalPrice, Product2Id
            FROM OrderItem
            WHERE OrderId = :order.Id
        ];

        for (Integer i = 0; i < orderItems.size(); i++) {
            OrderItem item = orderItems.get(i);
            Decimal amount = item.TotalPrice;
            Decimal taxAmount = (amount * 0.05).setScale(2); // 5% dummy tax
            totalAmount += amount;
            totalTaxAmount += taxAmount;

            Map<String, Object> lineItem = new Map<String, Object>{
                'id' => 'li_' + String.valueOf(Crypto.getRandomInteger()),
                'amount' => (amount * 100).setScale(0).intValue(),
                'amount_tax' => (taxAmount * 100).setScale(0).intValue(),
                'reference' => item.Id,
                'tax_behavior' => 'exclusive',
                'tax_code' => 'txcd_99999999'
            };
            lineItemsData.add(lineItem);
        }


        response.put('amount_total', (totalAmount * 100).setScale(0).intValue());
        response.put('tax_amount_exclusive', totalTaxAmount);

        // Customer details (optional for completeness)
        Map<String, Object> address = new Map<String, Object>{
            'city' => 'Test City',
            'country' => 'US',
            'line1' => '123 Test St',
            'postal_code' => '12345',
            'state' => 'CA'
        };
        response.put('customer_details', new Map<String, Object>{
            'address' => address,
            'address_source' => 'shipping'
        });

        // Line items section
        response.put('line_items', new Map<String, Object>{
            'data' => lineItemsData
        });

        // Tax breakdown (simplified)
        response.put('tax_breakdown', new List<Map<String, Object>>{
            new Map<String, Object>{
                'amount' => totalTaxAmount,
                'inclusive' => false,
                'tax_rate_details' => new Map<String, Object>{
                    'country' => 'US',
                    'flat_amount' => null,
                    'percentage_decimal' => '5.00',
                    'rate_type' => 'standard',
                    'state' => 'CA',
                    'tax_type' => 'sales_tax'
                },
                'taxability_reason' => 'standard',
                'taxable_amount' => totalAmount
            }
        });

        return JSON.serialize(response);
    }
}