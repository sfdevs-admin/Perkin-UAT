/**
 * Created by mgaska001 on 28.01.2026.
 */

import {api, LightningElement, wire} from 'lwc';
import {getFieldValue, getRecord} from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/SBQQ__Quote__c.Name";
import STATUS_FIELD from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Status__c";
import PRICE_REQUEST_STATUS_FIELD from "@salesforce/schema/SBQQ__Quote__c.Price_Request_Status__c";
import PRICE_STALE_ITEMS_FIELD from "@salesforce/schema/SBQQ__Quote__c.Price_Stale_Items__c";
import PRICE_RESPONSE_ERROR_FIELD from "@salesforce/schema/SBQQ__Quote__c.Price_Response_Error__c";

const FIELDS = [
    NAME_FIELD, STATUS_FIELD, PRICE_STALE_ITEMS_FIELD,
    PRICE_REQUEST_STATUS_FIELD, PRICE_RESPONSE_ERROR_FIELD
];

export default class QuotePricesStatus extends LightningElement {
    @api recordId;
    quote;

    @wire(getRecord, {
        recordId: "$recordId",
        fields: FIELDS
    })
    wiredRecord({ error, data }) {
        if (data) {
            this.quote = data;
            console.log('wiredRecord: ' + this.recordId);
        } else if (error) {
            console.error('wiredRecord: ' + JSON.stringify(error));
            this.handleError('Error loading quote', this.combineMessage(error));
        }
    }

    get quoteDraft() {
        return getFieldValue(this.quote, STATUS_FIELD) === 'Draft';
    }

    get hasStalePrices() {
        return getFieldValue(this.quote, PRICE_STALE_ITEMS_FIELD) > 0;
    }

    get quotePriceRequestStatus() {
        return getFieldValue(this.quote, PRICE_REQUEST_STATUS_FIELD);
    }

    get quotePriceResponseError() {
        return getFieldValue(this.quote, PRICE_RESPONSE_ERROR_FIELD);
    }

    get statusRequested() {
        return this.quotePriceRequestStatus === 'Requested';
    }

    get statusFailed() {
        return this.quotePriceRequestStatus === 'Failed';
    }

}