/* ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
 * Summary :       This is the JS controller for component.
 * ─────────────────────────────────────────────────────────────────────────────────────────────────────────────
 * @author         (PwC)Deepak Rajan <deepak.rajan.ext@perkinelmer.com>
 * @createdBy      (PwC)Deepak Rajan <deepak.rajan.ext@perkinelmer.com>
 * @maintainedBy   (PwC)Deepak Rajan <deepak.rajan.ext@perkinelmer.com>
 * @version        1.0
 * @createdDate    31-08-2021
 * @modified
 * @systemLayer    JS
 * @see            ????
 * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────
 * @changes
 * @modifiedBy
 * @modifiedDate
 * @version          1.1
 * @methodName
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
import { LightningElement, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import retrieveSearchResults from "@salesforce/apex/SmartSearchApexController.retrieveSearchResults";
import { COLUMNS, reduceErrors, removeDiacritics } from "./utility.js";
import { getRecord } from "lightning/uiRecordApi";
import PKI_COUNTRY_FIELD from "@salesforce/schema/User.PKICountry__c";
import USER_ID from "@salesforce/user/Id";

export default class MdmAccountSmartSearch extends NavigationMixin(
  LightningElement
) {
  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Variables declaration.
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  // store the account name entered in input field
  accountName;
  // store the acustomerNumber entered in input field
  customerNumber;
  // store the street entered in input field
  street;
  // store the city entered in input field
  city;
  // store the country entered in input field
  country;
  // store the columns for lightning data-table
  accountColumns = COLUMNS;
  // store the data for lightning data-table
  accountsData;
  //store the logged in users PKICountry__c
  userPKICountry;
  // store the maximum result to be displayed on UI
  maxResultCount = 400;
  // used to drive 'more result' message box
  isMore = false;
  //used to drive 'no result' message box
  noResults = false;
  // to store the total accounts fetched from server
  totalSize;
  //to show/hide the spinner in UI
  showSpinner = false;
  // to store the sortedBy in lighhtning data-table
  sortedBy;
  // to store the defaultSortDirection in lighhtning data-table
  defaultSortDirection = "asc";
  // to store the sortDirection for data in lighhtning data-table
  sortDirection = "asc";
  //proprty used in  lighhtning data-table
  @track rowNumberOffset;
  //porperty used to display data in  lighhtning data-table
  @track recordsToDisplay;
  //to dsplay the pagination on UI
  paginationOn = false;
  //to hide the search box feature on child component on UI
  searchBox = false;
  recordsPerPage = [25, 50, 100];
  sfdcBaseURL;

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      getters
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  get isMoreClass() {
    return `${
      this.isMore === true
        ? "slds-box slds-box_small slds-var-m-horizontal_small slds-align_absolute-center"
        : "slds-hide"
    }`;
  }

  get totalSizeClass() {
    return `${
      this.totalSize > 0
        ? "slds-badge slds-theme_success slds-var-m-around_medium"
        : "slds-hide"
    }`;
  }

  renderedCallback() {
    if (this.sfdcBaseURL) return;
    this.sfdcBaseURL = window.location.origin;
  }
  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Used to get logged in users PKICountry__c value.
   * @parameter        USER_ID and PKI_COUNTRY_FIELD
   * @returnValue
   * @example
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  @wire(getRecord, { recordId: USER_ID, fields: PKI_COUNTRY_FIELD })
  wireuser({ error, data }) {
    if (error) {
      this.fireToast("Error Occured", reduceErrors(error).join(", "), "Error");
    } else if (data) {
      this.userPKICountry = data.fields.PKICountry__c.value;
    }
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Used to get entered values from input field from UI and map it to respective property in js
   * @parameter        event
   * @returnValue
   * @example
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  handleInputChange(event) {
    this[event.target.dataset.id] = event.target.value;
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Used to reset the values
   * @parameter
   * @returnValue
   * @example
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  handleReset() {
    this.accountName = "";
    this.customerNumber = "";
    this.street = "";
    this.city = "";
    this.country = "";
    this.accountsData = null;
    this.isMore = false;
    this.totalSize = 0;
  }

  /* ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Used to navigate to a new account creation page or MDM url based on users PKIcountry value
   * @parameter
   * @returnValue
   * @example
   * ----- Change Log -----
   * 2025.02.28 - ives - Changed base url from Revvity's "uat.mdm4tst.com" to PKIs "ebx-uat.mypkiapps.com"
   *    and for prod URL from "mdm4tst.com" to "ebx-prod.mypkiapps.com"
   * 2025.03.26 - ives - New URL update, changing mypkiapps to perkinelmer.
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  handleNewAccount() {
    let newUrl = this.sfdcBaseURL.includes("--")
      ? "https://ebx-uat.perkinelmer.com/ebx?branch=CustomerMasterDataSpace&instance=CustomerMasterDataSet&service=LaunchSingleCustomerWorkflow"
      : "https://ebx-prod.perkinelmer.com/ebx?branch=CustomerMasterDataSpace&instance=CustomerMasterDataSet&service=LaunchSingleCustomerWorkflow";

      if (this.userPKICountry === "China") {
      newUrl=this.sfdcBaseURL.includes("--")
      ? "https://ebx-uat.perkinelmer.com/ebx?branch=CustomerMasterDataSpace&instance=CustomerMasterDataSet&service=LaunchSingleCustomerChinaWorkflow"
      : "https://ebx-prod.perkinelmer.com/ebx?branch=CustomerMasterDataSpace&instance=CustomerMasterDataSet&service=LaunchSingleCustomerChinaWorkflow";
      
      this[NavigationMixin.Navigate]({
        type: "standard__webPage",
        attributes: {
          url: newUrl
        }
      });
      

    } else {
      this[NavigationMixin.Navigate]({
        type: "standard__webPage",
        attributes: {
          url: newUrl
        }
      }); 
    }
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Used to call the server to pull the accounts
   * @parameter
   * @returnValue
   * @example
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  fetchAccount() {
    //create the payload string
    let tempPayLoad = JSON.stringify({
      searchKeyWord: this.accountName
        ? removeDiacritics(this.accountName).toUpperCase()
        : "",
      searchSAP: this.customerNumber,
      searchCity: this.city ? removeDiacritics(this.city).toUpperCase() : "",
      searchStreet: this.street
        ? removeDiacritics(this.street).toUpperCase()
        : "",
      searchCountry: this.country,
      maxResults: this.maxResultCount
    });
    this.showSpinner = true;
    //call the server w/input as payload string
    retrieveSearchResults({ payload: tempPayLoad })
      .then((result) => {
        //parse the response
        let output = JSON.parse(result);
        console.log(output);
        // if an error occured server side then present it now
        if (output.isError) {
          this.showSpinner = false;
          this.fireToast(
            "Error Occured",
            "An error has occured",
            output.message
          );
        }
        //process the records from server and assign the js properties
        console.log(JSON.stringify(output.accounts));
        let filteredRecords = this.processRecords(output.accounts);
        this.noResults = filteredRecords.length === 0;
        this.paginationOn = true;
        this.isMore = output.isMore;
        this.totalSize = filteredRecords.length;
        this.accountsData = filteredRecords;

        this.showSpinner = false;
      })
      .catch((error) => {
        this.showSpinner = false;
        this.fireToast(
          "Error Occured",
          reduceErrors(error).join(", "),
          "Error"
        );
      });
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      This is method for creating a new object of Account Records.
   * @parameter        inputRecords
   * @returnValue
   * @example
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  processRecords(inputRecords) {
    //create a new array of received response from server
    let recordsProcessed = inputRecords.map((val) => ({
      Id: val.Id,
      linkName: "/" + val.Id,
      Name: val.Name,
      PKI_SAP_Name_2__c: val.PKI_SAP_Name_2__c,
      PKI_SAP_Customer_Number__c: val.PKI_SAP_Customer_Number__c,
      PKI_SAP_Customer_Base_Name__c: val.PKI_SAP_Customer_Base_Name__c,
      ShippingStreet: val.ShippingStreet,
      ShippingCity: val.ShippingCity,
      ShippingState: val.ShippingState,
      ShippingCountry: val.ShippingCountry,
      Opportunity_Info__c: val.Opportunity_Info__c,
      NameLocal:val.NameLocal,
      PKI_ShippingStreetLocal__c:val.PKI_ShippingStreetLocal__c,
      //  PKI_ShippingCityLocal__c:val.PKI_ShippingStreetLocal__c,  next line revised/corrected
      PKI_ShippingCityLocal__c:val.PKI_ShippingCityLocal__c,
      PKI_SAP_Name_3__c: val.PKI_SAP_Name_3__c,
      PKI_SAP_Name_4__c: val.PKI_SAP_Name_4__c
    }));
    return recordsProcessed;
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      This is method for firing toast message for all variant types.
   * @parameter        _title,_message,_variant
   * @returnValue
   * @example
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  fireToast(_title, _message, _variant) {
    const toast = new ShowToastEvent({
      title: _title,
      message: _message,
      variant: _variant
    });
    this.dispatchEvent(toast);
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      This is method for sorting the column in lighning data-table
   * @parameter        stanrdard event
   * @returnValue
   * @example
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  handleSort(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    const cloneData = [...this.recordsToDisplay];
    cloneData.sort(this.sortBy(sortedBy, sortDirection === "asc" ? 1 : -1));
    this.recordsToDisplay = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      This is helper method for sorting data
   * @parameter        field, reverse, primer
   * @returnValue
   * @example
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  sortBy(field, reverse, primer) {
    const key = primer
      ? function (x) {
          return primer(x[field]);
        }
      : function (x) {
          return x[field];
        };

    return function (a, b) {
      a = key(a) ? key(a).toLowerCase() : ""; //To handle null values , uppercase records during sorting
      b = key(b) ? key(b).toLowerCase() : "";
      return reverse * ((a > b) - (b > a));
    };
  }
  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Capture the event fired from the paginator component
   * @parameter        standard event
   * @returnValue
   * @example
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  handlePaginatorChange(event) {
    this.recordsToDisplay = event.detail;
    if (typeof this.recordsToDisplay[0] !== "undefined")
      this.rowNumberOffset = this.recordsToDisplay[0].rowNumber - 1;
  }
}