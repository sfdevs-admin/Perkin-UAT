import { LightningElement, wire, track,api } from 'lwc';
import { NavigationMixin, navigate, NavigationContext, CurrentPageReference } from 'lightning/navigation';
import getSubscriptionItems from '@salesforce/apex/B2B_MySubscriptionController.getSubscriptionItems';
import labels from './labels';
import b2bClonePublicListModal from 'c/b2bClonePublicListModal';
import { getObjectInfo, getPicklistValuesByRecordType  } from 'lightning/uiObjectInfoApi';
import SUBSCRIPTION_OBJECT from '@salesforce/schema/B2B_Subscriptions__c';
import STATUS_FIELD from '@salesforce/schema/B2B_Subscriptions__c.B2B_Status__c';
import NAME_FIELD  from '@salesforce/schema/B2B_Subscriptions__c.Subscription_Name__c';
import DESCRIPTION_FIELD  from '@salesforce/schema/B2B_Subscriptions__c.Description__c';
import NEXT_BILLING_DATE_FIELD from '@salesforce/schema/B2B_Subscriptions__c.B2B_Next_Billing_Date__c';
import QUANTITY_FIELD  from '@salesforce/schema/B2B_Subscription_Items__c.B2B_Quantity__c';
import { updateRecord, deleteRecord  } from 'lightning/uiRecordApi';
import mainTemplate from "./b2bMySubscriptionDetails.html";
import stencilTemplate from "./b2bMySubscriptionDetailsStencil.html";
import { validateDealsForAccount, getEffectiveAccountId } from 'c/b2bDealsValidatorUtil';
import Toast from 'lightning/toast';
import createCartAndItems from '@salesforce/apex/B2B_SubscriptionController.createCartAndItems';
import communityId from '@salesforce/community/Id';
import { refreshCartSummary, CartSummaryAdapter } from 'commerce/cartApi';
import b2bMySubscriptionModal from 'c/b2bMySubscriptionModal';

import { getRecord } from 'lightning/uiRecordApi';
import B2B_SUBSCRIPTION_DISCOUNT from "@salesforce/schema/Account.B2B_Subscription_Discount__c";

export default class B2bMySubscriptionDetails extends NavigationMixin(LightningElement) {
    @track selectedListId;
    @track selectedListName = '';
    @track selectedListDescription = '';
    @track selectedListStatus = '';
    @track selectedListBillingFrequency = '';
    @track selectedListBillingDate = '';
    listItems =[];
    @track labels = labels;
    @track statusOptions =[];
    @track frequencyOptions =[];
    @track isLoading = false;
    @track hasDealsApplied = false;
    isSubscription = true;
    effectiveAccountId;
    isCartExist = false;
    isActivated = false;
    subscriptionObjectInfo;
    cartId;

    @api initialVisibleCount; 
    @api pageSize;
    @track visibleItemCount;

    @wire(CartSummaryAdapter)
    cartSummary({ data }) {
        if (data) {
            console.log('Cart summary data ::: ', data);
            let totalProductCount = data?.totalProductCount;
            this.cartId = data?.cartId;
            console.log('Total Product Count :::', totalProductCount);
            this.isCartExist = totalProductCount > 0 ? true : false;
        }
    }

    @wire(getObjectInfo, { objectApiName: SUBSCRIPTION_OBJECT })
    objectInfoHandler({ data, error }) {
        if (data) {
            console.log('Obj info::: ', data);
            this.subscriptionObjectInfo = data;
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getPicklistValuesByRecordType, { 
        objectApiName: SUBSCRIPTION_OBJECT,
        recordTypeId: '$subscriptionObjectInfo.defaultRecordTypeId'
    })
    picklistValuesHandler({ data, error }) {
        if (data) {
            console.log('All picklist values:', data.picklistFieldValues);

            this.statusOptions = data.picklistFieldValues.B2B_Status__c?.values.map(v => ({
                label: v.label,
                value: v.value
            }));

            this.frequencyOptions = data.picklistFieldValues.B2B_Billing_Frequency__c?.values.map(v => ({
                label: v.label,
                value: v.value
            }));
        } else if (error) {
            console.error(error);
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('currentPageReference::: ', currentPageReference);
        if (currentPageReference) {
            this.selectedListId = currentPageReference.state?.subscriptionListId || null;
            if (this.selectedListId) {
                this.pricingFailedProductIds = new Set();
                this.loadSubscriptionItems();
            }
        }
    }

    loadSubscriptionItems() {
        this.visibleItemCount = this.initialVisibleCount;
        this.isLoading = true;

        validateDealsForAccount()
        .then(result => {
            // console.log('Result validateDealsForAccount::: ', result);
            this.hasDealsApplied = result;
        });

        let mapParams = { subscriptionId: this.selectedListId };
        getSubscriptionItems({ mapParams: mapParams})
            .then(data => {
                console.log('Data::: ', data);
                if (data.isSuccess) {
                    this.selectedListName = data?.subscriptionData?.subscriptionName;
                    this.selectedListDescription = data?.subscriptionData?.subscriptionDescription;
                    this.selectedListStatus = data?.subscriptionData?.subscriptionStatus;
                    this.selectedListBillingFrequency = data?.subscriptionData?.subscriptionBillingFrequency;
                    this.selectedListBillingDate = data?.subscriptionData?.subscriptionNextBillingDate;
                    this.listItems = data?.subscriptionData?.items;
                } else {
                    this.selectedListName = '';
                    this.selectedListDescription ='';
                    this.selectedListStatus = '';
                    this.selectedListBillingFrequency = '';
                    this.selectedListBillingDate = '';
                    this.listItems = [];
                }
            })
            .catch(error => {
                console.error('error::: ', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    async openEditModal() {
        await b2bClonePublicListModal.open({
            label: this.labels.editList,
            size: 'small',
            isEdit: true,
            isSubscription: true,
            name: this.selectedListName,
            description: this.selectedListDescription,
            selectedStatus: this.selectedListStatus,
            selectedFrequency: this.selectedListBillingFrequency,
            statusOptions: this.statusOptions,
            frequencyOptions: this.frequencyOptions,
            billingDate: this.selectedListBillingDate,
            oneditsubscription: (event) => {
                event.stopPropagation();
                this.saveEditedList(event);
            }
        });

    }

    get addToCartButtonDisabled () {
        return false;
    }
    get itemCountInfo() {
        const total = this.listItems.length;

        return `${total} ${total === 1 ? labels.item : labels.items}`;
    }
    get isListEmpty() {
        return this.listItems.length === 0;
    }
    get showActivateButton() {
        return this.selectedListStatus === 'Inactive';
    }
    get showActiveSubscriptionButton() {
        return this.selectedListStatus === 'Paused';
    }
    get showStatusChangeButtons() {
        return this.selectedListStatus === 'Active';
    }
    get showEditButton() {
        return this.selectedListStatus === 'Cancelled';
    }
    get showSubscriptionPrices() {
        return this.selectedListStatus === 'Active' || this.selectedListStatus === 'Paused';
    }
    handlePause() {
        this.updateStatusUsingUiApi('Paused');
    }
    handleCancel() {
        this.updateStatusUsingUiApi('Cancelled');
    }
    updateStatusUsingUiApi(newStatus) {
        this.isLoading = true;
        const fieldsToUpdate = {
            Id: this.selectedListId,
            [STATUS_FIELD.fieldApiName]: newStatus
        };

        this.updateRecordFields(fieldsToUpdate);
    }
    handleMenuAction(event) {
        const selected = event.detail.value;
        console.log('Selected value :: ', selected);
        switch (selected) {
            case 'edit':
                this.openEditModal();
                break;
            case this.labels.pauseMenu:
                this.openStatusChangeModal(selected);
                // this.handlePause();
                break;
            case this.labels.cancelMenu:
                this.openStatusChangeModal(selected);
                // this.handleCancel();
                break;
            default:
                break;
        }
    }

    saveEditedList(event) {
        console.log('Event::: ', event);
        let name = event.detail.name;
        let description = event.detail.description;
        let status = event.detail.status;   
        let frequency = event.detail.frequency;

        const fields = { Id: this.selectedListId };

        if (name !== this.selectedListName) {
            fields[NAME_FIELD.fieldApiName] = name;
        }
        if (description !== this.selectedListDescription) {
            fields[DESCRIPTION_FIELD.fieldApiName] = description;
        }

        if (Object.keys(fields).length > 1) {
            this.updateRecordFields(fields);
        } else {
            console.log('No changes detected.');
            Toast.show({
                label: 'Info',
                message: this.labels.noChangesDetected,
                variant: 'info',
                mode: 'dismissible'
            });
        }
    }

    updateRecordFields(fieldsToUpdate) {
        this.isLoading = true;

        updateRecord({ fields: fieldsToUpdate })
            .then(() => {
                console.log('Record updated successfully');
                this.loadSubscriptionItems();
            })
            .catch(error => {
                console.error('Error updating record', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    async handleActivate() {
        this.isLoading = true;
        await getEffectiveAccountId()
        .then(result => {
            console.log('Result effectiveAccountId::: ', result);
            this.effectiveAccountId = result;
            this.callCreateCartAndItems();
        });
    }
    
    callCreateCartAndItems() {
        let mapParams = {
            'communityId': communityId,
            'recordId' : this.selectedListId,
            'effectiveAccountId': this.effectiveAccountId,
            'cartId': this.cartId,
            'pricingFailedProductIds': this.pricingFailedProductIds.size > 0
                                    ? Array.from(this.pricingFailedProductIds) 
                                    : null
        };

        createCartAndItems ( { mapParams : mapParams})
        .then(data => {
            console.log('Data cart create::: ', data); 
            if (data.isSuccess) {
                refreshCartSummary();
                this.isActivated = true;
                // this.openModal();
                this.navigateToCart();
            }   
        })
        .catch(error => {
            console.log('Error cart create::: ', error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleProductQuantity(event) {
        let productId = event.detail.productId;
        let newQuantity = event.detail.value;
        let itemId = event.detail.itemId;

        this.listItems = this.listItems.map(item => {
            if (item.productId === productId) {
                return { ...item, quantity: newQuantity };
            }
            return item;
        });

        this.updateSubItemQty(itemId, newQuantity);  
    }

    updateSubItemQty(itemId, newQuantity) {
        const fields = { Id: itemId };

        fields[QUANTITY_FIELD.fieldApiName] = newQuantity;
        this.updateRecordFields(fields); 
    }

    async openActivateSubModal() {
        if(this.isCartExist) {
            this.openModal();
        } else {
            this.handleActivate();
        }

    }
    async openModal() {
        await b2bMySubscriptionModal.open({
            label: this.labels.activateSubscription,
            size: 'small',
            isCartExist: this.isCartExist,
            isActivated: this.isActivated,
            onactivatesubscription: (event) => {
                event.stopPropagation();
                 this.handleActivate();
            },
            onnavigatetocart: (event) => {
                event.stopPropagation();
                this.navigateToCart();
            }
        });
    }
    activateSubscription() {
        this.handleActivate();
    }

    handleDeleteItemFromList(event) {
        this.isLoading = true;
        console.log('Event delete :: ', event);
        let itemId = event.detail.itemid;
         deleteRecord(itemId)
            .then(() => {
                console.log('Record deleted successfully');
                this.loadSubscriptionItems();
            })
            .catch(error => {
                console.error('Error deleting record', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    async openStatusChangeModal(selected) {
        let selectedLabel = (this.labels.pauseSubscription).replace('{0}', selected);
        let confirmTextLabel = (this.labels.confirmtext).replace('{0}', selected);

        await b2bMySubscriptionModal.open({
            label: selectedLabel,
            size: 'small',
            confirmAction: selected,
            confirmMessage: confirmTextLabel,
            showConfirmation: true,
            onconfirmsubscriptionaction: (event) => {
                const actionType = event.detail.action;
                
                if (actionType === this.labels.pauseMenu) {
                    this.handlePause();
                } else if (actionType === this.labels.cancelMenu) {
                    this.handleCancel(); 
                }
            }
        });
    }

    @wire(NavigationContext)
    navContext;
        
    navigateToCart() {
        this.navContext &&
            navigate(this.navContext, {
                type: 'comm__namedPage',
                attributes: {
                    name: 'Current_Cart',
                },
            });
    }

    //show more fucntionality 
    get isShowMoreVisible() {
        return this.pageSize > 0 && 
            this.initialVisibleCount > 0 &&
            this.listItems.length > this.initialVisibleCount;
    }
    get showMoreLabel() {
        return this.visibleItemCount >= this.listItems.length
            ? this.labels.showLess
            : this.labels.showMore;
    }

    get visibleItems() {
        if (!this.visibleItemCount || this.visibleItemCount <= 0) {
            return this.listItems;
        }
        return this.listItems.slice(0, this.visibleItemCount);
    }

    handleToggleShowMore() {
        if (this.visibleItemCount >= this.listItems.length) {
            this.visibleItemCount = this.pageSize;
        } else {
            this.visibleItemCount = Math.min(
                this.visibleItemCount + this.pageSize,
                this.listItems.length
            );
        }
    }




    render() {
        if(this.isLoading){
            return stencilTemplate;
        }
        return mainTemplate;
    }


    // prices not avaialbel then exclude products from adding to cart 
    pricingFailedProductIds = new Set();
    handlePricingStatus(event) {
        const { productId, failed } = event.detail;
        if (failed) {
            console.log('failed :: ', failed);
            this.pricingFailedProductIds.add(productId);
        } 
        // else {
        //     this.pricingFailedProductIds.delete(productId);
        // }

        console.log('this.pricingFailedProductIds ::: ', this.pricingFailedProductIds);
    }

    //handle paused subscription

    toIsoDate(dateStr) {
        // Convert '2/1/2025' -> '2025-02-01'
        let parts = dateStr.split('/');
        let month = parts[0].padStart(2, '0'); 
        let day = parts[1].padStart(2, '0');  
        let year = parts[2];                  
        return `${year}-${month}-${day}`;
    }

    handleActiveSubscription() {
        this.isLoading = true;

        let today = new Date();
        let updatedBillingDate;
        if (this.selectedListBillingDate) {
            let isoBillingDateStr = this.toIsoDate(this.selectedListBillingDate);
            let billingDate = new Date(isoBillingDateStr);

            //Apply date logic
            if (billingDate <= today) {
                // Move to next cycle aligned to the original day
                let nextBillingDate = new Date(today);
                let originalDay = billingDate.getDate();
                nextBillingDate.setMonth(nextBillingDate.getMonth() + 1);

                // Align to the original billing day 
                nextBillingDate.setDate(originalDay);
                if (nextBillingDate.getDate() !== originalDay) {
                    nextBillingDate.setDate(0); // last day of month
                }

                updatedBillingDate = nextBillingDate.toISOString().split('T')[0];

            }
        }

        //  Prepare fields for update
        const fieldsToUpdate = { 
            Id: this.selectedListId,
            [STATUS_FIELD.fieldApiName]: 'Active'
        };
        if (updatedBillingDate) {
            fieldsToUpdate[NEXT_BILLING_DATE_FIELD.fieldApiName] = updatedBillingDate;
        }
        // update record

        if (Object.keys(fieldsToUpdate).length > 1) {
            updateRecord({ fields: fieldsToUpdate})
                .then(() => {
                    this.isLoading = false;
                    this.loadSubscriptionItems();
                })
                .catch(() => {
                    this.isLoading = false;
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } else {
            this.isLoading = false;
        }
    
    }

    async connectedCallback() {
        await getEffectiveAccountId()
        .then(result => {
            console.log('Result effectiveAccountId::: ', result);
            this.effectiveAccountId = result;
        });
    }

    accountSubscriptionDiscount;
    
    @wire(getRecord, {
            recordId: "$effectiveAccountId",
            fields: [B2B_SUBSCRIPTION_DISCOUNT]
        })
        currentAccountRecord({ error, data }) {
            console.log('wire::: info ', data);
            if (data !== undefined) {
                console.log('wire::: ', data);
                if (!this.showSubscriptionPrices) {
                    this.accountSubscriptionDiscount = data.fields?.B2B_Subscription_Discount__c?.value; 
                }
            }
        }

}