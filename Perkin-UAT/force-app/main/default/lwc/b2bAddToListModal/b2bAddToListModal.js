import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import getShoppingList from '@salesforce/apex/B2B_ShoppingListController.getShoppingLists';
import createShoppingList from '@salesforce/apex/B2B_ShoppingListController.createShoppingList';
import addItemToShoppingList from '@salesforce/apex/B2B_ShoppingListController.addItemToShoppingList';
import Toast from 'lightning/toast';
import labels from './labels';

export default class B2bAddToListModal extends LightningModal {
    @track currentStep = 'select';

    shoppingLists = [];
    @track shoppingListExist = true;
    @track selectedListName = '';
    @track selectedListDescription = '';
    @track selectedListId = '';
    @track newListName = '';
    @track newListDescription = '';
    @track newListIsDefault = false;
    @api productId;
    @api quantity;
    @track isLoading = true;
    @track labels = labels;

    connectedCallback() {
        this.getAllActiveShoppingLists();
    }

    // Step Getters
    get isCreateStep() {
        return this.currentStep === 'create';
    }
    get isSelectExistingStep() {
        return this.currentStep === 'select';
    }
    get isSuccessStep() {
        return this.currentStep === 'success';
    }

    get disableSave() {
        return !this.newListName;
    }
    get disableAddToExistingList () {
        return !this.shoppingListExist;
    }

    // Step Navigation
    handleChooseCreate() {
        this.currentStep = 'create';
    }
    handleBack() {
        this.currentStep = 'select';
    }

    // Load Lists
    getAllActiveShoppingLists() {
        this.isLoading = true;
        let mapParams = {};
        getShoppingList({ mapParams })
            .then(result => {
                this.isLoading = false;
                if (result.isSuccess) {
                    this.shoppingListExist = true;
                    this.shoppingLists = result.shoppingLists;
                    const defaultList = this.shoppingLists.find(list => list.B2B_Default__c === true);
                    if (defaultList) {
                        this.setSelectedList(defaultList.Id);
                    }
                } else {
                    this.shoppingListExist = false;
                }
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error loading lists', error);
            });
    }

    get listOptions() {
        return (this.shoppingLists || []).map(list => ({
            label: list.B2B_Name__c + (list.B2B_Default__c ? ' '+ labels.defaultLabel : ''),
            value: list.Id
        }));
    }

    handleListChange(event) {
        const listId = event.detail.value;
        this.setSelectedList(listId);
    }

    setSelectedList(listId) {
        this.selectedListId = listId;
        const selected = this.shoppingLists.find(l => l.Id === listId);
        this.selectedListName = selected?.B2B_Name__c || '';
        this.selectedListDescription = selected?.B2B_Description__c || '';
    }

    // Create New List Handlers
    handleNameChange(event) {
        this.newListName = event.target.value;
    }
    handleDescriptionChange(event) {
        this.newListDescription = event.target.value;
    }
    handleIsDefaultChange(event) {
        this.newListIsDefault = event.target.checked;
    }

    handleSaveNewList() {
        this.isLoading = true;
        const mapParams = {
            name: this.newListName,
            description: this.newListDescription,
            isDefault: this.newListIsDefault
        };

        createShoppingList({ mapParams })
            .then(result => {
                // console.log('create list ---->', result);
                this.isLoading = false;
                if (result.isSuccess) {
                    this.selectedListId = result?.shoppingList?.Id;
                    this.selectedListName = result?.shoppingList?.B2B_Name__c || '';
                    this.selectedListDescription = result?.shoppingList?.B2B_Description__c || '';

                    this.newListName = '';
                    this.newListDescription = '';
                    this.newListIsDefault = false;
                    // this.currentStep = 'success'; //'review';

                    Toast.show({
                        label: this.labels.toastSuccess,
                        message: labels.shoppingListCreated,
                        variant: 'success',
                        mode: 'dismissible'
                    });
                    this.handleAddToList();
                } else {
                    Toast.show({
                        label: this.labels.toastError,
                        message: result.message,
                        variant: 'error',
                        mode: 'dismissible'
                    });
                }
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error creating shopping list', error);
            });
    }

    // Add Item to List
    handleAddToList() {
        this.isLoading = true;
        const mapParams = {
            shoppingListId: this.selectedListId,
            productId: this.productId,
            quantity: this.quantity
        };

        addItemToShoppingList({ mapParams })
            .then(result => {
                this.isLoading = false;
                if (result.isSuccess) {
                    this.currentStep = 'success';
                } else {
                    Toast.show({
                        label: this.labels.toastError,
                        message: result.message,
                        variant: 'error',
                        mode: 'dismissible'
                    });
                }
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error adding item', error);
            });
    }

    handleGoToMyList() {
        const navigateToCartEvent = new CustomEvent('navigatetoshoppinglistdetails', {
            detail: { 
                selectedListId: this.selectedListId
             }
        });
        this.dispatchEvent(navigateToCartEvent);
        this.close('closed');
    }

    closeModal() {
        this.close('closed');
    }
}