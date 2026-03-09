import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin, NavigationContext, navigate } from 'lightning/navigation';
import { CartItemsAdapter } from 'commerce/cartApi';
import { createCartClearAction, dispatchAction } from 'commerce/actionApi';
import checkForSubscriptionCart from '@salesforce/apex/B2B_SubscriptionController.checkForSubscriptionCart';
import { previewData } from './mockData';
import { Labels } from './labels';

const SHOW_STENCIL_LOADING = 'showStencilLoading';

/**
 * @slot cartItemsTitle ({ locked: false, defaultContent: [{ descriptor: "dxp_base/textBlock", attributes: {text: "Cart", textDisplayInfo: "{\"headingTag\": \"h3\", \"textStyle\": \"heading-medium\"}", "textDecoration": "{\"bold\": true}" }}] })
 * @slot clearCartMsg ({ locked: false, defaultContent: [{ descriptor: "dxp_base/textBlock", attributes: {text: "Cart", textDisplayInfo: "{\"headingTag\": \"h3\", \"textStyle\": \"heading-medium\"}", "textDecoration": "{\"bold\": true}" }}] })
 */
export default class B2bCartContents extends NavigationMixin(LightningElement) {
     /**
     * @description Enable the component to render as light DOM
     */
    static renderMode = 'light';

    /**
     * @description UI labels, to be replaced by Custom Labels and their translations
     */
    labels = Labels;

    /**
     * @description Custom page size for items to display
     */
    @api pageSize;

    /**
     * @description Show the "Delete" button
     */
    @api showRemoveItemOption;

    /**
     * @description Show Line Item Total
     */
    @api showLineItemTotal;

    /**
     * @description Show the "Show More" button
     */
    @api showMoreItemsOption;

    /**
     * @description Show Original Price
     */
    @api showOriginalPrice;

    /**
     * @description Show Product SKU
     */
    @api showSKU;

    /**
     * @description Show Product Thumbnail Image
     */
    @api showProductImage;

    /**
     * @description List of fields (Api Names) to display for each Item
     */
    @api productFields;

    /**
     * @description Show Price per Unit
     */
    @api showPricePerUnit;

    /**
     * @description Show Actual Price
     */
    @api showActualPrice;

    /**
     * @description Hide/Show the Quantity Selector
     */
    @api hideQuantitySelector;

    /**
     * @description Show Promotions per Item
     */
    @api showPromotions;

    /**
     * @description Cart Items data to show in UI, handles pagination against pageSize property
     */
    @track cartItemsToShow = [];

    isLoading = this.isInSitePreview() ? false : true;
    isSubscriptionCart = false;
    billingFrequency;

    /**
     * @description Number of current pages displayed (custom pagination)
     */
    pages = 1;

    /**
     * @description Cart Items provided by the Cart Data Expression
     */
    cartItems;
    
    /**
     * @description Total Count of Items in the cart (provided by the Cart Data Expression)
     */
    uniqueProductCount;

    @wire(CartItemsAdapter)
    setCartItems({ data, error }) {
        if (data) {
            // console.log('cart Items::: ', data);
            this.cartItems = data?.cartItems;
            this.uniqueProductCount = data?.cartSummary?.uniqueProductCount;
            this.handleCheckForSubscriptionCart(data?.cartSummary?.cartId);
            const itemCount = this.cartItemsToShow.length > 0 ? this.cartItemsToShow.length : this.pageSize;
            this.cartItemsToShow = this.cartItems.slice(0, itemCount);

            this.isLoading = false;
            this.notifyCartSumStencil(false);
        } else if (error) {
            if (error.name == "NonError") {
                this.cartItems = [];
                this.cartItemsToShow = [];
            }
            this.isLoading = false;
            this.notifyCartSumStencil(false);
            console.error("Error fetching cart items:", error);
        }
    }

    get showRemoveOption() {
        return this.showRemoveItemOption && !this.isSubscriptionCart;
    }

    get showCount() {
        if(this.uniqueProductCount != null && !this.showCartEmpty) {
            return this.uniqueProductCount > 1 ? this.uniqueProductCount + ' Items' : this.uniqueProductCount + ' Item';
        }
        return undefined;
    }

    get sortingOptions() {
        return [
            { label: this.labels.SortByNewest, value: 'CreatedDateDesc', selected: true },
            { label: this.labels.SortByOldest, value: 'CreatedDateAsc', selected: false },
            { label: this.labels.SortByAZ, value: 'NameAsc', selected: false },
            { label: this.labels.SortByZA, value: 'NameDesc', selected: false }
        ];
    }

    get isCartItemsAvailable() {
        if(this.isInSitePreview()) {
            this.cartItemsToShow = previewData;
            return true;
        }
        return this.cartItemsToShow != null && this.cartItemsToShow?.length >= 1 && !this.isLoading;
    }

    get showCartEmpty() {
        if((this.cartItems == null || this.cartItems?.length === 0) && !this.isLoading) {
            return true;
        }
    }

    get clearCartAndSortOptions() {
        return ((this.cartItems != null && this.cartItems?.length >= 1) && !this.isLoading)
    }

    /**
     * @description Show or hide "Show More" button, based on configuration or pagination state
     * @returns {boolean}
     */
    get needsToShowMore() {
        
        return this.showMoreItemsOption 
            && (this.isInSitePreview() || this.cartItemsToShow?.length < this.cartItems?.length);
    }

    handleSortChange(event) {
        this.isLoading = true;
        event.preventDefault();
        
        let cartItems = [...this.cartItemsToShow];
        let sortValue = event.target.value;
        if(sortValue === 'CreatedDateAsc') {
            this.cartItemsToShow = this.cartItems.slice(0, this.cartItemsToShow.length).reverse();
        } 
        else if(sortValue === 'CreatedDateDesc') {
            this.cartItemsToShow = this.cartItems.slice(0, this.cartItemsToShow.length);
        }
        else if(sortValue === 'NameDesc'){
            this.cartItemsToShow = this.sortByName(cartItems).reverse();
        }
        else if(sortValue === 'NameAsc'){
            this.cartItemsToShow = this.sortByName(cartItems)
        }
        this.isLoading = false;
    }

    sortByName(cartItems) {
        cartItems.sort(function (a, b) {
            if (a.cartItem.name < b.cartItem.name) {
                return -1;
            }
            if (a.cartItem.name > b.cartItem.name) {
                return 1;
            }
            return 0;
        });
        return cartItems;
    }

    /**
     * @description Requests more cart items either from the cache or CartItemsAdapter
     */
    handleShowMoreButton() {
        if (!this.isInSitePreview()) {
            this.cartItemsToShow = this.cartItems.slice(0, this.cartItemsToShow.length + this.pageSize);
        }
    }

    /**
     * @description Removes the deleted item from the current list
     * @param {CustomEvent} e
     */
    handleDeleteCartItem(e) {
        e.stopPropagation();
        const cartItemId = e.detail;
        this.cartItemsToShow = this.cartItemsToShow.filter(item => item.id !== cartItemId);
    }

    /**
     * @description Handles navigation to selected cart item's product
     * @param {CustomEvent} e
     */
    handleProductNavigation(e) {
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__webPage',
        //     attributes: {
        //         url: '/product/' + e.detail.urlName ?? undefined
        //     }
        // });

        this.navContext &&
            navigate(this.navContext, {
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: 'Product2',
                    recordId: e.detail.id,
                    actionName: 'view',
                    urlName: e.detail.urlName ?? undefined,
                },
                state: {
                    recordName: e.detail.name,
                },
            });
    }

    /**
     * @description Deletes the current cart
     * @param {CustomEvent} e
     */
    handleClearCart(e) {
        this.isLoading = true;
        this.isSubscriptionCart = false;
        this.notifyCartSumStencil(true);
        e.preventDefault();
        dispatchAction(this, createCartClearAction(), {
            onSuccess: (result) => {
                this.cartItems = [];
                this.cartItemsToShow = [];
                this.uniqueProductCount = 0;
                this.isLoading = false;
            },
            onError: (error) => {
                this.isLoading = false;
            },
        });
    }

    handleLoadingStencil(e) {
        e.preventDefault();
        this.isLoading = e.detail.value;
        if(e.detail.value) {
            this.notifyCartSumStencil(true);
        }
    }

    notifyCartSumStencil(val) {
        this.dispatchEvent(new CustomEvent(SHOW_STENCIL_LOADING, {
                detail: {
                    'value': val
                },
                bubbles: true,
                composed: true
            })
        );
    }

    handleCheckForSubscriptionCart(cartId) {

        let mapParams = {
            'cartId': cartId
        };

        checkForSubscriptionCart({ 'mapParams': mapParams})
        .then((result) => {
            if(result.isSuccess) {
                this.isSubscriptionCart = result.hasSubscription;
                this.billingFrequency = this.labels.SubcriptionMsg + ' ' + result.subscriptionName +' ('+ result.billingFrequency+')';
            }
        }).catch((err) => {
            console.error("Error is checking subscription cart", err);
        });
    }

    isInSitePreview() {
        let url = document.URL;
        
        return (url.indexOf('sitepreview') > 0 
            || url.indexOf('livepreview') > 0
            || url.indexOf('live-preview') > 0 
            || url.indexOf('live.') > 0
            || url.indexOf('.builder.') > 0);
    }

    @wire(NavigationContext)
    navContext;
}