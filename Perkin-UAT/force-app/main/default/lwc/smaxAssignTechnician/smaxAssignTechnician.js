/**
 * Created by Bolt Data - John Lill on 5/20/2021.
 */

import { LightningElement, api, wire, track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import extendedLightningDatatable from 'c/extendedLightningDatatable';
import getCandidates from '@salesforce/apex/SMAX_PS_AutoAssignmentObjectives.getCandidates';
import NAME_FIELD from '@salesforce/schema/SVMXC__Service_Order__c.Name';
import TECH_NAME_FIELD from '@salesforce/schema/SVMXC__Service_Order__c.SVMXC__Group_Member__r.Name';
import SCHEDULED_DATE_FIELD from '@salesforce/schema/SVMXC__Service_Order__c.SVMXC__Scheduled_Date__c';
import GEOGRAPHY from '@salesforce/schema/SVMXC__Service_Order__c.SMAX_PS_Geography__c';
import MODEL_SERIES from '@salesforce/schema/SVMXC__Service_Order__c.SMAX_PS_ModelSeries__c';
import getAssignmentPolicies from '@salesforce/apex/SMAX_PS_AutoAssignmentObjectives.getAssignmentPolicies';
import assignTech from '@salesforce/apex/SMAX_PS_AutoAssignmentObjectives.assignTech';

const fields = [
    NAME_FIELD,
    TECH_NAME_FIELD,
    SCHEDULED_DATE_FIELD,
    GEOGRAPHY,
    MODEL_SERIES
];

const candidateColumns = [
    { label: 'Name', fieldName: 'techName' },
    { label: 'Score', fieldName: 'totalScore', type: 'number', sortable: true, initialWidth: 100, cellAttributes: { alignment: 'left' } },
    { label: 'Expertise', fieldName: 'expertiseDisplay', type: 'text', sortable: true, initialWidth: 110, cellAttributes: { alignment: 'left' } },
    { label: 'Proximity', fieldName: 'proximityMileage', type: 'text', sortable: true, initialWidth: 170, cellAttributes: { alignment: 'left' } },
    { label: 'Availability', fieldName: 'availabilityDisplay', type: 'text', sortable: true, initialWidth: 120, cellAttributes: { alignment: 'left' } },
    { label: 'Continuity', fieldName: 'continuityDisplay', type: 'text', sortable: true, initialWidth: 110, cellAttributes: { alignment: 'left' } },
    { label: 'Bundling', fieldName: 'bundlingDisplay', type: 'text', sortable: true, initialWidth: 100, cellAttributes: { alignment: 'left' } },

//    { label: 'Date/Time', fieldName: 'firstTimeSlot', type: 'date', initialWidth: 160,
//        typeAttributes:{
//            year: 'numeric',
//            month: '2-digit',
//            day: '2-digit',
//            hour: '2-digit',
//            minute: '2-digit'
//        }
//    },

    { label: 'Pick Date/Time', type: 'picklist', wrapText: true, hideDefaultActions: true, initialWidth: 220,
        typeAttributes: {
            name: 'picklist',
            options: {fieldName: 'timeSlotOptions'},
            value: {fieldName: 'firstTimeSlot'}
        }
    },

    { label: 'Assign', type: 'button', hideDefaultActions: true, initialWidth: 90,
        	typeAttributes: {
        	    name: 'assignTechnician',
        	    alternativeText: 'Assign',
        	    variant: 'brand',
//        	    iconName: 'utility:new',
//        	    iconName: 'standard:avatar',
        	    label: 'Assign',
        	    disabled: {fieldName: 'disableAssignTechnician'}
        	}
    },
//    { type: 'action', typeAttributes: { rowActions: actions } },
];


export default class SmaxAssignTechnician extends LightningElement {
    debugger;
    @track workOrder;
    @track woNum;
    @track techId;
    @track expId;
    @track techName;
    @track startDate;
    @track endDate;
    @track geoId;
    @track modelSeries;
    @track assignmentPolicies;
    @track assignTechResults;
    @track selectedAssignmentPolicy = "Standard";
    @track showGetCandidates = false;
    @track candidates;
    @track isProcessing = false;
    @track candidateColumns = candidateColumns;
    @api recordId;

    @wire(getRecord, { recordId: "$recordId", fields })
        wiredRecord({data}) {
            if (data) {
                this.workOrder = data;
                this.startDate = this.workOrder.fields.SVMXC__Scheduled_Date__c.value;
                this.endDate = this.startDate;
                this.woNum = this.workOrder.fields.Name.value;
                this.geoId = this.workOrder.fields.SMAX_PS_Geography__c.value;
                this.modelSeries = this.workOrder.fields.SMAX_PS_ModelSeries__c.value;
                this.techName = this.workOrder.fields.SVMXC__Group_Member__r?.displayValue;
                console.log('this.techName: ' + this.techName);
//                console.log('this.workOrder: ' + JSON.stringify(this.workOrder, null, 2));
            }
        }

    handleStartDateChange(event){
        console.log('Start Date - event.detail.value: ' + event.detail.value);
        this.startDate = event.detail.value;
    }

    handleEndDateChange(event){
        console.log('End Date - event.detail.value: ' + event.detail.value);
        this.endDate = event.detail.value;
    }

    get techName() {
        return getFieldValue(this.workOrder, TECH_NAME_FIELD);
    }

    @wire(getAssignmentPolicies)
    policies({data}){
        if (data){
            console.log('getAssignmentPolicies: ' + JSON.stringify(data));
            this.assignmentPolicies = data;
        }
    }

    handleAssignmentPolicyChange(event)
    {
        console.log('Assignment Policy - event.detail.value: ' + event.detail.value);
        this.selectedAssignmentPolicy = event.detail.value;
    }

    getDateString(dt) {
        var nDate = dt.getDate(),
        nMonth = dt.getMonth(),
        nYear = dt.getFullYear();
        return nYear+'-'+this.zeroPad(nMonth + 1, 2)+'-'+this.zeroPad(nDate, 2);
    }

    getTimeString(dt) {
        var nHour = dt.getHours(),
        nMin = dt.getMinutes();
        return this.zeroPad((nHour+11)%12 + 1, 2)+':'+this.zeroPad(nMin, 2)+(nHour<12 ? ' AM' : ' PM');
    }

    zeroPad(nNum, nPad) {
      return ('' + (Math.pow(10, nPad) + nNum)).slice(1);
    }

    handleGetCandidatesClick(event)
    {
        console.log('Get Candidates Button was Clicked')
        this.isProcessing = true;

        console.log('this.startDate: ' + this.startDate);
        console.log('this.endDate: ' + this.endDate);

        getCandidates({woId:this.recordId, firstDate:this.startDate, lastDate:this.endDate, policyDevName:this.selectedAssignmentPolicy})
            .then((result) => {
                console.log('Get Candidates Result = ' + JSON.stringify(result));
                this.candidates = result;

                this.candidates.forEach(c => {
                   console.log('c: ' + JSON.stringify(c, null, 2));
                   if (c.hasOwnProperty('timeSlots')) {
                       console.log('c.timeSlots: ' + JSON.stringify(c.timeSlots));
                       c.timeSlotOptions = c.timeSlots?.map(ts => {
                           console.log('ts: ' + ts);
                           let labelDateTime = new Date(ts);
                           let displayTs = this.getDateString(labelDateTime) + ' ' + this.getTimeString(labelDateTime);
                           return { label: displayTs, value: ts };
                       });
                   } else {
                       console.log('No timeSlots found for candidate: ' + c.techName);
                   }

                });
                console.log('Get Candidates With Options = ' + JSON.stringify(this.candidates));
                this.candidates.forEach(c => {
                    if (c.mileage != undefined)
                    {
                        return c.proximityMileage = c.proximityDisplay + ' [' + c.mileage + ' miles]';
                    } else
                    {
                        return c.proximityMileage = c.proximityDisplay;
                    }
                });
                this.isProcessing = false;
                this.showGetCandidates = true;

                if (this.candidates.size == 0) {
                    const evt = new ShowToastEvent({ title: 'Get Candidates Error', message: 'Could not find a matching Technician for Geography: ' + this.geoId + ' and Skill: ' + this.modelSeries, variant: 'error', mode: 'sticky'});
                    this.dispatchEvent(evt);
                }
            })
            .catch((error) => {
                console.error('Get Candidates Error: ', JSON.stringify(error));
                this.isProcessing = false;
                const evt = new ShowToastEvent({ title: 'Get Candidates Error', message: 'Error: ' + error.body?.message + 'StackTrace: ' + error.body?.stackTrace, variant: 'error', mode: 'sticky'});
                this.dispatchEvent(evt);
            });
    }

    handleGetCandidatesClose(event)
    {
        this.showGetCandidates = false;
    }

    handleCandidatesRowAction(event)
    {
        console.log('handleCandidatesRowAction');
        console.log('event: ' + JSON.stringify(event, null, 2));

        console.log('event.detail.row.key: ' + event.detail.row.key);
        console.log('workOrder Id: ' + this.recordId);
        this.expId = event.detail.row.expId;
        console.log('expId: ' + this.expId);
        this.techId = event.detail.row.techId;
        console.log('techId: ' + this.techId);

        let actionName = event.detail.action.name;
        console.log('actionName: ' + actionName);

        this.isProcessing = true;

        if (actionName === 'picklist')
        {
            console.log('We are picking a date time');
        }

        if (actionName === 'assignTechnician')
        {
            console.log('Calling assignTech');
            this.isProcessing = true;

            if (typeof this.selectedDateTime === 'undefined')
            {
                this.selectedDateTime = event.detail.row.firstTimeSlot;
                console.log('selectedDateTime: ' + this.selectedDateTime);
            }

            // If it's still undefined then they have not picked a date/time
            if (typeof this.selectedDateTime === 'undefined')
            {
                console.log('They need to select a date/time');
                const evt = new ShowToastEvent({
                    title: 'Pick a Date/Time',
                    message: 'Assignment was unsuccessful. Please select a Date/Time.',
                    variant: 'warning',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.isProcessing = false;

            }
            else
            {
                assignTech({woId:this.recordId, techId:this.techId, schedDateTime:this.selectedDateTime, expId:this.expId})
                    .then((results) => {
                        this.assignTechResults = results;
                        console.log('this.assignTechResults: ' + JSON.stringify(this.assignTechResults, null, 2));
                        if (this.assignTechResults === 'Success')
                        {
                            const evt = new ShowToastEvent({
                                title: 'Assign Technician',
                                message: 'Assignment successful',
                                variant: 'success',
                                mode: 'dismissible'
                            });
                            this.dispatchEvent(evt);
                            this.showGetCandidates = false;

                            // Notify LDS that you've changed the record outside its mechanisms.
                            // This should refresh the page data
                            getRecordNotifyChange([{recordId: this.recordId}]);
                        } else
                        {
                            const evt = new ShowToastEvent({
                                title: 'Assign Technician',
                                message: 'Assignment was unsuccessful. Please ensure that a calendar event does not already exist for this Work Order/Technician. \n A System Administrator can check the debug logs if more details are needed.',
                                variant: 'warning',
                                mode: 'sticky'
                            });
                            this.dispatchEvent(evt);
                        }

                        this.isProcessing = false;
                    })
                    .catch((error) => {
                        const evt = new ShowToastEvent({
                            title: 'Assign Technician Error',
                            message: error.body.message,
                            variant: 'error',
                            mode: 'dismissible',
                        });

                        this.dispatchEvent(evt);
                        console.error('Assign Technician Error', JSON.stringify(error));

                        this.isProcessing = false;
                    });

            }

        }
    }

    handlePicklistChanged(event)
    {
        console.log('handlePicklistChanged');
        console.log('event.detail: ' + JSON.stringify(event.detail, null, 2));

        event.stopPropagation();
        console.log('selectedDateTime before: ' + this.selectedDateTime);
        this.selectedDateTime = event.detail.data.value;
        console.log('selectedDateTime after: ' + this.selectedDateTime);
    }

    handleValueSelect(event)
    {
        console.log('handleValueSelect');
        console.log('event: ' + JSON.stringify(event, null, 2));
    }

    handleCellChange(event)
    {
       console.log('handleCellChange');
       console.log('event: ' + JSON.stringify(event, null, 2));
    }

//    wrapperData = [];
//    data = tableData;
//    columns = columns;
    defaultSortDirection = 'desc';
    sortDirection = 'desc';
    sortedBy;

    // Used to sort the 'Age' column
    sortBy(field, reverse, primer) {
        const key = primer
            ? function(x) {
                  return primer(x[field]);
              }
            : function(x) {
                  return x[field];
              };

        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }
}