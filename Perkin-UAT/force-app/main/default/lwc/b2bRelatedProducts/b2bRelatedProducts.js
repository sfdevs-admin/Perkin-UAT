import { LightningElement, wire, api, track } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import glider from '@salesforce/resourceUrl/glider';
import getRelatedProducts from '@salesforce/apex/B2B_RelatedProductController.getRelatedProducts';
import { ProductAdapter, ProductCollectionAdapter } from 'commerce/productApi';
import { CurrentPageReference } from 'lightning/navigation';
import MAIN_TEMPLATE from "./b2bRelatedProducts.html";
import STENCIL from "./b2bRelatedProductsStencil.html";
//labels
import RELATED_HEADER from '@salesforce/label/c.B2B_PDP_RelatedTabHeader';
import TOP_HEADER from '@salesforce/label/c.B2B_Home_TopSellerHeader';
import PRODUCTS_HEADER from '@salesforce/label/c.B2B_PDP_RelatedProductsTabHeader';
import SELLERS_HEADER from '@salesforce/label/c.B2B_Home_TopSellerProductsHeader';

export default class B2bRelatedProducts extends LightningElement {
    static renderMode = "light"; // the default is 'shadow'
    @api productId;
    productData;
    tempProductListData;
    @track featuredProdIdList;
    displayView = false;
    isLoading = true;
    @api isPDP;
    isHomePage = false;
    productIds;
    chunkSize = 20;
    lastItemIndex = 0;

    fieldsList = ["Name", "StockKeepingUnit", "CAS__c", "B2B_Part_Number__c", "Is_B2B_Product__c", "B2B_Brand_Name__c", "B2B_Display_Name__c", "B2B_Item_Class_Description__c"];
    completeProductIdList = [];
    // render() {
    //     if (this.isLoading) {
    //         return STENCIL;
    //     } else {
    //         return MAIN_TEMPLATE;
    //     }
    // }

    get showCmp() {
        return this.featuredProdIdList?.length > 0;
    }

    get HeaderVal() {
        if (this.isPDP) {
            return RELATED_HEADER;
        } else {
            // return 'Featured';
            return TOP_HEADER;
        }
    }

    get HeaderVal2(){
        if (this.isPDP) {
            return PRODUCTS_HEADER;
        } else {
            // return 'Featured';
            return SELLERS_HEADER;
        }
    }


    @wire(CurrentPageReference)
    getPageRef(res) {
        
        if (res.attributes.recordId) {
            this.productId = res.attributes.recordId;
        }
        else if (res.attributes.name === 'Home') {
            console.log('B2bRelatedProducts CurrentPageReference res------- ' + JSON.stringify(res));
            this.isHomePage = true;
            this.callGetFeaturedProduct();
        }
    }

    @wire(ProductAdapter, { productId: '$productId' })
    getProdDetails({ error, data }) {
        if (error) {
            console.log('B2bRelatedProducts getProdDetails error exception----- ' + JSON.stringify(error));
        } else {
            if (data != undefined) {
                
                this.productData = data;
                this.callGetFeaturedProduct();
            }
        }
    }

    @wire(ProductCollectionAdapter, { ids: '$productIds', fields: '$fieldsList' })
    getProductList({ error, data }) {

       

        if (error) {
            console.log('getProductList----- ' + JSON.stringify(error));
        } else {
            if (data != undefined) {
                //take the products into temp list
                this.tempProductListData = this.tempProductListData ? this.tempProductListData : [];
                //add fresh fetched products
                this.tempProductListData = [...this.tempProductListData,
                ...data.products.filter(product => product.success)];

                //Need to chunk - as ConnectAPi has limit for 20 product ids so will call the wire adapter for every
                //20 items & add it in a list
                var tempProdIds = this.completeProductIdList.slice(this.lastItemIndex,
                    this.lastItemIndex + this.chunkSize);
                if (tempProdIds.length > 0) {
                    this.productIds = tempProdIds;
                    this.lastItemIndex = this.lastItemIndex + this.chunkSize;
                } else {
                    this.featuredProdIdList = this.tempProductListData;
                    //load the script
                    this.loadGliderJS();
                }

            }
        }
    }

    async loadGlider() {
        let tempThis = this;
        await loadStyle(tempThis, glider + '/Glider.js-master/glider.min.css');
        await loadScript(tempThis, glider + '/Glider.js-master/glider.min.js').then(() => {
            //this.isLoading = false;
            const el = this.querySelector('.glider'); //this.template.querySelector('.glider');
            let glider = new Glider(el, {
                // Mobile first
                slidesToShow: 'auto',
                slidesToScroll: 'auto',
                itemWidth: 350,
                duration: 0.25,
                draggable: true,
                // scrollLock: true,
                // scrollPropagate: false,
                // eventPropagate: true,
                arrows: {
                    prev: this.querySelector('.glider-prev'),
                    next: this.querySelector('.glider-next') 
                },
                responsive: [
                    {
                        // screens greater than >= 775px
                        breakpoint: 1024,
                        settings: {
                            // Set to `auto` and provide item width to adjust to viewport
                            slidesToShow: 'auto',
                            slidesToScroll: 'auto',
                            itemWidth: 300,
                            duration: 0.25
                        }
                    }
                ]
            });
            this.isLoading = false;
        });
    }

    async callGetFeaturedProduct() {
        if (this.productData || this.isHomePage) {
            let mapParams = {};
            mapParams.productId = this.productId;
            mapParams.isHomePage = this.isHomePage;
            getRelatedProducts({
                'mapParams': mapParams
            }).then((res) => {
                let response = JSON.parse(JSON.stringify(res));
                if (res.isSuccess) {
                    if (response.relatedProductList) {
                        //this.featuredProdIdList = response.relatedProductList;
                        this.productIds = [];
                        this.lastItemIndex = 0;
                        this.tempProductListData = [];
                        this.featuredProdIdList = [];
                        //Add ids of product whose details to be fetched from wire
                        this.completeProductIdList = response.relatedProductList;
                        this.displayView = true;

                        this.productIds = response.relatedProductList.slice(this.lastItemIndex, this.chunkSize);
                        this.lastItemIndex = this.chunkSize;
                    }
                } else {
                    //show no data found error
                    this.displayView = false;
                    this.isLoading = false;
                    console.log('B2bRelatedProducts getRelatedProducts is success false---- ' + JSON.stringify(res));
                }
            }).catch((e) => {
                this.displayView = false;
                this.isLoading = false;
            });
        }
    }
    loadGliderScript() {
        let tempThis = this;
        window.setTimeout(function () {
            tempThis.loadGliderJS();
        }, 1000);

    }

    async loadGliderJS() {
        try {
            this.isLoading = false;
            await this.loadGlider();
        } catch (e) {
            this.displayView = false;
            console.log('B2bRelatedProducts renderedCallback exception error--- ' + e);
        }
    }

}