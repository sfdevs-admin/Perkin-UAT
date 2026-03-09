import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CartItemsAdapter } from 'commerce/cartApi';
import { OrderSummaryLookupDataAdapter } from 'commerce/orderApi';
import getOrderSummaryId from '@salesforce/apex/B2B_ShippingController.getShippingDetails';

const FIELDS = [
    'OrderSummary.Promotions_Applied__c', 
    'Product2.B2B_Part_Number__c', 
    'Product2.B2B_Display_Name__c', 
    'Product2.B2B_Brand_Name__c',
    'Product2.B2B_Item_Class_Description__c',
];

export default class B2bTrackEventsForGA extends LightningElement {

    @api cartPageName;
    @api checkoutPageName;
    @api orderConfirmationPageName;

    pageTitle;
    cartId;
    cartSummary;
    cartItems = [];
    items = [];
    orderNumber;
    orderSummary;
    orderItems= [];

    cartEventAdded = false;
    checkoutEventAdded = false;
    orderEventAdded = false;

    timer;

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef) {
            window.setTimeout(() => {
                this.pageTitle = document.title || pageRef.state.pageTitle || 'Default Page';

                if(this.pageTitle === 'Order Confirmation') {
                    const urlParams = new URLSearchParams(window.location.search);
                    this.orderNumber = urlParams.get('orderNumber');
                }
            }, 50);
        }
    }
    
    @wire(CartItemsAdapter, {'cartStateOrId': 'current'}) 
    async getCartItems({ data, error }) {
        if (data) {
            this.cartItems = data.cartItems;
            this.cartSummary = data.cartSummary;
            this.items = [];

            if(this.cartItems.length > 0) {
                console.log('## Cart Summary: ', JSON.parse(JSON.stringify(this.cartSummary)));

                this.cartItems.forEach(item => {
                    this.items.push({
                        item_id: item.cartItem.productDetails.fields.B2B_Part_Number__c,
                        item_name: item.cartItem.productDetails.fields.B2B_Display_Name__c,
                        item_brand: item.cartItem.productDetails.fields.B2B_Brand_Name__c,
                        item_category: this.getProductCategory(item.cartItem.productDetails.fields.B2B_Item_Class_Description__c),
                        quantity: item.cartItem.quantity,
                        price: item.cartItem.unitAdjustedPriceWithItemAdj
                    });
                });
                console.log('## Cart/Checkout - Items: ', JSON.parse(JSON.stringify(this.items)));
                
                if(this.pageTitle != undefined ) {
                    this.trackEvent(this.pageTitle);
                }
            }
        } else if (error) {
            console.error('Error in getCartItems : ', error);
        }
    }

    @wire(OrderSummaryLookupDataAdapter, { 'orderSummaryIdOrRefNumber': '$orderNumber' ,'fields': FIELDS})
    async getOrderSummaryData({ data, error }) {
        if (data) {
            this.orderSummary = data;
            console.log('## Order Summary: ', JSON.parse(JSON.stringify(this.orderSummary)));

            this.orderItems = this.orderSummary.deliveryGroups[0].lineItems;
            if(this.orderItems.length > 0) {
                this.orderItems.forEach(item => {
                    this.items.push({
                        item_id: item?.product?.fields?.B2B_Part_Number__c?.text,
                        item_name: item?.product?.fields?.B2B_Display_Name__c?.text,
                        item_brand: null, //item.product.fields.B2B_Brand_Name__c.text,
                        item_category: this.getProductCategory(item?.product?.fields?.B2B_Item_Class_Description__c?.text),
                        quantity: item?.fields?.Quantity?.text,
                        price: item?.fields?.AdjustedLineAmount?.text ?? item?.fields?.TotalPrice?.text
                        
                    });
                });
            }
            console.log('## Purchase - Items: ', JSON.parse(JSON.stringify(this.items)));

            if(this.pageTitle != undefined) {
                this.trackEvent(this.pageTitle);
            }
        } else if (error) {
            console.error('Error in getOrderSummaryData : ', error);
        }
    }

    trackEvent(currentPage) {
        console.log('## Current Page: ', currentPage);
        switch (currentPage) {
            case 'Cart':
                if(!this.cartEventAdded) {
                    this.trackEventCart();
                }
                break;
            case 'Checkout':
                if(!this.checkoutEventAdded) {
                    this.trackEventCheckout();
                }
                break;
            case 'Order Confirmation':
                if(!this.orderEventAdded) {
                    this.trackEventOrderConfirmation();
                }
                break;
            default:
                break;
        }
    }

    trackEventCart() {
        window.dataLayer = window.dataLayer || [];

        window.dataLayer.push({ ecommerce: null });
        window.dataLayer.push({
            event: 'cart_value',
            ecommerce: {
                currency: this.cartSummary.currencyIsoCode,
                value: this.cartSummary.grandTotalAmount
            }
        });
        this.cartEventAdded = true;
        console.log('## GA - Cart Value Event: ', window.dataLayer);
    }

    trackEventCheckout() {
        window.dataLayer = window.dataLayer || [];

        window.dataLayer.push({ ecommerce: null });
        window.dataLayer.push({
            event: 'begin_checkout',
            ecommerce: {
                currency: this.cartSummary.currencyIsoCode,
                value: this.cartSummary.grandTotalAmount,
                items: this.items
            }
        });
        this.checkoutEventAdded = true;
        console.log('## GA - Begin Checkout Event: ', window.dataLayer);
    }

    trackEventOrderConfirmation() {
        let orderSummaryId = this.orderSummary?.id;

        if(!orderSummaryId) {
            console.log('IF');
            this.fetchOrderSummaryDetails(this.orderNumber)
        }
    }

    getProductCategory(itemClassDescription) {
        switch (itemClassDescription) {
            case "Consumable":
            case "Minor Accessory":
            case "Reagent":
                return "Consumables & Accessories";

            case "Instrument":
            case "Major Accessory":
                return "Instruments";

            case "Software":
                return "PCs & Software";

            case "Support, Consulting & Training":
                return "Training";

            case "Service Installation":
                return "Instrument Service";

            default:
                return "empty";
        }
    }

    fetchOrderSummaryDetails(order_Number) {
        let mapParams = {};
        mapParams.orderRefNumber = order_Number;

        getOrderSummaryId({ 'mapParams': mapParams})
        .then((result) => {
            console.log('Order summary details from apex --', result);
            if(result.isSuccess) {
                let order_summary_Id = result?.orderSummaryId;
                if(order_summary_Id) {
                    this.firePurchaseEvent(order_summary_Id);
                } else {
                    this.scheduleRetry(order_Number);
                }
            } else {
                this.scheduleRetry(order_Number);
            }
        })
        .catch((e) => {
            console.log('error -> ', e);
            this.firePurchaseEvent(this.orderSummary?.id);
        })
    }

    scheduleRetry(order_Number) {
        this.timer = setTimeout(() => {
            this.fetchOrderSummaryDetails(order_Number);
        }, 2000);
    }

    firePurchaseEvent(order_summary_Id) {
        window.dataLayer = window.dataLayer || [];

        window.dataLayer.push({ ecommerce: null });
        window.dataLayer.push({
            event: 'purchase',
            ecommerce: {
                transaction_id: order_summary_Id,
                // affiliation: 'Online Store',
                value: this.orderSummary.fields.GrandTotalAmount?.text,
                tax: this.orderSummary.fields.TotalTaxAmount?.text,
                shipping: this.orderSummary.fields.TotalAdjustedDeliveryAmount?.text,
                currency: this.orderSummary?.currencyIsoCode,
                coupon: this.orderSummary.fields.Promotions_Applied__c?.text,
                items: this.items
            }
        });
        this.orderEventAdded = true;
        console.log('## GA - Purchase Event: ', window.dataLayer);
    }
    disconnectedCallback() {
        clearTimeout(this.timer);
    }
}