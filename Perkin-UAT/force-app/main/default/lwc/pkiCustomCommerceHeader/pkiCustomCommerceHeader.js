import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
/**
 * @slot mobile-nav ({ locked: false})
 * @slot headerLogo ({ locked: false})
 * @slot desktop-nav ({ locked: false})
 * @slot profile-nav ({ locked: false})
 * @slot cart ({ locked: false})
 * @slot search-bar ({ locked: false}) - Slot for custom search bar component
 * @slot site-banner ({ locked: false}) - Slot for Site banner
 */

export default class PKICustomCommerceHeader extends LightningElement {

    // static renderMode = "light"; 

    @api externalUrl;
    @api urlTarget;
    
    pageTitle;
    fontLoaded = false;

    connectedCallback() {
        // Check if the font is available
        document.fonts.ready.then(() => {
            this.fontLoaded = true;
            // Force a re-render
            this.updateTitleVisibility();
        });
    }

    renderedCallback() {
        if (this.fontLoaded) {
            this.updateTitleVisibility();
        }
        this.handleLogoRedirection();
    }

    updateTitleVisibility() {
        const titleElement = this.template.querySelector('.PKI-page-title h1');
        if (titleElement) {
            titleElement.style.visibility = 'visible';
        }
    }

    handleLogoRedirection() {        
        const slot = this.template.querySelector('slot[name="headerLogo"]');
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

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef) {
            //eslint-disable-next-line
            window.setTimeout(() => {
                this.pageTitle = document.title || pageRef.state.pageTitle || 'Default Page';
                console.log('Current page title:', this.pageTitle);
                if (this.pageTitle === 'Checkout') {
                    this.visibleSearchBar = false;
                }
            }, 50);
        }
    }

    showSearchBar = false;
    visibleSearchBar = true;
    handleSearch() {
        this.showSearchBar = true;
    }
    handleCancel() {
        this.showSearchBar = false;
    }
}