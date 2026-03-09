import { LightningElement, track, api } from 'lwc';

export default class B2bProductDisplayName extends LightningElement {

    @track productDisplayName
    _productData;

    @api
    set productData(data) {
        if(data != null){
            this._productData = data;
            this.productDisplayName = this._productData?.fields?.B2B_Display_Name__c;
        }
    }

    get productData() {
        return this._productData;
    }
}