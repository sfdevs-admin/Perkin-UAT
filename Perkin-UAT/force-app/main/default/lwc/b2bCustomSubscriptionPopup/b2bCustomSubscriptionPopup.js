import { LightningElement, api, track } from 'lwc';
import CommonModal from 'c/commonModal';
import b2bCreateNewModal from 'c/b2bCreateNewModal';
import {
    AddToSubscription, questionToAddItem,
    NewSubscription, back,
    saveAndContinue,
    B2B_GotoSubscriptionList,
    ExistingSubtnMsg,
    CreateSUbscription,
    AddToExisting,
    ExistingSubscriptionMsg,
    actionContinueShopping
} from 'c/b2bCustomLabels';

export default class B2bCustomSubscriptionPopup extends LightningElement {
    //variables
    labels = {
        CreateSUbscription,
        ExistingSubtnMsg,
        AddToSubscription,
        questionToAddItem,
        NewSubscription,
        B2B_GotoSubscriptionList,
        back,
        saveAndContinue,
        ExistingSubscriptionMsg,
        AddToExisting,
        actionContinueShopping
    }
    spinnerModal;
    showSpinner = false;
    @api showExistingSubscriptionButton = false;
    _newSubscriptionProperties;
    @api parentRecordsMap;

    @api
    get newSubscriptionProperties() {
        return this._newSubscriptionProperties;
    }
    set newSubscriptionProperties(val) {

        this._newSubscriptionProperties = val;
    }
    @api
    set existingSubscriptionProperties(val) {

        this._existingSubscriptionProperties = val;
    }
    get existingSubscriptionProperties() {
        return this._existingSubscriptionProperties;
    }

    _existingSubscriptionProperties;

    @track launchNew = true;
    get properties() {
        return this.launchNew ? this.newSubscriptionProperties : this.existingSubscriptionProperties;
    }


    connectedCallback() {
        this.initialModal();
    }
    async initialModal() {
        this.showExistingSubscriptionModal();
    }
    async dummyModal() {
        var initialResult = await CommonModal.open({
            message: this.labels.ExistingSubtnMsg,
            label: 'Subscription', // <-- Required
            size: 'small', // <-- Optional, defaults to 'medium'
            description: 'Subscription', // <-- Optional
            secondaryActionLabel: this.showExistingSubscriptionButton ?
                this.labels.AddToExisting : '', // <-- Required
            primaryActionLabel: this.labels.CreateSUbscription, // <-- Required
            onprimaryactionclick: () => this.showNewSubscriptionModal(),
            onsecondaryactionclick: () => this.showExistingSubscriptionModal()

        });
        console.log('initialResult ', initialResult);
        if (!initialResult) {
            this.closeModal();
        }
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
    async showNewSubscriptionModal() {
        this.launchNew = true;
        let result = await b2bCreateNewModal.open({
            modalTitle: this.labels.NewSubscription,
            properties: this.properties,
            label: 'Subscription', // <-- Required
            size: 'small', // <-- Optional, defaults to 'medium'
            description: this.labels.NewSubscription, // <-- Optional
            secondaryActionLabel: this.labels.back, // <-- Required,
            primaryActionLabel: this.labels.saveAndContinue, // <-- Required

        });
        console.log('result ', result);
        if (result && result !== 'close') {
            this.showSpinner = true;
            await this.createNewSubscription(result, true);

        } else if (result === 'close') {
            this.initialModal();
        } else {
            this.closeModal();

        }
    }
    @api
    async showConfirmationScreen(resultInstance) {
        this.showSpinner = false;

        CommonModal.open(
            {
                message: resultInstance,
                label: this.labels.AddToSubscription, // <-- Required
                size: 'small', // <-- Optional, defaults to 'medium'
                description: this.labels.AddToSubscription, // <-- Optional
                primaryActionLabel : this.labels.B2B_GotoSubscriptionList,
                secondaryActionLabel: this.labels.actionContinueShopping,
                onprimaryactionclick: () => this.navigateToList(),
                onsecondaryactionclick: () => this.closeModal()
            }
        );

    }
    navigateToList() {
        this.dispatchEvent(new CustomEvent('navigatetolist', {
            detail: {}
        }));
        this.closeModal();
    }
    // handleItemCreation() {
    //     this.showSpinner = true;
    //     this.dispatchEvent(new CustomEvent('createchild', {
    //         bubbles: true,
    //         composed: true,
    //         detail: {
    //             subscriptionRecord: this.subscriptionRecord
    //         },
    //     }));

    // }

    async createNewSubscription(fields, isCreate) {
        this.dispatchEvent(new CustomEvent('createparent', {
            bubbles: true,
            composed: true,
            detail: {
                create: isCreate,
                subscriptionRecord: fields
            },
        }));
    }

    showExistingSubscriptionModal() {
        this.showSpinner = true;
        this.showExistingParentModal(this.existingSubscriptionProperties, this.parentRecordsMap);
    }

    @api
    async showExistingParentModal(subscriptionProperties, subscriptionsMap) {
        this.launchNew = false;

        this.showSpinner = false;
        let result = await b2bCreateNewModal.open({
            modalTitle: this.labels.ExistingSubscriptionMsg,
            properties: subscriptionProperties,
            label: this.labels.ExistingSubscriptionMsg, // <-- Required
            size: 'small', // <-- Optional, defaults to 'medium'
            description: this.labels.ExistingSubscriptionMsg, // <-- Optional
            secondaryActionLabel: this.labels.CreateSUbscription, // <-- Required,
            primaryActionLabel: this.showExistingSubscriptionButton ?
                this.labels.saveAndContinue : '', // <-- Required
            existingRecordMap: subscriptionsMap

        });
        console.log('result ', result);
        if (result && result != 'close') {
            this.showSpinner = true;
            await this.createNewSubscription(result, false);


        } else if (result == 'close') {
            this.showNewSubscriptionModal();
        } else {
            this.closeModal();

        }

    }

}