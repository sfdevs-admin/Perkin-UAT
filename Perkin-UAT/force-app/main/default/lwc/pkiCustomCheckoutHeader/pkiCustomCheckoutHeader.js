import { LightningElement, wire, track, api } from 'lwc';
import { navigate, NavigationContext, NavigationMixin } from 'lightning/navigation';
import labels from './labels';

/**
 * @slot checkoutHeaderLogo ({ locked: false})
 * @slot checkout-site-banner ({ locked: false}) - Slot for Site banner
 */
export default class PkiCustomCheckoutHeader extends NavigationMixin(LightningElement) {
    // static renderMode = 'light';

    @api externalUrl;
    @api urlTarget;

    @wire(NavigationContext)
    navContext;

    // Expose the labels to use in the template.
    @track labels = labels;

    handleBackToCart(){
        this.navigateToCart();
    }

    /**
     * Navigates to the cart page when the primary button is clicked
     * from the modal after adding an item to the cart
     * @private
     */
    navigateToCart() {
        var cartUrl = labels.cartUrlLabel;
        window.open(cartUrl, '_self');
    }
}