import { LightningElement, api, wire } from 'lwc';
import { ProductCategoryAdapter } from 'commerce/productApi';

export default class B2bCategoryNavigator extends LightningElement {
    @api categoryId;
    @api categoryLabel;
    urlName;

     @wire(ProductCategoryAdapter, {
            categoryId: '$categoryId',
        })
        wiredProductCategoryAdapter({ data }) {
            if (data) {
                this.urlName = data?.urlName;
            }
        }

        handleCategoryClick(event) {
            event.stopPropagation();
            const selectedCategoryId = event.currentTarget.dataset.categoryid;
            const selectedCategoryUrlName = this.urlName;
            this.dispatchEvent(new CustomEvent('navigatecategory', {
                detail: {
                    categoryId: selectedCategoryId,
                    urlName: selectedCategoryUrlName
                },
                bubbles: true,    
                composed: true 
            }));
        }

}