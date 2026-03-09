import { track, api } from 'lwc';
import LightningModal from 'lightning/modal';
import labels from './labels';  

export default class B2bClonePublicListModal extends LightningModal {
    @track newListName = '';
    @track newListDescription = '';
    @track newListIsDefault = false;
    @track labels = labels;

    @api isEdit = false;
    @api name = '';
    @api description = '';
    @api isDefault = false;

    @api isSubscription = false;
    @api selectedStatus;
    @api selectedFrequency;
    @api statusOptions = [];
    @api frequencyOptions = [];
    @api billingDate;
    @track newSelectedStatus;
    @track newSelectedFrequency;

    get modalTitle() {
        return this.isEdit ? this.labels.editListHeading : this.labels.clonePublicListHeading;
    }

    connectedCallback(){
        console.log('initial values');
        this.newListName = this.name || '';
        this.newListDescription = this.description || '';
        this.newListIsDefault = this.isDefault || false;
        this.newSelectedStatus = this.selectedStatus || '';
        this.newSelectedFrequency = this.selectedFrequency || '';
    }
    handleNameChange(event) {
        this.newListName = event.target.value;
    }
    handleDescriptionChange(event) {
        this.newListDescription = event.target.value;
    }
    handleIsDefaultChange(event) {
        this.newListIsDefault = event.target.checked;
    }
    handleStatusChange(event) {
        this.newSelectedStatus = event.detail.value;
    }

    handleFrequencyChange(event) {
        this.newSelectedFrequency = event.detail.value;
    }

    get disableSave() {
        return !this.newListName;
    }

    handleSave() {
        const eventName = this.isEdit ? 'editlist' : 'createclonelist';

        const detail = {
            newListName: this.newListName,
            newListDescription: this.newListDescription,
            newListIsDefault: this.newListIsDefault
        };

        const evt = new CustomEvent(eventName, { detail });
        this.dispatchEvent(evt);
        this.close('closed');
    }

    handleSaveSubscription() {
        console.log('this.newSelectedStatus:: ', this.newSelectedStatus);
        console.log('this.newSelectedFrequency:: ', this.newSelectedFrequency);
            
         const detail = {
            name: this.newListName,
            description: this.newListDescription,
            status: this.newSelectedStatus,
            frequency: this.newSelectedFrequency
        };
        const evt = new CustomEvent('editsubscription', { detail });
        this.dispatchEvent(evt);

        this.close('closed');
    }

    closeModal() {
        this.close('closed');
    }
}