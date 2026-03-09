import { LightningElement, wire } from 'lwc';
import {CheckoutInformationAdapter, useCheckoutComponent} from 'commerce/checkoutApi';
import updateCartWithShippingProviderDetails from '@salesforce/apex/B2B_UpdateCartController.updateCartWithShippingProviderDetails';
import Toast from 'lightning/toast';
import toastError from '@salesforce/label/c.B2B_Toast_Error';

const CheckoutStage = {
    CHECK_VALIDITY_UPDATE: 'CHECK_VALIDITY_UPDATE',
    REPORT_VALIDITY_SAVE: 'REPORT_VALIDITY_SAVE',
    START_PAYMENT_SESSION: 'START_PAYMENT_SESSION',
    BEFORE_PAYMENT: 'BEFORE_PAYMENT',
    PAYMENT: 'PAYMENT',
    BEFORE_PLACE_ORDER: 'BEFORE_PLACE_ORDER',
    PLACE_ORDER: 'PLACE_ORDER'
};

export default class B2bShippingProvider extends useCheckoutComponent(LightningElement) {

    checkoutDetails;
    cartId;
    selectedShippingMethod;
    showFields = false;
    value='';
    accountNumber='';
    errorMessage;
    showError=false;
    showSpinner=false;
    mapParams={};

    @wire(CheckoutInformationAdapter, {})
    checkoutInfo({ error, data }) {
        if ( data ) {
            this.checkoutDetails = data;
            console.log('checkoutDetails: ',this.checkoutDetails);
            this.selectedShippingMethod = data.deliveryGroups.items[0].selectedDeliveryMethod.name;
            console.log('selectedShippingMethod: ',this.selectedShippingMethod);
            this.cartId = data.cartSummary.cartId;
            console.log('cartId:',this.cartId);
            //If Freight Collect then show more fields
            if(this.selectedShippingMethod == 'Freight Collect'){
                this.showFields = true;
            }
            else{
                this.showFields = false;
            }
        } else if (error) {
            console.error('Error in CheckoutInfo: ', error);
        }
    }

    get options() {
        return [
            { label: 'UPS', value: 'UPS' },
            { label: 'FedEx', value: 'FedEx' },
        ];
    }

    checkValidity() {
        if(this.showFields){
            return !(this.value && this.accountNumber);
        }
        else{
            return true;
        }
    }  

    reportValidity() {
        if(this.showFields){
            this.showError = !this.value || !this.accountNumber;
        }
        else{
            this.showError = false;
        }
    
        if (this.showError) {
            this.errorMessage = 'Please select your Shipping Provider and enter its Account Number.';
            this.showCheckoutError(this.errorMessage);
        }
    
        return !this.showError; // true if valid
    }

    async stageAction(checkoutStage) {
        switch (checkoutStage) {
            case CheckoutStage.CHECK_VALIDITY_UPDATE:
                return Promise.resolve(this.checkValidity());
            case CheckoutStage.REPORT_VALIDITY_SAVE:
                return Promise.resolve(true);
            case CheckoutStage.START_PAYMENT_SESSION:
                console.log('selectedShippingMethod: ',this.selectedShippingMethod);
                console.log('reportValidity: ',this.reportValidity());
                if(this.showFields){
                    if(this.reportValidity()){
                        this.showSpinner=true;
                        this.mapParams.cartId = this.cartId;
                        this.mapParams.shippingProvider = this.value;
                        this.mapParams.shippingAccountNumber = this.accountNumber;
                        console.log('mapParams: ',this.mapParams);
                        // let result = await this.handleCartChange(this.mapParams);
                        updateCartWithShippingProviderDetails( {mapParams : this.mapParams} )
                        .then(result => {
                            console.log('result: ',result);
                            if(result.isSuccess){
                                this.showSpinner=false;
                                return Promise.resolve(this.reportValidity());
                            }
                            else{
                                this.showSpinner=false;
                                Toast.show({
                                    label: toastError,
                                    message: result.message,
                                    variant: 'error',
                                    mode: 'dismissible'
                                });
                                return Promise.resolve(false);
                            }
                        })
                        .catch(error => {
                            console.log('error: ',error);
                        });
                    }
                    else{
                        return Promise.resolve(this.reportValidity());
                    }
                }
                else{
                    return Promise.resolve(this.reportValidity());
                }
            default:
                return Promise.resolve(true);
        }
    }

    showCheckoutError(errorMessage) {
        console.log('## Checkout Error: ', errorMessage);
        this.dispatchUpdateErrorAsync({
            groupId: "Checkout",
            type: "/commerce/errors/checkout-failure",
            exception: errorMessage
        });
    }  

    handleChange(event) {
        this.value = event.detail.value;
    }

    handleNumberChange(event){
        this.accountNumber = event.detail.value;
    }

    async handleCartChange(mapParams){
        updateCartWithShippingProviderDetails( {mapParams : mapParams} )
        .then(result => {
            console.log('result: ',result);
            return result;
        })
        .catch(error => {
            console.log('error: ',error);
            return error;
        });
    }
}