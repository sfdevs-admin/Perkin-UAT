import { wire } from 'lwc';
import LightningModal from 'lightning/modal';
import {deleteCurrentCart} from 'commerce/cartApi';
import { CartSummaryAdapter } from 'commerce/cartApi';
import isGuest from '@salesforce/user/isGuest';
import userId from '@salesforce/user/Id';
import Toast from 'lightning/toast';
import getCountrySelectorMetadataRecords from '@salesforce/apex/B2B_CountrySwitcherController.getCountrySelectorMetadataRecords';
import getGuestLocaleMetadataRecords from '@salesforce/apex/B2B_CountrySwitcherController.getGuestLocaleMetadataRecords';
import updateLoggedInUserDetails from '@salesforce/apex/B2B_CountrySwitcherController.updateLoggedInUserDetails';
import B2B_Modal_First_Header from '@salesforce/label/c.B2B_Modal_First_Header';
import B2B_Modal_Second_Header from '@salesforce/label/c.B2B_Modal_Second_Header';
import B2B_Modal_Third_Header from '@salesforce/label/c.B2B_Modal_Third_Header';
import B2B_Modal_Body_Text_One from '@salesforce/label/c.B2B_Modal_Body_Text_One';
import B2B_Modal_Body_Text_Two from '@salesforce/label/c.B2B_Modal_Body_Text_Two';
import B2B_Modal_Continue_Button from '@salesforce/label/c.B2B_Modal_Continue_Button';
import B2B_Modal_Back_Button from '@salesforce/label/c.B2B_Modal_Back_Button';
import B2B_Modal_Cancel_Button from '@salesforce/label/c.B2B_Modal_Cancel_Button';
import B2B_Site_URL_Default_Pathname from '@salesforce/label/c.B2B_Site_URL_Default_Pathname';
import B2B_TOAST_ERROR from '@salesforce/label/c.B2B_Toast_Error';

export default class B2BLightningModal extends LightningModal {

    regions = [
        {
            id: 'region-1',
            countries: Array.from({ length: 12 }, (_, index) => ({ id: `emea-${index}` }))
        },
        {
            id: 'region-2',
            countries: Array.from({ length: 2 }, (_, index) => ({ id: `na-${index}` }))
        },
        {
            id: 'region-3',
            countries: Array.from({ length: 8 }, (_, index) => ({ id: `apac-${index}` }))
        },
        {
            id: 'region-4',
            countries: Array.from({ length: 3 }, (_, index) => ({ id: `latam-${index}` }))
        }
    ];

    customLabels = {
        B2B_Modal_First_Header,
        B2B_Modal_Second_Header,
        B2B_Modal_Third_Header,
        B2B_Modal_Body_Text_One,
        B2B_Modal_Body_Text_Two,
        B2B_Modal_Continue_Button,
        B2B_Modal_Back_Button,
        B2B_Modal_Cancel_Button,
        B2B_Site_URL_Default_Pathname,
        B2B_TOAST_ERROR
    };

    contentArray=[];
    regionToCountries={};
    countryToCurrency={};
    metadataRecord={};
    // activeSections = [];
    localeList = [];
    processedLocaleList = [];
    localeSelected=false;
    countrySelected=false;
    isLoading=true;
    isFinalScreenLoading=false;
    localeSelectedLabel;
    countrySelectedLabel;
    cartSummary;
    cartId;
    path;
    // singleMap = new Map();

    get gridClass() {
        return this.localeList && this.localeList.length === 1
            ? 'slds-grid slds-grid_vertical-align-center slds-grid_align-center'
            : 'slds-grid slds-wrap slds-gutters';
    }

    @wire(CartSummaryAdapter)
    wiredCartSummary({ data, error }) {
        if (data) {
            this.cartSummary = data;
            console.log('Cart Summary:', JSON.stringify(this.cartSummary));
            this.cartId = this.cartSummary.cartId;
            console.log('cartId:', this.cartId);
        } else if (error) {
            this.error = error;
            console.error('Error fetching cart summary:', error);
        }
    }

    async connectedCallback(){
        let pathName = window.location.pathname;
        this.path = this.cleanPath(pathName);
        console.log('path: ',this.path);

        try {
            console.log('custom label: ',this.customLabels.B2B_Modal_First_Header);
            getCountrySelectorMetadataRecords()
                .then(data => {
                    if(data.isSuccess){
                        this.isLoading=false;
                        console.log('data: ',data);
                        this.contentArray = data.countrySelectorRecords;
                        // this.regionToCountries = data.regionToCountriesMap;
                        console.log('regionToCountries',this.regionToCountries);
                        this.regionToCountries = Object.keys(data.regionToCountriesMap).map(region => ({
                            key: region,
                            value: data.regionToCountriesMap[region]
                        }));
                        console.log('regionToCountries',this.regionToCountries);
                        // this.activeSections = Object.keys(data.regionToCountriesMap);

                        this.countryToCurrency = Object.fromEntries(
                            Object.entries(data.countryToCurrencyMap).map(([country, currency]) => [country, currency])
                        );
                        console.log('countryToCurrency',this.countryToCurrency);
                        // this.contentArray.forEach(item => {
                        //     this.singleMap.set(item.Id, item);
                        // });
                        // console.log('singleMap',this.singleMap);
                    }
                    else{
                        Toast.show({
                            label: this.customLabels.B2B_TOAST_ERROR,
                            message: data.message,
                            variant: 'error',
                            mode: 'sticky'
                        });
                    }
                })
                .catch(error => {
                    console.log('error: ',error);
                });
            } catch (error) {
                console.error("Error fetching data:", error);
            }
    }

    handleClose() {
        this.close('okay');
    }

    handleCountry(event){
        this.countrySelected=true;
        this.countrySelectedLabel = event.target.innerText;
        console.log('this.countrySelectedLabel',this.countrySelectedLabel);
        for (const [key, value] of Object.entries(this.countryToCurrency)) {
            // console.log(`Checking key: "${key}" against selected: "${this.countrySelectedLabel}"`);
            if(this.countrySelectedLabel === key){
                // console.log('country found');
                this.localeList = value;
            }    
        }

        if(this.localeList){
            this.processLocaleList();
        }
        console.log('this.localeList',this.localeList);
        console.log('this.processedLocaleList',this.processedLocaleList);
    }

    // handleClick(event){
    //     this.localeSelected=true;
    //     this.localeSelectedLabel = event.target.innerText;

    //     this.contentArray.forEach(item => {
    //         if(this.localeSelectedLabel.includes(item.MasterLabel)){
    //             this.metadataRecord = item;
    //         }
    //     });
    //     // const id = event.currentTarget.dataset.id;
    //     // this.metadataRecord = this.singleMap.get(id);
    //     console.log('metadataRecord: ',this.metadataRecord);
    // }

    async handleClick(event) {
        this.isFinalScreenLoading=true;
        this.countrySelected = false;
        this.localeSelected = true;
        this.localeSelectedLabel = event.currentTarget.innerText;
        console.log("handleClick event", event);
        console.log("Processing Click for:", this.localeSelectedLabel);

        for (const item of this.contentArray) {
            if (this.localeSelectedLabel.includes(item.MasterLabel)) {
                this.metadataRecord = item;
                break; 
            }
            // Optional: Simulate async behavior (remove if not needed)
            await new Promise(resolve => setTimeout(resolve, 100)); 
        }
        
        if(this.metadataRecord){
            this.isFinalScreenLoading=false;
            // this.localeSelected = true;
            console.log('metadataRecord:', this.metadataRecord);
        }
        
    }

    handleContinue(){
        // this.handleClose();
        this.isFinalScreenLoading=true;
        console.log('metadata in handleContinue: ',this.metadataRecord);
        if(isGuest){
            if(this.cartId){
                deleteCurrentCart()
                .then(result => {
                    console.log('cart delete result ',result);
                    this.processCountrySwitchForGuest();
                })
                .catch(error => {
                    console.log('cart delete error ',JSON.stringify(error));
                });
            }
            else{
                this.processCountrySwitchForGuest();
            }
        }
        else{
            if(this.cartId){
                deleteCurrentCart()
                .then(result => {
                    console.log('cart delete result logged in user',result);
                    this.processCountrySwitchForLoggedInUser();
                })
                .catch(error => {
                    console.log('cart delete error logged in user',JSON.stringify(error));
                });
            }
            else{
                this.processCountrySwitchForLoggedInUser();
            }
        }   
    }

    handleCancel(){
        this.handleClose();
    }

    processLocaleList() {
        this.processedLocaleList = this.localeList.map(country => {
            let parts = country.split(' - ');
            return {
                country: country,
                mainText: parts[0],
                currencyText: parts.length > 1 ? parts[1] : '' 
            };
        });
    }

    handleBack(){
        this.countrySelected = false;
        this.localeSelected = false;
    }

    processCountrySwitchForGuest(){
        localStorage.setItem("selectedCountry", this.metadataRecord.Country_Code__c);
        localStorage.setItem("currentUserLocale", this.metadataRecord.Locale__c);
        localStorage.setItem("currentSalesOrg", this.metadataRecord.Sales_Org__c);
        localStorage.setItem("currentCountryLabel", this.metadataRecord.MasterLabel);
        window.location.href = window.location.origin + this.customLabels.B2B_Site_URL_Default_Pathname + localStorage.getItem("currentUserLocale") + '/' + this.path;
    }

    processCountrySwitchForLoggedInUser(){
        let mapParams = {};
        mapParams.userId = userId;
        mapParams.metadataRecord = this.metadataRecord;
        mapParams.deleteCurrentCart = false;
        updateLoggedInUserDetails({mapParams : mapParams})
        .then(data => {
            console.log('data on 64',data);
            if(data.isSuccess){
                localStorage.setItem("selectedCountry", this.metadataRecord.Country_Code__c);
                localStorage.setItem("currentUserLocale", this.metadataRecord.Locale__c);
                localStorage.setItem("currentSalesOrg", this.metadataRecord.Sales_Org__c);
                localStorage.setItem("currentCountryLabel", this.metadataRecord.MasterLabel);
                localStorage.setItem('localeInsertedForLoggedInUser', 'true');
                window.location.href = window.location.origin + this.customLabels.B2B_Site_URL_Default_Pathname + localStorage.getItem("currentUserLocale") + '/' + this.path;
            }
            else{
                Toast.show({
                    label: this.customLabels.B2B_TOAST_ERROR,
                    message: data.message,
                    variant: 'error',
                    mode: 'sticky'
                });
                let mapParams = {};
                mapParams.country = 'US';
                getGuestLocaleMetadataRecords({mapParams : mapParams})
                .then(data => {
                    if(data.isSuccess){
                        localStorage.setItem("selectedCountry", data.countrySwitcherRecords[0].Country_Code__c);
                        localStorage.setItem("currentUserLocale", data.countrySwitcherRecords[0].Locale__c);
                        localStorage.setItem("currentSalesOrg", data.countrySwitcherRecords[0].Sales_Org__c);
                        localStorage.setItem("currentCountryLabel", data.countrySwitcherRecords[0].MasterLabel);
                        window.location.href = window.location.origin + this.customLabels.B2B_Site_URL_Default_Pathname + '/' + this.path;
                        this.countrySelectorLabel = localStorage.getItem('currentCountryLabel');
                    }
                })
                .catch(error => {
                    console.log('error on 245',error);
                });  
            }
        })
        .catch(error => {
            console.log('error',error);
        });
    }

    cleanPath(path) {
        // Step 1: Remove '/store/' if it exists
        let cleanedPath = path.replace('/store/', '');


        // Remove leading slash if present - added here
        if (cleanedPath.startsWith('/')) {
            cleanedPath = cleanedPath.slice(1);
        }

        // Step 2: Remove locale if path now starts with something like 'en-CA/'
        const localeRegex = /^[a-z]{2}(-[A-Z]{2})?\//;
        cleanedPath = cleanedPath.replace(localeRegex, '');
    
        return cleanedPath;
    }
}