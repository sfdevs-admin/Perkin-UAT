import { LightningElement, wire } from "lwc";
import { CartSummaryAdapter } from "commerce/cartApi";
import { useCheckoutComponent } from "commerce/checkoutApi";
import updateSpecialInstruction from "@salesforce/apex/B2BCartController.updateSpecialInstruction";
import getSpecialInstruction from "@salesforce/apex/B2BCartController.getSpecialInstruction";
import { debounce } from "experience/utils";

export default class B2bSpecialInstruction extends useCheckoutComponent(
  LightningElement
) {
  static renderMode = "light";
  cartId;
  userInput;
  isLoading = true;
  showSpinner = false;

  @wire(CartSummaryAdapter, { cartStateOrId: "active" })
  async wiredCartSummaryData(result) {
    if (result.data && result.data.cartId) {
      this.cartId = result.data.cartId;
      this.fetchSpecialInstruction();
    }
  }

  fetchSpecialInstruction() {
    getSpecialInstruction({ webCartId: this.cartId })
      .then((data) => {
        console.log("Fetched Special Instruction:", data);
        this.isLoading = false;
        if (data !== null) {
          this.userInput = data;
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }

  handleChange(event) {
    this.userInput = event.target.value;
    this._saveSpecialInstruction();
  }

  // Debounced function
  _saveSpecialInstruction = debounce(() => {
    this.showSpinner = true;
    this.saveSpecialInstruction();
  }, 3000);

  saveSpecialInstruction() {
    updateSpecialInstruction({
      webCartId: this.cartId,
      specialInstruction: this.userInput
    })
      .then(() => {
        this.showSpinner = false;
      })
      .catch((error) => {
        this.showSpinner = false;
        console.error(error);
      });
  }
}