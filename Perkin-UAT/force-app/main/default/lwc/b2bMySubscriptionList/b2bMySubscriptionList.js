import { LightningElement, api, track, wire  } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getSubscriptionLists from '@salesforce/apex/B2B_MySubscriptionController.getSubscriptionLists';
import labels from './labels';
import B2B_PKI_RESOURCES from '@salesforce/resourceUrl/B2B_PKI_Resources';


export default class B2bMySubscriptionList extends NavigationMixin(LightningElement) {
    @api isMySubscriptionDetailPage;
    @track subscriptionLists = [];
    @track selectedListId;
    @track labels = labels;
    @track isLoading = true;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('page ref subsription list');
        if (currentPageReference) {
            const isSubscriptionDetailPage = currentPageReference?.attributes?.name || '';
            if ((isSubscriptionDetailPage !== undefined &&  isSubscriptionDetailPage === 'My_Subscription_Details__c')) {
                this.selectedListId = currentPageReference?.state?.subscriptionListId || null;
                // Update class on each item
                this.subscriptionLists = this.subscriptionLists.map(item => ({
                    ...item,
                    cardClass: item.Id === this.selectedListId ? 'summary-card selected-card summary-card-hover' : 'summary-card summary-card-hover'
                }));
            }
        }
    }

    async connectedCallback() {
        this.fetchSubscriptionLists();
    }

    fetchSubscriptionLists() {
        this.isLoading = true;
        getSubscriptionLists({ mapParams: {} })
            .then(result => {
                console.log('Result subscriptions :::', result);
                this.isLoading = false;
                if (result.isSuccess) {
                    if (this.isMySubscriptionDetailPage) {
                        this.subscriptionLists = result.subscriptionLists.map(item => ({
                            ...item,
                            cardClass: item.Id === this.selectedListId ? 'summary-card selected-card summary-card-hover' : 'summary-card summary-card-hover'
                        }));
                    } else {
                        this.subscriptionLists = result.subscriptionLists.map(item => ({
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

    get haSubscription() {
        return this.subscriptionLists && this.subscriptionLists.length > 0;
    }
    get containerClass() {
        return this.subscriptionLists.length > 5 ? 'card-container' : '';
    }
    get mainListContainer() {
        return this.isMySubscriptionDetailPage ? 'my-list-page-details':'my-list-page';
    }
    get emptySubscriptionImage() {
        return `${B2B_PKI_RESOURCES}/Images/subscription.png`;
    }

    handleViewDetails(event) {
        const listId = event.currentTarget.dataset.id;
        this.selectedListId = listId;
        // Update class on each item
        this.subscriptionLists = this.subscriptionLists.map(item => ({
            ...item,
            cardClass: item.Id === listId ? 'summary-card selected-card summary-card-hover' : 'summary-card summary-card-hover'
        }));

        this.navigateToDetails(listId);
    }
    handleCardClick(event) {
        const listId = event.currentTarget.dataset.id;

        this.subscriptionLists = this.subscriptionLists.map(item => ({
            ...item,
            cardClass: item.Id === listId ? 'summary-card selected-card' : 'summary-card'
        }));

        this.navigateToDetails(listId);
    }

    navigateToDetails(listId) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Subscription_Details__c'
            },
            state: {
                subscriptionListId: listId
            }
        });
    }
}