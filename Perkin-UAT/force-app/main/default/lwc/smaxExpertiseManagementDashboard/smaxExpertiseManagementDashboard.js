/**
 * Created by tony on 4/15/21.
 */

import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchTechSkills from '@salesforce/apex/SMAX_PS_ExpertiseManagementDashboard.searchTechSkills';
import buildTechSkillsTableFromSearch from '@salesforce/apex/SMAX_PS_ExpertiseManagementDashboard.buildTechSkillsTableFromSearch';
import removeExpertise from '@salesforce/apex/SMAX_PS_ExpertiseManagementDashboard.removeExpertise';
import createExpertise from '@salesforce/apex/SMAX_PS_ExpertiseManagementDashboard.createExpertise';
import getReportId from '@salesforce/apex/SMAX_PS_ExpertiseManagementDashboard.getReportId';
import getRecommendedActions from '@salesforce/apex/SMAX_PS_ExpertiseManagementDashboard.getRecommendedActions';

const techSkillActions = [
//    { label: 'Create Expertise', name: 'createExpertise' },
//    { label: 'Remove Expertise', name: 'removeExpertise' },
    { label: 'Training Report', name: 'trainingReport' },
    { label: 'Field Report', name: 'fieldReport' }
];

const techSkillColumns = [
//    { label: 'Key', fieldName: 'key' },
    { label: 'Technician/Skill', fieldName: 'keyUrl', type: 'url', typeAttributes: { label: { fieldName: 'name' }, target: '_blank' } },
    { label: 'Territory', fieldName: 'territory', type: 'text' },
//    { label: 'Training', fieldName: 'trainingScore', type: 'number', cellAttributes: { alignment: 'center' }, initialWidth: 120 },
//    { label: 'Training', fieldName: 'trainingScore', type: 'number', initialWidth: 100, cellAttributes: { alignment: 'center' } },
    { label: 'Training', fieldName: 'trainingSummary', type: 'text', initialWidth: 150, cellAttributes: { alignment: 'center' } },
//    { label: 'Training Report', type: 'button-icon', hideDefaultActions: true,
//            	typeAttributes: { name: 'trainingReport', variant: 'brand', iconName: 'utility:table', disabled: {fieldName: 'disableReport'} }, initialWidth: 120 },
//    { label: 'Field', fieldName: 'fieldScore', type: 'number', cellAttributes: { alignment: 'center' }, initialWidth: 120 },
//    { label: 'Field', fieldName: 'fieldScore', type: 'number', initialWidth: 90, cellAttributes: { alignment: 'center' } },
    { label: 'Field', fieldName: 'fieldSummary', type: 'text', initialWidth: 150, cellAttributes: { alignment: 'center' } },
//    { label: 'Field Report', type: 'button-icon', hideDefaultActions: true,
//                	typeAttributes: { name: 'fieldReport', variant: 'brand', iconName: 'utility:table', disabled: {fieldName: 'disableReport'} }, initialWidth: 120 },
//    { label: 'Experience Activity Types', fieldName: 'experienceActivityType', type: 'text', cellAttributes: { alignment: 'center' }, initialWidth: 200 },
//    { label: 'Final', fieldName: 'finalScore', type: 'number', cellAttributes: { alignment: 'center' }, initialWidth: 120 },
    { label: 'Proposed', fieldName: 'finalScore', type: 'number', initialWidth: 110, cellAttributes: { alignment: 'center' } },
//    { label: 'Proposed Activity Types', fieldName: 'experienceActivityType', type: 'text', cellAttributes: { alignment: 'center' } },
//    { label: 'Expertise', fieldName: 'expertiseScore', type: 'number', cellAttributes: { alignment: 'center' }, initialWidth: 120 },
//    { label: 'Expertise', fieldName: 'expertiseExists', type: 'boolean', cellAttributes: { alignment: 'center' }, initialWidth: 120 },
//    { label: 'Expertise', fieldName: 'expertiseExists', type: 'boolean', initialWidth: 90, cellAttributes: { alignment: 'center' } },
    { label: 'Expertise', fieldName: 'expertiseUrl', type: 'url', initialWidth: 105, typeAttributes: { label: { fieldName: 'expertiseScore' }, target: '_blank' }, cellAttributes: { alignment: 'center' } },
//    { label: 'Expertise Activity Types', fieldName: 'expertiseActivityType', type: 'text', cellAttributes: { alignment: 'center' }, initialWidth: 200 },
    { label: 'Expertise Activity Types', fieldName: 'expertiseActivityType', type: 'text', cellAttributes: { alignment: 'center' } },
    { label: 'Recommendation', fieldName: 'recommendedAction', type: 'text', cellAttributes: { alignment: 'center' } },
    { label: 'Create', type: 'button-icon', hideDefaultActions: true,
        	typeAttributes: { name: 'createExpertise', variant: 'brand', iconName: 'utility:new', disabled: {fieldName: 'disableCreate'} }, initialWidth: 70 },
    { label: 'Remove', type: 'button-icon', hideDefaultActions: true,
        	typeAttributes: { name: 'removeExpertise', variant: 'inverse', iconName: 'utility:delete', disabled: {fieldName: 'disableRemove'} }, initialWidth: 70 },
    { label: 'Last Modified By', fieldName: 'lastModified', type: 'text', cellAttributes: { alignment: 'center' } },
    { type: 'action', typeAttributes: { rowActions: techSkillActions, menuAlignment: 'right' }}
];

export default class SmaxExpertiseManagementDashboard extends LightningElement {

    @track selectedTechSkills = [];
    @track lookupErrors = [];
    @track isProcessing = false;
    @track rangeValue = ['training', 'field', 'expertise'];
    @track inputMin = 0.0;
    @track inputMax = 5.0;
    @track techSkillData = [];
    @track techSkillColumns = techSkillColumns;
    @track techSkillActions = techSkillActions;
    @track techSkillSelectedRowIds = [];
    @track techSkillExpandedRows = [];
    @track selectedRowKey = '';
    @track selectedTechnician = '';
    @track selectedSkill = '';
    @track selectedFinalScore = 0;
    @track expertiseId = '';
    @track inputSkillLevel = 0;
    @track showCreateExpertise = false;

    @track recActions = [];  //  value/label pairs for selectable recommendation action values
    @track selectedRecActions = [];  //  .value of selected status values
    _recommendedActionsResponse;  //  statuses variable for apex refresh calls

    @wire(getRecommendedActions, {})
    wiredRecommendedActions(response) {
        this._recommendedActionsResponse = response;
        let error = response && response.error;
        let data = response && response.data;
        if(data) {
            this.recActions = [];
            let i = 0;
            for(i=0; i<data.length; i++) {
                this.recActions = [...this.recActions, {value: data[i].value, label: data[i].label}];
            }
            //this.selectedRecActions = this.recActions.map(option => option.value);
            console.info('Selected Rec Actions = ' + this.selectedRecActions);
        }
        else if (error) {
            this.recActions = ['None'];
        }
    }

    handleRecActionChange(event) {
        const selectedRecActionValues = event.detail.value;
		this.selectedRecActions = selectedRecActionValues;
    }

    // Handle the Search for Technicians and Skills
    handleTechSkillSearch(event) {
        searchTechSkills(event.detail)
            .then((results) => {
                this.template.querySelector('c-custom-lookup').setSearchResults(results);
            })
            .catch((error) => {
                const toastEvent = new ShowToastEvent('Lookup Error', 'An error occurred while searching with the lookup field.', 'error');
                this.dispatchEvent(toastEvent);
                console.error('Lookup error', JSON.stringify(error));
                this.lookupErrors = [error];
            });
    }

    // Handle selection changes of the Technician and Skills
    handleTechSkillSelectionChange(event) {
        const selection = this.template.querySelector('c-custom-lookup').getSelection();
        this.selectedTechSkills = selection;
        console.info('Selected TechSkills: ' + JSON.stringify(this.selectedTechSkills));
    }

    // Provide the options for the Range Checkbox Group
    get rangeOptions() {
        return [
            { label: 'Training', value: 'training' },
            { label: 'Field', value: 'field' },
            { label: 'Expertise', value: 'expertise' },
        ];
    }

    // Handle changes to the Range Checkbox Group
    handleRangeFilterChange(event) {
        this.rangeValue = event.detail.value;
    }

    // Handle changes to the Minimum Range value
    handleInputMinChange(e) {
        this.inputMin = e.detail.value;
    }

    // Handle changes to the Maximum Range value
    handleInputMaxChange(e) {
        this.inputMax = e.detail.value;
    }

    // Handle Search button Click
    handleSearchClick() {
        console.log('Search was Clicked')

        let selectedTechSkillIds = [];
        this.selectedTechSkills.forEach(t => selectedTechSkillIds.push(t.id));
        buildTechSkillsTableFromSearch({techSkillIds:selectedTechSkillIds, rangeMin:this.inputMin, rangeMax:this.inputMax, rangeTypes:this.rangeValue, recommendedActions: this.selectedRecActions})
            .then((results) => {
                let tempData = JSON.stringify(results);
                tempData = tempData.replace(/items/g,'_children'); //Tree Grid requires _children instead of items
                tempData = tempData.replace(/\"_children\":\[\]\,/g, ''); //Remove the _children that have nothing in their list
                this.techSkillData = JSON.parse(tempData);


//                let keyUrl;
//                this.techSkillData = results.map(row => {
//                    keyUrl = '/' + row.key;
//                    return {...row , keyUrl}
//                })

                //this.techSkillData = results;
                console.log('this.techSkillData: ' + JSON.stringify(this.techSkillData, null, 2));
                console.log('this.techSkillData.length: ' + this.techSkillData.length);

                // Expand all the rows
                let tempTechSkillExpandedRows = [];
                for(let i = 0; i < this.techSkillData.length; i++) {
                    let expanded = JSON.stringify(this.techSkillData[i].expanded);
                    let techSkillId = JSON.stringify(this.techSkillData[i].key);
                    techSkillId = techSkillId.replace(/"/g, '');
                    console.log('techSkillId: ' + techSkillId);
                    if (expanded === 'true') {
                        console.log('tempTechSkillExpandedRows: ' + tempTechSkillExpandedRows);
                        tempTechSkillExpandedRows.push(techSkillId);
                    }
                }
                this.techSkillExpandedRows = [...tempTechSkillExpandedRows];
//                this.techSkillExpandedRows = [...this.techSkillExpandedRows, tempTechSkillExpandedRows];
                console.log('this.techSkillExpandedRows: ' + this.techSkillExpandedRows);

                })
            .catch((error) => {
                const evt = new ShowToastEvent({
                    title: 'buildTechSkillsTableFromSearch Error',
                    message: error.body.message,
                    variant: 'error',
                    mode: 'dismissible',
                });

                this.dispatchEvent(evt);
                console.error('buildTechSkillsTableFromSearch error', JSON.stringify(error));
                this.lookupErrors = [error];
            });
    }

    // Handle Clear Filter button click
    clearFilter(){
        this.selectedTechSkills = [];
        this.techSkillExpandedRows = [];
        this.techSkillData = [];
        this.rangeValue = ['training', 'field', 'expertise'];
        this.inputMin = 0.0;
        this.inputMax = 5.0;
        this.selectedRowKey = '';
        this.selectedTechnician = '';
        this.selectedSKill = '';
        this.expertiseId = '';
        this.selectedFinalScore = 0;
    }


    handleTechSkillOnRowAction(event) {
        console.log('handleTechSkillOnRowAction');
        console.log('event: ' + JSON.stringify(event, null, 2));

        console.log('event.detail.row.key: ' + event.detail.row.key);

        this.selectedRowKey = event.detail.row.key;
        console.log('selectedRowKey: ' + this.selectedRowKey);
        this.selectedTechnician = event.detail.row.techName;
        console.log('selectedTechnician: ' + this.selectedTechnician);
        this.selectedSkill = event.detail.row.name;
        console.log('selectedSkill: ' + this.selectedSkill);
        this.selectedFinalScore = event.detail.row.finalScore;
        console.log('selectedFinalScore: ' + this.selectedFinalScore);

        let actionName = event.detail.action.name;
        console.log('actionName: ' + actionName);
        this.expertiseId = event.detail.row.expertiseId;
        console.log('expertiseId: ' + this.expertiseId);

        this.isProcessing = true;

        if (actionName === 'removeExpertise') {

            // If this is a header record then don't remove an Expertise record
            console.log('this.selectedRowKey.length: ' + this.selectedRowKey.length);
            if (this.selectedRowKey.length > 30) {
                removeExpertise({techSkillKey:this.selectedRowKey, expertiseId:this.expertiseId})
                    .then((results) => {
                        this.techSkillProcessingResults = results;
                        console.log('this.techSkillProcessingResults: ' + JSON.stringify(this.techSkillProcessingResults, null, 2));
                        const evt = new ShowToastEvent({title: 'Delete Expertise', message: 'Delete successful',  variant: 'success'});
                        this.dispatchEvent(evt);
                        // Refresh the table
                        this.handleSearchClick();
                        })
                    .catch((error) => {
                        const evt = new ShowToastEvent({
                            title: 'processTechSkillsRowAction Error',
                            message: error.body.message,
                            variant: 'error',
                            mode: 'dismissible',
                        });

                        this.dispatchEvent(evt);
                        console.error('processTechSkillsRowAction error', JSON.stringify(error));
                        this.lookupErrors = [error];
                    });
            } else {
                const evt = new ShowToastEvent({title: 'Remove Expertise', message: 'You cannot remove an Expertise from a Technician, please select a Skill.',  variant: 'error'});
                this.dispatchEvent(evt);
            }
        }

        if (actionName === 'createExpertise') {

            // If this is a header record then don't create and Expertise record
            console.log('this.selectedRowKey.length: ' + this.selectedRowKey.length);
            if (this.selectedRowKey.length > 30) {
//                this.showCreateExpertise = true;

                console.log('Calling createExpertise');
                createExpertise({techSkillKey:this.selectedRowKey, skillLevel:this.selectedFinalScore})
                    .then((results) => {
                        this.techSkillProcessingResults = results;
                        console.log('this.techSkillProcessingResults: ' + JSON.stringify(this.techSkillProcessingResults, null, 2));
                        const evt = new ShowToastEvent({title: 'Create Expertise', message: 'Save successful',  variant: 'success'});
                        this.dispatchEvent(evt);
                        // Refresh the table
                        this.handleSearchClick();
                        })
                    .catch((error) => {
                        const evt = new ShowToastEvent({
                            title: 'processTechSkillsRowAction Error',
                            message: error.body.message,
                            variant: 'error',
                            mode: 'dismissible',
                        });

                        this.dispatchEvent(evt);
                        console.error('processTechSkillsRowAction error', JSON.stringify(error));
                        this.lookupErrors = [error];
                    });

            } else {
                const evt = new ShowToastEvent({title: 'Create Expertise', message: 'You cannot create an Expertise from a Technician, please select a Skill.',  variant: 'error'});
                this.dispatchEvent(evt);
            }
        }

        if(actionName == 'trainingReport' || actionName == 'fieldReport') {
            this.doReportPop(event);
        }

        this.isProcessing = false;
    }

    handleInputSkillLevelChange(event) {
        this.inputSkillLevel = event.detail.value;
    }

//    handleCreateExpertiseSave(event) {
//        console.log('handleCreateExpertiseSave');
//        console.log('event: ' + event);
//
//        createExpertise({techSkillKey:this.selectedRowKey, skillLevel:this.inputSkillLevel, expertiseId:this.expertiseId})
//            .then((results) => {
//                this.techSkillProcessingResults = results;
//                console.log('this.techSkillProcessingResults: ' + JSON.stringify(this.techSkillProcessingResults, null, 2));
//                const evt = new ShowToastEvent({title: 'Save Expertise', message: 'Save successful',  variant: 'success'});
//                this.dispatchEvent(evt);
//                })
//            .catch((error) => {
//                const evt = new ShowToastEvent({
//                    title: 'processTechSkillsRowAction Error',
//                    message: error.body.message,
//                    variant: 'error',
//                    mode: 'dismissible',
//                });
//
//                this.dispatchEvent(evt);
//                console.error('processTechSkillsRowAction error', JSON.stringify(error));
//                this.lookupErrors = [error];
//            });
//
//        this.showCreateExpertise = false;
//    }

    //-----------------------//
    // -- REPORT REDIRECT -- //
    //-----------------------//
    _reportType = '';
    _memberName = '';
    _skillName = '';
    @track reportUrl = '';

    doReportPop(event) {
        this._reportType = event.detail.action.name;
        this._memberName = '"' + event.detail.row.techName + '"';
        this._skillName = event.detail.row.name;
        console.log(JSON.stringify(event, null, 2));

        var d = new Date();
        var datePreUrl = (d.getMonth()+1) + '/' + d.getDate() + '/' + d.getFullYear();
        d.setMonth(d.getMonth() - Number(this.horizonValue));
        var dateForUrl = (d.getMonth()+1) + '/' + d.getDate() + '/' + d.getFullYear();
        console.log('Date Before = ' + datePreUrl + ', Date = ' + dateForUrl);

        getReportId({reportType: this._reportType}).then(reportId => {

            console.log('reportType = ' + this._reportType + ', Report Id = ' + reportId);
            if (reportId != null) {
//                this.reportUrl = window.location.origin + '/lightning/r/Report/'+encodeURIComponent(reportId)+'/view?fv0='+encodeURIComponent(this._reportType)+'&fv1='+encodeURIComponent(this._reportProduct)+'&fv2='+encodeURIComponent(this._reportModel)+'&fv3='+encodeURIComponent(dateForUrl);
                this.reportUrl = window.location.origin + '/lightning/r/Report/'+encodeURIComponent(reportId)+'/view?fv0='+encodeURIComponent(this._memberName)+'&fv1='+encodeURIComponent(this._skillName);
                window.open(this.reportUrl);
            } else {
                console.error('Report Error: No Report Found!');
                const evt = new ShowToastEvent({
                    title: 'Report Error',
                    message: 'No Report found to match this report type.',
                    variant: 'error',
                    mode: 'dismissible'
                });
                this.dispatchEvent(evt);
            }

        })
        .catch(error => {
            console.error('Error from Apex call to : getReportId()' + JSON.stringify(error, null, 2));
            const evt = new ShowToastEvent({
                title: 'Report Error',
                message: 'An error occurred while searching for Report.',
                variant: 'error',
                mode: 'dismissible'
            });
            this.dispatchEvent(evt);
        })
    }
}