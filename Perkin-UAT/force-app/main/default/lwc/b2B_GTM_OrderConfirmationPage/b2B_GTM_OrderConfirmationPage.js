import { LightningElement, api, wire, track } from 'lwc';
import getOrderWithItems from '@salesforce/apex/B2BGTMOrderConfCont.getOrderWithItems';

export default class B2B_GTM_OrderConfirmationPage extends LightningElement {
    @api orderId;             // Pass this in from the LWR page or parent
    @track orderNumber;
    @track totalAmount;
    @track currencyIsoCode;
    @track items = [];

    @wire(getOrderWithItems, { orderId: '$orderId' })
    wiredOrder({ data, error }) {
        if (data) {
            // Basic fields
            this.orderNumber = data.OrderNumber;
            this.totalAmount = data.TotalAmount;
            this.currencyIsoCode = data.CurrencyIsoCode;

            // Transform each OrderItem for GTM
            if (data.OrderItems) {
                this.items = data.OrderItems.map(oi => {
                    return {
                        item_id: oi.PricebookEntry.Product2Id,
                        item_name: oi.PricebookEntry.Product2?.Name,
                        quantity: oi.Quantity,
                        price: oi.UnitPrice
                    };
                });
            }

            // Push the purchase event into the dataLayer
            window.dataLayer = window.dataLayer || [];
            window.dataLayer.push({
                event: 'purchase',
                transactionId: this.orderId,          // or this.orderNumber
                value: this.totalAmount,
                currency: this.currencyIsoCode,
                items: this.items
            });

        } else if (error) {
            console.error('Error retrieving order data:', error);
        }
    }
}