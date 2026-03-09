import { api, LightningElement } from 'lwc';
import Toast from 'lightning/toast';
import getShippingDetails from '@salesforce/apex/B2B_ShippingController.getShippingDetails';
import { Labels } from './labels';

export default class B2bShippingInformation extends LightningElement {

    connectedCallback() {
        if(this.isInSitePreview()) {
            this.showStencil = false;
            this.estimatedDate = '7/31/2025';
        }
    }

    @api
    get orderDetails(){
        return this._orderDetails;
    }
    set orderDetails(value){
        if(value){
            this._orderDetails = value;
            if(!this.isInSitePreview()) {
                this.fetchShippingDetails(value?.orderSummaryId);
            }
        }
    }

    @api
    isOrderConfirmPage;

    labels = Labels;
    showStencil = false;
    street;
    city;
    state;
    postalCode;
    country;
    method;
    charges;
    estimatedDate;
    currencyCode;
    timer;

    get isOrderDetailsAvailable() {
        return this._orderDetails != null;
    }

    get isEstimatedDateAvailable() {
        return this.estimatedDate != null;
    }

    fetchShippingDetails(orderSummaryId) {
        this.showStencil = true;

        let mapParams = {};

        if(!orderSummaryId) {
            let urlParams = new URLSearchParams(window.location.search);
            let orderNumber = urlParams.get('orderNumber'); 
            mapParams.orderRefNumber = orderNumber;
        } else {
            mapParams.recordId = orderSummaryId;
        }

        getShippingDetails({ 'mapParams': mapParams})
        .then((result) => {
            if(result.isSuccess) {
                this.estimatedDate = result?.shippingDate;
                if(this.isOrderConfirmPage) {
                    this.street = result?.shippingStreet;
                    this.city = result?.shippingCity;
                    this.state = result?.shippingState;
                    this.postalCode = result?.shippingPostalCode;
                    this.country = result?.shippingCountry;
                    this.method = result?.shippingMethod;
                    this.charges = result?.shippingCharges
                    this.currencyCode = result?.currencyCode;
                }
                this.showStencil = false;
            } else {
                let t = this
                this.timer = setTimeout(() => {
                    t.fetchShippingDetails(this._orderDetails?.orderSummaryId)
                }, 2000);
            }
        })
        .catch((e) => {
            this.showStencil = false;
            this.showErrorToast(JSON.stringify(e?.body?.message));
        })
    }

    disconnectedCallback() {
        clearTimeout(this.timer);
    }

    showErrorToast(errorMessage) {
        Toast.show({
            label: this.labels.toastError,
            message: errorMessage,
            variant: 'error'
        });
    }

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