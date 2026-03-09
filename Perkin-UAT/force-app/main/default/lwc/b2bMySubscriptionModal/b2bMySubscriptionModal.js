import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import { refreshCartSummary, deleteCurrentCart } from 'commerce/cartApi';
import labels from './labels';

export default class B2bMySubscriptionModal extends LightningModal {
    @api isCartExist = false;
    @api isActivated = false;
    @api label;
    @track cartDeleted = false;

    @api showConfirmation = false;
    @api confirmAction = '';
    @api confirmMessage = '';
    @track labels = labels

    get isSubscriptionActivated() {
        return this.isCartExist || this.cartDeleted ? false : this.isActivated;
    }

    handleClearCart() {
        // const evt = new CustomEvent('deletecurrentcart', { });
        // this.dispatchEvent(evt);
        // this.close('closed');
        this.deleteCurrentCartBeforeActivate();
        
    }
    deleteCurrentCartBeforeActivate() {
        this.isLoading = true;
        deleteCurrentCart()
            .then((data) => {
                console.log('Delete current cart::: ', data);
                refreshCartSummary();
                this.cartDeleted = true;
                this.isCartExist = false;
            })
            .catch((error) => {
                console.error('Error deleting cart:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    handleActivate() {
        this.dispatchEvent(new CustomEvent('activatesubscription'));
        this.close('closed');
    }

    handleViewCart() {
        const evt = new CustomEvent('navigatetocart', { });
        this.dispatchEvent(evt);
        this.close('closed');
    }

    handleConfirmAction() {
        this.dispatchEvent(
            new CustomEvent('confirmsubscriptionaction', { detail: { action: this.confirmAction } })
        );
        this.close('closed');
    }
    get subscriptionLabel() {
        // return `${this.confirmAction} subscription`;
        return (this.labels.pauseSubscription).replace('{0}', this.confirmAction);
    }

    
}