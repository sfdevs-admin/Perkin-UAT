import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class NavigateToVfPage extends LightningElement {

    @api quoteId;
    @api showNext = false;
    @api availableActions = [];

    renderedCallback() {
        // Focus the Next button after render to remove Cancel focus
        if (this.showNext) {
            const nextButton = this.template.querySelector('.next-button');
            if (nextButton) {
                nextButton.focus();
            }
        }
    }

    handleCancel() {
        const url = '/apex/sbqq__sb?id=' + this.quoteId;
        window.location.replace(url);
    }

    handleNext() {
        if (this.availableActions.find(action => action === 'NEXT')) {
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }
}