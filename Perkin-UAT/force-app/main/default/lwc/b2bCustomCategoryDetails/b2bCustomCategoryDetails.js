import { api, LightningElement, wire } from 'lwc';
import { ProductCategoryAdapter } from 'commerce/productApi';
import { CurrentPageReference } from "lightning/navigation";

export default class B2bCustomCategoryDetails extends LightningElement {

    categoryId;
    categoryHeader;
    categoryData;
    showTileImage = false;
    showBannerImage = false;

    categoryBanner;
    categoryDescriptio;
    showCategoryDescription = false;
    isLoading = true;

    _recordId;
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        console.log('B2bCustomCategoryDetails value--- ', value);

        if (value) {
            this._recordId = value;
            this.categoryId = value;
        } else {
            this.isLoading = true;
        }
    }

    // @wire(CurrentPageReference)
    // getCurrentPageReference(pageRef) {
    //     console.log('B2bCustomCategoryDetails getCurrentPageReference pageRef--- ', pageRef);
    //     if( pageRef && pageRef.attributes && pageRef.attributes.recordId ){
    //         this.categoryId = pageRef.attributes.recordId;
    //     }
    // }

    @wire(ProductCategoryAdapter, {
        categoryId: '$categoryId',
    })
    wiredProductCategoryAdapter({ data }) {
        console.log('B2bCustomCategoryDetails wiredProductCategoryAdapter data--- ', data);
        if (data) {
            this.categoryData = data;
            this.categoryHeader = this.categoryData?.fields?.B2B_Category_Heading__c ?? undefined;
            if (this.categoryData?.bannerImage) {


                //Adding prefix url for externally hosted domain
                var imageurl = this.categoryData?.bannerImage?.url.startsWith('/cms') ?
                    '/sfsites/c' + this.categoryData?.bannerImage?.url : this.categoryData?.bannerImage?.url;

                this.categoryBanner = {
                    ...this.categoryData?.bannerImage,
                    imageurl: imageurl
                }

                this.showBannerImage = true;
                this.showTileImage = false;

            } else if (this.categoryData?.tileImage) {

                var imageurl = this.categoryData?.tileImage?.url.startsWith('/cms') ?
                    '/sfsites/c' + this.categoryData?.tileImage?.url :
                    this.categoryData?.tileImage?.url;

                //Adding prefix url for externally hosted domain
                this.categoryBanner = {
                    ...this.categoryData?.tileImage,
                    imageurl: imageurl
                }


                this.showTileImage = true;
                this.showBannerImage = false;
            }
            else {
                this.showTileImage = false;
                this.showBannerImage = false;

            }

            if (this.categoryData?.fields?.Description) {
                this.categoryDescription = this.categoryData?.fields?.B2B_Category_Description__c;
                this.showCategoryDescription = true;
            } else {
                this.showCategoryDescription = false;
            }
            this.isLoading = false;
        } else {

        }
    }
}