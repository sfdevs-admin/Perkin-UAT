import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProductWithFieldSet from '@salesforce/apex/B2B_ProductSpecificationController.getProductWithFieldSet';
import B2B_Product_Specifications from "@salesforce/label/c.B2B_Product_Specifications";

export default class B2bProductSpecification extends LightningElement {

    label = {
        B2B_Product_Specifications 
    };

    _productData;
    listOfFields=[];
    showTable=false;
    showSpinner=false;
    mapParams={};
    
    @api
    set productData(data) {
        this._productData = data;
        this.getDataToShowOnTable();
    }
    get productData() {
        return this._productData;
    }

    getDataToShowOnTable(){
        this.showSpinner=true;
        this.mapParams.fields = this.productData.fields;
        console.log('this.mapParams: ',JSON.stringify(this.mapParams));
        getProductWithFieldSet( {mapParams : this.mapParams} )
        .then(data => {
            if(data.isSuccess){
                console.log('data: ',data);
                if(this.listOfFields.length == 0){
                    for (const [key, value] of Object.entries(data.labelAndValueMap)) {
                        //console.log(`${key} ${value}`);
                        this.listOfFields.push({'fieldName':key, 'fieldValue':value});    
                    }
                } 
                console.log('this.listOfFields ',this.listOfFields);
                if(this.listOfFields.length > 0){
                    this.showSpinner=false;
                    this.showTable=true;
                }
                else{
                    console.log('length is zero');
                    this.showTable=false;
                    this.showSpinner=false;
                }
            }
            else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: data.message,
                        variant: 'error',
                        mode: 'sticky',
                    })
                );
            }
        })
        .catch(error => {
            console.log('error:',error);
        })
    }
}