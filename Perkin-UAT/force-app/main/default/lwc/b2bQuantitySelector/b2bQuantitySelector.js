import { LightningElement,track, api } from 'lwc';
import { dispatchAction } from 'commerce/actionApi';

export default class B2bQuantitySelector extends LightningElement {

    @api quantity = 1;
    @api productId;
    @api isSubscriptionCart;

    get quantities() {
        return this.quantity;
    }

    set quantities(value) {
        this.quantity = value;
    }

    increaseQuantity() {
        this.quantity += 1;
        this.passProductQuantity();
        console.log('Qty =' , this.quantity);
    }

    decreaseQuantity() {
        if (this.quantity > 1) {
            this.quantity -= 1;
            this.passProductQuantity();
        }
    }

    handleQuantityChange(event){
        console.log('event.target.value',event.target.value);
        if (event.target.value >= 1) {
            this.quantity = parseInt(event.target.value, 10);
            this.passProductQuantity();
        }else{
            this.quantity = 1;
            event.target.value = 1;
            this.passProductQuantity();
        }
        
    }

    passProductQuantity() {
        console.log('product Id---> ', this.productId);
        this.dispatchEvent(new CustomEvent('productquantity', {
            detail: {
                message: this.quantity,
                productId:this.productId
            }
        }));
    }

}