import { LightningElement, api } from 'lwc';
import basePath from "@salesforce/community/basePath";
import { updateItemInCart, deleteItemFromCart } from 'commerce/cartApi';

const DELETE_ITEM_EVENT = 'deletecartitem';
const NAVIGATE_PRODUCT_EVENT = 'navigatetoproduct';
const LOADING_STENCIL = 'loadingstencil';

/**
 * UI component for an individual cart item. Handles deletion,
 * quantity update, product navigation and fields to display per item.
 */
export default class B2bCartItem extends LightningElement {/**
     * @description UI labels, to be replaced by Custom Labels and their translations
     */
    @api labels;

    /**
     * @description Current Cart Item
     */
    @api item;

    /**
     * @description Show the "Delete" button
     */
    @api showRemoveItemOption;
    
    /**
     * @description Show Line Item Total
     */
    @api showLineItemTotal;

    /**
     * @description Show Original Price
     */
    @api showOriginalPrice;

    /**
     * @description Show Product SKU
     */
    @api showSku;

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
     * @description Preview mode if component is rendered in the Builder
     */
    @api isPreview;

    /**
     * @description Tells if the cart is a subscription cart
     */
    @api isSubscriptionCart;

    /**
     * @description Minimum quantity from purchaseQuantityRule if provided
     */
    minQuantity;

    /**
     * @description Maximum quantity from purchaseQuantityRule if provided
     */
    maxQuantity;

    /**
     * @description Increment step from purchaseQuantityRule if provided
     */
    incrementStep;

    connectedCallback() {
        // minQuantity falls back to 1 if purchaseQuantityRule is not provided
        this.minQuantity = Number(this.item?.productDetails?.purchaseQuantityRule?.minimum || 1);
        // ommit maxQuantity if purchaseQuantityRule is not provided
        this.maxQuantity = Number(this.item?.productDetails?.purchaseQuantityRule?.maximum) || undefined;
        // incrementStep falls back to 1 if purchaseQuantityRule is not provided
        this.incrementStep = Number(this.item?.productDetails?.purchaseQuantityRule?.increment || 1);
    }

    // renderedCallback() {
    //     // report invalid quantities after rendering the item
    //     this.refs.quantitySelector?.reportValidity();
    // }

    /**
     * @description Returns current cart item currency code
     * @returns {String}
     */
    get currencyCode() {
        return this.item?.currencyIsoCode;
    }

    /**
     * @description Fixes the promotion badge under the quantity selector
     * @returns {String}
     */
    get additionalBadgeStyle() {
        return !this.hideQuantitySelector ? 'margin-top: 15px; margin-bottom: 15px;' : 'top: 10px';
    }

    /**
     * @description Returns current item quantity
     * @returns {Number}
     */
    get quantity() {
        return Number(this.item?.quantity);
    }
    
    /**
     * @description Returns if a quantity rule exists for the current item,
     * an existent one should have the required field maxQuantity
     * @returns {Boolean}
     */
    get hasQuantityRule() {
        return this.maxQuantity;
    }

    /**
     * @description Returns help text which describes the quantity rule
     * @returns {String}
     */
    get quantityRuleHelpText() {
        return `${this.labels.minQty}: ${this.minQuantity}, ${this.labels.maxQty}: ${this.maxQuantity}, ${this.labels.incrementStep}: ${this.incrementStep}`;
    }

    /**
     * @description Returns true if minQuantity is reached or the closest possible value to it
     * @returns {Boolean}
     */
    get stopDecreaseQuantity() {
        return this.item?.quantity === this.minQuantity || this.item.quantity-this.incrementStep<this.minQuantity;
    }

    /**
     * @description Returns true if maxQuantity is reached or the closest possible value to it
     * @returns {Boolean}
     */
    get stopIncreaseQuantity() {
        return this.item?.quantity === this.maxQuantity || this.item.quantity+this.incrementStep>this.maxQuantity;
    }

    /**
     * @description Returns saved amount (adjustment amount)
     * @returns {Number | undefined}
     */
    get savedAmount() {
        if (this.showPromotions && this.item?.totalAdjustmentAmount !== 0) {
            return this.item?.totalAdjustmentAmount * -1;
        }
        return undefined;
    }

    /**
     * @description Returns whether or not to display original item price
     * @returns {Boolean}
     */
    get needsOriginalPrice() {
        return this.showOriginalPrice &&  Number(this.item?.listPrice) !== 0;
    }

    get imageUrl() {
        let imgUrl = this.item?.productDetails?.thumbnailImage?.url;
        return imgUrl.includes("cms") ? basePath + "/sfsites/c" + imgUrl : imgUrl;
    }

    get totalPrice() {
        // return (this.item?.unitAdjustedPrice * this.quantity) + this.item?.totalAdjustmentAmount;
        return this.item?.totalPrice;
    }

    get totalListPrice() {
        return Number(this.item?.listPrice) * Number(this.item?.quantity);
    }

    /**
     * @description Shows current items based on configuration:
     * 1 - Extract fields from productFields property
     * 2 - Set label + value (switch from camelCase to sentence case)
     * 3 - Sort items by the order in productFields property
     * 
     * @returns {List}
     */
    get fieldsWithLabels() {
        let productFieldsNames = this.productFields.split(';');
        return Object.entries(this.item?.productDetails?.fields)
            // include only fields marked in parameter productFields
            .filter(([label]) => productFieldsNames.includes(label))
            .map(([lbl, value]) => ({
                // Add space before capital letters
                label: lbl.replace(/([A-Z])/g, ' $1').replace(/^./, (str) => str.toUpperCase()).trim(),
                key: lbl,
                value
            })).sort((a, b) => {
                const indexA = productFieldsNames.indexOf(a.key);
                const indexB = productFieldsNames.indexOf(b.key);
                return indexA - indexB;
            });
    }  

    /**
     * @description Sends an event to the parent component to delete the current item
     * @param {CustomEvent} e
     */
    handleDelete(e) {
        this.notifyStencilLoading(true);
        e.stopPropagation();
        if (!this.isPreview) {
            deleteItemFromCart(this.item?.cartItemId).then(() => {
                this.dispatchEvent(
                    new CustomEvent(DELETE_ITEM_EVENT, {
                        detail: this.item?.cartItemId,
                        composed: true,
                        bubbles: true,
                    })
                );
            }).catch((e) => {
                console.error(e);
                this.notifyStencilLoading(false);
            });
        }
    }

    /**
     * @description Sends an event to the parent component to navigate to the current item
     * @param {CustomEvent} e
     */
    handleProductRedirection(e){
        e.stopPropagation();
        let urlName = this.item?.productDetails?.productUrlName !== null ? this.item?.productDetails?.productUrlName : this.item?.productDetails?.fields?.B2B_Part_Number__c;
        this.dispatchEvent(
            new CustomEvent(NAVIGATE_PRODUCT_EVENT, {
                detail: {
                    id: this.item?.productDetails?.productId,
                    name: this.item?.productDetails?.name,
                    urlName: urlName
                },
                composed: true,
                bubbles: true,
            })
        );
    }

    handleProductQuantity(event) {
        this.notifyStencilLoading(true);
        updateItemInCart(this.item?.cartItemId, event.detail.message).then((result) => {
            let updatedCartItem = {
                cartItem: {
                    ...result,
                    productDetails: {
                        ...result.productDetails,
                        fields: this.item?.productDetails?.fields
                    }
                }
            };
            this.item = [updatedCartItem].map(this.mapCartItem)[0];
        }).catch((e) => {
            console.error(e);
            this.notifyStencilLoading(false);
        });
    }

    notifyStencilLoading(val) {
        this.dispatchEvent(
            new CustomEvent(LOADING_STENCIL, {
                detail: {
                    value: val
                },
                composed: true,
                bubbles: true,
            })
        );
    }

    // Cart item mapping function
    mapCartItem = (sourceCartItem) => {
        const {
            cartItem: {
                cartItemId: id,
                name,
                quantity,
                type,
                totalAdjustmentAmount,
                salesPrice,
                totalAdjustmentAmount: adjustmentAmount,
                totalAmount: totalAmount,
                totalListPrice: listPrice,
                totalPrice: totalPrice,
                totalTax: tax,
                unitAdjustedPrice,
                unitAdjustmentAmount,
                productDetails,
            },
            messages,
            subscriptionId,
            subscriptionTermUnit,
            subscriptionTerm,
            subscriptionType,
        } = sourceCartItem;

        return {
            id,
            name,
            quantity,
            type,
            totalAdjustmentAmount,
            salesPrice,
            adjustmentAmount,
            totalAmount,
            listPrice,
            totalPrice,
            tax,
            unitAdjustedPrice,
            unitAdjustmentAmount,
            ProductDetails: {
                name: productDetails.fields.Name,
                productId: productDetails.productId,
                purchaseQuantityRule: productDetails.purchaseQuantityRule,
                sku: productDetails.sku,
                fields: productDetails.fields,
                thumbnailImage: productDetails.thumbnailImage,
                variationAttributes: productDetails.variationAttributes,
                productSubscriptionInformation: productDetails.productSubscriptionInformation,
            },
            Messages: messages,
            subscriptionId,
            subscriptionTermUnit,
            subscriptionTerm,
            subscriptionType,
        };
    };
}