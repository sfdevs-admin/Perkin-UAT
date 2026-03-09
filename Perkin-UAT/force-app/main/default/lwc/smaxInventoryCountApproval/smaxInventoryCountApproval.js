/**
 * Created by frankvanloon on 5/5/20.
 */

import { LightningElement, wire, track, api } from 'lwc';
import lookupFilters from '@salesforce/apex/BD_Inventory_Count_Approval.lookupFilters';
import filterInventory from '@salesforce/apex/BD_Inventory_Count_Approval.filterInventory';
import getLines from '@salesforce/apex/BD_Inventory_Count_Approval.getLines';
import updateInventory from '@salesforce/apex/BD_Inventory_Count_Approval.updateInventory';
// 8/17/20 tony - added to allow updates of inventory lines form the header level
import updateInventoryFromHeader from '@salesforce/apex/BD_Inventory_Count_Approval.updateInventoryFromHeader';
import searchTechnicians from '@salesforce/apex/BD_CustomLookupService.searchTechnicians';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { type: 'url', fieldName: 'recordUrl', label: 'Inventory Count Name', typeAttributes: { label: { fieldName: 'recordLabel' } } },
//    { type: 'text', fieldName: 'StatusSummary', label: 'Status', wrapText: true },
    { type: 'text', fieldName: 'SMAX_PS_Status__c', label: 'Status' },
//    { type: 'date', fieldName: 'LastModifiedDate', label: 'Last Modified' },
    { type: 'url', fieldName: 'techUrl', label: 'Technician', wrapText: true, typeAttributes: { label: { fieldName: 'TechSummary' } } },
//    { type: 'text', fieldName: 'LocationCode', label: 'Location Code' },
//    { type: 'url', fieldName: 'techUrl', label: 'Technician', typeAttributes: { label: { fieldName: 'TechName' } } },
//    { type: 'text', fieldName: 'Plant', label: 'Plant' },
    //{ type: 'text', fieldName: 'SMAX_PS_InvCnt_Status__c', label: 'Line Status' },
//    { type: 'text', fieldName: 'PartNumber', label: 'Part Number' },
    { type: 'url', fieldName: 'partUrl', label: 'Part', typeAttributes: { label: { fieldName: 'PartNumber' } } },
    //*** Testing, remove when done
    //{ type: 'text', fieldName: 'lineCount', label: 'Part'},
    //{ type: 'url', fieldName: 'Id', label: 'Line Name', typeAttributes: { label: { fieldName: 'Name' } } },
//    { type: 'number', fieldName: 'SMAX_PS_BookedQty__c', label: 'Booked Qty' },
//    { type: 'number', fieldName: 'SMAX_PS_CountedQty__c', label: 'Counted Qty' },
    { type: 'text', fieldName: 'QtyCompare', label: 'Counted Qty / Booked Qty' },
//    { type: 'currency', fieldName: 'SMAX_PS_ProductCost__c', label: 'Product Cost' },
//    { type: 'currency', fieldName: 'SMAX_PS_Difference_in_Cost__c', label: 'Difference in Cost' },

    // 8/6/20 tony - changed this to use a variable instead of the field so we can calculate it later
    //{ type: 'currency', fieldName: 'SMAX_PS_DifferenceValue__c', label: 'Difference' },
    { type: 'currency', fieldName: 'Difference', label: 'Difference', typeAttributes: { currencyCode: { fieldName: 'currencyCode' } } },

//    { type: 'textarea', fieldName: 'SMAX_PS_Reason_for_Difference__c', label: 'Reason for Difference' },
//    { type: 'textarea', fieldName: 'SMAX_PS_Why_Recount_Needed__c', label: 'Why Recount Needed' }
    { type: 'textarea', fieldName: 'ReasonText', label: 'Reason' }

];

export default class SmaxInventoryCountApproval extends LightningElement {

    @track allPlants = [];
    @track allStatuses = [];
    @track allTechnicians = [];

    @track selectedPlants = [];
    @track selectedStatuses = [];
    @track selectedTechnicians = [];

    @track busySearching = false;
    @track columns = columns;
    @track inventoryList; // TODO: Remove (not used)
    @track inventoryCounts = [];
    @track treeItems=[];
    @track expandedRows=[];

    @track selectedReviewStatus;
    @track selectedRejectReason;
    @track reviewOptions = [
        { label: 'Confirmed', value: 'Confirmed' },
        { label: 'Recount', value: 'Recount' },
        { label: 'Approved', value: 'Approved' },
    ];

    @track filterObj={};

    @track selectedRows = [];
    @track selectedRowMessage = null;
    @track selectedRowCount=null;
    @track parentRow = null;

    lineIds=[];
    @track updateMessage=null;
    @track updateResult=null;
    @track updateObj=[];

    @track error;
    @track error2;
    @track lookupErrors = [];
    @track filterError;

    @wire(lookupFilters)
    wireFilters( { error, data })
    {
        if (data) {
            this.allPlants = data.allPlants;
            this.allStatuses = data.allStatuses;

            console.log('AllStatuses: '+this.allStatuses);
            if(this.selectedStatus==null){
                this.selectedStatuses.push('Submitted');
            }
        } else {
            this.error = error;
        }
    }

    handlePlantChange(evt) {
        console.log(JSON.stringify(evt.srcElement));
        this.selectedPlants=evt.detail.value;
        if(evt.detail.value==null||evt.detail.value===''){
            this.selectedPlants=null;
        }
        console.log('selected Plants:'+this.selectedPlants);
    }
    handleStatusChange(evt) {
        // this._selected = evt.detail.value;
        this.selectedStatuses=evt.detail.value;
        console.log('Status:'+this.selectedStatuses);
    }
    handleReviewStatusChange(evt) {
        // this._selected = evt.detail.value;
        this.selectedReviewStatus=evt.detail.value;
        console.log('Review Status:'+this.selectedReviewStatus);
    }
    handleRejectReasonChange(evt) {
        // this._selected = evt.detail.value;
        this.selectedRejectReason=evt.detail.value;
        console.log('Reject Reason:'+this.selectedRejectReason);
    }

    handleTechSearch(event) {
        searchTechnicians(event.detail)
            .then((results) => {
                this.template.querySelector('c-custom-lookup').setSearchResults(results);
            })
            .catch((error) => {
                const toastEvent = new ShowToastEvent('Lookup Error', 'An error occured while searching with the lookup field.', 'error');
                this.dispatchEvent(toastEvent);
                // eslint-disable-next-line no-console
                console.error('Lookup error', JSON.stringify(error));
                this.lookupErrors = [error];
            });
    }

    handleTechSelectionChange(event) {
        const selection = this.template.querySelector('c-custom-lookup').getSelection();
        this.selectedTechnicians = selection;
        console.info('Selected Technicians: ' + JSON.stringify(this.selectedTechnicians));
    }

    handleSelectedRow(evt) {

        var numOldSelected = this.selectedRows.length;
        var numNewSelected = evt.detail.selectedRows.length;
        console.log('old selected = ' + numOldSelected + ', new selected = ' + numNewSelected);
        var allSelectedIds = [];
        var newSelectedIds = [];
        var unSelectedIds = [];
        for(var i=0; i < evt.detail.selectedRows.length; i++)
        {
            var rowId = evt.detail.selectedRows[i].Id;
            if (evt.detail.selectedRows[i].SMAX_PS_Status__c !== 'Submitted'
            	&& evt.detail.selectedRows[i].SMAX_PS_Status__c !== 'Confirmed')
            {
                // Skip the selection b/c not Submitted
                continue;
            }
            allSelectedIds.push(rowId);
            if (!this.selectedRows.includes(rowId)) {
                newSelectedIds.push(rowId);
            }
        }
        for(var i=0; i < this.selectedRows.length; i++)
        {
            var rowId = this.selectedRows[i];
            if (!allSelectedIds.includes(rowId)) {
                unSelectedIds.push(rowId);
            }
        }

        console.log('New Selected Ids = ' + newSelectedIds);
        console.log('Un-Selected Ids = ' + unSelectedIds);

        for(var i=0; i < this.treeItems.length; i++)
        {
            var row = this.treeItems[i];
            if (newSelectedIds.includes(row.Id)) {
                for(var j=0; j < row._children.length; j++) {
                    if (row._children[j].SMAX_PS_Status__c !== 'Submitted')
                    {
                        // Skip the selection b/c not Submitted
                        continue;
                    }
                    if (!allSelectedIds.includes(row._children[j].Id)) {
                        allSelectedIds.push(row._children[j].Id);
                    }
                }
            } else if (unSelectedIds.includes(row.Id)) {
                for(var j=0; j < row._children.length; j++) {
                    var childIdx = allSelectedIds.indexOf(row._children[j].Id);
                    if (childIdx >= 0) {
                        allSelectedIds.splice(childIdx, 1);
                    }
                }
            }
        }
        console.log('ALL Selected Ids = ' + allSelectedIds);

        this.selectedRows = allSelectedIds;
    }

    buildFilter() {

        this.busySearching = true;
        this.filterObj={};
        this.error2=null;
        this.inventoryList=null;
        this.expandedRows=[];
        if(this.selectedStatuses!=''){
        this.filterObj.selectedStatuses=this.selectedStatuses;
        }
        if(this.selectedPlants!=''){
        this.filterObj.selectedPlants=this.selectedPlants;
        }
        if(this.selectedTechnician!='' && this.selectedTechnician!=null){
        this.filterObj.selectedTechnician=this.selectedTechnician;
        }

        if(this.selectedTechnicians!='' && this.selectedTechnicians){
        this.filterObj.selectedTechnicians = this.selectedTechnicians;
        }
        console.log('filterObj: '+JSON.stringify(this.filterObj));
            console.log('technicianLocation'+JSON.stringify(this.filterObj.selectedTechnicians));
            console.log('selectedPlants '+this.filterObj.selectedPlants);


        if((this.filterObj.selectedPlants==null) && (this.filterObj.selectedTechnicians==null || !this.filterObj.selectedTechnicians))
        {
            this.error2='error';
            if(this.error2!=null){
                const evt = new ShowToastEvent({
                    title: 'Filter Error',
                    message: 'Please apply a filter for plant or select a technician/location.',
                    variant: 'error',
                    mode: 'sticky',
                });
                this.dispatchEvent(evt);
            }
            console.log('plants'+this.filterObj.selectedPlants);
            console.log('technicianLocation'+this.filterObj.selectedTechnicians);
        }
        if(this.error2==null)
        {
            filterInventory({filter:this.filterObj})
                .then(result =>{
                    this.inventoryCounts = result;
                    var tempjson1=JSON.parse(JSON.stringify(this.inventoryCounts).split('Inventory_Count_Lines__r').join('_children'));
                    var tempjson=JSON.parse(JSON.stringify(tempjson1).split('SMAX_PS_RequestedTechnician__r').join('_technician'));

                    for (var i = 0; i < tempjson.length; i++){
                        // NOTE: Down-side to combined columns is formatting (Currency, Date, etc.)
                        tempjson[i].StatusSummary = tempjson[i].SMAX_PS_Status__c
                            + ('\n' + tempjson[i].LastModifiedDate).replace('T', ' ').replace('.000Z', ' ');
                        // ITSVMX-392 Find Inv Counts without Technician
                        //tempjson[i].LocationCode=tempjson[i]._technician.SMAX_PS_LocationCode__c;
                        if (tempjson[i].SMAX_PS_RequestedFrom__r) {
	                        tempjson[i].LocationCode=tempjson[i].SMAX_PS_RequestedFrom__r.SMAX_PS_LocationCode__c;
                        } else {
                            tempjson[i].LocationCode='';
                        }
                        //tempjson[i].Plant=tempjson[i]._technician.SMAX_PS_Plant__c;
                        tempjson[i].Plant=tempjson[i].SMAX_PS_Maintenance_Plant__c;
                        if (tempjson[i]._technician) {
							tempjson[i].TechName=tempjson[i]._technician.Name;
							tempjson[i].TechId=tempjson[i]._technician.Id;
                        } else {
							tempjson[i].TechName='BLANK TECHNICIAN';
							tempjson[i].TechId='';
                        }
                        tempjson[i].TechSummary=tempjson[i].TechName
                            + '\nPlant: ' + tempjson[i].Plant
                            + '\nLoc Code: ' + tempjson[i].LocationCode;

                        // 8/6/20 tony - Added rollup summary fields
                        //tempjson[i].lineCount = tempjson[i].SMAX_PS_Lines_Count__c + ' Line(s)';
                        tempjson[i].PartNumber = tempjson[i].SMAX_PS_Lines_Count__c + ' Line(s)';
                        tempjson[i].partUrl = '/lightning/r/' + tempjson[i].Id + '/related/Inventory_Count_Lines__r/view';

                        var countQtyTotal = tempjson[i].SMAX_PS_Counted_Qty_Total__c;
                        tempjson[i].QtyCompare = '';
                        if (tempjson[i].SMAX_PS_Is_Found_Item_True_Count__c > 0) {
                            tempjson[i].QtyCompare = tempjson[i].SMAX_PS_Is_Found_Item_True_Qty__c + " (Found)";
                        }

                        if (countQtyTotal > 0 || tempjson[i].SMAX_PS_Booked_Qty_Total__c > 0) {
                            tempjson[i].QtyCompare = (countQtyTotal ? countQtyTotal : 0) + " / " + tempjson[i].SMAX_PS_Booked_Qty_Total__c
                                + (tempjson[i].QtyCompare ? '  : ' + tempjson[i].QtyCompare : '');
                        }

                        tempjson[i].Difference = tempjson[i].SMAX_PS_Difference_Value_Total__c;
                        tempjson[i].currencyCode = tempjson[i].CurrencyIsoCode;
                        tempjson[i].hideCheckboxColumn=true;
                        tempjson[i].recordLabel = tempjson[i].Name;
                        tempjson[i].recordUrl = '/' + tempjson[i].Id;
                        tempjson[i].techUrl = '/' + tempjson[i].TechId;
                        tempjson[i].hasChildrenContent = false;
                        tempjson[i]._children = [];
                        console.log('tempjson[i]: '+JSON.stringify(tempjson[i]));

//                        if (tempjson[i]._children) {
//                            for(var i2 = 0; i2 < tempjson[i]._children.length; i2++){
//                                tempjson[i]._children[i2].SMAX_PS_Status__c=tempjson[i]._children[i2].SMAX_PS_InvCnt_Status__c;
//                                tempjson[i]._children[i2].StatusSummary = tempjson[i]._children[i2].SMAX_PS_InvCnt_Status__c
//                                    + ('\n' + tempjson[i]._children[i2].LastModifiedDate).replace('T', ' ').replace('.000Z', ' ');
//                                tempjson[i]._children[i2].LocationCode=tempjson[i].LocationCode;
//                                tempjson[i]._children[i2].Plant=tempjson[i].Plant;
//                                tempjson[i]._children[i2].TechName=tempjson[i].TechName;
//                                tempjson[i]._children[i2].TechId=tempjson[i].TechId;
//                                tempjson[i]._children[i2].TechSummary=tempjson[i].TechName; // Lets keep the lines simply the name..
//                                tempjson[i]._children[i2].PartNumber=tempjson[i]._children[i2].SMAX_PS_Product__r.Partnum__c
//                                    + '\n' + tempjson[i]._children[i2].SMAX_PS_Product__r.Name;
//                                tempjson[i]._children[i2].partUrl = '/' + tempjson[i]._children[i2].SMAX_PS_Product__r.Id;
//                                tempjson[i]._children[i2].recordUrl = '/' + tempjson[i]._children[i2].Id;
//                                var recName = tempjson[i]._children[i2].Name;
//                                tempjson[i]._children[i2].recordLabel = recName.substr(recName.lastIndexOf("-")+1);
//                                tempjson[i]._children[i2].techUrl = '/' + tempjson[i]._technician.Id;
//                                var countQty = tempjson[i]._children[i2].SMAX_PS_CountedQty__c;
//
//                                // SMAX_PS_Found_Item__c, SMAX_PS_EntryQty__c
//                                if (tempjson[i]._children[i2].SMAX_PS_Found_Item__c == true) {
//                                    tempjson[i]._children[i2].QtyCompare = tempjson[i]._children[i2].SMAX_PS_EntryQty__c + " (Found)";
//                                } else {
//                                    tempjson[i]._children[i2].QtyCompare = (countQty ? countQty : 0) + " / " + tempjson[i]._children[i2].SMAX_PS_BookedQty__c;
//                                }
//
//                                tempjson[i]._children[i2].ReasonText = '';
//                                if (tempjson[i]._children[i2].SMAX_PS_Why_Recount_Needed__c) {
//                                    tempjson[i]._children[i2].ReasonText += "\nWhy Recount Needed: " + tempjson[i]._children[i2].SMAX_PS_Why_Recount_Needed__c;
//                                }
//                                if (tempjson[i]._children[i2].SMAX_PS_Reason_for_Difference__c) {
//                                    tempjson[i]._children[i2].ReasonText += "\nReason for Difference: " + tempjson[i]._children[i2].SMAX_PS_Reason_for_Difference__c;
//                                }
//
//                                console.log('tempjson[i2]: '+JSON.stringify(tempjson[i]._children[i2]));
//                            }
//                        }
                    }
                    console.log('preFormattedJSON:'+JSON.stringify(this.inventoryCounts));
                    console.log('tempJson:'+JSON.stringify(tempjson));
                    this.treeItems=tempjson;

//                    var expandedTemp = [];
//                    for (var i = 0; i < this.inventoryCounts.length; i++){
//                        expandedTemp.push(this.inventoryCounts[i].Id);
//                    }
//
//                    console.log('expanded rows: '+JSON.stringify(expandedTemp));
//                    this.expandedRows = expandedTemp;
                    this.busySearching = false;
                })
                .catch((error) =>{
                    this.error = error;
					console.log('newest error'+JSON.stringify(this.error));
					// ITSVMX-1327 Show filter errors to user in LWC
					let errorMsg = (this.error.body) ? this.error.body.message : JSON.stringify(this.error);
					const evt = new ShowToastEvent({
						title: 'Filter Error',
						message: errorMsg,
						variant: 'error',
						mode: 'dismissable',
					});
					this.dispatchEvent(evt);
                    this.busySearching = false;
                });
        } else {
            this.busySearching = false;
        }
    } // End buildFilter

    handleRowToggle(event) {
        this.parentRow = event.detail.row;
        const rowId = event.detail.name;
        const hasChildrenContent = event.detail.hasChildrenContent;

        if (hasChildrenContent === false) {
            this.busySearching = true;

            // call a method to retrieve the updated data tree that includes the missing children
            getLines({inventoryCountId:this.parentRow.Id}).then(result => {

                var tempjson=JSON.parse(JSON.stringify(result).split('SMAX_PS_RequestedTechnician__r').join('_technician'));

                for(var i2 = 0; i2 < tempjson.length; i2++){
                    tempjson[i2].SMAX_PS_Status__c=tempjson[i2].SMAX_PS_InvCnt_Status__c;
                    tempjson[i2].StatusSummary = tempjson[i2].SMAX_PS_InvCnt_Status__c
                        + ('\n' + tempjson[i2].LastModifiedDate).replace('T', ' ').replace('.000Z', ' ');
                    tempjson[i2].LocationCode=this.parentRow.LocationCode;
                    tempjson[i2].Plant=this.parentRow.Plant;
                    tempjson[i2].TechName=this.parentRow.TechName;
                    tempjson[i2].TechId=this.parentRow.TechId;
                    tempjson[i2].TechSummary=this.parentRow.TechName; // Lets keep the lines simply the name..
                    tempjson[i2].PartNumber=tempjson[i2].SMAX_PS_Product__r.Partnum__c
                        + '\n' + tempjson[i2].SMAX_PS_Product__r.Name;
                    tempjson[i2].partUrl = '/' + tempjson[i2].SMAX_PS_Product__r.Id;
                    tempjson[i2].recordUrl = '/' + tempjson[i2].Id;
                    var recName = tempjson[i2].Name;
                    tempjson[i2].recordLabel = recName.substr(recName.lastIndexOf("-")+1);
                    tempjson[i2].techUrl = '/' + this.parentRow.TechId;
                    var countQty = tempjson[i2].SMAX_PS_CountedQty__c;
                    // SMAX_PS_Found_Item__c, SMAX_PS_EntryQty__c
                    if (tempjson[i2].SMAX_PS_Found_Item__c == true) {
                        tempjson[i2].QtyCompare = tempjson[i2].SMAX_PS_EntryQty__c + " (Found)";
                    } else {
                        tempjson[i2].QtyCompare = (countQty ? countQty : 0) + " / " + tempjson[i2].SMAX_PS_BookedQty__c;
                    }

                    // 8/6/20 tony - added to use a variable instead of a field
                    tempjson[i2].Difference = tempjson[i2].SMAX_PS_DifferenceValue__c;
                    tempjson[i2].currencyCode = tempjson[i2].CurrencyIsoCode;

                    tempjson[i2].ReasonText = '';
                    if (tempjson[i2].SMAX_PS_Why_Recount_Needed__c) {
                        tempjson[i2].ReasonText += "\nWhy Recount Needed: " + tempjson[i2].SMAX_PS_Why_Recount_Needed__c;
                    }
                    if (tempjson[i2].SMAX_PS_Reason_for_Difference__c) {
                        tempjson[i2].ReasonText += "\nReason for Difference: " + tempjson[i2].SMAX_PS_Reason_for_Difference__c;
                    }

                    console.log('tempjson[i2]: '+JSON.stringify(tempjson[i2]));
                }
                var newData = this.addChildrenToRow(this.treeItems, this.parentRow.Id, tempjson);
                this.treeItems = newData;

                this.busySearching = false;
            });
        }
    }

    addChildrenToRow(data, rowId, children) {
        // step through the array using recursion until we find the correct row to update
        const newData = data.map(row => {
            // does this row have a properly formatted _children key with content?
            let hasChildrenContent = false;
            if (
                // eslint-disable-next-line no-prototype-builtins
                row.hasOwnProperty('_children') &&
                Array.isArray(row._children) &&
                row._children.length > 0
            ) {
                hasChildrenContent = true;
            }

            // if this is the row that was toggled then add the child content
            if (row.Id === rowId) {
                row._children = children;
                // otherwise keep searching for the correct row by recursively searching the tree
            } else if (hasChildrenContent) {
                // NOTE: Don't need the recursion
                //this.addChildrenToRow(row._children, rowName, children);
            }

            return row;
        });

        return newData;
    }

    handleUpdate({data,error}){
        this.error2=null;
        this.updateMessage=null;
//        if(this.template.querySelector('lightning-tree-grid').getSelectedRows()==null||!this.template.querySelector('lightning-tree-grid').getSelectedRows()){
//            this.error2='Please select at least one row to update.'
//                    const evt = new ShowToastEvent({
//                        title: 'Update Error',
//                        message: 'Please select at least one row to update.',
//                        variant: 'error',
//                        mode: 'dismissable',
//                    });
//                    this.dispatchEvent(evt);
//        }
        if(this.selectedReviewStatus==null||this.selectedReviewStatus==='')
        {
            this.error2='Please provide a review status.'
            console.log('error2: '+this.error2);
            const evt = new ShowToastEvent({
                title: 'Update Error',
                message: 'Please provide a review status.',
                variant: 'error',
                mode: 'dismissable',
            });
            this.dispatchEvent(evt);
        }
        else if((this.selectedRejectReason==null||this.selectedRejectReason==='') && this.selectedReviewStatus==='Recount')
        {
            this.error2='Please add a reason for recount.'
            console.log('error2: '+this.error2);
            const evt = new ShowToastEvent({
                title: 'Update Error',
                message: 'Please add a reason for recount.',
                variant: 'error',
                mode: 'dismissable',
            });
            this.dispatchEvent(evt);
        }
        else
        {
            this.error2=null;
        }
        console.log('error2: '+this.error2);

        if((this.selectedReviewStatus==='Confirmed' || this.selectedReviewStatus==='Approved')
        	&& this.selectedRejectReason!=null && this.selectedRejectReason!='') {
            this.selectedRejectReason=null
        }
        var lines=[];
        var headers=[]; // 8/17/20 tony - added to allow update of Inventory Lines from the Header record being selected
        console.log('check for selected rows');
        if(this.template.querySelector('lightning-tree-grid').getSelectedRows()!=null && this.error2==null)
        {
            console.log('There are selected rows');
            this.busySearching = true;
            this.selectedRows=this.template.querySelector('lightning-tree-grid').getSelectedRows();
            for (var i = 0; i < this.selectedRows.length; i++){
                console.log('processing selectedRows['+ i +'] Inventory Count:' +this.selectedRows[i].SMAX_PS_InventoryCount__c + '  Status:' + this.selectedRows[i].SMAX_PS_Status__c);
                if(this.selectedRows[i].SMAX_PS_InventoryCount__c!=null&&this.selectedRows[i].SMAX_PS_InventoryCount__c!=''
                	&& (this.selectedRows[i].SMAX_PS_Status__c==='Submitted' || this.selectedRows[i].SMAX_PS_Status__c==='Confirmed')){
                   lines.push(this.selectedRows[i].Id);
                    console.log('currentId: '+this.selectedRows[i].Id+' name: '+this.selectedRows[i].Name);
                }
                // 8/17/20 tony - added to allow update of Inventory Lines from the Header record being selected
                //else if ((this.selectedRows[i].SMAX_PS_InventoryCount__c===null||this.selectedRows[i].SMAX_PS_InventoryCount__c==='')&&this.selectedRows[i].SMAX_PS_Status__c==='Submitted'){
                else if ((this.selectedRows[i].SMAX_PS_InventoryCount__c==null||this.selectedRows[i].SMAX_PS_InventoryCount__c==='')
                	&& (this.selectedRows[i].SMAX_PS_Status__c==='Submitted' || this.selectedRows[i].SMAX_PS_Status__c==='Confirmed')){
                    headers.push(this.selectedRows[i].Id);
                    console.log('Header - currentId: '+this.selectedRows[i].Id+' name: '+this.selectedRows[i].Name);
                    this.selectedRows[i].selected=false;
                }

                else{
                    console.log('No matches so setting selected to false');
                    this.selectedRows[i].selected=false;
                }
            }
            console.log('HeaderIds: '+JSON.stringify(headers)); // 8/17/20 tony - added to allow update of Inventory Lines from the Header record being selected
            //console.log('LineIds: '+JSON.stringify(lines));
            console.log('Selected Rows: '+JSON.stringify(this.selectedRows));

            // 8/17/20 tony - added to allow update of Inventory Lines from the Header record being selected
            for (var i = 0; i < this.selectedRows.length; i++){
                var parentId = this.selectedRows[i].SMAX_PS_InventoryCount__c;

                // Remove any header Id that has child line Ids selected
                if (headers.includes(parentId)){
                    var removeId = headers.indexOf(parentId);
                    if (removeId > -1) {
                    headers.splice(removeId, 1);
                    }
                }
            }

            this.lineIds=JSON.stringify(lines);
            console.log('LineIds: '+this.lineIds);
            if(this.lineIds!=null && this.lineIds!='' && this.lineIds!='[]')
            {
                this.updateObj={};
                this.updateObj.selectedLines=lines;
                this.updateObj.selectedReviewStatus=this.selectedReviewStatus;
                this.updateObj.selectedRejectReason=this.selectedRejectReason;
                console.log('updateObj: '+JSON.stringify(this.updateObj));

                updateInventory({iList:this.updateObj})
                   .then(result =>{
                       this.updateMessage = result;
                       console.log(this.updateMessage);
                       this.updateResult=this.updateMessage;
                       this.selectedRowMessage=null;
                       this.buildFilter();
                        this.busySearching = false;
                    })
                    .catch((error) =>{
                        this.error = error;
                        console.log('error'+JSON.stringify(this.error));
                        this.busySearching = false;
                    })
            }
            
            // 8/17/20 tony - added to allow update of Inventory Lines from the Header record being selected
            for(var i = 0; i < headers.length; i++){
                this.updateObj={};
                this.updateObj.selectedHeaderLine=headers[i];
                this.updateObj.selectedReviewStatus=this.selectedReviewStatus;
                this.updateObj.selectedRejectReason=this.selectedRejectReason;
                console.log('HEADER updateObj: '+JSON.stringify(this.updateObj));

                updateInventoryFromHeader({headerData:this.updateObj})
                   .then(result =>{
                       this.updateMessage = result;
                       console.log(this.updateMessage);
                       this.updateResult=this.updateMessage;
                       this.selectedRowMessage=null;
                       //this.buildFilter();  //TODO:  When should this be done for headers
                        this.busySearching = false;
                    })
                    .catch((error) =>{
                        this.error = error;
                        console.log('error'+JSON.stringify(this.error));
                        this.busySearching = false;
                    })
            }

        }
    } // End handleUpdate

    clearFilter()
    {
        this.selectedPlants=null;
        this.selectedStatuses=['Submitted'];
        this.selectedTechnicians=[];
        this.treeItems=null;
        this.inventoryList=null;
    }

}