import { LightningElement, api, track } from 'lwc';
import REQUEST_INFORMATION_URL from '@salesforce/label/c.Request_Information_URL';
import B2B_REQUEST_MORE_INFORMATION from '@salesforce/label/c.B2b_Request_More_Information';
import INSTRUMENT from '@salesforce/label/c.B2B_RequestMore_Instrument';
import MAJOR_ACCESSORY from '@salesforce/label/c.B2B_RequestMore_MajorAccessory';
import { NavigationMixin } from 'lightning/navigation';


export default class B2bRequestMoreInformation extends NavigationMixin(LightningElement) {
    static renderMode = 'light';
    
    label = {
        B2B_REQUEST_MORE_INFORMATION,
        REQUEST_INFORMATION_URL
    };

    _productPricing;
    _productData;
    showButton = false;
    
    @api showButtonWhenCalledFromParent;
    
    @api
    set productPricing(data) {
        if (data != null) {
            this._productPricing = data;
            
            if (!this._productPricing.unitPrice) {
                this.showButton = true;
                console.log('ShowButton: ', this.showButton);
            }
        }
    }
    
    get productPricing() {
        return this._productPricing;
    }

    @api
    set productDetails(data) {
        this._productData = data;
        console.log('Product Item Class Description: ', this._productData.fields.B2B_Item_Class_Description__c);
    }

    get productDetails() {
        return this._productData;
    }

    handleRedirect() {
        const itemClassDesc = this._productData.fields.B2B_Item_Class_Description__c;
        const partNumber = this._productData.fields.B2B_Part_Number__c;
        // const productLine = this._productData.fields.B2B_Product_Line__c;
        const productLine = this._productData.fields.product_line__c;
        const productName = this._productData.fields.Name;
        const prodId = this._productData.id;

        if (itemClassDesc === INSTRUMENT || itemClassDesc === MAJOR_ACCESSORY ) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url:
                        this.label.REQUEST_INFORMATION_URL +
                        partNumber +
                        '&pl=' +
                        productLine +
                        '&pname=' +
                        encodeURIComponent(productName)
                }
            });
        } else {
            var stateObj = {};
            stateObj.productId = prodId;
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'ContactUs__c'
                },
                state: stateObj
            });
        }
    }
}