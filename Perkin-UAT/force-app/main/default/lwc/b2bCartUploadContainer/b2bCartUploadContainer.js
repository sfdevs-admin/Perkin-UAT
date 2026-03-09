import { LightningElement, track, wire } from 'lwc';
import labels from './labels';
import b2bCartUploadModal from 'c/b2bCartUploadModal';
import { navigate, NavigationContext, NavigationMixin } from 'lightning/navigation';

export default class B2bCartUploadContainer extends NavigationMixin(LightningElement) {

    // Expose the labels to use in the template.
    @track label = labels;

    async handleClick(){
        const result = await b2bCartUploadModal.open({
            size: 'small',
            label: 'My Modal Title',
            description: 'This is a description',
            onnavigatetocart: (event) => {
                // stop further propagation of the event
                event.stopPropagation();
                // hand off to separate function to process
                // result of the event (see above in this example)
                this.navigateToCart();
                // or proxy to be handled above by dispatching
                // another custom event to pass on the event
                // this.dispatchEvent(e);
            }
        });
        console.log('b2bCartUploadModal result : ',result);
    }

    @wire(NavigationContext)
    navContext;

    navigateToCart() {
        this.navContext &&
        navigate(this.navContext, {
            type: 'comm__namedPage',
            attributes: {
                name: 'Current_Cart',
            },
        });
    }
}