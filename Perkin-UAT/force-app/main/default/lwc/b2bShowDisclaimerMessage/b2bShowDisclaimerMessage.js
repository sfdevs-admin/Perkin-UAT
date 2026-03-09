import { LightningElement } from 'lwc';
import LightningModal from 'lightning/modal';
import B2B_Disclaimer_Message from '@salesforce/label/c.B2B_Disclaimer_Message';
import B2B_Modal_Proceed_Button from '@salesforce/label/c.B2B_Modal_Proceed_Button';
import B2B_Disclaimer_Message2 from '@salesforce/label/c.B2B_Disclaimer_Message2';

export default class B2bShowDisclaimerMessage extends LightningModal {
    customLabel={
        B2B_Disclaimer_Message,
        B2B_Modal_Proceed_Button,
        B2B_Disclaimer_Message2
    };

    handleProceed(){
        this.close('Proceed');
    }
}