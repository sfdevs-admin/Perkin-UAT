import { LightningElement, api, track, wire } from 'lwc';
//import ADD_TO_CART from '@salesforce/label/c.Add_To_Cart';
import isGuest from '@salesforce/user/isGuest';
import Toast from 'lightning/toast';
import { createCartItemAddAction, dispatchAction } from 'commerce/actionApi';
import CommonModal from 'c/commonModal';
import { navigate, NavigationContext, NavigationMixin } from 'lightning/navigation';
import B2B_Is_Subscription_FIELD from "@salesforce/schema/WebCart.B2B_Is_Subscription__c";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CartSummaryAdapter } from 'commerce/cartApi';
//import required labels
import {
    ADD_TO_CART,
    AddToCartSubscriptionMsg,
    actionContinueShopping,
    actionViewCart,
    addToCartErrorMessage, 
    toastSuccess,
    toastError
} from 'c/b2bCustomLabels';
export default class B2bAddToCart extends NavigationMixin(LightningElement) {
    static renderMode = 'light';
    
    @api productData;
    @api productId;
    @api quantity = 1;
    label = {
        ADD_TO_CART,
        AddToCartSubscriptionMsg,
        actionContinueShopping,
        actionViewCart,
        addToCartErrorMessage, 
        toastError,
        toastSuccess
    };
    @api showQuantity = false;

    isLoading = true;
    cartId;
    //cartsummaryadapter
    @wire(CartSummaryAdapter, { 'cartStateOrId': 'current' })
    async wiredCartSummaryData(result) {
        console.log('result.data ', result?.data?.cartId);
        if (result.data && result.data.cartId) {
            this.cartId = result.data.cartId;
            this.isLoading = false;
        }else if( result?.data ){
            this.isLoading = false;
        }
    }

    //Get Cart Record
    @wire(getRecord, {
        recordId: "$cartId",
        fields: [B2B_Is_Subscription_FIELD],
    })
    currentCart;

    //flag to define enable/disable for add to cart button
    get isSubscriptionCart() {
        console.log('this?.currentCart ', this?.currentCart);

        //Need to check for this.cartid as in someinstance cartmay not be created earlier & additemtocart() will create it
        //button should be enabled only for Cart which is not subscribed"
        return this.cartId && this?.currentCart?.data && getFieldValue(this.currentCart.data, B2B_Is_Subscription_FIELD);
        // return this.cartId && this.currentCartStage != 'Quote';
    }

    handleAddToCart() {
        this.addItemToCart(this.productId, this.quantity);
    }

    addItemToCart(inputProductId, inputProductQuantity) {
        let productId = inputProductId;
        let productQuantity = inputProductQuantity;
        if (this.isSubscriptionCart) {
            Toast.show({
                label: this.label.toastError,
                message: this.label.AddToCartSubscriptionMsg,
                variant: 'error',
                mode: 'dismissible'
            });
        } else {
            if (productId && productQuantity && productQuantity > 0) {
                dispatchAction(this, createCartItemAddAction(productId, productQuantity), {
                    onSuccess: (result) => {
                        console.log('#Add To Cart Success Event: ', JSON.parse(JSON.stringify(result)));
                        //Add this event to Google analytics
                        let product = {
                            currencyCode: result.currencyIsoCode,
                            quantity: result.quantity,
                            unitPrice: result.unitAdjustedPriceWithItemAdj,
                            totalPrice: result.totalPrice,
                            sku: this.productData.fields.B2B_Part_Number__c,
                            name: this.productData.fields.B2B_Display_Name__c,
                            category: this.productData.fields.B2B_Item_Class_Description__c,
                            brand: this.productData.fields.B2B_Brand_Name__c
                        };
                        this.trackAddToCart(product);

                        CommonModal.open({
                            label: this.label.toastSuccess,
                            size: 'small',
                            secondaryActionLabel: this.label.actionContinueShopping,
                            primaryActionLabel: this.label.actionViewCart,
                            onprimaryactionclick: () => this.navigateToCart(),
                        });
                    },
                    onError: (error) => {
                        // this.dispatchEvent(
                        //     new ShowToastEvent({
                        //         title: 'Error',
                        //         message: error.message,
                        //         variant: 'error',
                        //         mode: 'sticky',
                        //     })
                        // );
                        console.log('error', error);
                        Toast.show({
                            label: this.label.toastError,
                            message: error.message +' '+ this.label.addToCartErrorMessage,
                            variant: 'error',
                            mode: 'dismissible'
                        });
                    },
                });
            }
        }
        // if(!isGuest){

        // }else{
        //     this[NavigationMixin.Navigate]({
        //         type: 'standard__webPage',
        //         attributes: {
        //             url: '/store/login'
        //         }
        //     });
        // }

    }

    @wire(NavigationContext)
    navContext;

    navigateToCart() {
        this.navContext &&
            navigate(this.navContext, {
                type: 'comm__namedPage',
                attributes: {
                    name: 'Current_Cart',
                },
            });
    }

    increaseQuantity() {
        this.quantity += 1;
    }

    decreaseQuantity() {
        if (this.quantity > 1) {
            this.quantity -= 1;
        }
    }

    handleQuantityChange(event) {
        if (event.target.value >= 1) {
            this.quantity = event.target.value;
        } else {
            this.quantity = 1;
        }
    }

    trackAddToCart(product) {
        window.dataLayer = window.dataLayer || [];

        window.dataLayer.push({ ecommerce: null });
        window.dataLayer.push({
            event: 'add_to_cart',
            ecommerce: {
                currency: product.currencyCode,
                value: product.totalPrice,
                items: [{
                    item_id: product.sku,
                    item_name: product.name,
                    item_brand: product.brand,
                    item_category: this.getProductCategory(product.category),
                    quantity: this.quantity,
                    price: product.unitPrice
                }]
            }
        });
        console.log('GA - Add To Cart Event: ', window.dataLayer);
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
}