import { LightningElement, api } from 'lwc';

export default class B2bProductDetails extends LightningElement {
    _productData;
    shortDescription;

    @api
    set productData(data) {
        this._productData = data;
        this.getShortDescription();
    }
    get productData() {
        return this._productData;
    }

    getShortDescription() {
        this.shortDescription = this._productData?.fields?.B2B_Short_Description__c;
    }
}