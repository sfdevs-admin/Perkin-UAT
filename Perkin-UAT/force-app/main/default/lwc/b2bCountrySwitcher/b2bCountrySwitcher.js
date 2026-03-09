import { LightningElement, api, track } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import userId from '@salesforce/user/Id';
import B2BLightningModal from 'c/b2BLightningModal';
import b2bShowDisclaimerMessage from 'c/b2bShowDisclaimerMessage';
import Toast from 'lightning/toast';
import { NavigationMixin } from 'lightning/navigation';
import getGuestLocaleMetadataRecords from '@salesforce/apex/B2B_CountrySwitcherController.getGuestLocaleMetadataRecords';
import updateLoggedInUserDetails from '@salesforce/apex/B2B_CountrySwitcherController.updateLoggedInUserDetails';
import getLoggedInUserBG from '@salesforce/apex/B2B_CountrySwitcherController.getLoggedInUserBG';
import LightningAlert from "lightning/alert";
import getPromotionBGInfo from '@salesforce/apex/B2B_CountrySwitcherController.getPromotionBGInfo';
import B2B_IP_Address_URL from '@salesforce/label/c.B2B_IP_Address_URL';
import B2B_Guest_User_Details_URL from '@salesforce/label/c.B2B_Guest_User_Details_URL';
import B2B_Site_URL_Default_Pathname from '@salesforce/label/c.B2B_Site_URL_Default_Pathname';
import B2B_Site_US_Locale from '@salesforce/label/c.B2B_Site_US_Locale';

export default class B2bCountrySwitcher extends NavigationMixin(LightningElement) {
    label = {
        B2B_IP_Address_URL,
        B2B_Guest_User_Details_URL,
        B2B_Site_URL_Default_Pathname,
        B2B_Site_US_Locale
    };

    @api alertTitle;
    @api alertMessage;
    @api alertTheme;

    guestIpAddress='';
    guestDetails;
    value='';
    mapParams = {};
    currentPageReference;
    guestUserDetailsURL = '';
    countrySelectorLabel='';
    metadataRecords;
    pageReloaded = false;
    marketList = [];
    path;
    locale;
    showSpinner=false;
    @track ipAddress = ''; 

    async connectedCallback(){
        this.fetchGuestAndLoggedInUsersDetails();
    }

    fetchGuestAndLoggedInUsersDetails() {
        let pathName = window.location.pathname;
        this.path = this.cleanPath(pathName);
        this.locale = this.getLocaleFromPath();
        
        if(isGuest){

            if (localStorage.getItem('userID')) {
                localStorage.removeItem('userID');
                localStorage.removeItem('selectedCountry');
            }
            
            if(window.localStorage.length == 0 || !localStorage.getItem('selectedCountry')){
                // For guest users do not show pop up use the IP address api to fetch country and stored on localstorage
                this.fetchGuestUserLocation();

            }
            else{
                if(!localStorage.getItem('reloaded')){
                    if(!window.location.pathname.includes(localStorage.getItem('currentUserLocale'))){
                        this.countrySelectorLabel = localStorage.getItem('currentCountryLabel');
                        let url = window.location.origin + this.label.B2B_Site_URL_Default_Pathname + localStorage.getItem("currentUserLocale") + '/' + this.path;
                        window.location.href = url;
                        localStorage.setItem('reloaded',true);
                    }
                    else{
                        this.countrySelectorLabel = localStorage.getItem('currentCountryLabel');
                    }
                }
                else if(localStorage.getItem('reloaded') && !window.location.pathname.includes(localStorage.getItem('currentUserLocale')) && this.locale != this.label.B2B_Site_US_Locale){
                    if(this.locale){
                        this.countrySelectorLabel = localStorage.getItem('currentCountryLabel');
                        window.location.href = window.location.origin + this.label.B2B_Site_URL_Default_Pathname + localStorage.getItem("currentUserLocale") + '/' + this.path;
                    }
                    else{
                        this.countrySelectorLabel = localStorage.getItem('currentCountryLabel');
                    }
                    
                }
                else{
                    this.countrySelectorLabel = localStorage.getItem('currentCountryLabel');
                }
                
            }
        }
        else{
            localStorage.setItem('userID', userId);// added

            if(!(window.location !== window.parent.location)){
                let obj1 = {};
                obj1.userId = userId;
                getLoggedInUserBG({mapParams : obj1} )
                .then( data=> {
                    console.log('data on 257',data);
                    if(data.isSuccess){
                        if(localStorage.getItem('selectedCountry') || localStorage.getItem('currentUserLocale')){
                            let updatedUserLocale = localStorage.getItem('currentUserLocale');
                            updatedUserLocale = updatedUserLocale.replace('-','_');

                            if(data.currentAccountBG.B2B_Country_Code__c != localStorage.getItem('selectedCountry') ||
                                data.currentUser.LocaleSidKey != updatedUserLocale){

                                this.showSpinner=true;
                                let mapParams = {};
                                // mapParams.country = localStorage.getItem('selectedCountry');
                                mapParams.country = data.currentAccountBG.B2B_Country_Code__c; //added new change
                                getGuestLocaleMetadataRecords({mapParams : mapParams})
                                .then(data => {
                                    if(data.isSuccess){
                                        let obj = {};
                                        obj.userId = userId;
                                        obj.metadataRecord = data.countrySwitcherRecords[0];
                                        // obj.deleteCurrentCart = true;
                                        obj.deleteCurrentCart = false;
                                        setTimeout(() => {
                                            updateLoggedInUserDetails({mapParams : obj})
                                            .then(data => {
                                                console.log('data on 263',data);
                                                if(data.isSuccess){
                                                    localStorage.setItem("selectedCountry", data.metadataRecord.Country_Code__c);
                                                    localStorage.setItem("currentUserLocale", data.metadataRecord.Locale__c);
                                                    localStorage.setItem("currentSalesOrg", data.metadataRecord.Sales_Org__c);
                                                    localStorage.setItem("currentCountryLabel", data.metadataRecord.MasterLabel);
                                                    this.countrySelectorLabel = localStorage.getItem('currentCountryLabel');
                                                    this.showSpinner=false;

                                                    window.location.href = window.location.origin + this.label.B2B_Site_URL_Default_Pathname + localStorage.getItem("currentUserLocale") + '/' + this.path;
                                                    // this.showDisclaimer();
                                                    // window.location.href = window.location.href;
                                                }
                                                else{
                                                    this.showSpinner=false;
                                                }
                                            })
                                            .catch(error => {
                                                console.log('error',error);
                                            });
                                        }, "2000");
                                    }
                                    else{
                                        this.showSpinner=false;
                                    }
                                })
                                .catch(error => {
                                    console.log('error on 297',error);
                                }); 

                            }
                            else{
                                console.log('Do not update Buyer Group');
                                this.countrySelectorLabel = localStorage.getItem('currentCountryLabel');
                                if(!window.location.pathname.includes(localStorage.getItem('currentUserLocale')) && this.locale != this.label.B2B_Site_US_Locale){
                                    if(this.locale){
                                        this.countrySelectorLabel = localStorage.getItem('currentCountryLabel');
                                        window.location.href = window.location.origin + this.label.B2B_Site_URL_Default_Pathname + localStorage.getItem("currentUserLocale") + '/' + this.path;
                                    }
                                    else{
                                        this.countrySelectorLabel = localStorage.getItem('currentCountryLabel');
                                    }
                                    
                                }
                                else{
                                    this.countrySelectorLabel = localStorage.getItem('currentCountryLabel');
                                }
                            }
                        }
                        else{
                            this.showSpinner=true;
                            let mapParams = {};
                            mapParams.country = data.currentAccountBG.B2B_Country_Code__c;
                            getGuestLocaleMetadataRecords({mapParams : mapParams})
                            .then(data => {
                                if(data.isSuccess){
                                    this.setLocalStorageValues(data);
                                    this.countrySelectorLabel = localStorage.getItem('currentCountryLabel');
                                    this.showSpinner=false;
                                    window.location.href = window.location.origin + this.label.B2B_Site_URL_Default_Pathname + localStorage.getItem("currentUserLocale") + '/' + this.path;
                                }
                                else{
                                    this.showSpinner=false;
                                }
                            })
                            .catch(error => {
                                console.log('error on 265',error);
                                this.showSpinner=false;
                            }); 
                        }
                    }
                })
                .catch( error => {
                    // this.showSpinner=false;
                });
            }
  
        }
    }

    async handleClick() {

        if(isGuest){
            const result = B2BLightningModal.open({
                size: 'medium',
                label: 'My Modal Title',
                description: 'This is a description'
            });
            console.log('result:',result);
        }else{
            //Promotions: Check if the Account is part of customer specific promotion buyer group
            let obj = {};
            obj.userId = userId;
            await getPromotionBGInfo({mapParams : obj} )
            .then(data=> {
                console.log('getPromotionBGInfo Result: ', data);
                if(data.isSuccess){
                    if(data.assignedToPromotionBG) {
                        //If Yes, show pop-up that you are not allowed to switch countries
                        LightningAlert.open({
                            message: this.alertMessage,
                            theme: this.alertTheme,
                            label: this.alertTitle
                        });
                    }
                    //Else proceed with below exisiting logic.
                    else {
                        const result = B2BLightningModal.open({
                            size: 'medium',
                            label: 'My Modal Title',
                            description: 'This is a description'
                        });
                        console.log('result:',result);
                    }
                }
            })
            .catch(error => {
                console.error('Error in getPromotionBGInfo: ', error);
            })
            // if modal closed with X button, promise returns result = 'undefined'
            // if modal closed with OK button, promise returns result = 'okay'
        }
        
    }

    async showDisclaimer() {
        const result = await b2bShowDisclaimerMessage.open({
            size: 'medium',
            label: 'My Modal Title',
            description: 'This is a description'
        });
        console.log('result:',result);
        if(result == 'Proceed'){
            window.location.href = window.location.href;
        }
    }

    cleanPath(path) {
        // Remove '/store/' if it exists
        let cleanedPath = path.replace('/store/', '');
    
        // Remove leading slash if present
        if (cleanedPath.startsWith('/')) {
            cleanedPath = cleanedPath.slice(1);
        }
    
        // Remove locale if present at the beginning
        const localeRegex = /^[a-z]{2}(-[A-Z]{2})?\//;
        cleanedPath = cleanedPath.replace(localeRegex, '');
    
        return cleanedPath;
    }        

    getLocaleFromPath() {
        const path = window.location.pathname; // e.g. /store/zh-CN/products or /zh-CN/products
        const segments = path.split('/').filter(Boolean);
        const localeRegex = /^[a-z]{2}(-[A-Z]{2})?$/;
        const locale = segments.find(seg => localeRegex.test(seg));
        return locale || null;
    }

    // for guest users do not open modal

    async fetchGuestUserLocation() {
        let geoData;
        try {
            // Step 1: Get guest user IP
            const ipResponse = await fetch(B2B_IP_Address_URL);
            if (!ipResponse.ok) throw new Error('Failed to fetch IP');
            this.ipAddress = await ipResponse.text();

            // Step 2: Get geo info using IP
            const geoResponse = await fetch(`${B2B_Guest_User_Details_URL}${this.ipAddress}/json`);
            if (!geoResponse.ok) throw new Error('Failed to fetch geo info');

            geoData = await geoResponse.json();

            console.log('geoData:', geoData);

            //Step 3: Update the Local storage as per metadata for country code
            // this.getGuestLocalMetadataInfo(geoData);
        } catch (err) {
            console.error(err);
            this.error = err.message;
        } finally {
            // Always runs, even if fetch fails
            let countryCode = geoData?.country ?? 'US';
            this.getGuestLocalMetadataInfo(countryCode);
        }
    }

    getGuestLocalMetadataInfo(countryCode) {
        let mapMetadataParams = {};
        mapMetadataParams.country = countryCode;

        getGuestLocaleMetadataRecords({ mapParams: mapMetadataParams })
            .then(data => {
                console.log('data', data);
                if(data.isSuccess){
                    this.setLocalStorageValues(data);
                    window.location.href = window.location.origin + this.label.B2B_Site_URL_Default_Pathname + localStorage.getItem("currentUserLocale") + '/' + this.path;
                } else {
                    let mapMetadataParams = {};
                    mapMetadataParams.country = 'US';

                    getGuestLocaleMetadataRecords({ mapParams: mapMetadataParams })
                        .then(data => {
                            if(data.isSuccess){
                                this.setLocalStorageValues(data);
                                window.location.href = window.location.origin + this.label.B2B_Site_URL_Default_Pathname + localStorage.getItem("currentUserLocale") + '/' + this.path;
                            }
                    })
                }
            })
            .catch(error => {
                console.log('error on 245',error);
            });
    }

    setLocalStorageValues(data) {
        localStorage.setItem("selectedCountry", data.countrySwitcherRecords[0].Country_Code__c);
        localStorage.setItem("currentUserLocale", data.countrySwitcherRecords[0].Locale__c);
        localStorage.setItem("currentSalesOrg", data.countrySwitcherRecords[0].Sales_Org__c);
        localStorage.setItem("currentCountryLabel", data.countrySwitcherRecords[0].MasterLabel);
    }

}