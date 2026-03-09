import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin, navigate, NavigationContext } from 'lightning/navigation';
import { ProductAdapter, ProductPricingAdapter } from 'commerce/productApi';
import labels from './labels';
import { fetchWebStoreId, fetchPromotionsForProductIds } from 'c/b2bApiUtils';
import basePath from '@salesforce/community/basePath';
import { validateDealsForAccount, getEffectiveAccountId } from 'c/b2bDealsValidatorUtil';



import SUBSCRIPTION_DISCOUNT from '@salesforce/label/c.B2B_PDP_Subscription_Discount';

export default class B2bShoppingListItems extends NavigationMixin(LightningElement) {
    @api item;
    @api disabled = false;
    @api disabledDelete = false;
    @api isPublicListPage = false;
    prodImageUrl;
    prodName;
    currencyCode;
    unitPrice;
    listPrice;
    productId;
    @track labels = labels;
    productDetails;
    _calculatedPrice;
    webStoreId;
    locale;
    promoPrice;
    savedAmount;
    isPricingFailed = false;
    @api hasDealsApplied = false;
    @api isSubscription = false;
    @api showSubscriptionPrices = false;

    @track hasDealsAppliedonAccount = false;
    @track productPricing;
    @api effectiveAccountId;

    async connectedCallback() {
        this.productId = this.item?.productId;
        // console.log('hasDealsApplied: '+ this.hasDealsApplied);
        // if(!this.hasDealsApplied) {
        //     this.fetchPromotionPricing();
        // }
        this.validateDeals();
        
    }

    validateDeals() {
        validateDealsForAccount()
        .then(result => {
            // console.log('Result validateDealsForAccount Item Page::: ', result);
            this.hasDealsAppliedonAccount = result;

            // if(!hasDealsApplied) {
            //     this.fetchPromotionPricing();
            // }
        });
    }

    @wire(ProductAdapter, { productId: '$productId' })
    getProdDetails({ data, error }) {
        if (data !== undefined) {
            // console.log('Product Adapter data ---> ', data);  
            this.productDetails = data;
            // this.prodImageUrl = data?.defaultImage?.url;      
            this.prodImageUrl = this.isCmsImage(data?.defaultImage?.url);      
            this.prodName = data?.fields?.B2B_Display_Name__c;  
            this.validateDeals();    
        }
        if (error) {
            console.log('B2bShoppingList getProdDetails error exception----- ' + error);
        }
    }

    @wire(ProductPricingAdapter, { productId: '$productId' })
    getProdPricingInfo({ data, error }) {
        if (data !== undefined) {
            // console.log('Product Pricing data ---> ', data);  
            this.productPricing = data;      
            this.currencyCode = data?.currencyIsoCode;
            this.unitPrice = data?.unitPrice;
            this.listPrice = data?.listPrice;
            this.isPricingFailed = false;

            this.dispatchEvent(new CustomEvent('pricingstatus', {
                detail: { productId: this.productId, failed: false }
            }));

            this.subscriptionDiscountLogic();
        }
        if (error) {
            console.log('Product Pricing error exception----- ' + error);
            this.isPricingFailed = true;

            // notify parent failure
            this.dispatchEvent(new CustomEvent('pricingstatus', {
                detail: { productId: this.productId, failed: true }
            }));

        }
    }

    isCmsImage(url){
        let windowUrl = window.location.href;
        if( windowUrl.indexOf('preview') > 0 ){
            return basePath + '/sfsites/c' + url;
        }
        else if(url.startsWith('/cms')){
            return basePath + '/sfsites/c' + url;
        }
        return url; 
    }

    // get calculatedPrice () {
    //     this._calculatedPrice = this.unitPrice * this.item?.quantity;
    //     return this._calculatedPrice.toFixed(2);
    // }

    handleAddToCart(event) {
        event.stopPropagation();
        const addEvent = new CustomEvent('addtocart', {
            detail: {
                productId: event.currentTarget.dataset.pid,
                quantity: event.currentTarget.dataset.quantity,
                productData: this.productDetails,
                // calculatedPrice: this._calculatedPrice.toFixed(2)
                calculatedPrice: this.calculatedPrice,
                unitPrice: this.unitPrice
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(addEvent);
    }

    @wire(NavigationContext)
    navContext;

    handleNavigateToProductPage(event) {
        event.stopPropagation();
        const urlName = event.currentTarget.dataset.purlname ?? undefined;
        this.navContext &&
            navigate(this.navContext, {
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: 'Product2',
                    recordId: event.currentTarget.dataset.pid,
                    actionName: 'view',
                    urlName: urlName,
                },
                state: {
                    recordName: event.currentTarget.dataset.pname,
                },
            });
    }

    handleDeleteItemFromList(event) {
        event.stopPropagation();
        const addEvent = new CustomEvent('deleteitemfromlist', {
            detail: {
                itemid: event.currentTarget.dataset.itemid
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(addEvent);

    }

    showInlineQuantitySelector = true;
    handleValueChanged(event) {
        const quantityChangeEvent = new CustomEvent('valuechanged', {
            detail: {
                productId: event.detail.productId,
                value: event.detail.value,
                itemId: this.item?.id
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(quantityChangeEvent);

    }

    isPromotionLoaded = false;

    get calculatedPrice() {
        const qty = this.item?.quantity ?? 1;

        const price = this.promoPrice ?? this.unitPrice;
        // console.log('calculated price --> ', price);
        return (price * qty).toFixed(2);
    }

    get unitPriceDisplay() {
        const qty = this.item?.quantity ?? 1;
        return (this.unitPrice * qty).toFixed(2);
    }

    get displaySavedAmount() {
        if (this.isPromotionLoaded && this.savedAmount) {
            return parseFloat(this.savedAmount);
        }
        return null;
    }


    fetchPromotionPricing() {
        this.isPromotionLoaded = false;
        fetchWebStoreId()
            .then(result => {
                this.webStoreId = result.webstoreId;

                if (this.productId) {
                    const locale = localStorage.getItem('currentUserLocale') || 'en-US';
                    // return fetchProductPromotions(this.webStoreId, this.productId, locale);
                    const productIds = [this.productId];
                    return fetchPromotionsForProductIds(this.webStoreId, productIds, locale);
                }
            })
           .then(data => {
                // console.log('Fetched Promotions:', data);
                const result = this.extractPromoData(data);
                // console.log('result after extraction', result);
                if (result) {
                    // console.log('IF result after extraction', result);
                    this.promoPrice = result.promoPrice;
                    this.savedAmount = result.savedAmount;
                    this.isPromotionLoaded = true;
                } else {
                    this.promoPrice = null;
                    this.savedAmount = null;
                    this.isPromotionLoaded = false;
                }
            })
            .catch(error => {
                console.log('Error fetch:', error);
            });
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

    handleRequestQuote() {
        var stateObj = {};
        let partNumber = this.productDetails.fields.B2B_Part_Number__c;
        let productLine = this.productDetails.fields.product_line__c;
        let productName = this.productDetails.fields.Name;
        let itemClassDesc = this.productDetails.fields.B2B_Item_Class_Description__c;

        // console.log('##Product Item Class Description: ', itemClassDesc);
        if (itemClassDesc === 'Instrument' || itemClassDesc === 'Major Accessory' ) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url:
                        this.labels.requestInfoUrl +
                        partNumber +
                        '&pl=' +
                        productLine +
                        '&pname=' +
                        encodeURIComponent(productName)
                }
            });
        }
        else {
            stateObj.productId = this.productId;
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'ContactUs__c'
                },
                state: stateObj
            });
        }
    }


    //subscription disocunt 
    @api accountSubscriptionDiscount;
    isSubscriptionDiscountApplied = false;
    displaySavedPercentage;
    finalPrice;

    subscriptionDiscountLogic() {
        let unitPrice = this.productPricing?.unitPrice || 0;

        if (!this.hasDealsAppliedonAccount) {
            if (this.isSubscription) {
                if (this.accountSubscriptionDiscount) {
                    //do the calculation here for price this.productPricing?.unitPrice and append on UI
                    this.finalPrice = (unitPrice - (unitPrice * this.accountSubscriptionDiscount / 100)).toFixed(2);
                    this.isSubscriptionDiscountApplied = true;
                    this.displaySavedPercentage = (unitPrice * this.accountSubscriptionDiscount / 100).toFixed(2);

                } else if (Number(SUBSCRIPTION_DISCOUNT) > 0) {
                    //do the calculation here for price this.productPricing?.unitPrice and append on UI 
                    let subscriptionDiscountLabel = Number(SUBSCRIPTION_DISCOUNT);
                    this.finalPrice = (unitPrice - (unitPrice * subscriptionDiscountLabel / 100)).toFixed(2);
                    this.isSubscriptionDiscountApplied = true;
                    this.displaySavedPercentage = (unitPrice * subscriptionDiscountLabel / 100).toFixed(2);

                } 
            } else {
                this.fetchPromotionPricing();
                this.isSubscriptionDiscountApplied = false;
            }
        }
    }

}