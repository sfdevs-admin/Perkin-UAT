/**
 * Created by tony on 6/18/21.
 */

import { LightningElement, api, wire, track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import getCoveragesForIp from '@salesforce/apex/SMAX_PS_ExtendedWarranty.getCoveragesForIp';

export default class SmaxExtendedWarranty extends LightningElement {

    @track extendedWarrantyParts;
    @track extendedWarrantyPart;
    @track warrantyContract;
    @track warrantyContractItem;
    @track coveredPart;
    @track coveredUntil;
    @api recordId;
    @track showExtendedWarranty = false;

    @wire(getCoveragesForIp, { ipId: "$recordId"} )
        wiredCoverages({ error, data }) {
            if (data) {
                try {
                    console.log('Extended Warranty Parts ran successfully. recordId: ' + this.recordId);
                    console.log('getCoverages data: ' + JSON.stringify(data, null, 2));

                    // Convert Ids into relative URLs
                    const addForwardSlash = a => '/' + a;

                    const result = data.map(o => ({ ...o,
                        extendedWarrantyPartId: addForwardSlash(o.extendedWarrantyPartId),
                        coveredPartId: addForwardSlash(o.coveredPartId),
                        warrantyContractId: addForwardSlash(o.warrantyContractId),
                        warrantyContractItemId: addForwardSlash(o.warrantyContractItemId)
                     }));

                    this.extendedWarrantyParts = result;

                    console.log('this.extendedWarrantyParts: ' + JSON.stringify(this.extendedWarrantyParts, null, 2));

                    if (this.extendedWarrantyParts.length > 0) {
                        this.showExtendedWarranty = true;
                    }

                } catch(e){
                    //error when handling result
                    console.error('Extended Warranty Parts Result Error: ', JSON.stringify(error));
                    const evt = new ShowToastEvent({ title: 'Extended Warranty Parts Error', message: 'Error: ' + error.body?.message + ' -- ' + error.body?.stackTrace, variant: 'error', mode: 'sticky'});
                    this.dispatchEvent(evt);
                }
            } else if (error) {
                //error with value provisioning
                console.error('Extended Warranty Parts Provisioning Error: ', JSON.stringify(error));
                const evt = new ShowToastEvent({ title: 'Extended Warranty Parts Provisioning Error', message: 'Error: ' + error.body?.message + ' -- ' + error.body?.stackTrace, variant: 'error', mode: 'sticky'});
                this.dispatchEvent(evt);
            }
        }

}