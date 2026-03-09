import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class MergePDFModal extends LightningModal {
    @api mode;  // SAVE, PREVIEW
    @api sourceIds = [];
    @api documentName;
}