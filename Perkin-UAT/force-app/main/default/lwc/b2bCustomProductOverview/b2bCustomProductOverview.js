import { LightningElement, api, wire } from 'lwc';
import B2B_Product_Overview from "@salesforce/label/c.B2B_Product_Overview";
import B2B_PDP_TAB_RESOURCES from "@salesforce/label/c.B2B_PDP_TabResourcesEvents";

/**
 * @slot resourcesEventsAndMore
 */

export default class B2bCustomProductOverview extends LightningElement {
    static renderMode = "light"; // the default is 'shadow'

    label = {
        B2B_Product_Overview,
        B2B_PDP_TAB_RESOURCES 
    };

    selectedTab;
    _productData;
    recordId;
    @api productFieldMapping;

    longDescription='';
    listOfFields = [];
    showDescription=false;

    connectedCallback(){
        this.selectedTab = 'Tab 1';
    }
    
    @api
    set productData(data) {
        this._productData = data;
        //console.log('in parent product.details: ', this._productData);
        this.getLongDescriptionValue();
    }
    get productData() {
        return this._productData;
    }

    getLongDescriptionValue(){
        // this.longDescription = this._productData.fields.B2B_Long_Description__c;
        this.longDescription = this._productData.fields.B2B_SKU_Description__c;
        console.log('this.longDescription: ',this.longDescription);
        if(this.longDescription != null){
            this.showDescription=true;
        }
    }
    // get longDescriptionRichText(){
        
    // }

    handleActive(event) {
        const tabName = event.target.value;
        if( this.selectedTab != tabName ){
            this.selectedTab = tabName;
        }
        // console.log(`Clicked on ${tabName}`);
        console.log("Clicked on ", tabName);
        
    }

    get tab1Selected(){
        if( this.selectedTab == 'Tab 1' ){
            return true;
        }
        return false;
    }

    get tab2Selected(){
        if( this.selectedTab == 'Tab 2' ){
            return true;
        }
        return false;
    }

}