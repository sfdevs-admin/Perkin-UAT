import { LightningElement, api, track, wire } from 'lwc';
import BillingFrequencyField from "@salesforce/schema/B2B_Subscriptions__c.B2B_Billing_Frequency__c";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getSessionContext } from 'commerce/contextApi';
import isGuest from '@salesforce/user/isGuest';
import loginStartUrl from '@salesforce/label/c.B2B_Site_Start_Url';
import { NavigationMixin } from 'lightning/navigation';
import { fetchWebStoreId, fetchPromotionsForProductIds } from 'c/b2bApiUtils';
import { validateDealsForAccount } from 'c/b2bDealsValidatorUtil';

//import required labels
import {
    ItemErrorMsg,
    BillingFrequency, ProductAlreadyExist,
    ProductNextBillingCycleNote,
    SbsctnCreationSuccess,
    SubscriptionError,
    AddToSubscription,
    ItemSuccess,
    B2B_Product_Add_Sub,
    saved,
    chooseSubscriptionList,
    note,
    toastError
} from 'c/b2bCustomLabels';
import getSubscriptions from '@salesforce/apex/B2B_SubscriptionController.getSubscriptions';
import createSFRecord from '@salesforce/apex/B2B_SubscriptionController.createRecord';
import DefaultRecordTypeId from '@salesforce/label/c.DefaultRecordTypeId';
import Toast from 'lightning/toast';

import SUBSCRIPTION_DISCOUNT from '@salesforce/label/c.B2B_PDP_Subscription_Discount';
import GENERAL_ERROR_MESSAGE from '@salesforce/label/c.B2B_GeneralErrorMessage';
import UNIT_PRICE from '@salesforce/label/c.B2B_UnitPrice';
import { debounce } from "experience/utils";

export default class B2bCustomSubscriptionPdp extends NavigationMixin(LightningElement) {
    static renderMode = 'light';
    
    //variables
    labels = {
        ItemErrorMsg,
        saved,
        ProductAlreadyExist,
        BillingFrequency,
        ProductNextBillingCycleNote,
        SbsctnCreationSuccess,
        SubscriptionError,
        ItemSuccess,
        AddToSubscription,
        B2B_Product_Add_Sub,
        chooseSubscriptionList,
        note,
        GENERAL_ERROR_MESSAGE,
        UNIT_PRICE,
        toastError
    }
    productId;
    _productData;
    subscriptionRecord = {};
    showSubscriptionModal = false;
    quantity = 1;
    webStoreId;
    showExistingSubscriptionButton = true;
    promoPrice = null;
    savedAmount = null;
    isPromotionLoaded = false;
    effectiveAccountId;
    isDisabled = true;

    //track
    @track subscriptions;
    @track selectedFrequency;
    @track frequencyOptions = [];
    @track subscriptionListOptions
    @track existingSubscriptionProperties = [];
    get newSubscriptionProperties() {
        return [
            {
                isLabel: true,
                label: this.labels.BillingFrequency + ' : ' + this.selectedFrequency,

            },
            {
                isLabel: true,
                isInput: true,
                propertyId: 'Subscription_Name__c',
                label: 'Subscription Name',
                dataType: 'text',
                selectedAnswer: '',
                isRequired: true
            },
            {
                isLabel: true,
                isTextArea: true,
                label: 'Description',
                propertyId: 'Description__c',
                selectedAnswer: '',
                isRequired: false
            }

        ]
    };

    //api getters
    @api productPricing;
    @api
    set productData(value) {
        if (value) {
            this._productData = value;
            this.productId = this._productData.id;
            this.getAllActiveSubscriptions();
        }
    }
    get productData() {
        return this._productData;
    }

    get pricingCurrencyIsoCode() {
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
    get pricingCurrencyIsoCode() {
        return this.productPricing?.currencyIsoCode || '';
    }



    //connectedcallback
    async connectedCallback() {
        await this.getSessionDetails();
        validateDealsForAccount()
            .then(result => {
                console.log('Result validateDealsForAccount PDP Subscriotion::: ', result);
                this.hasDealsApplied = result;

                // if (!hasDealsApplied) {
                //     console.log('Promo apply');
                //     this.fetchPromotionPricing();
                // }
            });
        // this.fetchPromotionPricing();
        // await this.getSessionDetails();
        this.subsciptionDiscountCalculation();
    }

    //Session details
    async getSessionDetails() {

        await getSessionContext()
            .then((response) => {

                this.effectiveAccountId = response.effectiveAccountId || response.accountId;
            })
            .catch((error) => {
                console.error(error);
            });
    }
    //Add to subsciption click
    handleSubscriptionClick() {
        if (!isGuest) {
            this.showSubscriptionModal = true;
        } else {
            //For Guest Redirect to Login page
            const baseURL = window.location.pathname + window.location.search;
            const loginURL = `${loginStartUrl}${encodeURIComponent(baseURL)}`;
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: loginURL
                }
            });
        }
    }

    //Get Billing frequency Picklist values
    @wire(getPicklistValues, { recordTypeId: DefaultRecordTypeId, fieldApiName: BillingFrequencyField })
    jobTitleValues({ error, data }) {
        if (data) {
            this.frequencyOptions = data.values.map(option => {
                return {
                    label: option.label,
                    value: option.value,
                    //For 1st Element to be selected on load
                    variant: option.value == data.values[0].value ?
                        'brand' : 'neutral'
                };
            });
            this.selectedFrequency = this.frequencyOptions[0].value;
            this.getAllActiveSubscriptions();

        }
        else if (error) {
            console.error('Error in getPicklistValues: ', error);
        }
    }

    //fetch Promotion pricing
    fetchPromotionPricing() {
        this.isPromotionLoaded = false;
        fetchWebStoreId()
            .then(result => {
                this.webStoreId = result.webstoreId;

                if (this.productId) {
                    const locale = localStorage.getItem('currentUserLocale') || 'en-US';
                    const productIds = [this.productId];
                    // return fetchProductPromotions(this.webStoreId, this.productId, locale);
                    return fetchPromotionsForProductIds(this.webStoreId, productIds, locale)
                }
            })
            .then(data => {
                const result = this.extractPromoData(data);
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

    // Get all active subscriptions
    getAllActiveSubscriptions() {
        this.launchNew = false;
        if (isGuest) {
            this.isDisabled = false;
        } else {
            let mapParams = {};
            if (this.selectedFrequency && this.productData?.id && this.effectiveAccountId) {
                //map instance
                mapParams.accountId = this.effectiveAccountId;
                mapParams.billingFrequency = this.selectedFrequency;
                mapParams.productId = this.productData?.id;

                getSubscriptions({ mapParams })
                    .then(result => {

                        if (result.isSuccess) {
                            this.isDisabled = false;
                            //map of existing subscriptions
                            this.subscriptions = result.subscriptions;
                            //for dropdown
                            this.subscriptionListOptions = Object.entries(result.subscriptions).map(([key, value]) => ({
                                label: value.Subscription_Name__c,
                                value: key
                            }));

                            //existin modal properties
                            this.existingSubscriptionProperties = [
                                {
                                    isLabel: true,
                                    label: this.labels.BillingFrequency + ' : ' + this.selectedFrequency,

                                },
                                {
                                    isLabel: true,
                                    label: this.labels.ProductNextBillingCycleNote,
                                    criteria: 'existingRecord?.B2B_Status__c == "Active"',
                                    style: 'display:none'
                                },
                                {
                                    isLabel: true,
                                    isCombobox: true,
                                    label: this.labels.chooseSubscriptionList,
                                    options: this.subscriptionListOptions,
                                    selectedAnswer: this.subscriptionListOptions?.length > 0 ?
                                        this.subscriptionListOptions[0].value : '',
                                    propertyId: 'id',
                                    isExisting: true,
                                    disabled: result.message == 'No Subscriptions found'
                                },
                                {
                                    isLabel: true,
                                    label: this.labels.note,

                                },
                            ];
                            this.showExistingSubscriptionButton = result.message != 'No Subscriptions found';

                        } /* else if (result.message == 'No Subscriptions found') {
                        this.showExistingSubscriptionButton = false;
                    } */
                    })
                    .catch(error => {
                        console.error('Error loading lists', error);
                    });
            }
        }
    }

    //On QTY Change
    handleProductQuantity(event) {
        this.quantity = event.detail.message;
    }

    //On Frequency Change
    handleDeliverySelect(event) {
        this.selectedFrequency = event.target.dataset.value;
        this.frequencyOptions = this.frequencyOptions.map(opt => ({
            ...opt,
            variant: opt.value === this.selectedFrequency ? 'brand' : 'neutral'
        }));
        this.getAllActiveSubscriptions();
    }

    handleCloseSubscription() {
        this.showSubscriptionModal = false;

    }

    //Event handler for Subscription creation
    async handleParentCreate(event) {
        var fields = event.detail.subscriptionRecord;
        //create
        if (event.detail.create) {
            fields['B2B_Account__c'] = this.effectiveAccountId;
            //fields.B2B_Contact__c = this.contactId;
            fields['B2B_Billing_Frequency__c'] = this.selectedFrequency;
            fields['B2B_Status__c'] = 'Inactive';
            var mapParams = {
                'insertRecord': fields,
                'sobjectType': 'B2B_Subscriptions__c',
                'accountId': this.effectiveAccountId
            }

            // Invoke createRecord
            createSFRecord({ mapParams })
                .then(result => {
                    console.log('Craete SF ::: ', result);
                    if (result.isSuccess == true) {

                        //inserted subscription record
                        this.subscriptionRecord = result.insertRecord;
                        this.handleChildCreate();
                        // this.template.querySelector('c-b2b-custom-subscription-popup').showConfirmationScreen(this.labels.B2B_Product_Add_Sub);
                        // //Success toast
                        // Toast.show({
                        //     label: 'Success',
                        //     message: this.labels.SbsctnCreationSuccess,
                        //     variant: 'success',
                        //     mode: 'dismissible'
                        // });
                    } else {
                        this.showSubscriptionModal = false;
                        Toast.show({
                            label: toastError,
                            message: this.labels.SubscriptionError,
                            variant: 'error',
                            mode: 'dismissible'
                        });
                    }
                })
                .catch(error => {
                    console.error('Error creating subscription', error);
                });

        }//add id to instance
        else {
            this.subscriptionRecord = event.detail.subscriptionRecord;
            await this.handleChildCreate();

            // var msg = this.subscriptionRecord?.B2B_Subscription_Items__r?.length > 0 ?
            //     this.labels.ProductAlreadyExist : this.labels.B2B_Product_Add_Sub;
            // if (this.subscriptionRecord?.B2B_Subscription_Items__r?.length == 0) {
            //     await this.handleChildCreate();
            // }
            //this.template.querySelector('c-b2b-custom-subscription-popup').showConfirmationScreen(msg);

        }
    }


    // Event Handler for On Subscription Item Creation 
    async handleChildCreate() {
        console.log('displayPrice ', this.displayPrice);
        let subscriptionItem = {};
        subscriptionItem.B2B_Product__c = this.productData.id;
        subscriptionItem.B2B_Quantity__c = this.quantity;
        subscriptionItem.B2B_Subscriptions__c = this.subscriptionRecord.id || this.subscriptionRecord.Id;
        subscriptionItem.B2B_Unit_Price__c = this.isSubscriptionDiscountApplied ? parseFloat(this.finalPrice) : parseFloat(this.displayPrice);
        let listPrice = this.productPricing?.listPrice ?? this.productPricing?.unitPrice ;
        subscriptionItem.B2B_List_Price__c = parseFloat( listPrice );

        try {
            let msg = this.subscriptionRecord?.B2B_Subscription_Items__r?.length > 0 ?
                this.labels.ProductAlreadyExist : this.labels.B2B_Product_Add_Sub + ' ' + this.subscriptionRecord.Subscription_Name__c + ' ('+ this.subscriptionRecord.B2B_Billing_Frequency__c+')';
            let mapParams = {
                'insertRecord': subscriptionItem,
                'sobjectType': 'B2B_Subscription_Items__c',
                'accountId': this.effectiveAccountId
            }
            // Invoke createRecord
            createSFRecord({ mapParams })
                .then(result => {
                    if (result.isSuccess == true) {

                        // Toast.show({
                        //     label: 'Success',
                        //     message: this.labels.ItemSuccess,
                        //     variant: 'success',
                        //     mode: 'dismissible'
                        // });
                        this.getAllActiveSubscriptions();

                        this.querySelector('c-b2b-custom-subscription-popup').showConfirmationScreen(msg);
                        // this.template.querySelector('c-b2b-custom-subscription-popup').showConfirmationScreen(msg);
                        this.subscriptionItemRecord = result.insertRecord;
                        this.showSubscriptionModal = false;

                    } else {
                        this.showSubscriptionModal = false;
                        Toast.show({
                            label: toastError,
                            message: this.labels.ItemErrorMsg,
                            variant: 'error',
                            mode: 'dismissible'
                        });
                    }
                })
                .catch(error => {
                    console.error('Error creating subscription', error);
                });


        } catch (error) {
            // Handle error

            Toast.show({
                label: toastError,
                message: GENERAL_ERROR_MESSAGE,
                variant: 'error',
                mode: 'dismissible'
            });
        }
    }

    navigateToList() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Subscriptions__c'
            }
        });
    }


    finalPrice;
    isSubscriptionDiscountApplied = false;
    displaySavedPercentage;
    @api accountSubscriptionDiscount;
    hasDealsApplied = false;

    subsciptionDiscountLogic() {
        let unitPrice = this.productPricing?.unitPrice || 0;

        if (isGuest) {
            if (!this.hasDealsApplied) {
                if (Number(SUBSCRIPTION_DISCOUNT) > 0) {
                    //do the calculation here for price this.productPricing?.unitPrice and append on UI 
                    let subscriptionDiscountLabel = Number(SUBSCRIPTION_DISCOUNT);
                    this.finalPrice = (unitPrice - (unitPrice * subscriptionDiscountLabel / 100)).toFixed(2);
                    console.log('final price  label : ', this.finalPrice);
                    this.isSubscriptionDiscountApplied = true;
                    this.displaySavedPercentage = (unitPrice * subscriptionDiscountLabel / 100).toFixed(2);

                } else {
                    this.fetchPromotionPricing();
                }
            }
        } else {
            if (!this.hasDealsApplied) {
                if (this.accountSubscriptionDiscount) {
                    //do the calculation here for price this.productPricing?.unitPrice and append on UI
                    this.finalPrice = (unitPrice - (unitPrice * this.accountSubscriptionDiscount / 100)).toFixed(2);
                    console.log('final price : ', this.finalPrice);
                    this.isSubscriptionDiscountApplied = true;
                    this.displaySavedPercentage = (unitPrice * this.accountSubscriptionDiscount / 100).toFixed(2);

                } else if (Number(SUBSCRIPTION_DISCOUNT) > 0) {
                    //do the calculation here for price this.productPricing?.unitPrice and append on UI 
                    let subscriptionDiscountLabel = Number(SUBSCRIPTION_DISCOUNT);
                    this.finalPrice = (unitPrice - (unitPrice * subscriptionDiscountLabel / 100)).toFixed(2);
                    console.log('final price  label : ', this.finalPrice);
                    this.isSubscriptionDiscountApplied = true;
                    this.displaySavedPercentage = (unitPrice * subscriptionDiscountLabel / 100).toFixed(2);

                } else {
                    this.fetchPromotionPricing();
                    this.isSubscriptionDiscountApplied = false;
                }
                
            }
        }
    }


    subsciptionDiscountCalculation = debounce(() => {
        this.subsciptionDiscountLogic();
    }, 2000);

}