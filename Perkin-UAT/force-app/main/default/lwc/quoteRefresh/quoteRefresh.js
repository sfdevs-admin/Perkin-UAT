/**
 * Created by mgaska001 on 28.01.2026.
 */

import {api, LightningElement} from 'lwc';
import {RefreshEvent} from "lightning/refresh";
import {subscribe, unsubscribe} from 'lightning/empApi';

export default class QuoteRefresh extends LightningElement {
    @api recordId;

    channelName = "/event/Refresh_Event__e";
    subscription = {};

    connectedCallback() {
        const self = this;
        const messageCallback = function(response) {
            console.log("New message received: ", JSON.stringify(response));
            let refreshRecordId = response.data.payload.Record_Id__c;
            if (refreshRecordId === self.recordId) {
                self.handleRefresh();
            }
        }

        subscribe(this.channelName,-1, messageCallback).then((response) => {
            console.log("Subscription request sent to: ", JSON.stringify(response.channel));
            this.subscription = response;
        });
    }

    disconnectedCallback() {
        unsubscribe(this.subscription, (response) => {
            console.log("Unsubscribe response: ", JSON.stringify(response));
        });
    }

    handleRefresh() {
        this.dispatchEvent(new RefreshEvent());
    }

}