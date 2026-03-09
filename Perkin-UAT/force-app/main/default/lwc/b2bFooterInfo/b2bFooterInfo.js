import { LightningElement, api } from 'lwc';

/**
 * @slot logo
 */
export default class B2bFooterInfo extends LightningElement {

    @api
    addressLine1;

    @api
    addressLine2;

    @api
    supportLink;

    @api
    globalLocationsLink;

    @api
    otherSitesLink;

    @api
    externalUrl;

    @api
    urlTarget;

    renderedCallback() {
        this.handleLogoRedirection();
    }

    handleLogoRedirection() {
        const slot = this.template.querySelector('slot[name="logo"]');
        if (slot) {
            const assignedNodes = slot.assignedElements();
            if (assignedNodes.length > 0) {
                const logoElement = assignedNodes[0]; 
                logoElement.style.cursor = 'pointer';
                logoElement.addEventListener('click', (event) => {
                    event.stopPropagation();
                    window.open(this.externalUrl, this.urlTarget);
                });
            }
        }
    }
}