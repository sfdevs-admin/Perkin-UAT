import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin, navigate, NavigationContext, CurrentPageReference } from 'lightning/navigation';
import getShoppingListById from '@salesforce/apex/B2B_ShoppingListController.getShoppingListById';
import getShoppingListItems from '@salesforce/apex/B2B_ShoppingListController.getShoppingListItems';
import deleteShoppingList from '@salesforce/apex/B2B_ShoppingListController.deleteShoppingList';
import updateShoppingListItemQty from '@salesforce/apex/B2B_ShoppingListController.updateShoppingListItemQty';
import deleteShoppingListItem from '@salesforce/apex/B2B_ShoppingListController.deleteShoppingListItem';
import getPublicShoppingListById from '@salesforce/apex/B2B_ShoppingListController.getPublicShoppingListById';
import cloneShoppingList from '@salesforce/apex/B2B_ShoppingListController.cloneShoppingList';
import updateShoppingListDetails from '@salesforce/apex/B2B_ShoppingListController.updateShoppingListDetails';
import { addItemToCart, addItemsToCart, CartSummaryAdapter } from 'commerce/cartApi';
import Toast from 'lightning/toast';
import CommonModal from 'c/commonModal';
import isGuest from '@salesforce/user/isGuest';
import b2bClonePublicListModal from 'c/b2bClonePublicListModal';
import labels from './labels';
import mainTemplate from "./b2bShoppingListDetails.html";
import stencilTemplate from "./b2bShoppingListDetailsStencil.html";
import SHOPPING_LIST_UPDATE from '@salesforce/messageChannel/b2b_ShoppingListUpdate__c';
import { publish, MessageContext } from 'lightning/messageService';
import { validateDealsForAccount } from 'c/b2bDealsValidatorUtil';

import B2B_Is_Subscription_FIELD from "@salesforce/schema/WebCart.B2B_Is_Subscription__c";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import {
    ADD_TO_CART,
    AddToCartSubscriptionMsg
} from 'c/b2bCustomLabels';

export default class B2bShoppingListDetails extends NavigationMixin(LightningElement) {

    @wire(MessageContext) messageContext;
    @api isPublicListPage;
    @track selectedListId;
    @track selectedListName = '';
    @track selectedListDescription = '';
    @track selectedListIsDefault;
    @track selectedShoppingListId;
    @track listItems = [];
    @track filteredListItems = [];
    @track showSpinner = false;
    @track isLoading = false;
    searchKey = '';
    @track itemCountLabel = '';
    @track labels = labels;

    @api initialVisibleCount; 
    @api pageSize;
    @track visibleItemCount;
    @track hasDealsApplied = false;

    connectedCallback() {
        this.visibleItemCount = this.initialVisibleCount;
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        const baseURL = window.location.pathname + window.location.search;
        if (currentPageReference) {
            this.selectedListId = currentPageReference.state?.shoppingListId || null;
            if (this.selectedListId) {
                if (this.isPublicListPage) {
                    this.loadPublicListDetails();
                } else {
                    this.loadListDetails();
                }
                
            }
        }
    }

    label = {
        ADD_TO_CART,
        AddToCartSubscriptionMsg
    };
    cartId;
    //cartsummaryadapter
    @wire(CartSummaryAdapter, { 'cartStateOrId': 'current' })
    async wiredCartSummaryData(result) {
        if (result.data && result.data.cartId) {
            this.cartId = result.data.cartId;
        }
    }

    //Get Cart Record
    @wire(getRecord, {
        recordId: "$cartId",
        fields: [B2B_Is_Subscription_FIELD],
    })
    currentCart;

    get isSubscriptionCart() {
        return this.cartId && this?.currentCart?.data && getFieldValue(this.currentCart.data, B2B_Is_Subscription_FIELD);
    }

    loadListDetails() {

        validateDealsForAccount()
        .then(result => {
            // console.log('Result validateDealsForAccount::: ', result);
            this.hasDealsApplied = result;
        });

        // this.showSpinner = true;
        this.isLoading = true;
        let mapParams = { shoppingListId: this.selectedListId };

        getShoppingListById({ mapParams: mapParams })
            .then((listResult) => {
                // console.log('List Result ---> ', listResult);
                if (listResult.isSuccess && listResult?.shoppingLists?.length > 0) {
                    const list = listResult.shoppingLists[0];
                    this.selectedListName = list.B2B_Name__c;
                    this.selectedListDescription = list.B2B_Description__c;
                    this.selectedListIsDefault = list.B2B_Default__c;
                    this.selectedShoppingListId = list.Id;

                    this.getShoppingListItems(mapParams);
                } else {
                    this.listItems = [];
                    this.filteredListItems = [...this.listItems];
                    this.showSpinner = false;
                    this.isLoading = false;
                }
            })
            .catch((error) => {
                console.error(error);
                this.showSpinner = false;
                this.isLoading = false;
            });

    }

    loadPublicListDetails() {

        validateDealsForAccount()
        .then(result => {
            // console.log('Result validateDealsForAccount::: ', result);
            this.hasDealsApplied = result;
        });

        // this.showSpinner = true;
        this.isLoading = true;
        let mapParams = { shoppingListId: this.selectedListId };

        getPublicShoppingListById({ mapParams: mapParams })
            .then((listResult) => {
                // console.log('Public List Result ---> ', listResult);

                if (listResult.isSuccess && listResult?.publicShoppingList?.length > 0) {
                    const list = listResult.publicShoppingList[0];
                    this.selectedListName = list.B2B_Name__c;
                    this.selectedListDescription = list.B2B_Description__c;

                    this.getShoppingListItems(mapParams);
                } else {
                    this.listItems = [];
                    this.filteredListItems = [...this.listItems];
                    this.showSpinner = false;
                    this.isLoading = false;
                }
            })
            .catch((error) => {
                console.error(error);
                this.showSpinner = false;
                this.isLoading = false;
            });
    }

    getShoppingListItems(mapParams) {
        getShoppingListItems({ mapParams: mapParams })
        .then((itemsResult) => {
            // console.log('itemsResult----> ' , itemsResult);

            if (itemsResult.isSuccess) {
                this.listItems = itemsResult.shoppingListItems.map(item => ({
                    ...item,
                    isSelected: false,
                    quantity: item.quantity || 1
                }));

                this.filteredListItems = [...this.listItems];
                const itemCount = this.filteredListItems.length;
                this.itemCountLabel = itemCount === 1 ? `1 ${labels.item}` : `${itemCount} ${labels.items}`;
            } else {
                this.listItems = [];
                this.filteredListItems = [...this.listItems];
                this.itemCountLabel = '0 ' + labels.items;
            }
            this.showSpinner = false;
            this.isLoading = false;
        })
        .catch(err => {
            console.error(err);
            this.showSpinner = false;
            this.isLoading = false;
        });
    }

    get addToCartButtonDisabled () {
        return false;
    }
    get deleteListButtonDisabled () {
        return false;
    }
    get itemCountInfo() {
        const total = this.listItems.length;
        const filtered = this.filteredListItems.length;

        if (this.searchKey) {
            return `${filtered} ${filtered === 1 ? labels.item : labels.items} ${labels.outOf} ${total}`;
        }
        return `${total} ${total === 1 ? labels.item : labels.items}`;
    }
    get isListEmpty() {
        return this.listItems.length === 0 && this.searchKey === '';
    }
    get isSearchListEmpty() {
        return this.listItems.length > 0 && this.filteredListItems.length === 0 && this.searchKey !== '';
    }
    get isListActionDisabled() {
        return this.listItems.length === 0
    }


    handleSearchChange(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.filteredListItems = this.listItems.filter(item => {
            const name = (item.displayName || '').toLowerCase();
            const sku = (item.sku || '').toLowerCase();
            return name.includes(this.searchKey) || sku.includes(this.searchKey);
        });

        const filteredCount = this.filteredListItems.length;
        this.itemCountLabel = filteredCount === 1 ? `1 ${labels.item}` : `${filteredCount} ${labels.items}`;
    }

    handleCheckboxChange(event) {
        const isChecked = event.currentTarget.checked;
        const itemId = event.currentTarget.dataset.itemid;
        this.listItems = this.listItems.map(item => {
            if (item.id === itemId) {
                return { ...item, isSelected: isChecked };
            }
            return item;
        });
        this.handleSearchChange({ target: { value: this.searchKey } });
    }

    handleDeleteList() {
        this.openCommonModal();
    }

    openCommonModal() {
        CommonModal.open({
            label: labels.deleteModalHeading,
            size: 'small',
            message: labels.deleteConfirmationText,
            primaryActionLabel: labels.deleteList,
            secondaryActionLabel: labels.backToList,
            onprimaryactionclick: () => this.deleteList(),
        });
    }

    deleteList() {
        this.isLoading = true;
        deleteShoppingList({ mapParams: { shoppingListId: this.selectedListId } })
            .then((result) => {
                this.showSpinner = false;
                this.isLoading = false;
                if (result.isSuccess) {
                    Toast.show({
                        label: this.labels.deleted,
                        message: labels.shoppingListDeleted,
                        variant: 'success'
                    });

                    this.navigateToMyLists();
                } else {
                    this.showErrorToast(result.message);
                }
            })
            .catch(err => {
                this.showSpinner = false;
                this.isLoading = false;
                console.error(err);
            });
    }

    // Events from child component
    handleAddToCart(event) {
        if (this.isSubscriptionCart) {
            this.showErrorToast(this.label.AddToCartSubscriptionMsg);
            return;
        }
        // this.showSpinner = true;
        const pid = event.detail.productId;
        const quantity = event.detail.quantity;
        const productData = event.detail.productData;
        const calculatedPrice = event.detail.calculatedPrice;
        const unitPrice = event.detail.unitPrice;

        addItemToCart(pid, quantity)
            .then(( result ) => {
                // console.log('result addtocart API--> ', result);
                this.showSpinner = false;

                //Add this event to Google analytics
                let product = {
                    currencyCode: result.currencyIsoCode,
                    quantity: quantity,
                    unitPrice: result.unitAdjustedPriceWithItemAdj === 0 ? unitPrice : result.unitAdjustedPriceWithItemAdj,
                    totalPrice: calculatedPrice,
                    sku: productData.fields.B2B_Part_Number__c,
                    name: productData.fields.B2B_Display_Name__c,
                    category: productData.fields.B2B_Item_Class_Description__c,
                    brand: productData.fields.B2B_Brand_Name__c
                };
                this.trackAddToCart(product);


                this.showSuccessModal();
                this.disabledAddToCarButton = false;
            })
            .catch((error) => {
                console.log('error add to cart-->', error);
                this.showSpinner = false;
                this.showErrorToast(labels.errorAddToCart);
                this.disabledAddToCarButton = false;    
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

        this.filteredListItems = this.listItems.filter(item => {
            const name = (item.productName || '').toLowerCase();
            const sku = (item.sku || '').toLowerCase();
            return name.includes(this.searchKey) || sku.includes(this.searchKey);
        });

        if (!this.isPublicListPage) {
            this.updateShoppingItemQty(itemId, newQuantity);
        }
    }

    updateShoppingItemQty(itemId, newQuantity) {
        const mapParams = {
            shoppingListItemId: itemId,  
            quantity: newQuantity                         
        };

        updateShoppingListItemQty({ mapParams })
            .then(result => {
            })
            .catch(error => {
                console.error('Update qty error:', error);
            });
    }

    handleDeleteItemFromList(event) {
        this.showSpinner = true;
        let itemId = event.detail.itemid;
        let mapParams = {};
        mapParams.shoppingListItemId = itemId;

        deleteShoppingListItem({mapParams})
            .then((result) => {
                this.showSpinner = false;
                if (result.isSuccess) {
                    this.showSuccessToast(labels.productRemoveMessage);
                    let params = {
                        shoppingListId: this.selectedListId
                    };
                    this.getShoppingListItems(params);
                } else {
                    this.showErrorToast(result.message);
                }
            })
            .catch(error => {
                this.showSpinner = false;
                console.log('Error in deleting shopping list item---> ',error);
            });
    }

    async handleCloneList() {
        if (isGuest) {
            const baseURL = window.location.pathname + window.location.search;
            const loginURL = `${labels.loginStartUrl}${encodeURIComponent(baseURL)}`;
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: loginURL
                }
            });
            
        } else {
            await b2bClonePublicListModal.open({
                label: this.labels.toastSuccess,
                size: 'small',
                oncreateclonelist : (event) => {
                    event.stopPropagation();
                    this.createNewCloneList(event);
                }
            });
        }
    }

    showSuccessModal() {
        CommonModal.open({
            label: this.labels.toastSuccess,
            size: 'small',
            secondaryActionLabel: labels.backToList,
            primaryActionLabel: labels.viewCart,
            onprimaryactionclick: () => this.navigateToCart(),
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

    navigateToMyLists() {
        this.navContext &&
            navigate(this.navContext, {
            type: 'comm__namedPage',
            attributes: {
                name: 'Wishlist'
            }
        });
    }

    //custom event from clone modal
    createNewCloneList(event) {
        this.showSpinner = true;

        let mapParams = {
            "publicListId":  this.selectedListId,
            "newName": event.detail.newListName,
            "newDescription": event.detail.newListDescription,
            "makeDefault": event.detail.newListIsDefault
        }

        cloneShoppingList({ mapParams: mapParams})
            .then(result => {
                this.showSpinner = false;
                if (result.isSuccess) {
                    this.showSuccessToast(result.message);
                } else {
                    this.showErrorToast(result.message);
                }
                
            })
            .catch(error => {
                console.log('clone error', error);
                this.showSpinner = false;
            });
    }

    render() {
        if(this.isLoading){
            return stencilTemplate;
        }
        return mainTemplate;
    }

    get hasSelectedItems() {
        return this.listItems.some(item => item.isSelected);
    }

    get addToCartButtonLabel() {
        if (this.hasSelectedItems || this.searchKey) {
            return this.labels.addSelectedToCart;
        }
        return this.labels.addAllToCart;
    }

    handleAddToCartClick() {
        console.log('handle add all items to cart :: ', this.listItems);
        if (this.isSubscriptionCart) {
            this.showErrorToast(this.label.AddToCartSubscriptionMsg);
            return;
        }

        let itemsToAdd = [];

        if (this.hasSelectedItems || this.searchKey) {
            // add selected only
            itemsToAdd = this.listItems
                .filter(item => item.isSelected && !this.failedProductIds.has(item.productId))
                .map(item => ({
                    productId: item.productId,
                    quantity: item.quantity || 1
                }));
                // .filter(item => item.isSelected && !this.failedProductIds.has(item.productId))
        } else {
            // add all
            itemsToAdd = this.listItems
            .filter(item => !this.failedProductIds.has(item.productId))
            .map(item => ({
                productId: item.productId,
                quantity: item.quantity || 1
            }));
            
        }

        if (!itemsToAdd.length) {
            this.showErrorToast(this.labels.noProductSelected);
            return;
        }

        this.showSpinner = true;

        addItemsToCart(itemsToAdd)
            .then((result) => {
                // console.log('result addItemstocart API--> ', result);
                // console.log('itemsToAdd--> ', itemsToAdd);
                this.showSpinner = false;

                this.trackAddAllToCart(result.results, itemsToAdd);

                this.showSuccessModal();
            })
            .catch(err => {
                this.showSpinner = false;
                console.error(err);
                this.showErrorToast(this.labels.errorAddToCart);
            });
    }

    showSuccessToast(message) {
        Toast.show({
            label: this.labels.toastSuccess,
            message: message,
            variant: 'success',
            mode: 'dismissible'
        });
    }

    showErrorToast(message) {
        Toast.show({
            label: this.labels.toastError,
            message: message,
            variant: 'error',
            mode: 'dismissible'
        });
    }

    trackAddToCart(product) {
        window.dataLayer = window.dataLayer || [];
        
        window.dataLayer.push({ ecommerce: null });
        window.dataLayer.push({
            event: 'add_to_cart',
            ecommerce: {
                currency: product.currencyCode,
                value: product.totalPrice,
                items: [{
                    item_id: product.sku,
                    item_name: product.name,
                    item_brand: product.brand,
                    item_category: this.getProductCategory(product.category),
                    quantity: product.quantity,
                    price: product.unitPrice
                }]
            }
        });
        // console.log('GA - Add To Cart Event Shopping list: ', window.dataLayer);
    }

    getProductCategory(itemClassDescription) {
        switch (itemClassDescription) {
            case "Consumable":
            case "Minor Accessory":
            case "Reagent":
                return "Consumables & Accessories";

            case "Instrument":
            case "Major Accessory":
                return "Instruments";

            case "Software":
                return "PCs & Software";

            case "Support, Consulting & Training":
                return "Training";

            case "Service Installation":
                return "Instrument Service";

            default:
                return "empty";
        }
    }

    trackAddAllToCart(apiResults, itemsToAdd) {
        if (!Array.isArray(itemsToAdd) || itemsToAdd.length === 0 || !Array.isArray(apiResults)) {
            return;
        }

        const trackedItems = itemsToAdd.map(itemToAdd => {
            // find the enriched product in listItems
            const enriched = this.listItems.find(li => li.productId === itemToAdd.productId) || {};
            // find the matching API result
            const apiItem = apiResults.find(r => r.result?.productId === itemToAdd.productId);
            const unitPrice = apiItem?.result?.unitAdjustedPriceWithItemAdj || 0;

            return {
                item_id: enriched.sku || '',
                item_name: enriched.displayName || '',
                item_brand: enriched.brandName || '',
                item_category: this.getProductCategory(enriched.itemClass) || '',
                quantity: itemToAdd.quantity,
                price: unitPrice
            };
        });

        const totalValue =  Number(trackedItems.reduce(
                                (sum, item) => sum + (item.price * item.quantity), 0
                            ).toFixed(2));

        window.dataLayer = window.dataLayer || [];

        window.dataLayer.push({ ecommerce: null });
        window.dataLayer.push({
            event: 'add_to_cart',
            ecommerce: {
                currency: apiResults[0]?.result?.currencyIsoCode || 'USD',
                value: totalValue,
                items: trackedItems
            }
        });

        // console.log('GA - Add All To Cart Event:', window.dataLayer);
    }


    async openEditModal() {
        await b2bClonePublicListModal.open({
            label: this.labels.editList,
            size: 'small',
            isEdit: true,
            name: this.selectedListName,
            description: this.selectedListDescription,
            isDefault: this.selectedListIsDefault,
            oneditlist: (event) => {
                event.stopPropagation();
                this.saveEditedList(event);
            }
        });

    }

    saveEditedList(event) {
        const newName = event.detail.newListName;
        const newDescription = event.detail.newListDescription;
        const newIsDefault = event.detail.newListIsDefault;

        const nameChanged = newName !== this.selectedListName;
        const descChanged = newDescription !== this.selectedListDescription;
        const defaultChanged = newIsDefault !== this.selectedListIsDefault;

        if (!nameChanged && !descChanged && !defaultChanged) {
            Toast.show({
                label: this.labels.toastInfo,
                message: this.labels.noChanges,
                variant: 'info',
                mode: 'dismissible'
            });
            return;
        }

        let mapParams = {
            shoppingListId: this.selectedShoppingListId,
            newName: newName,
            newDescription: newDescription,
            makeDefault: newIsDefault
        };
        
        updateShoppingListDetails({ mapParams })
            .then((result) => {
                // console.log('result of update list', result);
                if (result.isSuccess) {
                    this.selectedListName = event.detail.newListName;
                    this.selectedListDescription = event.detail.newListDescription;
                    this.selectedListIsDefault = event.detail.newListIsDefault;
                    publish(this.messageContext, SHOPPING_LIST_UPDATE, {
                        updated: true
                    });
                    this.showSuccessToast( result.message);
                    this.loadListDetails();
                } else {
                    this.showErrorToast(result.message);
                }
            })
            .catch(error => {
                console.error(error);
                this.showErrorToast(error.message);
            });
    }


    //show more fucntionality 

    get isShowMoreVisible() {
        return this.pageSize > 0 && this.initialVisibleCount > 0 && this.filteredListItems.length > this.initialVisibleCount;
    }
    get showMoreLabel() {
        return this.visibleItemCount >= this.filteredListItems.length
            ? this.labels.showLess
            : this.labels.showMore;
    }

    get visibleItems() {
        if (!this.visibleItemCount || this.visibleItemCount <= 0) {
            return this.filteredListItems;
        }
        return this.filteredListItems.slice(0, this.visibleItemCount);
    }

    handleToggleShowMore() {
        if (this.visibleItemCount >= this.filteredListItems.length) {
            this.visibleItemCount = this.pageSize;
        } else {
            this.visibleItemCount = Math.min(
                this.visibleItemCount + this.pageSize,
                this.filteredListItems.length
            );
        }
    }

    // prices not available then exclude products from adding to cart 
    failedProductIds = new Set();
    handlePricingStatus(event) {
        const { productId, failed } = event.detail;
        if (failed) {
            console.log('failed :: ', failed);
            this.failedProductIds.add(productId);
            this.listItems = this.listItems.map(item => {
                if (item.productId === productId) {
                    return { ...item, isPricingFailed: true }; // add new property
                }
                return item;
            });
        } else {
            this.failedProductIds.delete(productId);
            this.listItems = this.listItems.map(item => {
                if (item.productId === productId) {
                    return { ...item, isPricingFailed: false }; // add new property
                }
                return item;
            });
        }

        this.filteredListItems= [...this.listItems];
    }

}