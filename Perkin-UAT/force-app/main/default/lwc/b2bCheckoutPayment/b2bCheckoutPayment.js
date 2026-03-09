import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { CartSummaryAdapter, refreshCartSummary } from 'commerce/cartApi';
import { getSessionContext } from 'commerce/contextApi';
import { useCheckoutComponent, CheckoutInformationAdapter, postAuthorizePayment, placeOrder, simplePurchaseOrderPayment, createContactPointAddress } from 'commerce/checkoutApi';
import getCustomerId from '@salesforce/apex/B2BStripePaymentController.getCustomerId';
import processPayments from '@salesforce/apex/B2BStripePaymentController.processPayments';
import validateSession from '@salesforce/apex/B2BStripePaymentController.validateSession';
import getExistingBillingAddress from '@salesforce/apex/B2BCheckoutBillingAddressController.getExistingBillingAddress';
import logExceptionForPayment from '@salesforce/apex/B2BCheckoutBillingAddressController.logExceptionForPayment';
import MaxNumOfRetries from '@salesforce/label/c.B2B_Stripe_Max_Num_of_Retries';

import getBillingCpaExist from '@salesforce/apex/B2BCheckoutBillingAddressController.getBillingCpaExist';
import TEMP_ACCOUNT_FIELD from "@salesforce/schema/Account.Temp_eComm_Acct__c";
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

import CommonModal from 'c/commonModal';
import REGION_REQUIRED_COUNTRIES from '@salesforce/label/c.B2B_Checkout_Region_Required_Countries';
import CHECKOUT_MODAL_HEADER from '@salesforce/label/c.B2B_Checkout_Modal_Header';
import WITHOUT_FILE_UPLOAD from '@salesforce/label/c.B2B_Checkout_Without_File_Upload';
import RETURN_TO_CHECKOUT from '@salesforce/label/c.B2B_Checkout_Return_To_Checkout';
import CHECKOUT_BODY_MESSAGE from '@salesforce/label/c.B2B_Checkout_Without_PO_Upload';
import BILLING_ADDRESS from '@salesforce/label/c.B2B_OrderSummary_Billing_Address';
import SAME_AS_SHIPPING_ADDRESS from '@salesforce/label/c.B2B_Checkout_SameAsShipping';
import PAY_NOW from '@salesforce/label/c.B2B_Checkout_PayNow';
import SUBMIT_PO from '@salesforce/label/c.B2B_Checkout_SubmitPO';
import ERROR_PAYMENT_TEXT from '@salesforce/label/c.B2B_Checkout_ErrorPaymentProcessText';
import ERROR_EMAIL_TEXT from '@salesforce/label/c.B2B_Checkout_ErrorEmailText';
import ERROR_PO_TEXT from '@salesforce/label/c.B2B_Checkout_ErrorPOText';
import ERROR_BILLING_ADDRESS_TEXT from '@salesforce/label/c.B2B_Checkout_ErrorBillingAddressText';
import ERROR_ORDER_CREATION_TEXT from '@salesforce/label/c.B2B_Checkout_ErrorOrderCreationText';
import ERROR_GENERAL_TEXT from '@salesforce/label/c.B2B_Checkout_ErrorGeneralText';
import ENTER_PO from '@salesforce/label/c.B2B_Checkout_EnterPOText';

import CART_OBJECT from '@salesforce/schema/WebCart';
import CART_ID_FIELD from '@salesforce/schema/WebCart.Id';
import IS_ATTACHMENT_EXIST_FIELD from '@salesforce/schema/WebCart.B2B_Is_PO_Attachment_Exist__c';

const CheckoutStage = {
    CHECK_VALIDITY_UPDATE: 'CHECK_VALIDITY_UPDATE',
    REPORT_VALIDITY_SAVE: 'REPORT_VALIDITY_SAVE',
    BEFORE_PAYMENT: 'BEFORE_PAYMENT',
    PAYMENT: 'PAYMENT',
    BEFORE_PLACE_ORDER: 'BEFORE_PLACE_ORDER',
    PLACE_ORDER: 'PLACE_ORDER'
};

export default class B2bCheckoutPayment extends NavigationMixin(useCheckoutComponent(LightningElement)) {
    labels = {
        BILLING_ADDRESS,
        SAME_AS_SHIPPING_ADDRESS,
        PAY_NOW,
        SUBMIT_PO
    };

    fileNameList = [];
    reqErrorMessage = '';

    showReqError = false;
    showAddressForm = false;

    @api recordId;
    @api loadingMessage;
    @api paynowLabel;
    @api purchaseOrderLabel;
    @api checkoutDetails;
    @api existingBillingAddress = {
        addressType: 'Billing',
        firstName: "",
        lastName: "",
        street: "",
        city: "",
        region: "",
        country: "",
        postalCode: ""
    };

    checkoutId;
    deliveryAddress;
    sameAsShipping;
    billingAddress;
    isTempAccount;

    @track hideSameAsShippingCheckbox = false;
    @wire(getRecord, {
        recordId: "$effectiveAccountId",
        fields: [TEMP_ACCOUNT_FIELD]
    })
    currentAccountRecord({ error, data }) {
        if (data) {
            this.isTempAccount = data.fields?.Temp_eComm_Acct__c?.value;
            if (this.isTempAccount) {
                this.hideSameAsShippingCheckbox = false;
                let sameAsShippingValue = localStorage.getItem('sameAsShipping');
                this.sameAsShipping = sameAsShippingValue === null ? true : sameAsShippingValue === 'true';
            } else {
                this.sameAsShipping = false;
                this.hideSameAsShippingCheckbox = true;
            }    
        }
    }
    //hide same as shipping checkbox for qualified account
    get hideSameAsShipping() {
        return this.hideSameAsShippingCheckbox;
    }


    handleCheckboxChange(event) {
        console.log('handle checkbox change:: ', this.existingBillingAddress);
        this.sameAsShipping = event.target.checked;
        this.showAddressForm = !this.sameAsShipping;
        localStorage.setItem('sameAsShipping', this.sameAsShipping);
    }

    handleAddressChange(event) {
        this.billingAddress = event.detail;

        //hide same as shipping when billing address exist
        this.hideSameAsShippingCheckbox = true;
        this.sameAsShipping = false;
    }

    @wire(CheckoutInformationAdapter, {})
    checkoutInfo({ error, data }) {
        if (data) {
            this.checkoutDetails = data;
            this.checkoutId = data.checkoutId;
            this.deliveryAddress = data.deliveryGroups.items[0].deliveryAddress;
        } else if (error) {
            console.error('Error in CheckoutInfo: ', error);
        }
    }

    showFileUpload = false;
    isChecked = false;
    showSpinner = false;
    isRendered = false;
    errorMessage = '';
    paymentOption = 'paynow';
    pageReference;
    effectiveAccountId;
    customerId;
    session;
    paymentIntent;
    selectedPaymentMethod;
    stripePaymentDone = false;
    numOfRetry = 0;

    paymentOptions = [
        { label: PAY_NOW, value: 'paynow' },
        { label: SUBMIT_PO, value: 'po' },
    ];

    get options() {
        return this.paymentOptions;
    }

    @wire(CurrentPageReference)
    handleStateChange(pageReference) {
        // let sameAsShippingValue = localStorage.getItem('sameAsShipping');
        // this.sameAsShipping = sameAsShippingValue === null ? true : sameAsShippingValue === 'true';
        this.pageReference = pageReference;
        this.checkSession();
    }

    @wire(CartSummaryAdapter, { 'cartStateOrId': 'current' })
    async wiredCartSummaryData(result) {
        if (result.data && result.data.cartId) {
            this.recordId = result.data.cartId;
            if (this.recordId !== undefined) {
                await this.getBillingAddress();
            }
        }
        this.checkSession();
    }

    async getBillingAddress() {
        getExistingBillingAddress({
            cartId: this.recordId
        })
            .then(result => {
                console.log('existing billing addresses:: ', result);
                if (result != null) {
                    this.existingBillingAddress.firstName = result.Billing_FirstName__c;
                    this.existingBillingAddress.lastName = result.Billing_LastName__c;
                    this.existingBillingAddress.street = result.BillingStreet;
                    this.existingBillingAddress.city = result.BillingCity;
                    this.existingBillingAddress.region = result.BillingState;
                    this.existingBillingAddress.postalCode = result.BillingPostalCode
                    this.existingBillingAddress.country = result.BillingCountry;
                    this.billingAddress = this.existingBillingAddress;
                }

                if (this.isTempAccount && result?.BillingCountry != null) {
                    //hide same as shipping when billing address exist
                    this.hideSameAsShippingCheckbox = true;
                    this.sameAsShipping = false;
                }

                this.showAddressForm = !this.sameAsShipping;
            })
            .catch(error => {
                console.error('Error in getBillingAddress: ', error);
            })
    }

    async placeOrderFunction() {
        this.showSpinner = true;

        const placeOrderResult = await placeOrder();

        if (placeOrderResult && placeOrderResult.orderReferenceNumber) {
            refreshCartSummary();
            this.showSpinner = false;
            if (!this.sameAsShipping) {
                this.validateAndCreatedCPA(this.billingAddress);
                // await createContactPointAddress(this.billingAddress);
            }
            localStorage.removeItem('sameAsShipping');
            this.navigateToOrderConfirmation(placeOrderResult.orderReferenceNumber);
        }
        else {
            this.showSpinner = false;
            this.errorMessage = ERROR_ORDER_CREATION_TEXT;
            this.showCheckoutError(this.errorMessage);
        }
    }

    navigateToOrderConfirmation(orderNumber) {
        this[NavigationMixin.Navigate]({
            type: "comm__namedPage",
            attributes: {
                name: "Order"
            },
            state: {
                orderNumber: orderNumber
            }
        });
    }

    checkForAddress() {
        return this.sameAsShipping ? this.deliveryAddress : this.billingAddress
    }

    async checkSession() {
        try {
            if (this.pageReference == undefined || !this.recordId) { return; }
            let session = this.pageReference.state.session;

            if (!!session && !this.isChecked) {
                this.showSpinner = true;
                this.isChecked = true;

                let result = await this.validateSession(session);
                if (result && this.checkForAddress()) {
                    let paymentDataObj = await this.processPaymentFunction();

                    if (paymentDataObj && paymentDataObj.responseCode) {
                        await this.placeOrderFunction();
                    } else {
                        this.showSpinner = false;
                        this.errorMessage = ERROR_PAYMENT_TEXT;
                        this.logExceptions('Stripe Response :- \n' +
                            'isSessionValid: ' + result + '\n' +
                            'paymentIntent: ' + this.paymentIntent + '\n' +
                            'selectedPaymentMethod: ' + this.selectedPaymentMethod + '\n'
                            , 'Payment and Order Block');
                        this.showCheckoutError(this.errorMessage);
                    }
                }
                else {
                    if (this.numOfRetry < MaxNumOfRetries) {
                        this.numOfRetry++;
                        setTimeout(() => {
                            this.isChecked = false;
                            this.checkSession();
                        }, 4000);
                    }
                    else {
                        history.replaceState({ session: "" }, "", window.location.href.split('?')[0]);
                        this.showSpinner = false;
                        this.errorMessage = ERROR_PAYMENT_TEXT;
                        this.logExceptions('Stripe Response :- \n' +
                            'isSessionValid: ' + result + '\n' +
                            'paymentIntent: ' + this.paymentIntent + '\n' +
                            'selectedPaymentMethod: ' + this.selectedPaymentMethod + '\n'
                            , 'Retry Block');
                        this.showCheckoutError(this.errorMessage);
                    }
                }
            }
        } catch (error) {
            this.logExceptions(error.message, 'Catch Block');
        }
    }

    logExceptions(msg, subCategory) {

        let mapParams = {
            recordId: this.recordId,
            exceptionMsg: msg,
            exceptionType: 'Checkout - checkSession',
            category: 'Checkout',
            subCategory: subCategory
        };
        this.logExceptionForPaymentSF(mapParams);

    }

    logExceptionForPaymentSF(mapParams) {
        logExceptionForPayment({ 'mapParams': mapParams })
            .then((result) => {
                if (result.isSuccess) {
                    //The exception record in created.
                }
            })
            .catch((e) => {
                console.log('Error in logExceptions: ', e);
            })
    }

    async selectPaymentOption(event) {
        this.paymentOption = event.target.value;
        if (this.paymentOption == 'paynow') {
            await this.getCustomerId();
            this.showFileUpload = false;
        }
        else {
            this.showFileUpload = true;
        }
    }

    async connectedCallback() {
        this.effectiveAccountId = await this.getEffectiveAccountId();
        await this.getCustomerId();
    }

    async getCustomerId() {
        let { isSuccess, result, errorMessage } = await this.doRequest(getCustomerId, {});
        if (isSuccess) {
            this.customerId = result;
        } else {
            console.error('Error in getCustomerId: ', errorMessage);
        }
    }

    async getEffectiveAccountId() {
        return new Promise(async (resolve, reject) => {
            let result = null;
            await getSessionContext()
                .then((response) => {
                    result = response.effectiveAccountId || response.accountId;
                    resolve(result);
                })
                .catch((error) => {
                    console.error(error);
                    reject(result);
                });
        });
    }

    async validateSession(session) {
        let { isSuccess, result, errorMessage } = await this.doRequest(validateSession, {
            sessionId: session,
            webCartId: this.recordId
        });
        if (isSuccess) {
            this.paymentIntent = result.paymentIntent;
            this.selectedPaymentMethod = result.paymentMethodType;
        } else {
            console.error('Error in validateSession: ', errorMessage);
        }
        return result.isSessionValid;
    }

    async stageAction(checkoutStage) {
        switch (checkoutStage) {
            case CheckoutStage.CHECK_VALIDITY_UPDATE:
                return Promise.resolve(true);
            case CheckoutStage.REPORT_VALIDITY_SAVE:
                return Promise.resolve(this.checkValidity());
            case CheckoutStage.BEFORE_PAYMENT:
                if (!this.stripePaymentDone) {
                    if (this.paymentOption == 'paynow') {
                        if (this.customerId != null) {
                            this.showSpinner = true;
                            const href = window.location.href;
                            this.session = await this.processPayments(href);
                            window.location = this.session.url;
                            return Promise.resolve(true);
                        }
                        else {
                            this.errorMessage = ERROR_EMAIL_TEXT;
                            this.showCheckoutError(this.errorMessage);
                        }
                    }
                    if (this.paymentOption === 'po') {
                        const isFileMissing = !this.fileNameList || this.fileNameList.length === 0;
                        await this.updatePOAttachmentStatus();
                        if (isFileMissing) {
                            // Show modal prompting user action
                            return new Promise(async (resolve) => {
                                const resultModal = await CommonModal.open({
                                    label: CHECKOUT_MODAL_HEADER,
                                    message: CHECKOUT_BODY_MESSAGE,
                                    size: 'small',
                                    primaryActionLabel: WITHOUT_FILE_UPLOAD,
                                    secondaryActionLabel: RETURN_TO_CHECKOUT,

                                    // Proceed without PO → continue with order placement
                                    onprimaryactionclick: async () => {
                                        this.closeModal();
                                        this.showSpinner = true;
                                        await this.simplePOPayment();
                                        resolve(true);
                                    },

                                    //Return → cancel order placement
                                    onsecondaryactionclick: () => {
                                        this.closeModal();
                                        resolve(false);
                                    }
                                });
                                if (resultModal === undefined || resultModal === '') {
                                    resolve(false);
                                }
                            });
                        } else {
                            // File uploaded → continue normal PO flow
                            this.showSpinner = true;
                            await this.simplePOPayment();
                            return Promise.resolve(true);
                        }
                    }
                } else {
                    return Promise.resolve(true);
                }
            default:
                return Promise.resolve(true);
        }
    }

    async handleUpload(event) {
        const dataFromChild = JSON.parse(JSON.stringify(event.detail));
        this.fileNameList = dataFromChild;

        await this.updatePOAttachmentStatus();
    }

    checkValidity() {
        let purchaseOrderInputValue;

        if (this.paymentOption === 'po') {
            const poInput = this.getPurchaseOrderInput();
            purchaseOrderInputValue = poInput ? poInput.value : null;
        }

        this.showReqError = this.paymentOption === 'po' &&
            (!purchaseOrderInputValue || purchaseOrderInputValue.trim() === '');

        if (this.showReqError) {
            this.errorMessage = ERROR_PO_TEXT;
            this.showCheckoutError(this.errorMessage);
            return false;
        }

        this.dispatchUpdateErrorAsync({
            groupId: 'Checkout',
            type: null,
            exception: null
        });

        return true;
    }
   
    closeModal() {
        this.dispatchEvent(new CustomEvent('closesubscription', {
            bubbles: true,
            composed: true,
            detail: {
                close: true
            },
        }));
    }
    get isValidBillingAddress() {
        return this.sameAsShipping
            ? this.deliveryAddress && this.deliveryAddress?.country && this.deliveryAddress?.postalCode && this.deliveryAddress?.street && this.deliveryAddress?.city
            : this.billingAddress && this.billingAddress?.country && this.billingAddress?.postalCode && this.billingAddress?.street && this.billingAddress?.city;
    }

    async processPaymentFunction() {
        this.showSpinner = true;
        let paymentToken = this.paymentIntent;
        let billingAddress = this.sameAsShipping ? this.deliveryAddress : this.billingAddress;
        let paymentData = {
            'paymentMethod': this.selectedPaymentMethod
        }
        var paymentBillingAddress = '';
        try {
            if (this.isValidBillingAddress) {
                paymentBillingAddress = {
                    'firstName': billingAddress.firstName,
                    'lastName': billingAddress.lastName,
                    'city': billingAddress.city,
                    'country': billingAddress.country,
                    'postalCode': billingAddress.postalCode,
                    'street': billingAddress.street
                };
                // Conditionally include region
                const country = billingAddress.country ? billingAddress.country.toUpperCase() : '';
                const regionRequiredCountries = REGION_REQUIRED_COUNTRIES.split(',')
                    .map(code => code.trim().toUpperCase());

                // Include region only if the country is in the allowed list
                if (regionRequiredCountries.includes(country)) {
                    paymentBillingAddress.region = billingAddress.region;
                }


                const paymentResult = await postAuthorizePayment('active', paymentToken, paymentBillingAddress, paymentData);

                if (paymentResult.errors.length > 0) {
                    this.showCheckoutError(paymentResult.errors[0]?.detail);
                    return false;
                } else {
                    this.stripePaymentDone = true;
                    return {
                        responseCode: paymentToken
                    };
                }
            }
            else {
                this.showSpinner = false;
                this.errorMessage = ERROR_BILLING_ADDRESS_TEXT
                this.showCheckoutError(this.errorMessage);
                return false;
            }
        } catch (error) {

            let mapParams = {
                recordId: this.recordId,
                exceptionMsg: JSON.stringify(error),
                exceptionType: 'Checkout - checkSession',
                category: 'Payment',
                subCategory: 'Payment Via Stripe',
                requestJson: 'Selected Billing Address ' + JSON.stringify(paymentBillingAddress)
            };
            this.logExceptionForPaymentSF(mapParams);
            this.showSpinner = false;

            this.errorMessage = ERROR_GENERAL_TEXT;
            this.showCheckoutError(this.errorMessage);
            resolve({
                isSuccess: false,
                errorMessage: JSON.stringify(error)
            });

        }
    }

    async processPayments(href) {
        this.showSpinner = true;

        let { isSuccess, result, errorMessage } = await this.doRequest(processPayments, {
            webCartId: this.recordId,
            customerId: this.customerId,
            href: href
        });

        return result;
    }

    doRequest(action, params) {
        return new Promise((resolve, reject) => {
            action(params)
                .then(res => {
                    resolve({
                        isSuccess: true,
                        result: res,
                        errorMessage: ''
                    });
                })
                .catch(error => {
                    this.errorMessage = ERROR_GENERAL_TEXT;
                    this.showCheckoutError(this.errorMessage);
                    resolve({
                        isSuccess: false,
                        errorMessage: JSON.stringify(error)
                    });
                });
        });
    }

    showCheckoutError(errorMessage) {
        this.dispatchUpdateErrorAsync({
            groupId: "Checkout",
            type: "/commerce/errors/checkout-failure",
            exception: errorMessage
        });
    }

    get placeholderLabel() {
        return ENTER_PO;
    }

    get inputLabel() {
        return SUBMIT_PO;
    }

    async simplePOPayment() {
        let address = this.sameAsShipping ? this.deliveryAddress : this.billingAddress;

        let finalAddress = { ...address };
        const regionRequiredCountries = REGION_REQUIRED_COUNTRIES.split(',')
            .map(code => code.trim().toUpperCase());
        // Remove region if country is not in the allowed list
        if (!regionRequiredCountries.includes(finalAddress.country?.toUpperCase())) {
            delete finalAddress.region;
        }


        const purchaseOrderInputValue = this.getPurchaseOrderInput().value;
        try {
            let po = await simplePurchaseOrderPayment(this.checkoutId, purchaseOrderInputValue, finalAddress);

            if (po && po.errors.length > 0) {
                this.showCheckoutError(po.errors[0]?.detail);
                return false;
            }
            else {
                await this.placeOrderFunction();
            }
        } catch (error) {
            let mapParams = {
                recordId: this.recordId,
                exceptionMsg: JSON.stringify(error),
                exceptionType: 'Checkout - checkSession',
                category: 'Payment',
                subCategory: 'Payment Via PO Number',
                requestJson: 'Selected Billing Address ' + JSON.stringify(address)
            };
            this.logExceptionForPaymentSF(mapParams);
            this.showSpinner = false;
            this.errorMessage = ERROR_GENERAL_TEXT;
            this.showCheckoutError(this.errorMessage);
        }
    }

    getPurchaseOrderInput() {
        return this.refs.poInput;
    }

    //validate the Billling CPA exist or not, then create CPA
    async validateAndCreatedCPA(billingAddress) {
        const mapParams = {
            accountId: this.effectiveAccountId,
            billingAddress: {
                street: billingAddress.street,
                city: billingAddress.city,
                region: billingAddress.region,
                postalCode: billingAddress.postalCode,
                country: billingAddress.country,
                firstName: billingAddress.firstName,
                lastName: billingAddress.lastName
            }
        };

        const result = await getBillingCpaExist({ mapParams: mapParams });
        if (!result?.isDuplicate) {
            await createContactPointAddress(this.billingAddress);
        }
    }

    //
    async updatePOAttachmentStatus() {
        const isFileMissing = !this.fileNameList || this.fileNameList.length === 0;
        const attachmentStatus = isFileMissing ? 'NoAttachment' : '';

        try {
            await updateRecord({
                fields: {
                    Id: this.recordId,
                    [IS_ATTACHMENT_EXIST_FIELD.fieldApiName]: attachmentStatus
                }
            });
            console.log(' PO Attachment status updated:', attachmentStatus);
        } catch (error) {
            console.error(' Error updating PO Attachment status:', error);
        }
    }
}