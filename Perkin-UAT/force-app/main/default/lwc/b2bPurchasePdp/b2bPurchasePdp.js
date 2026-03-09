import { LightningElement, api, track, wire } from 'lwc';
import {SubscriptionTab1,SubscriptionTab2, description, partNumber} from 'c/b2bCustomLabels';

import { getSessionContext } from 'commerce/contextApi';
import { getRecord } from 'lightning/uiRecordApi';
import B2B_SUBSCRIPTION_DISCOUNT from "@salesforce/schema/Account.B2B_Subscription_Discount__c";


export default class B2bPurchasePdp extends LightningElement {
    labels = {
        SubscriptionTab2,
        SubscriptionTab1,
        description, 
        partNumber
    }
    _productData;
    _productPricing;
    showDetails = false;

    @api
    set productData(data) {
        if(data != null){
            this._productData = data;
        }
        
        console.log('product._productData: ', JSON.stringify(this._productData));
    }
    get productData() {
        return this._productData;
    }

    get productItemClass(){
        return this.itemCodeList.includes(this.productData.fields.Item_Class__c);
    }
    itemCodeList = ['3','4','B']

    @api
    set productPricing(data) {
        if(data != null){
            this._productPricing = data;
            if(this._productPricing.unitPrice){
                this.showDetails = true;
            }
        }
    }
    get productPricing() {
        return this._productPricing;
    }
    //subscription discount 
    effectiveAccountId;
    accountSubscriptionDiscount

    async connectedCallback() {
        await this.getSessionDetails();
    }

    async getSessionDetails() {
        await getSessionContext()
            .then((response) => {

                this.effectiveAccountId = response.effectiveAccountId || response.accountId;
            })
            .catch((error) => {
                console.error(error);
            });
    }

    @wire(getRecord, {
        recordId: "$effectiveAccountId",
        fields: [B2B_SUBSCRIPTION_DISCOUNT]
    })
    currentAccountRecord({ error, data }) {
        if (data) {
            this.accountSubscriptionDiscount = data.fields?.B2B_Subscription_Discount__c?.value;
        }
    }
    
}