import { api, LightningElement, wire } from 'lwc';
import Id from '@salesforce/user/Id';
import getAttachmentIdOnCart from '@salesforce/apex/B2B_EnhancedFileUploaderController.getAttachmentIdOnCart';

//labels 
import B2B_UPLOADFILELABEL from '@salesforce/label/c.B2B_Checkout_UploadFileLabel';
import B2B_UPLOADFILEHELPTEXT from '@salesforce/label/c.B2B_Checkout_UploadFileHelpText';
import B2B_UPLOADFILEREQUIREDTEXT from '@salesforce/label/c.B2B_Checkout_UploadFileRequiredText';

export default class B2bCheckoutFileUpload extends LightningElement {

    userId = Id;
    _checkoutDetails;
    @api
    get checkoutDetails() {
        return this._checkoutDetails;
    }
    set checkoutDetails(value) {
        if( value ){
            console.log('B2bCheckoutFileUpload checkoutDetails--- ', JSON.parse(JSON.stringify(value)));
            this._checkoutDetails = value;
        }
    }

    get acceptedFormats() {
        return ['.pdf', '.png'];
    }

    get recordIdVal() {
        // return '003bc00000DoeArAAJ';
        if( this.b2bAttachmentId ){
            return this.b2bAttachmentId;
        }
    }

    get labelVal() {    
        return B2B_UPLOADFILELABEL;
    }

    get fileNameOverrideVal() {
        if( this.checkoutDetails?.cartSummary?.cartId ){
            let retVal = this.checkoutDetails.cartSummary.cartId;
            return retVal;
        }
    }

    get currentCartId (){
        if( this.checkoutDetails?.cartSummary?.cartId ){
            let retVal = this.checkoutDetails.cartSummary.cartId;
            return retVal;
        }
    }

    get isRequiredVal() {
        return false;
    }

    get fileSizeLimitVal() {
        return 1000000;
    }

    get helpTextVal() {   
        return B2B_UPLOADFILEHELPTEXT;
    }

    get isUploadDisabledVal() {
        return false;
    }

    get allowMultiple(){
        return "CB_TRUE";
    }

    get renderExistingFilesVal() {
        // return true;
        return "CB_TRUE";
    }

    get requiredMessageVal (){
        return B2B_UPLOADFILEREQUIREDTEXT;
    }

    b2bAttachmentId;
    @wire(getAttachmentIdOnCart,{cartId: '$currentCartId'})
    wiredValue({error,data}){
        if(data){
            this.b2bAttachmentId = data;
            console.log('data in getAttachmentIdOnCart', data);
        }
        else if (error){
            console.log('Error in getAttachmentIdOnCart', error);
        }
    }
}