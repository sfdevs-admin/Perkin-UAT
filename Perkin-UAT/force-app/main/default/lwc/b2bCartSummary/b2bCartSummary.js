import { LightningElement, api } from 'lwc';
/**
 * @slot headerText ({ locked: false, defaultContent: [{ descriptor: "dxp_base/textBlock", attributes: {text: "Summary", textDisplayInfo: "{\"headingTag\": \"h2\", \"textStyle\": \"heading-medium\"}", "textDecoration": "{\"bold\": true}" }}] })
 * @slot promotionsLabel ({ locked: false, defaultContent: [{ descriptor: "dxp_base/textBlock", attributes: {text: "Promotions", textDisplayInfo: "{\"headingTag\": \"p\", \"textStyle\": \"body-regular\"}" }}] })
 * @slot shippingLabel ({ locked: false, defaultContent: [{ descriptor: "dxp_base/textBlock", attributes: {text: "Shipping", textDisplayInfo: "{\"headingTag\": \"p\", \"textStyle\": \"body-regular\"}" }}] })
 * @slot subtotalLabel ({ locked: false, defaultContent: [{ descriptor: "dxp_base/textBlock", attributes: {text: "Subtotal", textDisplayInfo: "{\"headingTag\": \"p\", \"textStyle\": \"body-regular\"}" }}] })
 * @slot taxIncludedLabel ({ locked: false, defaultContent: [{ descriptor: "dxp_base/textBlock", attributes: {text: "Tax included", textDisplayInfo: "{\"headingTag\": \"p\", \"textStyle\": \"body-regular\"}", textAlign: "right" }}] })
 * @slot taxLabel ({ locked: false, defaultContent: [{ descriptor: "dxp_base/textBlock", attributes: {text: "Tax", textDisplayInfo: "{\"headingTag\": \"p\", \"textStyle\": \"body-regular\"}" }}] })
 * @slot totalLabel ({ locked: true, defaultContent: [{ descriptor: "dxp_base/textBlock", attributes: {text: "Total", textDisplayInfo: "{\"headingTag\": \"p\", \"textStyle\": \"heading-small\"}", "textDecoration": "{\"bold\": true}" }}] })
 */

export default class B2bCartSummary extends LightningElement {

    /**
     * Enable the component to render as light DOM
     *
     * @static
     */
    static renderMode = 'light';

    isLoading = false;

    @api
    get cartTotals() {
        return this._cartTotals;
    }
    set cartTotals(value) {
        if(value){
            this._cartTotals = value;
        }
        if(this.isInSitePreview()) {
            this._cartTotals = {
                grandTotal: 100,
                taxAmount: 100,
                chargeAmount: 100,
                productAmount: 100,
                promotionalAdjustmentAmount: 100,
            }
        }
    }

    get showCartSummary() {
        if(this.isInSitePreview()) {
            return true;
        }
        return this._cartTotals != null && !this.isLoading;
    }

    get cartSubTotal() {
        return this.cartTotals?.productAmount ? this.cartTotals?.productAmount : 0;
    }

    get shippingAmt() {
        if(this.cartTotals?.chargeAmount !== 0) {
            return this.cartTotals?.chargeAmount;
        }
        return undefined;
    }

    get cartPromotion() {
        if(this.cartTotals?.promotionalAdjustmentAmount !== 0) {
            return this.cartTotals?.promotionalAdjustmentAmount;
        }
        return undefined;
    }

    get taxAmt() {
        if(this.cartTotals?.taxAmount !== 0) {
            return this.cartTotals?.taxAmount;
        }
        return undefined;
    }

    get grandTotal() {
        return this.cartTotals?.grandTotal ? this.cartTotals?.grandTotal : 0;
    }

    connectedCallback() {
        window.addEventListener('showStencilLoading', this.showStencilLoading.bind(this));
    }

    disconnectedCallback(){
        window.removeEventListener('showStencilLoading', this.showStencilLoading.bind(this));
    }

    showStencilLoading(event) {
        if(event && event.detail) {
            this.isLoading = event.detail.value;
        }
    }

    isInSitePreview() {
        let url = document.URL;
        
        return (url.indexOf('sitepreview') > 0 
            || url.indexOf('livepreview') > 0
            || url.indexOf('live-preview') > 0 
            || url.indexOf('live.') > 0
            || url.indexOf('.builder.') > 0);
    }
}