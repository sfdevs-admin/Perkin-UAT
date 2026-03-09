import { LightningElement,wire,track, api } from 'lwc';
import cartApi from 'commerce/cartApi';
import getProductIdFromSKU from "@salesforce/apex/B2BCartUploadController.getProductIdFromSKU";
import { AppContextAdapter } from 'commerce/contextApi';
import { getSessionContext } from 'commerce/contextApi';
import { CartSummaryAdapter } from 'commerce/cartApi';
import ToastContainer from 'lightning/toastContainer';
import Toast from 'lightning/toast';
import labels from './labels';
import LightningModal from 'lightning/modal';

export default class B2bCartUploadModal extends LightningModal {
    // static renderMode = "light"; // the default is 'shadow'

    fileData;
    errorMessage = labels.B2B_CSVTOCART_ERRORMESSAGE;
    isUploadDisable = true;
    isLoading = false;
    showLimitError = false;
    errorSkuList = [];
    get acceptedFormats() {
        return ['.csv'];
    }
    webStoreId;
    showResults = false;
    errorResultFound = false ;
    effectiveAccountId;
    totalRecordCount;
    successRecordCount = 0;
    errorRecordCount;

    // Expose the labels to use in the template.
    @track labels = labels;

    showAddToCartButton = false;

    async getAccountId()
    {
        const result = await getSessionContext();
        if(result && result.effectiveAccountId)
        {
            this.effectiveAccountId = result.effectiveAccountId;
        }
    }
    connectedCallback() {
        const toastContainer = ToastContainer.instance();
        toastContainer.maxShown = 5;
        toastContainer.toastPosition = 'top-center';
    }

    allowedProductToAdd = 500;

    @wire(CartSummaryAdapter, { webstoreId: '$webStoreId', cartStateOrId: 'current' })
    onGetCartSummary(result) {
        if (result.data && result.data.uniqueProductCount > 0) {
            this.allowedProductToAdd = this.allowedProductToAdd - result.data.uniqueProductCount ;
            if(this.allowedProductToAdd == 0){
                this.showToast(labels.B2B_CSVTOCART_CARTISFULL,labels.B2B_CSVTOCART_MAX500,'sticky','error');
                return ;
            }
        }
    }

    @wire(AppContextAdapter)
    wireAppContext(result) {
        if (result.data) {
            this.webStoreId = result.data.webstoreId;
            this.getAccountId();
        }
    }

    downloadSampleCSV(){
        var sampleCSVData = [  
            [labels.B2B_CSVTOCART_PARTNUMBER, labels.B2B_CSVTOCART_QUANTITY], 
            [labels.B2B_CSVTOCART_PARTNUMBER + ' 1', '2'], 
            [labels.B2B_CSVTOCART_PARTNUMBER + ' 2', '5'], 
        ];  
        let csv = '';
        sampleCSVData.forEach(function(row) {  
                csv += row.join(',');  
                csv += "\n";  
        }); 
        this.downloadCSV(csv,labels.B2B_CSVTOCART_SAMPLEBULKUPLOAD);
    }

    handleUploadClick(){
        this.isLoading = true;
        this.showResults = false;
        this.successRecordCount = 0;
        this.errorResultFound = false;
        this.errorSkuList = [];
        let fileData = this.fileData;
        if(fileData && fileData.csvData){
            let csvData = fileData.csvData;
            let csvDataList = csvData.includes("\r\n") ? csvData.split("\r\n") : csvData.split("\n") ;
            let cartItemsMap = {};
            csvDataList.forEach(element => {
                let ele = element;
                if(ele != 'Part Number,Quantity' && ele != 'Part Number,Quantity,Message' && !ele.includes('Part Number,Quantity')){
                    let eleList = element.split(",");
                    if(eleList[0] != null && eleList[0] != '' && eleList[0].trim() != ''
                        && eleList[1] != null && eleList[1] != '' && eleList[1].trim() != '' && eleList[1].trim() != '0'
                    ){
                        if(cartItemsMap.hasOwnProperty(eleList[0])){
                            let qty = cartItemsMap[0];
                            cartItemsMap[eleList[0]] = eleList[1]; 
                        }else{
                            cartItemsMap[eleList[0]] = eleList[1]; 
                        }
                    }
                }
            });
            if(cartItemsMap){
                this.processCartItems(cartItemsMap);
            }
        }
    }

    async createCartItemsRequest(cartItemsMap){
        let resMap = await this.getProductIdFromSKU(Object.keys(cartItemsMap));
        console.log('B2bCartUpload createCartItemsRequest getProductIdFromSKU resMap--- ',JSON.parse( JSON.stringify( resMap ) ) );
        let productSKUMap = resMap.validSKUMap ;
        let errorPricingLineItemResults = resMap.errorPricingLineItemResults;
        let qtyRuleMap = resMap.qtyRuleMap ;
        let entitledProducts = resMap.entitledProducts ;
        let cartItemInputRequest = []; 
        for(let k in cartItemsMap){
            if(productSKUMap.hasOwnProperty(k)){
                if(entitledProducts.indexOf(productSKUMap[k]) != -1){
                    console.log('cartItemsMap[k]',cartItemsMap[k]);
                    console.log('k',k);
                    console.log('qtyRuleMap',qtyRuleMap);
                    if(qtyRuleMap.hasOwnProperty(productSKUMap[k])){
                        let qtyRule = qtyRuleMap[productSKUMap[k]];
                        let isQtyRulePassed = true;
                        let qty = cartItemsMap[k] ;
                        if(qtyRule){
                            if(qtyRule.maximum && parseInt(qty) > parseInt(qtyRule.maximum)  ){
                                isQtyRulePassed = false;
                                this.errorSkuList.push({"SKU": k ,"Part Number": k ,"Quantity":  cartItemsMap[k] ,"Message":'Maximum purchase Quantity is '+qtyRule.maximum });
                            }else if(qtyRule.minimum && parseInt(qty) < parseInt(qtyRule.minimum) ){
                                isQtyRulePassed = false;
                                this.errorSkuList.push({"SKU": k ,"Part Number": k ,"Quantity":  cartItemsMap[k] ,"Message":'Minimum purchase Quantity is '+qtyRule.minimum });
                            }else if(qtyRule.increment && parseInt(qty)%parseInt(qtyRule.increment)!=0 ){
                                isQtyRulePassed = false;
                                this.errorSkuList.push({"SKU": k ,"Part Number": k ,"Quantity":  cartItemsMap[k] ,"Message":'This Product can only be purchased in multiple of '+qtyRule.increment });
                            }
                        }
                        if(isQtyRulePassed){
                            cartItemInputRequest[productSKUMap[k]] = cartItemsMap[k];
                        }
                    }else{
                        cartItemInputRequest[productSKUMap[k]] = cartItemsMap[k];
                    }
                }else if(errorPricingLineItemResults.hasOwnProperty(productSKUMap[k])){
                    let msg = errorPricingLineItemResults[productSKUMap[k]];
                    if(msg == 'ITEM_NOT_FOUND'){
                        msg = labels.B2B_CSVTOCART_PRODUCTNOTFOUNDERROR;
                        //msg = 'Product is not Entitled.';
                    }else if(msg == 'PRICE_NOT_FOUND'){
                        msg = labels.B2B_CSVTOCART_PRICENOTFOUNDERROR;
                        // msg = 'Price not found.';
                    }
                    this.errorSkuList.push({"SKU": k ,"Part Number": k ,"Quantity":  cartItemsMap[k] ,"Message":msg });
                }else{
                    // this.errorSkuList.push({"Part Number": k ,"Quantity":  cartItemsMap[k] ,"Message":'Product is Not Entitled'});
                    this.errorSkuList.push({"SKU": k ,"Part Number": k ,"Quantity":  cartItemsMap[k] ,"Message": labels.B2B_CSVTOCART_PRODUCTNOTFOUNDERROR});
                }
            }else{
                // this.errorSkuList.push({"Part Number": k ,"Quantity":  cartItemsMap[k] ,"Message":'Invalid SKU'});
                this.errorSkuList.push({"SKU": k ,"Part Number": k ,"Quantity":  cartItemsMap[k] ,"Message":labels.B2B_CSVTOCART_INVALIDSKUERROR});
            }
        }
        return cartItemInputRequest;
    }

    handleResetClick(){
        this.fileData = {};
        this.isUploadDisable = true;
        this.showLimitError = false;
    }

    get noteRichText(){
        //return 'You should be able to navigate with the following links: <ul><li><a href="http://www.google.com">www.google.com</a></li><li>www.salesforce.com</li><li>http://www.google.com</li><li>salesforce.com</li></ul> and this email address: email@richtext.com.';
        return labels.B2B_CSVTOCART_LIMITERRORLABEL;
    }

    get step2Description(){
        return labels.B2B_CSVTOCART_STEP2VALUE;
    }

    async processCartItems(cartItemsMap){
        try{
            let cartItemInputRequest = await this.createCartItemsRequest(cartItemsMap);
            if(Object.keys(cartItemInputRequest).length > this.allowedProductToAdd){
                let cartItemLimitMessage = labels.B2B_CSVTOCART_CARTITEMLIMITMESSAGE.replace(
                                                '{0}',
                                                this.allowedProductToAdd
                                            );
                this.showToast(labels.B2B_CSVTOCART_CARTFULLMAXITEM, cartItemLimitMessage,'sticky','error');
                this.isLoading = false;
                return;
            }
            let respose = await this.handleAddItemsToCart(cartItemInputRequest);
            this.showResults = true;
            this.totalRecordCount = Object.keys(cartItemsMap).length ;
            this.errorRecordCount = this.totalRecordCount - this.successRecordCount;// this.errorSkuList.length  ;
            if(this.errorSkuList && this.errorSkuList.length>0){
                this.errorResultFound = true;
            }
            this.showAddToCartButton = true;
        }catch(ex){
            this.isLoading = false;
            console.error(ex);
            this.showToast(labels.B2B_CSVTOCART_ERROROCCUREDADDTOCART,ex,'sticky','error');
        }
    }

    downloadErrorCSV(){
        let errorSkuList = this.errorSkuList;
        var sampleCSVData = [  
            [labels.B2B_CSVTOCART_PARTNUMBER, labels.B2B_CSVTOCART_QUANTITY,labels.B2B_CSVTOCART_SAMPLEFILEMESSAGE]
        ];  
        errorSkuList.forEach(element => {
            sampleCSVData.push([element.SKU,element.Quantity,element.Message]);
        });
        let csv = '';
        sampleCSVData.forEach(function(row) {  
                csv += row.join(',');  
                csv += "\n";  
        }); 
        this.downloadCSV(csv,'Error');
    }

    async getProductIdFromSKU(skuList){
        const res = await getProductIdFromSKU({"skuList":skuList,"effectiveAccountId":this.effectiveAccountId,"webStoreId": this.webStoreId});
        return res;
    }

    downloadCSV(csvString,name){
        let downloadElement = document.createElement('a');
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        downloadElement.download = name;// 'Sample Bulk Upload.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click(); 
    }
    async addItemsToCart(addItems) {
        const result = await cartApi.addItemsToCart(addItems);
        return result;
    }

    populateErrorRecords(errResults,uploadedData){
        errResults.forEach(element => {
            this.errorSkuList.push({"SKU": k ,"Part Number": k ,"Quantity":  cartItemsMap[k] ,"Message":'Product Not Found'});
        });
    }

    async handleAddItemsToCart(addItemsToCartActionPayload) {
        console.log(Object.keys(addItemsToCartActionPayload).length);
        let addItems = {};
        let res = {} ;
        res.hasErrors = true;
        for (const key in addItemsToCartActionPayload) {
            addItems[key] = addItemsToCartActionPayload[key] ;
            // this.allowedProductToAdd = this.allowedProductToAdd  - 1;
            // if(this.allowedProductToAdd == 0){

            // }
            if(Object.keys(addItems).length == 100){
                res = await this.addItemsToCart(addItems);
                console.log('res');
                console.log(res.results.length);
                if(!res.hasErrors){
                    this.successRecordCount +=  res.results.length;
                }else{
                    //this.populateErrorRecords(res.results);
                }
                addItems = {};
            }
        }
        if(Object.keys(addItems).length > 0){
            res = await this.addItemsToCart(addItems);
            console.log('res');
            console.log(res.results.length);
            if(!res.hasErrors){
                this.successRecordCount +=  res.results.length;
            }else{
                //this.populateErrorRecords(res.results);
            }
            addItems = {};
        }
        this.isLoading = false;
        return res;
    }

    openfileUpload(event) {
        const file = event.target.files[0]
        var reader = new FileReader()
        reader.onload = () => {
            var csvData = reader.result;
            var csvDataLength = this.countRows(csvData);
            csvDataLength = csvDataLength - 1; // subtracting header row
            if( csvDataLength > 50 ){
                //error message
                this.handleResetClick();
                // this.showToast('Limit exceeded','More rows than allowed.','sticky','error');
                this.showLimitError = true;
                // this.showToast(labels.B2B_CSVTOCART_LIMITERRORLABEL,labels.B2B_CSVTOCART_LIMITERROR,'sticky','error');
            }else{
                this.showLimitError = false;
                this.isUploadDisable = false;
                this.fileData = {
                    'filename': file.name,
                    'csvData': csvData
                }
            }
        }
        reader.readAsText(file)
    }

    countRows(csvText) {
        const lines = csvText.split('\n');
        // Filter out empty lines
        const filteredLines = lines.filter(line => line.trim() !== '');
        return filteredLines.length;
    }

    showToast(label,message,mode,variant){
        Toast.show({
            label: label,
            message: message,
            mode: mode,
            variant: variant
        }, this);
    }

    closeModal() {
        // immediately exits, so no need to trigger
        // this.disableClose = false OR
        // this.saveInProcess = false;
        // modal is destroyed, and focus moves
        // back to originally clicked item that
        // generated the modal
        // this.close('canceled');
        this.close('closed');
    }

    navigateToCart() {
        const navigateToCartEvent = new CustomEvent('navigatetocart', {
            detail: {  }
        });
        this.dispatchEvent(navigateToCartEvent);
        this.closeModal();
    }

}