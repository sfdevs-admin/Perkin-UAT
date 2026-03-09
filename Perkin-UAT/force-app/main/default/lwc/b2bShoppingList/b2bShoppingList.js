import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getShoppingList from '@salesforce/apex/B2B_ShoppingListController.getShoppingLists';
import B2B_PKI_RESOURCES from '@salesforce/resourceUrl/B2B_PKI_Resources';
import labels from './labels';
import SHOPPING_LIST_UPDATE from '@salesforce/messageChannel/b2b_ShoppingListUpdate__c';
import { subscribe, MessageContext } from 'lightning/messageService';

export default class MyList extends NavigationMixin(LightningElement) {
    
    @wire(MessageContext) messageContext;
    @api isMyListDetailPage ;
    @track shoppingLists = [];
    @track isLoading = true;
    @track selectedListId;
    @track labels = labels;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('page ref shopping list');
        if (currentPageReference) {
            const isMyListDetailPage = currentPageReference?.attributes?.name || '';
            if ((isMyListDetailPage !== undefined &&  isMyListDetailPage === 'My_List_Details__c')) {
                this.selectedListId = currentPageReference?.state?.shoppingListId || null;
                // Update class on each item
                this.shoppingLists = this.shoppingLists.map(item => ({
                    ...item,
                    cardClass: item.Id === this.selectedListId ? 'summary-card selected-card summary-card-hover' : 'summary-card summary-card-hover'
                }));
            }
        }
    }

    async connectedCallback() {
        this.fetchShoppingLists();
        this.subscription = subscribe(this.messageContext, SHOPPING_LIST_UPDATE, (message) => {
            this.handleMessage(message);
        });
    }

    fetchShoppingLists() {
        this.isLoading = true;
        getShoppingList({ mapParams: {} })
            .then(result => {
                this.isLoading = false;
                if (result.isSuccess) {
                    if (this.isMyListDetailPage) {
                        this.shoppingLists = result.shoppingLists.map(item => ({
                            ...item,
                            cardClass: item.Id === this.selectedListId ? 'summary-card selected-card summary-card-hover' : 'summary-card summary-card-hover'
                        }));
                    } else {
                        this.shoppingLists = result.shoppingLists.map(item => ({
                            ...item,
                            cardClass: item.Id === this.selectedListId ? 'summary-card selected-card' : 'summary-card'
                        }));
                    }
                }
            })
            .catch(error => {
                this.isLoading = false;
            });
    }

    get mainListContainer() {
        return this.isMyListDetailPage ? 'my-list-page-details':'my-list-page';
    }
    get containerClass() {
        return this.shoppingLists.length > 5 ? 'card-container' : '';
    }
    get hasShoppingLists() {
        return this.shoppingLists && this.shoppingLists.length > 0;
    }
    get emptyWishlistImage() {
        return `${B2B_PKI_RESOURCES}/Images/EmptyWishlist.png`;
    }

    handleViewDetails(event) {
        const listId = event.currentTarget.dataset.id;
        this.selectedListId = listId;
        // Update class on each item
        this.shoppingLists = this.shoppingLists.map(item => ({
            ...item,
            cardClass: item.Id === listId ? 'summary-card selected-card summary-card-hover' : 'summary-card summary-card-hover'
        }));

        this.navigateToDetails(listId);
    }

    handleCardClick(event) {
        const listId = event.currentTarget.dataset.id;

        this.shoppingLists = this.shoppingLists.map(item => ({
            ...item,
            cardClass: item.Id === listId ? 'summary-card selected-card' : 'summary-card'
        }));

        this.navigateToDetails(listId);
    }

    navigateToDetails(listId) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_List_Details__c'
            },
            state: {
                shoppingListId: listId
            }
        });
    }

    handleMessage(message) {
        if (message.updated) {
            this.fetchShoppingLists();
        }
    }

}