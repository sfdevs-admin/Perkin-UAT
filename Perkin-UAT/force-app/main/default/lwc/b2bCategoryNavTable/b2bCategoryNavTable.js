import { api, LightningElement, wire } from 'lwc';
import fetchChildCategories from "@salesforce/apex/B2B_CategoryNavTableController.fetchChildCategories";
import { NavigationMixin, NavigationContext, navigate } from 'lightning/navigation';
export default class B2bCategoryNavTable extends NavigationMixin(LightningElement) {

    categoryId;
    categoryWrapperList = [];
    isLoading = true;
    _recordId;
    @api
    get recordId(){
        return this._recordId;
    }
    set recordId(value){
        // console.log('B2bCategoryNavTable recordId--- ', value);
        if(value){
            this._recordId = value;
            this.categoryId = value;
            if( this.categoryId ){
                this.callFetchChildCategories();
            }
        }
    }

    async callFetchChildCategories() {
        if ( this.categoryId ) {
            let mapParams = {};
            mapParams.categoryId = this.categoryId;
            fetchChildCategories({
                'mapParams': mapParams
            }).then(( res ) => {
                let response = JSON.parse(JSON.stringify( res ));
                // console.log('B2bCategoryNavTable fetchChildCategories is success---- ' + JSON.stringify( response ));
                if ( response.isSuccess ) {
                    if ( response.categoryWrapperList ) {
                        this.categoryWrapperList = response.categoryWrapperList;
                        this.isLoading = false;
                    }
                } else {
                    //show no data found error
                    this.isLoading = false;
                    console.log('B2bCategoryNavTable fetchChildCategories is success false---- ' + JSON.stringify(res));
                }
            }).catch((e) => {
                this.isLoading = false;
            });
        }
    }

    handleNavigateToCategory( event ) {
        const { categoryId, urlName } = event.detail;
        if (urlName) {
            // Navigate with SEO-friendly URL
            navigate(this.navContext, {
                type: 'standard__webPage',
                attributes: {
                    url: `/category/${urlName}`
                }
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: 'ProductCategory',
                    actionName: 'view',
                    recordId: categoryId
                }
            });
        }
    }

    @wire(NavigationContext)
    navContext;

}