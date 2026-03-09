/**
 * Created by b.s.salmans on 3/19/2021.
 */

import { LightningElement, api, track} from 'lwc';

const DELAY = 300;
const recordsPerPage = [10,25,50,100];
const pageNumber = 1;
const showIt = 'visibility:visible';
const hideIt = 'visibility:hidden'; //visibility keeps the component space, but display:none doesn't
export default class Paginator extends LightningElement {
    @api paginationOn = false;
    @api showSearchBox = false; //Show/hide search box; valid values are true/false
    @api showPagination; //Show/hide pagination; valid values are true/false
    @api pageSizeOptions = recordsPerPage; //Page size options; valid values are array of integers
    @api
    get records() { //All records available in the data table; valid type is Array
        return this._records;
    };
    set records(value) {
        this._records = value;
        this.setRecordsToDisplay();
    }
    @track pageSize; //No.of records to be displayed per page
    @track totalPages; //Total no.of pages
    @track pageNumber = pageNumber; //Page number
    @track searchKey; //Search Input
    @track controlPagination = showIt;
    @track controlPrevious = hideIt; //Controls the visibility of Previous page button
    @track controlNext = showIt; //Controls the visibility of Next page button
    recordsToDisplay = []; //Records to be displayed on the page

    _records;
    _totalRecords;

    //Called after the component finishes inserting to DOM
    connectedCallback() {
        if(this.pageSizeOptions && this.pageSizeOptions.length > 0)
            this.pageSize = this.pageSizeOptions[0];
        else {
            this.pageSize = this.totalRecords;
            this.showPagination = false;
        }
        this.controlPagination = this.showPagination === false ? hideIt : showIt;
        this.setRecordsToDisplay();
    }

    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.setRecordsToDisplay();
    }

    handlePageNumberChange(event) {
        if(event.keyCode === 13) {
            this.pageNumber = event.target.value;
            this.setRecordsToDisplay();
        }
    }

    previousPage() {
        this.pageNumber = this.pageNumber-1;
        this.setRecordsToDisplay();
    }

    nextPage() {
        this.pageNumber = this.pageNumber+1;
        this.setRecordsToDisplay();
    }

    setRecordsToDisplay() {
        console.log(' $$ in set records to display...');
        console.log(' $$ current records: '+JSON.stringify(this._records));
        console.log(' $$ current records length: '+this._records.length);

        //if(this._records.length < 1) return;
        this.recordsToDisplay = [];
        if(!this.pageSize) {
            console.log(' $$ current records - total records: '+JSON.stringify(this.totalRecords));
            this.pageSize = this.totalRecords;
        }

        this.totalPages = Math.ceil(this._records.length/this.pageSize);

        console.log(' $$ current records - total pages: '+JSON.stringify(this.totalPages));

        this.setPaginationControls();

        console.log(' $$ current records - page number: '+this.pageNumber);
        console.log(' $$ current records - page size: '+this.pageSize);
        console.log(' $$ current records - total records: '+this._records.length);

        for(let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if(i === this._records.length) break;

            console.log(' $$ current records - this record: '+JSON.stringify(this._records[i]));
            this.recordsToDisplay.push(this._records[i]);
        }

        console.log(' $$ current records - records To Display: '+JSON.stringify(this.recordsToDisplay));
        this.dispatchEvent(new CustomEvent('paginatorchange', {detail: this.recordsToDisplay})); //Send records to display on table to the parent component
    }

    setPaginationControls() {
        //Control Pre/Next buttons visibility by Total pages
        if(this.totalPages === 1) {
            this.controlPrevious = hideIt;
            this.controlNext = hideIt;
        }
        else if(this.totalPages > 1) {
           this.controlPrevious = showIt;
           this.controlNext = showIt;
        }
        //Control Pre/Next buttons visibility by Page number
        if(this.pageNumber <= 1){
            this.pageNumber = 1;
            this.controlPrevious = hideIt;
        }
        else if(this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
            this.controlNext = hideIt;
        }
        //Control Pre/Next buttons visibility by Pagination visibility
        if(this.controlPagination === hideIt) {
            this.controlPrevious = hideIt;
            this.controlNext = hideIt;
        }
    }

    handleKeyChange(event) {
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        if(searchKey){
            this.delayTimeout = setTimeout(() => {
                this.controlPagination = hideIt;
                this.setPaginationControls();

                this.searchKey = searchKey;
                //Use other field name here in place of 'Name' field if you want to search by other field
                //this.recordsToDisplay = this.records.filter(rec => rec.includes(searchKey));
                //Search with any column value (Updated as per the feedback)
                this.recordsToDisplay = this.records.filter(rec => JSON.stringify(rec).includes(searchKey));
                if(Array.isArray(this.recordsToDisplay) && this.recordsToDisplay.length > 0)
                    this.dispatchEvent(new CustomEvent('paginatorchange', {detail: this.recordsToDisplay})); //Send records to display on table to the parent component
            }, DELAY);
        }else{
            this.controlPagination = showIt;
            this.setRecordsToDisplay();
        }
    }
}