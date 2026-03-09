import { LightningElement, api, track } from 'lwc';
import getBillingDetails from '@salesforce/apex/B2B_BillingController.getBillingDetails';
import { debounce } from "experience/utils";
import labels from './labels';

export default class B2bBillingInformation extends LightningElement {
    _orderDetails;
    showStencil = false;
    @track billingDetails;
    @track labels = labels;

    @api
    get orderDetails(){
        return this._orderDetails;
    }
    set orderDetails(value){
        if(value){
            console.log('Value:::: ', value);
            this._orderDetails = value;
            this.fetchBillingDetails(value?.orderSummaryId);
            if(!this.isInSitePreview()) {
                // this.fetchBillingDetails(value?.orderNumber);
            }
        }
    }

    fetchBillingDetails(orderNumber) {
        console.log('orderNumber:::: ', orderNumber);
        this.showStencil = true;

        let mapParams = {};
        mapParams.orderNumber = orderNumber;

        getBillingDetails({mapParams: mapParams})
            .then(result => {
                console.log('Result:::: ', result);
                if (result.isSuccess) {
                    this.billingDetails = result?.data;
                    this.showStencil = false;
                } else {
                    console.log('ELSE::: ', this._orderDetails); 
                    this.callFetchBillingdetails();
                }    
            })
            .catch(error => {
                console.log('Error:::: ', error);
                this.showStencil = false;
            });
    }

    // Debounced function
    callFetchBillingdetails = debounce(() => {
        this.fetchBillingDetails(this._orderDetails?.orderNumber)
    }, 3000);


    /**
     * Determines if you are in the experience builder currently
     */
    isInSitePreview() {
        let url = document.URL;

        return (
        url.indexOf("sitepreview") > 0 ||
        url.indexOf("livepreview") > 0 ||
        url.indexOf("live-preview") > 0 ||
        url.indexOf("live.") > 0 ||
        url.indexOf(".builder.") > 0
        );
    }
}