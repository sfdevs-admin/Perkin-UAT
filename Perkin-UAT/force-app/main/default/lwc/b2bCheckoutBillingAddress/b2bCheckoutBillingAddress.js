import { LightningElement, api, wire, track } from 'lwc';
import { useCheckoutComponent, createContactPointAddress } from 'commerce/checkoutApi';
import validateAddress from "@salesforce/apex/B2BCheckoutBillingAddressController.validateAddress";
import updateBiilingAddressOnCart from "@salesforce/apex/B2BCheckoutBillingAddressController.updateBiilingAddressOnCart";
import BillingAddressEmpty from '@salesforce/label/c.B2B_Billing_Address_Empty';
import BillingAddressInvalid from '@salesforce/label/c.B2B_Billing_Address_Invalid';
import BillingAddressNotValidated from '@salesforce/label/c.B2B_Billing_Address_Not_Validated';
import BillingFirstName from '@salesforce/label/c.B2B_Billing_FirstName';
import BillingLastName from '@salesforce/label/c.B2B_Billing_LastName';
import BillingStreet from '@salesforce/label/c.B2B_Billing_Street';
import BillingCity from '@salesforce/label/c.B2B_Billing_City';
import BillingPostalCode from '@salesforce/label/c.B2B_Billing_PostalCode';
import BillingCountry from '@salesforce/label/c.B2B_Billing_Country';
import BillingState from '@salesforce/label/c.B2B_Billing_State';
import BillingAddressValidate from '@salesforce/label/c.B2B_Billing_Address_Validate_Button';
import BillingAddressModalHeading from '@salesforce/label/c.B2B_Billing_Address_Modal_Heading';
import BillingAddressModalContent from '@salesforce/label/c.B2B_Billing_Address_Modal_Content';
import BillingAddressCancel from '@salesforce/label/c.B2B_Billing_Address_Cancel_Button';
import BillingAddressUpdate from '@salesforce/label/c.B2B_Billing_Address_Update_Button';
import TEMP_ACCOUNT_FIELD from "@salesforce/schema/Account.Temp_eComm_Acct__c";
import BillingStreet_FIELD from "@salesforce/schema/Account.BillingStreet";
import BillingState_FIELD from "@salesforce/schema/Account.BillingState";
import BillingCity_FIELD from "@salesforce/schema/Account.BillingCity";
import BillingPostalCode_FIELD from "@salesforce/schema/Account.BillingPostalCode";
import BillingCountry_FIELD from "@salesforce/schema/Account.BillingCountry";
import BillingAddressModalHeader from '@salesforce/label/c.BillingAddressModalHeader';
import ChangeLabel from '@salesforce/label/c.ChangeLabel';
import BillingAddressMsg from '@salesforce/label/c.BillingAddressMsg';
import cancelButton from '@salesforce/label/c.Search_Facets_cancelButton';
import okButton from '@salesforce/label/c.B2B_Modal_OkButton';
import CommonModal from 'c/commonModal';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';


import getBillingCpaExist from '@salesforce/apex/B2BCheckoutBillingAddressController.getBillingCpaExist';
import getExistingOrders from '@salesforce/apex/B2BCheckoutBillingAddressController.getExistingOrders';

const CheckoutStage = {
    CHECK_VALIDITY_UPDATE: 'CHECK_VALIDITY_UPDATE',
    REPORT_VALIDITY_SAVE: 'REPORT_VALIDITY_SAVE',
    BEFORE_PAYMENT: 'BEFORE_PAYMENT',
    PAYMENT: 'PAYMENT',
    BEFORE_PLACE_ORDER: 'BEFORE_PLACE_ORDER',
    PLACE_ORDER: 'PLACE_ORDER'
};

export default class B2bCheckoutBillingAddress extends useCheckoutComponent(LightningElement) {

    @api accountid;
    @api
    label = {
        firstName: BillingFirstName,
        lastName: BillingLastName,
        street: BillingStreet,
        city: BillingCity,
        postalCode: BillingPostalCode,
        country: BillingCountry,
        state: BillingState,
        validate: BillingAddressValidate,
        modaHeading: BillingAddressModalHeading,
        modalContent: BillingAddressModalContent,
        cancel: BillingAddressCancel,
        update: BillingAddressUpdate,
        changeLabel: ChangeLabel,
        readMsg: BillingAddressMsg,
        billingHeader : BillingAddressModalHeader
    };

    showFormattedAddress = false;
    disableButton = true;
    isValidAddress = false;
    showSpinner = false;
    showAddressErrorMsg = false;

    invalidAddressMsg;
    formattedAddress = '';
    errorMessage;
    addressResponse;
    isTempAccount = false;
    currentAccount = {};
    showReadAddress = false;
    @api existingBillingAddress;

    @wire(getRecord, {
        recordId: "$accountid",
        fields: [TEMP_ACCOUNT_FIELD, BillingStreet_FIELD, BillingState_FIELD, BillingCity_FIELD
            , BillingPostalCode_FIELD, BillingCountry_FIELD]
    })
    currentAccountRecord({ error, data }) {
        console.log('acc ', data);
        console.log('error ', error);


        if (data) {
            this.isTempAccount = data.fields?.Temp_eComm_Acct__c?.value;
            this.currentAccount = data;
            this.setBillingAdddress();

        }
    }
    get showComp() {
        return !this.showReadOnlyAddress || (this.showReadOnlyAddress && (this.billingAddress.street ||
            this.billingAddress.city || this.billingAddress.region ||
            this.billingAddress.country || this.billingAddress.postalCode));
    }
   
    /*Show Read View For 
    * Qualified Account - Has Billing Address From Account
    * For Temp Account - Address is saved via Form or address exist on cart
    */
    get showReadOnlyAddress() {
        return (this.showReadAddress) && this.billingAddress.postalCode;
        // return (!this.isTempAccount || this.showReadAddress) && this.billingAddress.postalCode;


        // return (!this.isTempAccount && this.billingAddress.postalCode) || this.showReadAddress ||
        //     (!this.showReadAddress && this.existingBillingAddress.postalCode);
    }
    @track billingAddress = {
        addressType: 'Billing',
        firstName: "",
        lastName: "",
        street: "",
        city: "",
        region: "",
        country: "",
        postalCode: ""
    };

    connectedCallback() {
        console.log('##Address Form Loaded', this.isTempAccount);
        //this.showReadOnlyAddress = !this.isTempAccount;
        this.showSpinner = true;
        this.setBillingAdddress();
    }

    setBillingAdddress() {
        const addr = this.existingBillingAddress;
        if (!this.isTempAccount && (this.currentAccount?.fields?.BillingStreet?.value ||
            this.currentAccount?.fields?.BillingState?.value ||
            this.currentAccount?.fields?.BillingPostalCode?.value ||
            this.currentAccount?.fields?.BillingCountry?.value ||
            this.currentAccount?.fields?.BillingCity?.value)) {
            this.billingAddress.street = this.currentAccount.fields.BillingStreet.value;
            this.billingAddress.city = this.currentAccount.fields.BillingCity.value;
            this.billingAddress.region = this.currentAccount.fields.BillingState.value;
            this.billingAddress.postalCode = this.currentAccount.fields.BillingPostalCode.value;
            this.billingAddress.country = this.currentAccount.fields.BillingCountry.value;
            this.validateFieldValues();

        }
        else if (addr && Object.keys(addr).length > 0 && (addr.firstName || addr.street || addr.postalCode)) {
            console.log('##Existing Billing Address: ', JSON.stringify(this.existingBillingAddress));
            this.billingAddress.firstName = this.existingBillingAddress.firstName;
            this.billingAddress.lastName = this.existingBillingAddress.lastName;
            this.billingAddress.street = this.existingBillingAddress.street;
            this.billingAddress.city = this.existingBillingAddress.city;
            this.billingAddress.region = this.existingBillingAddress.region;
            this.billingAddress.postalCode = this.existingBillingAddress.postalCode;
            this.billingAddress.country = this.existingBillingAddress.country;

            this.validateFieldValues();
            //Need to validate it
            if (addr.street || addr.postalCode) {
                this.isValidAddress = true;
                this.showReadAddress = true;
            }
        }
        this.showSpinner = false;

        this.getExistingOrdersFunc();
    }

    handleAddressChange(event) {
        const fieldName = event.target.name;
        if (fieldName === 'firstName') {
            this.billingAddress.firstName = event.target.value;
        }
        else if (fieldName === 'lastName') {
            this.billingAddress.lastName = event.target.value;
        }
        else if (fieldName === 'address') {
            const { street, city, province, country, postalCode } = event.detail;

            this.billingAddress.street = street;
            this.billingAddress.city = city;
            this.billingAddress.postalCode = postalCode;
            this.billingAddress.region = province;
            this.billingAddress.country = country;
        }
        this.isValidAddress = false;
        this.validateFieldValues();
    }

    validateFieldValues() {
        if (
            this.billingAddress.firstName != "" && this.billingAddress.firstName != null &&
            this.billingAddress.lastName != "" && this.billingAddress.lastName != null &&
            this.billingAddress.street != "" && this.billingAddress.street != null &&
            this.billingAddress.city != "" && this.billingAddress.city != null &&
            this.billingAddress.region != "" && this.billingAddress.region != null &&
            this.billingAddress.postalCode != "" && this.billingAddress.postalCode != null &&
            this.billingAddress.country != "" && this.billingAddress.country != null
        ) {
            this.disableButton = false;
            return true;
        }
        else {
            this.disableButton = true;
            return false;
        }
    }

    async validateBillingAddress() {
        this.showSpinner = true;
        // clear input validity errors from previous submit
        this.clearInputValidity();

        await validateAddress({
            address: this.billingAddress
        })
            .then((response) => {
                console.log("##Address Validation Response: ", response);

                if (response.isValid && response.invalidFields.length == 0) {
                    this.formattedAddress = response.address;
                    this.addressResponse = response;
                    this.showSpinner = false;
                    this.showFormattedAddress = true;
                }
                else {
                    console.log("##Invalid Fields:", response.invalidFields);
                    this.isValidAddress = false;
                    this.showSpinner = false;

                    let displayNamesMap = {
                        province: 'state',
                        postalCode: 'zip code'
                    };

                    let readableFields = response.invalidFields.map((field) => {
                        return displayNamesMap[field] || field;
                    });

                    let invalidFieldsText = '';
                    if (readableFields.length === 1) {
                        invalidFieldsText = readableFields[0];
                    } else if (readableFields.length === 2) {
                        invalidFieldsText = readableFields.join(' and ');
                    } else {
                        invalidFieldsText = readableFields.slice(0, -1).join(', ') + ', and ' + readableFields.slice(-1);
                    }

                    this.invalidAddressMsg = BillingAddressInvalid + ' ' + invalidFieldsText;

                    this.showAddressErrorMsg = true;
                }
            })
            .catch((error) => {
                console.error("Error in Validating Shipping Address : ", JSON.stringify(error));
                this.showSpinner = false;
                this.showAddressErrorMsg = true;
            });
    }

    clearInputValidity() {
        this.showAddressErrorMsg = false;
    }

    closeModal() {
        this.showFormattedAddress = false;
        this.isValidAddress = false;
    }

    async updateAddress() {
        this.billingAddress.street = this.addressResponse.street;
        this.billingAddress.city = this.addressResponse.city;
        this.billingAddress.postalCode = this.addressResponse.postalCode;
        this.billingAddress.region = this.addressResponse.state;
        this.billingAddress.country = this.addressResponse.country;

        await updateBiilingAddressOnCart({
            address: this.billingAddress
        })
            .then(() => {
                this.showReadAddress = true;
                if (this.isTempAccount) {
                    console.log('create cpa when new billing created on checkout ', this.billingAddress);
                    this.validateAndCreatedCPA(this.billingAddress);
                }
            })
            .catch(error => {
                console.error('Error in updateBiilingAddressOnCart: ', JSON.stringify(error));
            });

        this.showFormattedAddress = false;
        this.isValidAddress = true;

        const selectedEvent = new CustomEvent("submitaddress", {
            detail: this.billingAddress
        });
        this.dispatchEvent(selectedEvent);
    }

    async stageAction(checkoutStage) {
        switch (checkoutStage) {
            case CheckoutStage.CHECK_VALIDITY_UPDATE:
                return Promise.resolve(this.checkValidity);
            case CheckoutStage.REPORT_VALIDITY_SAVE:
                return Promise.resolve(this.reportValidity());
            default:
                return Promise.resolve(true);
        }
    }

    get checkValidity() {
        //skip for qualified account condtn 
        if (!this.disableButton || !this.isTempAccount) {
            //skip for qualified account condtn 
            if (this.isValidAddress || !this.isTempAccount) {
                return true;
            }
            else {
                this.errorMessage = BillingAddressNotValidated;
                this.showCheckoutError(this.errorMessage);
                return false;
            }
        }
        else {
            this.errorMessage = BillingAddressEmpty;
            this.showCheckoutError(this.errorMessage);
            return false;
        }
    }

    async reportValidity() {
        return this.checkValidity;
    }

    showCheckoutError(errorMessage) {
        this.dispatchUpdateErrorAsync({
            groupId: "Checkout",
            type: "/commerce/errors/checkout-failure",
            exception: errorMessage
        });
    }
    handleChangeClick(event) {
        if ( this.isTempAccount && this.existingOrdersSize == 0 ) {
            this.showReadAddress = false;
        } else {
            CommonModal.open({
                message: this.label.readMsg,
                label: this.label.billingHeader, // <-- Required
                size: 'small', // <-- Optional, defaults to 'medium'
                description: this.label.readMsg, // <-- Optional
                secondaryActionLabel: cancelButton, // <-- Required
                primaryActionLabel: okButton, // <-- Required

            });
        }
    }

    //validate the Billling CPA exist or not, then create CPA
        async validateAndCreatedCPA(billingAddress) {
            const mapParams = {
                accountId: this.accountid,
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


    existingOrdersSize = 0;
    async getExistingOrdersFunc(){
        const mapParams = {
            accountId: this.accountid,
        };
        await getExistingOrders({
            mapParams: mapParams
        })
        .then(( res ) => {
            console.log('B2bCheckoutBillingAddress getExistingOrdersFunc---- ', res);
            if( res.isSuccess ){
                this.existingOrdersSize = res.existingOrderListSize;
            }
        })
        .catch(error => {
            console.error('B2bCheckoutBillingAddress getExistingOrdersFunc error exception---- ', JSON.stringify(error));
        });
    }
}