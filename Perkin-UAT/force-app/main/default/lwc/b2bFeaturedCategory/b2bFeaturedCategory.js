import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin, NavigationContext, navigate } from 'lightning/navigation';
import getFeaturedCategories from '@salesforce/apex/B2BFeaturedCategoryController.getFeaturedCategories';
import mainTemplate from "./b2bFeaturedCategory.html";
import stencilTemplate from "./b2bFeaturedCategoryStencil.html";

export default class B2bFeaturedCategory extends NavigationMixin(LightningElement) {

    @api headingLabel;
    mapParamsInput = {};
    featuredCategories = [];
    categories = [];
    error;
    isLoading = true;

    @wire(getFeaturedCategories, {
        mapParams: '$mapParamsInput',
    })
    wiredFeaturedCategories({ error, data }) {
        if (data) {
            if(data.isSuccess){
                let categoriesData = data.featuredCategories;
                this.categories = categoriesData.map(category => ({
                    id: category.Id,
                    name: category.Name
                }));
                this.error = undefined;
            }
            setTimeout(() => {
                this.isLoading = false;
            },1000)
        } else if (error) {
            this.error = error?.message || 'Error fetching featured categories';
            this.categories = [];
            this.featuredCategories = [];
            this.isLoading = false;
            console.error('Error fetching featured categories:', error);
        }
    }

    handleCategoryLoaded(event) {
        const categoryData = event.detail;
        this.featuredCategories = [...this.featuredCategories, categoryData];

        this.featuredCategories.sort((a, b) => {
            const indexA = this.categories.findIndex(cat => cat.id === a.id);
            const indexB = this.categories.findIndex(cat => cat.id === b.id);
            return indexA - indexB;
        });
    }

    handleCategoryClick(event) {
        const categoryId = event.currentTarget.dataset.id;
        const categoryUrlName = event.currentTarget.dataset.urlname ?? undefined;
        const categoryName = event.currentTarget.dataset.name;
        if (categoryUrlName) {
            // Navigate with SEO-friendly URL
            navigate(this.navContext, {
                type: 'standard__webPage',
                attributes: {
                    url: `/category/${categoryUrlName}`
                },
                state: {
                    recordName: categoryName
                }
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: 'ProductCategory',
                    actionName: 'view',
                    recordId: categoryId,
                }
            });
        }

    }

    render() {
        if(this.isLoading){
            return stencilTemplate;
        }else{
            return mainTemplate;
        }
    }

    @wire(NavigationContext)
    navContext;
}