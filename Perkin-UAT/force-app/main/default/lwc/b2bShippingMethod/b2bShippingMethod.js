import { LightningElement, api, wire } from 'lwc';
import { mockData } from './b2bShippingMethodMockData';
import { updateDeliveryMethod, CheckoutInformationAdapter, loadCheckout, useCheckoutComponent} from 'commerce/checkoutApi';//notifyCheckout
import { refreshCartSummary } from "commerce/cartApi";
import mainTemplate from "./b2bShippingMethod.html";
import stencilTemplate from "./b2bShippingMethodStencil.html";
import LABELS from './b2bShippingMethodConst';
import { CurrentPageReference } from 'lightning/navigation';
import { debounce } from "experience/utils";

const CheckoutStage = {
    CHECK_VALIDITY_UPDATE: "CHECK_VALIDITY_UPDATE",
    REPORT_VALIDITY_SAVE: "REPORT_VALIDITY_SAVE",
    BEFORE_PAYMENT: "BEFORE_PAYMENT",
    PAYMENT: "PAYMENT",
    BEFORE_PLACE_ORDER: "BEFORE_PLACE_ORDER",
    PLACE_ORDER: "PLACE_ORDER",
  };

export default class B2bShippingMethod extends useCheckoutComponent(LightningElement) {
    parsedData; 
    isDisabled = true;
    _errorMessage = '';
    isSummary = false;
    selectedGroup;
    isLoading = true;
    transformedOptions;
    pageReference;
    retryAllowed = true;

    // this variable can be removed if you don't plan to use the expression, but loadCheckout instead
    @api checkoutData;

    @wire(CurrentPageReference) 
    handleStateChange(pageReference) {
        this.pageReference = pageReference;
    }

    @wire(CheckoutInformationAdapter, {})
    checkoutInfo({ error, data }) {
        if (data ) {
            this.getCommerceCheckoutInfo(data);
        } else if (error) {
            if(this.isInSitePreview()) {
                this.isLoading = false;
                this.transformedOptions = mockData;
            }
        }
        
    }

    /**
     * 
     * Get the checkout data for the user
     */
    async getCommerceCheckoutInfo(data) {
        console.log('shipping method --->', data);
        this.parsedData = data;
        this.deliveryGroups = this.parsedData?.deliveryGroups?.items?.[0]?.availableDeliveryMethods;
        let isDeliveryAddressExist = this.parsedData?.deliveryGroups?.items?.[0]?.deliveryAddress;
        if (isDeliveryAddressExist) {
            
            if(this.deliveryGroups.length !== 0){
                // clear any errors before proceeding
                this.clearCheckoutError();

                // transforms the data into a format that the frontend can use
                const tempTransformedOptions = this.transformedMethods(this.parsedData);
                this.isDisabled = false;
                this.isLoading = false;

                // ensure the values are unique before passing them to the frontend
                const arrUniq = [...new Map(tempTransformedOptions.map(v => [v.id, v])).values()]
                this.transformedOptions = arrUniq;
            }else{
                this._showError();
            }
        }
    }

    _showError = debounce(() => {
        this.clearCheckoutError();
        if(this.deliveryGroups.length === 0){ 
            this.isLoading = true;
            this._errorMessage = LABELS.B2B_NoDeliveryMethods;
            this.dispatchUpdateErrorAsync({
                    groupId: 'ShippingMethod',
                    type: '/commerce/errors/checkout-failure',
                    exception:  this._errorMessage
                    
            });
        }
    }, 3000);

    /**
     * Consumes the raw api data and transforms into formated delivery options for frontend
     */
    transformedMethods(deliveryMethods){
      var deliveryGroups = deliveryMethods.deliveryGroups.items[0].availableDeliveryMethods;
      this.selectedGroup = deliveryMethods?.deliveryGroups?.items?.[0]?.selectedDeliveryMethod;
      let selectedGroupArray = [];
      if (this.selectedGroup != null || this.selectedGroup !== undefined) {
        selectedGroupArray = [this.selectedGroup];
      }

      let options = [];
      deliveryGroups.forEach(newOption => {
        var selected = false;

        if (selectedGroupArray.length > 0) {
            selected = !!selectedGroupArray.find(e => e.id === newOption.id);
        }
       
        
        let option = {
          'key': Math.random().toString(36).substring(2, 15),
          'id': newOption.id,
          'name': newOption.name,
          'shippingFee': newOption.shippingFee,
          'currencyIsoCode': newOption.currencyIsoCode,
          'selected': selected ? true : false,
        }
        options.push(option);

        if( selected ){
            this.updateDeliveryMethodById( newOption.id );
        }
       });
       console.log('options---> ',options);

       // Sort: Freight Collect goes to bottom, others sorted by shippingFee
        options.sort((a, b) => {
            const isFreightA = a.name?.toLowerCase().includes('freight collect');
            const isFreightB = b.name?.toLowerCase().includes('freight collect');

            if (isFreightA && !isFreightB) return 1;
            if (!isFreightA && isFreightB) return -1;
            if (isFreightA && isFreightB) return 0;

            // Compare shipping fee (lowest to highest)
            return a.shippingFee - b.shippingFee;
        });
        console.log('After sorting options---> ',options);
        return options;
    }

    /**
     * Determines if you are in the experience builder currently
     */
    isInSitePreview() {
        let url = document.URL;
        
        return (url.indexOf('sitepreview') > 0 
            || url.indexOf('livepreview') > 0
            || url.indexOf('live-preview') > 0 
            || url.indexOf('live.') > 0
            || url.indexOf('.builder.') > 0);
    }

    /**
     * Updates the exisitng options and rebuilds the array to keep the selection
     */
    updateOptions(value){
        const newtransformedOptions = [];

        this.transformedOptions.forEach(option => {
            if(option.id === value){
                const newOption = {...option, selected:true};
                newtransformedOptions.push(newOption);
                this.selectedGroup = newOption;
            }else{
                const newOption = {...option, selected:false};
                newtransformedOptions.push(newOption);
            }
            this.transformedOptions = newtransformedOptions
        });
    }

    /**
     * 
     * handle event for any change in selection of the shipping options
     */
    async handleChange(event){
        // disable while the component is saving the values
        this.isDisabled = true;
        this.updateOptions(event.target.value);
        updateDeliveryMethod(event.target.value)
        .then(result => {
            this.doRefreshCartSummary();
        })
        .catch(error => {
            this.isDisabled = false;
            this._errorMessage = LABELS.B2B_ErrorMessage;

            this.dispatchUpdateErrorAsync({
                groupId: 'ShippingMethod',
                type: '/commerce/errors/checkout-failure',
                exception:  this._errorMessage
            });
        });
    }

    async updateDeliveryMethodById( Id ){
        console.log('updateDeliveryMethodById--- ',Id);
        this.isLoading = true;
        if( this.retryAllowed ){
            updateDeliveryMethod( Id )
            .then(result => {
                this.doRefreshCartSummary();
                this.retryAllowed = false;
                this.isLoading = false;
            })
            .catch(error => {
                this.isDisabled = false;
                this._errorMessage = LABELS.B2B_ErrorMessage;
                this.retryAllowed = false;
                this.isLoading = false;

                this.dispatchUpdateErrorAsync({
                    groupId: 'ShippingMethod',
                    type: '/commerce/errors/checkout-failure',
                    exception:  this._errorMessage
                });
            });
        }
    }

    /**
     * 
     * Refreshes the cart summary after the shipping method has been updated
     * 
     */
    async doRefreshCartSummary() {
        await refreshCartSummary();
        await loadCheckout();
        this.isDisabled = false;
    }

    /**
     * 
     * Clears any ShippingMethod errors
     * 
     */
    clearCheckoutError() {
        this.dispatchUpdateErrorAsync({
            groupId: 'ShippingMethod'
        });

    }

    /**
     * update form when our container asks us to
     */
    stageAction(checkoutStage /*CheckoutStage*/) {
        switch (checkoutStage) {
            case CheckoutStage.CHECK_VALIDITY_UPDATE:
                return Promise.resolve(this.checkValidity());
            case CheckoutStage.REPORT_VALIDITY_SAVE:
                return Promise.resolve(this.reportValidity());
            default:
                return Promise.resolve(true);
        }
    } 

    /**
     * handles the aspects changing on the site.
     */
    async setAspect(newAspect) {
        if (!this.isInSitePreview()) {
            if ((this.pageReference === undefined || this.pageReference?.state?.session == null)) {
                if(newAspect.summary){
                    this.isSummary = true;
                }else {
                    this.isSummary = false;
                    this.getCommerceCheckoutInfo();
                }
            } else {
                this.isSummary = true;
            }
        }
    }

    /**
     * checkValidity 
     */
    @api
    checkValidity() {
        return true;
    }
  
    /**
     * reportValidity
     */
    @api
    reportValidity() {
        return true;
    }

    render() {
        if (this.isLoading) {
            return stencilTemplate;
        }
        return mainTemplate;
    }

    summaryRequested = false;
    async connectedCallback() {
        if(!this.isInSitePreview()) {
            this.updateSetAspect();
        } else {
            this.transformedOptions = mockData;
        }
    }

    async updateSetAspect() {
        if (this.pageReference?.state?.session != null) {
            if (!this.summaryRequested) {
                this.summaryRequested = true;
                this.retryAllowed = false;
                const desiredAspect = {
                    summarizable: true
                };
                await this.dispatchRequestAspect(desiredAspect);
            }
        }
    }
}