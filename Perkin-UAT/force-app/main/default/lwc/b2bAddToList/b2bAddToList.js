import { LightningElement, api } from 'lwc'; 
import isGuest from '@salesforce/user/isGuest';
import { NavigationMixin } from 'lightning/navigation';
import b2bAddToListModal from 'c/b2bAddToListModal';
import loginStartUrl from '@salesforce/label/c.B2B_Site_Start_Url';
import addToList from '@salesforce/label/c.B2B_PDP_Add_To_List';
import toastSuccess from '@salesforce/label/c.B2B_Toast_Success';

export default class B2bAddToList extends NavigationMixin(LightningElement) {
    static renderMode = 'light';
    
    @api productId;
    @api quantity;
    labels = {
        addToList
    };

    async handleAddToList(){
        console.log('quantity--> ', this.quantity, 'productId--> ', this.productId);
        if(!isGuest){
            await b2bAddToListModal.open({
                label: toastSuccess,
                size: 'small',
                productId: this.productId,
                quantity: this.quantity,
                onnavigatetoshoppinglistdetails: (event) => {
                    event.stopPropagation();
                    this.navigateToShoppingListDetails();
                }
            });
        } else {
            const baseURL = window.location.pathname + window.location.search;
            // const loginURL = `/login?startURL=${encodeURIComponent(baseURL)}`;
            const loginURL = `${loginStartUrl}${encodeURIComponent(baseURL)}`;
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: loginURL
                }
            });
        }
    }

    navigateToShoppingListDetails() {
         this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Wishlist'
            }
        });
    }
}