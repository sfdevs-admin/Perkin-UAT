/**
 * Created by b.s.salmans on 2/15/2021.
 */

import { LightningElement, wire, track, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import {refreshApex} from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import searchJobs from '@salesforce/apex/SMAX_PS_WorkOrderStandardJobTime.searchJobs';
import chartjs from '@salesforce/resourceUrl/Chartjs';
import apexStatuses from '@salesforce/apex/SMAX_PS_WorkOrderStandardJobTime.apexStatuses';
import apexOrderTypes from '@salesforce/apex/SMAX_PS_WorkOrderStandardJobTime.apexOrderTypes';
import apexProductLines from '@salesforce/apex/SMAX_PS_WorkOrderStandardJobTime.apexProductLines';
import apexModelSeries from '@salesforce/apex/SMAX_PS_WorkOrderStandardJobTime.apexModelSeries';
import getSjtDetails from '@salesforce/apex/SMAX_PS_WorkOrderStandardJobTime.getSjtDetails';
import getReportId from '@salesforce/apex/SMAX_PS_WorkOrderStandardJobTime.getReportId';
import getAllExtantModels from '@salesforce/apex/SMAX_PS_WorkOrderStandardJobTime.getAllExtantModels';
// Add Job Times Pop-up:
import allOrderTypes from '@salesforce/apex/SMAX_PS_WorkOrderStandardJobTime.allOrderTypes';
import findNewSJT from '@salesforce/apex/SMAX_PS_WorkOrderStandardJobTime.findNewSJT';
import createNewSJT from '@salesforce/apex/SMAX_PS_WorkOrderStandardJobTime.createNewSJT';

const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Data', name: 'data' },
    { label: 'Report', name: 'report' }
];

// USED
const sjtColumns = [
    { type: 'url', fieldName: 'recordUrl', label: 'Name', typeAttributes: { label: { fieldName: 'name' } } },
//    { label: 'Name', fieldName: 'name' },
    { label: 'Status', fieldName: 'status' },
    { label: 'Order Type', fieldName: 'type' },
    { label: 'Product Line', fieldName: 'product' },
    { label: 'Model Series', fieldName: 'model' },
    { label: 'Count', fieldName: 'count' },
    { label: 'Standard', fieldName: 'standard', type: 'number', typeAttributes: { maximumFractionDigits: 2 } },
    { label: 'Actuals', fieldName: 'actual', type: 'number', typeAttributes: { maximumFractionDigits: 2 } },
    { label: 'Difference', fieldName: 'diff', type: 'percent', typeAttributes: { maximumFractionDigits: 2 } },
    { label: 'Edit', type: 'button-icon', hideDefaultActions: true, fixedWidth: 75,
    	typeAttributes: { name: 'edit', variant: 'brand', iconName: 'utility:edit' } },
    { label: 'Split', type: 'button-icon', hideDefaultActions: true, fixedWidth: 75,
    	typeAttributes: { name: 'split', variant: 'brand', iconName: 'utility:rules', disabled: {fieldName: 'disableSplit'} } },
    { label: 'Metrics', type: 'button-icon', hideDefaultActions: true, fixedWidth: 75,
    	typeAttributes: { name: 'data', variant: 'brand', iconName: 'utility:metrics' } },
    { label: 'Report', type: 'button-icon', hideDefaultActions: true, fixedWidth: 75,
    	typeAttributes: { name: 'report', variant: 'brand', iconName: 'utility:table' } },
//    { type: 'action', typeAttributes: { rowActions: actions, menuAlignment: 'right' } }
];

let i = 0;
export default class SmaxStandardJobTimesDashboard extends NavigationMixin(LightningElement) {

    @track horizonValue = '1';  //  selected value of horizon radio button //
    @track sliderValue = 25;  //  selected value of actVdiff slider
    @track minCountValue = 10; // selected min count slider
    @track sjtData = [];  //  standard job records returned from search
    @track sjtColumns = sjtColumns;  //  columns for display of standard job records
    @track selectedJobs = [];
    @track selectedFilters = [];  //  filters (order,line,model) for searching standard jobs
    @track isChartJsInitialized;
    @track showFilters = true;
    @track chartType;
    chart;

    //  USING? ----------------------------
    @track isProcessing = false;
    @track error;
    @track lookupErrors = [];
    @track filterError;
    @track showJobEdit;
    // ---------------------------------------

    //------ITSVMX-401--------//
    // -- STATUS SELECTION -- //
    //------------------------//
    @track statuses = [];  //  value/label pairs for selectable status values
    @track selectedStatuses = ['Active'];  //  .value of selected status values
    _statusesResponse;  //  statuses variable for apex refresh calls

    @wire(apexStatuses, {})
    wiredStatuses(response) {
        this._statusesResponse = response;
        let error = response && response.error;
        let data = response && response.data;
        if(data) {
            this.statuses = [];
            for(i=0; i<data.length; i++) {
                this.statuses = [...this.statuses, {value: data[i].value, label: data[i].label}];
            }
            this.error = undefined;
        }
        else if (error) {
            this.error = error;
            this.statuses = undefined;
        }
    }

    handleStatusChange(event) {
        const selectedStatusValues = event.detail.value;
		this.selectedStatuses = selectedStatusValues;
    }

    //----------------------------//
    // -- ORDER TYPE SELECTION -- //
    //----------------------------//
    @track orderTypes = [];  //  value/label pairs for selectable order types
    @track selectedType = '';  //  .value currently selected order type
    @track selectedTypes = [];  //  .value of selected order types
    _typeResponse;  //  order type variable for apex refresh calls

    // returns the order types that can be selected from picklist
    @wire(apexOrderTypes, {selectedTypes:'$selectedTypes'})
    wiredOrderTypes(response) {
        this._typeResponse = response;
        let error = response && response.error;
        let data = response && response.data;
        if(data) {
            this.orderTypes = [];
            for(i=0; i<data.length; i++) {
                this.orderTypes = [...this.orderTypes, {value: data[i].value, label: data[i].label}];
            }

            this.selectedType = null;
            this.selectedProductLine = null;
            this.selectedModelSeries = null;
            this.error = undefined;
        }
        else if (error) {
            this.error = error;
            this.orderTypes = undefined;
        }
    }

    // event handler for change in order type picklist
    typeChange(event) {
        const selectedOrderType = event.detail.value;
        this.selectedType = selectedOrderType;
        this.selectedTypes = [...this.selectedTypes, this.selectedType];
        this.selectedFilters = [...this.selectedFilters, {label:this.selectedType, name:this.selectedType,
        	icon: 'standard:work_type'}];
        refreshApex(this._typeResponse);

        this.selectedType = null;
        this.selectedProductLine = null;
        this.selectedModelSeries = null;
    }

    get orderTypes() {
        return this.orderTypes;
    }

    get selectedType() {
        return this.selectedType;
    }
    // -- END ORDER TYPE SELECTION -- //

    //------------------------------//
    // -- PRODUCT LINE SELECTION -- //
    //------------------------------//
    @track productLines = [];  //  value/label pairs for selectable product lines
    @track selectedProductLine = '';  //  .value currently selected product line
    @track selectedProductLines = [];  //  .value of selected product lines
    _lineResponse;  //  product line variable for apex refresh calls

    // returns the product lines that can be selected from picklist
    @wire(apexProductLines, {includedTypes:'$selectedTypes', selectedLines:'$selectedProductLines'})
    wiredProductLines(response) {
        this._lineResponse = response;
        let error = response && response.error;
        let data = response && response.data;
        if(data) {
            this.productLines = [];
            for(i=0; i<data.length; i++) {
                this.productLines = [...this.productLines, {value: data[i].value, label: data[i].label}];
            }

            this.selectedType = null;
            this.selectedProductLine = null;
            this.selectedModelSeries = null;
            this.error = undefined;
        }
        else if (error) {
            this.error = error;
            this.productLines = undefined;
        }
    }

    // event handler for change in product line picklist
    productLineChange(event) {
        const selectedProductLine_ = event.detail.value;
        this.selectedProductLine = selectedProductLine_;
        this.selectedProductLines = [...this.selectedProductLines, this.selectedProductLine];
        this.selectedFilters = [...this.selectedFilters, {label:this.selectedProductLine,
        	name:this.selectedProductLine, icon: 'standard:product_item'}];
        refreshApex(this._lineResponse);
        this.selectedType = null;
        this.selectedProductLine = null;
        this.selectedModelSeries = null;
    }

    get productLines() {
        return this.productLines;
    }

    get selectedProductLine() {
        return this.selectedProductLine;
    }
    // -- END PRODUCT LINE SELECTION -- //

    //------------------------------//
    // -- MODEL SERIES SELECTION -- //
    //------------------------------//
    @track modelSeries = [];  //  value/label pairs for selectable model series
    @track selectedModelSeries = '';  //  .value currently selected model series
    @track selectedModelSeriesList = [];  //  .value of selected model series
    _modelResponse;  //  model series variable for apex refresh calls

    // returns the model series that can be selected from picklist
    @wire(apexModelSeries, {includedTypes:'$selectedTypes', includedLines:'$selectedProductLines', selectedModels:'$selectedModelSeriesList'})
    wiredModelSeries(response) {
        this._productResponse = response;
        let error = response && response.error;
        let data = response && response.data;
        if(data) {
            this.modelSeries =[];
            for(i=0; i<data.length; i++) {
                this.modelSeries = [...this.modelSeries, {value: data[i].value, label: data[i].label }];
            }

            this.selectedType = null;
            this.selectedProductLine = null;
            this.selectedModelSeries = null;
            this.error = undefined;
        }
        else if (error) {
            this.error = error;
            this.productLines = undefined;
        }
    }

    // event handler for change in model series picklist
    modelSeriesChange(event) {
        const selectedModelSeries_ = event.detail.value;
        this.selectedModelSeries = selectedModelSeries_;
        this.selectedModelSeriesList = [...this.selectedModelSeriesList, this.selectedModelSeries];
        this.selectedFilters = [...this.selectedFilters, {label:this.selectedModelSeries,
        	name:this.selectedModelSeries, icon: 'standard:category'}];
        refreshApex(this._modelResponse);

        this.selectedType = null;
        this.selectedProductLine = null;
        this.selectedModelSeries = null;
    }

    get modelSeries() {
        return this.modelSeries;
    }

    get selectedModelSeries() {
        return this.selectedModelSeries;
    }
    // -- END MODEL SERIES SELECTION -- //

    //------------------------//
    // -- PILL BOX SECTION -- //
    //------------------------//
    @api
    handleRemoveSelectedItem(event) {
        const recordId = event.currentTarget.name;
        this.selectedFilters = this.selectedFilters.filter((item) => item.name !== recordId);
        this.selectedTypes = this.selectedTypes.filter((item) => item !== recordId);
        this.selectedProductLines = this.selectedProductLines.filter(function(value,index,arr){ return value !== recordId });
        this.selectedModelSeriesList = this.selectedModelSeriesList.filter(function(value,index,arr){ return value !== recordId });
        refreshApex(this._typeResponse);
        refreshApex(this._lineResponse);
        refreshApex(this._modelResponse);
        this.selectedType = '';
        this.selectedProductLine = '';
        this.selectedModelSeries = '';
    }
    // -- END PILL BOX SECTION -- //

    //--------------//
    // -- SEARCH -- //
    //--------------//
    //@track showTable = false;  //  Used to render table after we get the data from apex controller
    @track recordsToDisplay = [];  //  Records to be displayed on the page
    @track rowNumberOffset;  //  Row number
    @track paginationOn = false;
    @track totalNumberOfRecords;

    handleJobSearch(event) {
        if(this.horizonValue == '' || this.horizonValue == null) this.horizonValue = '1';
        searchJobs({statuses:this.selectedStatuses,
        	types:this.selectedTypes, lines:this.selectedProductLines, model:this.selectedModelSeriesList,
        	horizon:this.horizonValue, minDelta:this.sliderValue, minCount:this.minCountValue})
        .then((results) => {
            //this.sjtData = results;
            // pagination
            let recs = [];
            for(let i = 0; i < results.length; i++) {
                let sjtRec = {};
                var rowNum = ''+(i+1);
                console.log(' !! handlejobsearch: getting here 1...');
                sjtRec.rowNumber = rowNum;
                console.log(' !! handlejobsearch: getting here 2...');
                //sjtRec.oppLink = '/'+results[i].Id;
                sjtRec = Object.assign(sjtRec, results[i]);
                sjtRec.recordUrl = '/' + sjtRec.id;
                recs.push(sjtRec);
            }
            this.sjtData = recs;
            console.log(' !! handlejobsearch: total record number = '+this.sjtData.length);
            this.totalNumberOfRecords = this.sjtData.length;
            console.log(' !! handlejobsearch: total record number = '+this.totalNumberOfRecords);
            this.paginationOn = true;
            //this.showTable = true;
        })
        .catch((error) => {
            const toastEvent = new ShowToastEvent('Lookup Error', 'An error occurred while searching with the lookup field.', 'error');
            this.dispatchEvent(toastEvent);
            console.error('Lookup error', JSON.stringify(error));
            this.lookupErrors = [error];
        });
    }

    //Capture the event fired from the paginator component
    handlePaginatorChange(event) {
        console.log(' !! in paginator event - event.detail: '+JSON.stringify(event.detail));
        this.recordsToDisplay = event.detail;
        console.log(' !! in paginator event - recordsToDisplay: '+JSON.stringify(this.recordsToDisplay));
        if(typeof this.recordsToDisplay[0] !== 'undefined') this.rowNumberOffset = this.recordsToDisplay[0].rowNumber-1;
        console.log(' !! in paginator event - returning...');
    }

    handleClear(event) {
        this.horizonValue = '1';
        this.sliderValue = 25;
        this.minCountValue = 10;
        this.sjtData = [];
        this.recordsToDisplay = [];
        this.selectedFilters = [];
        this.selectedModelSeriesList = [];
        this.selectedProductLines = [];
        this.selectedTypes = [];
        refreshApex(this._lineResponse);
        refreshApex(this._modelResponse);
        refreshApex(this._typeResponse);
        this.selectedType = '';
        this.selectedProductLine = '';
        this.selectedModelSeries = '';
        this.paginationOn = false;
    }
    // -- END SEARCH -- //

    //--------------------//
    // -- MONTH FILTER -- //
    //--------------------//
    get horizonOptions() {
        return [
            { label: '1 Month', value: '1' },
            { label: '3 Months', value: '3' },
            { label: '6 Months', value: '6' },
            { label: '12 Months', value: '12' },
        ];
    }

    handleHorizonChange(event) {
        this.horizonValue = event.detail.value;
    }
    // -- END MONTH FILTER -- //

    //--------------//
    // -- SLIDERS -- //
    //--------------//
    get sliderValue() {
        return this.sliderValue;
    }

    handleSliderChange(event) {
        this.sliderValue = event.detail.value;
    }

    get minCountValue() {
        return this.minCountValue;
    }

    handleMinCountChange(event) {
        this.minCountValue = event.detail.value;
    }
    // -- END SLIDERS -- //

    //--------------------------//
    // -- DATA TABLE METHODS -- //
    //--------------------------//
    recordList;
    pagelist;
    currentPage = 1;
    recordPerPage = 10;
    totalPages = 1;

    handleNext() {
        this.currentPage += 1;
        this.preparePaginationList();
    }

    handlePrevious() {
        this.currentPage -= 1;
        this.preparePaginationList();
    }

    handleFirst() {
        this.currentPage = 1;
        this.preparePaginationList();
    }

    handleLast() {
        this.currentPage = this.totalPages;
        this.preparePaginationList();
    }

    handleRowAction(event) {
        console.log('ROW ACTION = ' + event.detail.action.name);
        console.log('ROW ACTION = ' + JSON.stringify(event.detail.action));
        if(event.detail.action.name == 'edit') {
            this.doEditPop(event);
        }
        if(event.detail.action.name == 'split') {
            this.doSplitPop(event);
        }
        if(event.detail.action.name == 'data') {
            this.doDataPop(event);
        }
        if(event.detail.action.name == 'report') {
            this.doReportPop(event);
        }
    }
    // -- END DATA TABLE METHODS -- //

    //---------------------------//
    // -- STANDARD JOB POP-UP -- //
    //---------------------------//
    @track showSJTpopup = false;
    @track selectedSjt;
    @track selectedSjtName;
    @track groupByCountryGraph = false;
    @track groupByTechnicianGraph = false;
    @track groupByTechnicianManagerGraph = false;
    @track groupByModelGraph = false;
    @track sjtId;
    @track oldSjtId;
    @track showStjLine = true;
    @track showManagerBar = false;
    @track staleVal;
    _testConfig;

    doDataPop(event) {
        this.sjtId = event.detail.row.id;
        this.selectedSjtName = event.detail.row.name;
        getSjtDetails({jobId: this.sjtId})
        .then(result => {
            this.selectedSjt = result;
            this.chartType = 'line';
            this.showFilters = false;
            this.showSJTpopup = true;
        })
        .catch(error => {
            console.error('Error getting standard job record: ', JSON.stringify(error));
            this.isProcessing = false;
            const evt = new ShowToastEvent({ title: 'Error getting standard job record', message: error.body.message, variant: 'error', mode: 'sticky'});
            this.dispatchEvent(evt);
         });
    }

    handleDataClose(event) {
        this.showFilters = true;
        this.showSJTpopup = false;
        this.groupByCountryGraph = false;
        this.groupByTechnicianGraph = false;
        this.groupByModelGraph = false;
        this.groupByTechnicianManagerGraph = false;
    }
    // -- END STANDARD JOB POP-UP -- //

    //-----------------------//
    // -- EDIT JOB POP-UP -- //
    //-----------------------//
    @track recordEditPopup = false;
    @track recordToEditId;
    @track recordToEditName;

    doEditPop(event) {
        this.recordEditPopup = true;
        let sjtId = event.detail.row.id;
        getSjtDetails({jobId:sjtId})
        .then((results) => {
            this.recordToEditId = results.Id;
            this.recordToEditName = results.Name;
        })
        .catch((error) => {
            console.error('Error getting standard job record: ', JSON.stringify(error));
            this.isProcessing = false;
            const evt = new ShowToastEvent({ title: 'Error getting standard job record', message: error.body.message, variant: 'error', mode: 'sticky'});
            this.dispatchEvent(evt);
        });
    }

    handleEditClose(event) {
        this.recordEditPopup = false;
    }

    handleEditSave(event) {
        this.recordEditPopup = false;
        this.handleJobSearch(event);
    }
    // -- END EDIT JOB POP-UP -- //

    //-----------------------//
    // -- REPORT REDIRECT -- //
    //-----------------------//
    _reportType = '';
    _reportProduct = '';
    _reportModel = '';
    @track reportUrl = '';

    doReportPop(event) {
        this._reportType = event.detail.row.type;
        this._reportProduct = event.detail.row.product;
        this._reportModel = event.detail.row.model;

        var d = new Date();
        var datePreUrl = (d.getMonth()+1) + '/' + d.getDate() + '/' + d.getFullYear();
        d.setMonth(d.getMonth() - Number(this.horizonValue));
        var dateForUrl = (d.getMonth()+1) + '/' + d.getDate() + '/' + d.getFullYear();
		console.log('Date Before = ' + datePreUrl + ', Date = ' + dateForUrl);
        var isEmpty = (this._reportModel == '(Empty)');
		getReportId({empty: isEmpty}).then(reportId => {
		    console.log('IsEmpty = ' + isEmpty + ', Report Id = ' + reportId);
			if(isEmpty == true) {
				getAllExtantModels({orderType:this._reportType, productLine:this._reportProduct})
				.then(result => {
					this.reportUrl = window.location.origin + '/lightning/r/Report/'+encodeURIComponent(reportId)+'/view?fv0='+encodeURIComponent(this._reportType)+'&fv1='+encodeURIComponent(this._reportProduct)+'&fv2='+encodeURIComponent(result)+'&fv3='+encodeURIComponent(dateForUrl);
					window.open(this.reportUrl);
				})
				.catch(error => {
					const toastEvent = new ShowToastEvent('Extant Model Error', 'An error occurred while searching for extant models.', 'error');
					this.dispatchEvent(toastEvent);
					console.error('Extant Model Error', JSON.stringify(error));
				})
			}
			else {
				this.reportUrl = window.location.origin + '/lightning/r/Report/'+encodeURIComponent(reportId)+'/view?fv0='+encodeURIComponent(this._reportType)+'&fv1='+encodeURIComponent(this._reportProduct)+'&fv2='+encodeURIComponent(this._reportModel)+'&fv3='+encodeURIComponent(dateForUrl);
				window.open(this.reportUrl);
			}
		})
		.catch(error => {
			const toastEvent = new ShowToastEvent('Report Error', 'An error occurred while searching for Report.', 'error');
			this.dispatchEvent(toastEvent);
			console.error('Report Error', JSON.stringify(error));
		})
    }

    // -- END REPORT REDIRECT -- //


    //-----------------------//
    // --  ADD JOB TIMES  -- //
    //-----------------------//

	@track addSjtColumns = [
		{ label: 'Order Type', fieldName: 'type' },
		{ label: 'Product Line', fieldName: 'product' },
		{ label: 'Model Series', fieldName: 'model' },
		{ label: 'Count', fieldName: 'count' }
	];

    @track showAddJobTimes = false;
    @track showAddOrderType = true;
    @track addOrderTypes = [];  //  value/label pairs for selectable order types
    @track selectedAddOrderType = null;  //  value of selected order type
    _allOrderTypesResponse;  //  statuses variable for apex refresh calls

    @wire(allOrderTypes, {})
    wiredAllOrderTypes(response) {
        this._allOrderTypesResponse = response;
        let error = response && response.error;
        let data = response && response.data;
        if(data) {
            this.addOrderTypes = [];
            for(i=0; i<data.length; i++) {
                this.addOrderTypes = [...this.addOrderTypes, {value: data[i].value, label: data[i].label}];
            }
            this.error = undefined;
        }
        else if (error) {
            this.error = error;
            this.statuses = undefined;
        }
    }

	openAddJobTimes(event) {
	    this.selectedAddOrderType = null;
	    this.newJobItems = [];
	    this.selectedNewJobRows = [];
	    this.newJobItemsExpanded = [];
		this.showAddOrderType = true;
		this.showAddJobTimes = true;
	}

	doSplitPop(event) {
	    this.selectedAddOrderType = event.detail.row.type;
	    let rootItem = JSON.parse(JSON.stringify(event.detail.row));
	    rootItem._children = [];
	    this.newJobItems = [ rootItem ];
	    this.selectedNewJobRows = [];
	    let fakeEvent = { detail: { name: rootItem.name }};
	    this.handleNewJobExpand(fakeEvent);
	    this.newJobItemsExpanded = [ rootItem.name ];
		this.showAddOrderType = false;
		this.showAddJobTimes = true;
	}

	@track newJobItems = [];
	@track newJobItemsExpanded = [];
	@track selectedNewJobRows = [];
	@track newJobSearching = false;

    handleAddOrderTypeChange(event) {
		this.selectedAddOrderType = event.detail.value;
		this.newJobSearching = true;
		// Lookup New Job Types...
		findNewSJT({ orderType: this.selectedAddOrderType, productLine: null})
		.then(result => {
			var tempResults = JSON.parse(JSON.stringify(result));
			for(var i = 0; i < tempResults.length; i++) {
			    tempResults[i]._children = [];
			}
			this.newJobItems = tempResults;
			this.newJobSearching = false;
		});
    }

	handleNewJobSelect(event) {
		let selectedNames = event.detail.selectedRows.map(row => row.name);
		console.log('Selected Names = ' + selectedNames);
		this.selectedNewJobRows = selectedNames;
	}

	handleNewJobExpand(event) {
        let parentRowName = event.detail.name;
        let parentRow = this.newJobItems.find(item => item.name == parentRowName);
		if (parentRow._children && parentRow._children.length == 0) {
			let selProductLine = parentRow.product;
			this.newJobSearching = true;
			// Lookup New Job Types...
			findNewSJT({ orderType: this.selectedAddOrderType, productLine: selProductLine })
			.then(result => {
				var tempResults = JSON.parse(JSON.stringify(result));
				parentRow._children = tempResults;
				this.newJobItems = [...this.newJobItems];
				this.newJobSearching = false;
			});

		}
	}

	handleNewJobCreate(event) {
	    this.newJobSearching = true;

		let selectedJobs = [];
		this.newJobItems.forEach(item => {
			if (this.selectedNewJobRows.includes(item.name)) {
				selectedJobs.push(item);
			}
			item._children.forEach(child => {
				if (this.selectedNewJobRows.includes(child.name)) {
					selectedJobs.push(child);
				}
			});
		});
		console.log('Selected Jobs = ' + selectedJobs.length);

		createNewSJT({ jobTimes: selectedJobs })
		.then(result => {
			const toastEvent = new ShowToastEvent({'title':'Created Job Times',
				'message':result, 'variant':'success'});
			this.dispatchEvent(toastEvent);
			this.newJobSearching = false;
			this.handleAddJobTimesClose(event);
		})
		.catch((error) => {
		    //let errorMsg = (error.body && error.body.message) ? error.body.message : error;
			const toastEvent = new ShowToastEvent({'title':'Create Job Time Error',
				'message':'An error occurred while trying to create new job times',
				'variant':'error', 'mode':'sticky'});
			this.dispatchEvent(toastEvent);
			console.error('createNewSJT error', JSON.stringify(error));
			this.newJobSearching = false;
		});
	}

    handleAddJobTimesClose(event) {
        this.showAddJobTimes = false;
    }

    // -- END ADD JOB TIMES -- //
}