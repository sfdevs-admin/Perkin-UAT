import { LightningElement, api, wire } from 'lwc';
import { ProductAdapter, ProductPricingAdapter } from 'commerce/productApi';
import basePath from '@salesforce/community/basePath';
import { navigate, NavigationContext, CurrentPageReference } from 'lightning/navigation';
import { addItemToCart } from 'commerce/cartApi';
import { CartSummaryAdapter } from 'commerce/cartApi';
import B2B_Is_Subscription_FIELD from "@salesforce/schema/WebCart.B2B_Is_Subscription__c";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Toast from 'lightning/toast';
import {
    ADD_TO_CART,
    AddToCartSubscriptionMsg,
    priceNotFound,
    saved,
    toastError
} from 'c/b2bCustomLabels';
import { fetchWebStoreId, fetchPromotionsForProductIds } from 'c/b2bApiUtils';
import { validateDealsForAccount } from 'c/b2bDealsValidatorUtil';

export default class B2bRelatedProductsChild extends LightningElement {
    static renderMode = "light"; // the default is 'shadow'
    @api isPDP;
    @api productId;
    @api productData;
    label = {
        ADD_TO_CART,
        AddToCartSubscriptionMsg,
        priceNotFound,
        saved,
        toastError
    };
    
    unitPrice;
    listPrice;
    currencyCode;
    isPriceAvailable = false;
    @api quantity = 1;
    cartId;
    isPromotionLoaded = false;

    get prodImageUrl(){
        console.log('is pdp :::; ', this.isPDP);
        return this.productData?.defaultImage?.url ? this.isCmsImage(this.productData.defaultImage.url) : '';
    };
    get prodName(){
        return this.productData?.fields?.B2B_Display_Name__c;
    };
    get prodCatlogNumber(){
        return this.productData?.fields?.StockKeepingUnit;
    };
    get prodCass(){
        return this.productData?.fields?.CAS__c;
    };
    get prodIsb2bProduct() {
        return this.productData?.fields?.Is_B2B_Product__c;
    };

    @wire(NavigationContext)
    navContext;

    @wire(CartSummaryAdapter, { 'cartStateOrId': 'current' })
    async wiredCartSummaryData(result) {
        if (result.data && result.data.cartId) {
            this.cartId = result.data.cartId;
        }
    }

    //Get Cart Record
    @wire(getRecord, {
        recordId: "$cartId",
        fields: [B2B_Is_Subscription_FIELD],
    })
    currentCart;

    get isSubscriptionCart() {
        return this.cartId && this?.currentCart?.data && getFieldValue(this.currentCart.data, B2B_Is_Subscription_FIELD);
    }

    isCmsImage(url){
        let windowUrl = window.location.href;
        if( windowUrl.indexOf('preview') > 0 ){
            return basePath + '/sfsites/c' + url;
        }
        else if(url.startsWith('/cms')){
            return basePath + '/sfsites/c' + url;
        }else{
            return url;
        }
    }

    /**
     * Handles navigating to the product detail page from the search results page.
     * @param {CustomEvent<{productId: string; productName: string}>} event The event object
     */
    handleNavigateToProductPage(event) {
        event.stopPropagation();
        const urlName = this.productData?.fields?.B2B_Part_Number__c !== null ? this.productData?.fields?.B2B_Part_Number__c : undefined;
        this.navContext &&
            navigate(this.navContext, {
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: 'Product2',
                    recordId: this.productId,
                    actionName: 'view',
                    urlName: urlName,
                },
                state: {
                    recordName: this.prodName,
                },
            });
    }

    @wire(ProductPricingAdapter, { productId: '$productId' })
    getProdPricingInfo({ data, error }) {
        this.validateDealsOnAccount();
        if (data) {
            this.isPriceAvailable = this.prodIsb2bProduct && data?.unitPrice > 0 ;
            this.unitPrice = data?.unitPrice;
            this.listPrice = data?.listPrice;
            this.currencyCode = data?.currencyIsoCode;
        }
        if (error) {
            this.isPriceAvailable = false;
            console.log('error :: ', error);
        }
    }

    handleAddToCart(event) {
        if (this.isSubscriptionCart) {
            Toast.show({
                label: this.label.toastError,
                message: this.label.AddToCartSubscriptionMsg,
                variant: 'error',
                mode: 'dismissible'
            });
        } else {
            let pid = event.currentTarget.dataset.pid;
            addItemToCart(pid, this.quantity)
                .then(( result ) => {
                    //Add this event to Google analytics
                    let product = {
                        currencyCode: result.currencyIsoCode,
                        quantity: this.quantity,
                        unitPrice: this.unitPrice,
                        totalPrice: this.unitPrice,
                        sku: this.productData.fields.B2B_Part_Number__c,
                        name: this.productData.fields.B2B_Display_Name__c,
                        category: this.productData.fields.B2B_Item_Class_Description__c,
                        brand: this.productData.fields.B2B_Brand_Name__c
                    };
                    this.trackAddToCart(product);
                })
                .catch(( error ) => {
                    console.log('error add to cart :: ', error);
                });
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
                    quantity: product.quantity,
                    price: product.unitPrice
                }]
            }
        });
        // console.log('GA - Add To Cart Event Shopping list: ', window.dataLayer);
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

    validateDealsOnAccount() {
        validateDealsForAccount()
            .then(result => {
                let hasDealsApplied = result;

                if (!hasDealsApplied) {
                    this.fetchPromotionPricing();
                }
            });
    }
    fetchPromotionPricing() {
        this.isPromotionLoaded = false;
        fetchWebStoreId()
            .then(result => {
                this.webStoreId = result.webstoreId;

                if (this.productId) {
                    const locale = localStorage.getItem('currentUserLocale') || 'en-US';
                    const productIds = [this.productId];
                    return fetchPromotionsForProductIds(this.webStoreId, productIds, locale)
                }
            })
            .then(data => {
                const result = this.extractPromoData(data);
                if (result) {
                    this.promoPrice = result.promoPrice;
                    this.savedAmount = result.savedAmount;
                    this.isPromotionLoaded = true;
                } else {
                    this.promoPrice = null;
                    this.savedAmount = null;
                    this.isPromotionLoaded = false;
                }
            })
    } 
    extractPromoData(data) {
        const results = data?.promotionProductEvaluationResults;
        if (results && results.length > 0) {
            const firstResult = results.find(
                r => r.productId === this.productId && r.promotionPriceAdjustmentList?.length > 0
            );

            if (firstResult) {
                return {
                    promoPrice: parseFloat(firstResult.promotionalPrice),
                    savedAmount: Math.abs(parseFloat(firstResult.promotionPriceAdjustmentList[0].adjustmentAmount)).toFixed(2)
                };
            }
        }
        return null;
    }  

    get displayPrice() {
        if (this.isPromotionLoaded && this.promoPrice != null) {
            return this.promoPrice;
        }
        return this.unitPrice || 0;
    }
    get displaySavedAmount() {
        if (this.isPromotionLoaded && this.savedAmount) {
            return parseFloat(this.savedAmount);
        }
        return null;
    }
    
}