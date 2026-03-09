import { LightningElement, api, track } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import { NavigationMixin } from 'lightning/navigation';
import { fetchWebStoreId, fetchProductPromotions, fetchPromotionsForProductIds } from 'c/b2bApiUtils';
import labels from './labels';
import { validateDealsForAccount } from 'c/b2bDealsValidatorUtil';

export default class B2bProductPurchaseOption extends NavigationMixin(LightningElement) {

    _productData;
    quantity=1;
    // guestUser=false;
    _productPricing;
    showDetails = false;

    promoPrice = null;
    savedAmount = null;
    isPromotionLoaded = false;
    productId;
    @track labels = labels;

    handleProductQuantity(event) {
        this.quantity= event.detail.message;
        // console.log('quantity: ',this.quantity);
    }

    @api
    set productPricing(data) {
        if(data != null){
            this._productPricing = data;
            // console.log('product.pricing: ', JSON.stringify(this._productPricing));
            if(this._productPricing.unitPrice){
                this.showDetails = true;
                // console.log('showDetails: ', this.showDetails);
            }

        }
    }
    get productPricing() {
        return this._productPricing;
    }

    @api
    set productData(data) {
        if(data != null){
            this._productData = data;
            this.productId = data.id;
        }
        
        // console.log('product._productData: ', JSON.stringify(this._productData));
    }
    get productData() {
        return this._productData;
    }

    get pricingCurrencyIsoCode(){
        // console.log('pricingCurrencyIsoCode OUTPUT----: ',this.productPricing);
        
        return this.productPricing?.currencyIsoCode || '';
    }

    get displayPrice() {
        if (this.isPromotionLoaded && this.promoPrice != null) {
            return this.promoPrice;
        }
        return this.productPricing?.unitPrice || 0;
    }

    get displaySavedAmount() {
        if (this.isPromotionLoaded && this.savedAmount) {
            return parseFloat(this.savedAmount);
        }
        return null;
    }


    handleClick(){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/store/login'
            }
        });
    }

    connectedCallback() {
        validateDealsForAccount()
        .then(result => {
            // console.log('Result validateDealsForAccount PDP::: ', result);
            let hasDealsApplied = result;

            if (!hasDealsApplied) {
                this.fetchPromotionPricing();
            }
        });

        // this.fetchPromotionPricing();
    }

    fetchPromotionPricing() {
        this.isPromotionLoaded = false;
        fetchWebStoreId()
            .then(result => {
                this.webStoreId = result.webstoreId;

                if (this.productId) {
                    const locale = localStorage.getItem('currentUserLocale') || 'en-US';
                    const productIds = [this.productId];
                    // return fetchProductPromotions(this.webStoreId, this.productId, locale);
                    return fetchPromotionsForProductIds (this.webStoreId, productIds, locale)
                }
            })
           .then(data => {
                // console.log('Fetched Promotions:', data);
                const result = this.extractPromoData(data);
                // console.log('result extraction --> ', result);
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
}