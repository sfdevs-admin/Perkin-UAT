import { api, LightningElement, wire } from 'lwc';
import { ProductCategoryAdapter } from 'commerce/productApi';
import { navigate, NavigationContext,NavigationMixin } from 'lightning/navigation';
/**
 * @slot categoryTable ({ locked: false})
 * @slot searchResultLayout ({ locked: false})
 */
export default class B2bCategoryPage extends NavigationMixin(LightningElement) {


    get showSearchResultLayout(){
        let isPreview = false; //this.isInSitePreview();
        if( isPreview ){
            return true;
        }else{
            return this.hideProducts ?? true;
        }
    }

    get showCategoryTable(){
        let isPreview = false; //this.isInSitePreview();
        if( isPreview ){
            return true;
        }else{
            return ! this.hideProducts ?? false;
        }
    }

    hideProducts = false;
    categoryDataObj;
    categoryId;
    _recordId;
    @api 
    get recordId(){
        return this._recordId;
    }
    set recordId(value){
        console.log('B2bCategoryPage recordId--- ', value);
        if(value){
            this._recordId = value;
            this.categoryId = value;
        }
    }

    @wire(ProductCategoryAdapter, {
        categoryId: '$categoryId',
    })
    wiredProductCategoryAdapter({ data }) {
        if (data) {
            console.log('B2bCategoryPage wiredProductCategoryAdapter data--- ', data);
            this.categoryDataObj = data;
            let categoryData = data;
            if( categoryData && categoryData.fields ){
                let categoryFields = categoryData.fields;

                //check is navigation category
                if( categoryFields?.B2B_Navigation__c && categoryFields?.B2B_Navigation__c === 'true' ){
                    this.navigateToContactUsPage();
                }else{

                }

                if( categoryFields?.B2B_Hide_Products__c && categoryFields?.B2B_Hide_Products__c === 'true' ){
                    this.hideProducts = true;
                }else{
                    this.hideProducts = false;
                }
            }
        } else{

        }
    }

    @wire(NavigationContext)
    navContext;

    navigateToContactUsPage(){
        console.log('B2bCategoryPage navigateToContactUsPage- ');
        let redirectToPage;
        if(this.categoryDataObj){
            redirectToPage = this.categoryDataObj?.fields?.B2B_Redirect_To_Page__c ?? 'ContactUs__c';
        }
        this.navContext &&
        navigate(this.navContext, {
            type: 'comm__namedPage',
            attributes: {
                name: redirectToPage,
            },
        });
    }

    isInSitePreview() {
        let url = document.URL;
        return (url.indexOf('sitepreview') > 0
            || url.indexOf('livepreview') > 0
            || url.indexOf('live-preview') > 0
            || url.indexOf('live.') > 0
            || url.indexOf('.builder.') > 0);
    }
}