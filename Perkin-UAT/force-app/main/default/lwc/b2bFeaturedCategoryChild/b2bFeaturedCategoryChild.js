import { LightningElement, api, wire } from 'lwc';
import { ProductCategoryAdapter } from 'commerce/productApi';

export default class B2bFeaturedCategoryChild extends LightningElement {

    @api categoryId;
    @api categoryName;

    categoryData;
    error;

    @wire(ProductCategoryAdapter, { categoryId: '$categoryId' })
    wiredCategory({ error, data }) {
        if (data) {
            this.categoryData = {
                id: this.categoryId,
                name: this.categoryName,
                imageUrl: data?.tileImage?.url,
                urlName: data?.urlName
            };
            this.error = undefined;
            
            this.dispatchEvent(new CustomEvent('categoryloaded', {
                detail: this.categoryData
            }));
        } else if (error) {
            this.error = error?.message || 'Error fetching category data';
            this.categoryData = null;
            console.error('Error fetching category data for ID', this.categoryId, ':', error);
        }
    }
}