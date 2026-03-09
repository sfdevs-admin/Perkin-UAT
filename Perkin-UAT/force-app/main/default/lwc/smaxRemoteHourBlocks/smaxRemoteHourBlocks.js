/**
 * Created by tony on 8/10/21.
 */

import { LightningElement, api, wire, track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import getRemoteHourBlocksForRecord from '@salesforce/apex/SMAX_PS_RemoteHourBlocks.getRemoteHourBlocksForRecord';
//import phoneSupportStaticResource from '@salesforce/resourceUrl/PhoneSupport';

export default class SmaxRemoteHourBlocks extends LightningElement {

//    phoneSupportImage = phoneSupportStaticResource;

    @track remoteHourBlocks;
    @api recordId;
    @track showRemoteHourBlocks = false;

    @wire(getRemoteHourBlocksForRecord, { recordId: "$recordId"} )
        wiredCoverages({ error, data }) {
            if (data) {
                try {
                    console.log('Remote Hour Blocks ran successfully. recordId: ' + this.recordId);
                    console.log('getRemoteHourBlocks data: ' + JSON.stringify(data, null, 2));

                    // Convert Ids into relative URLs
                    const addForwardSlash = a => '/' + a;

                    const result = data.map(o => ({ ...o,
                        coveredProductId: addForwardSlash(o.coveredProductId),
                        serviceMaintenanceContractId: addForwardSlash(o.serviceMaintenanceContractId),
                        installedProductId: addForwardSlash(o.installedProductId),
                     }));

                    this.remoteHourBlocks = result;

                    console.log('this.remoteHourBlocks: ' + JSON.stringify(this.remoteHourBlocks, null, 2));

                    if (this.remoteHourBlocks.length > 0) {
                        this.showRemoteHourBlocks = true;
                    }

                } catch(e){
                    //error when handling result
                    console.error('Remote Hour Blocks Result Error: ', JSON.stringify(error));
                    const evt = new ShowToastEvent({ title: 'Remote Hour Blocks Error', message: 'Error: ' + error.body?.message + ' -- ' + error.body?.stackTrace, variant: 'error', mode: 'sticky'});
                    this.dispatchEvent(evt);
                }
            } else if (error) {
                //error with value provisioning
                console.error('Remote Hour Blocks Provisioning Error: ', JSON.stringify(error));
                const evt = new ShowToastEvent({ title: 'Remote Hour Blocks Provisioning Error', message: 'Error: ' + error.body?.message + ' -- ' + error.body?.stackTrace, variant: 'error', mode: 'sticky'});
                this.dispatchEvent(evt);
            }
        }

}