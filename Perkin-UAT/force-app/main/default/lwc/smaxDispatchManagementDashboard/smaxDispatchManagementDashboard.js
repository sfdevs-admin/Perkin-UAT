/**
 * Created by tony on 1/20/21.
 */

import { LightningElement, wire, track } from 'lwc';
//import { createRecord } from 'lighting/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import loadPermissions from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.loadPermissions';
import getUnassignedGeographiesCount from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.getUnassignedGeographiesCount';
import searchTerritories from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.searchTerritories';
import buildWrappers from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.buildWrappers';
import buildTeams from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.buildTeams';
import buildTreeFromSearch from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.buildTreeFromSearch';
import buildDispatcherDataTable from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.buildDispatcherDataTable';
import buildTechnicianDataTable from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.buildTechnicianDataTable';
import selectedTerrIdsTeamIdsInDispatcherAccess from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.selectedTerrIdsTeamIdsInDispatcherAccess';
import getChildTerritoryIds from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.getChildTerritoryIds';
import saveDispatcherEditDetails from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.saveDispatcherEditDetails';
import loadManageGeoGrid from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.loadManageGeoGrid';
import saveManageGeoGrid from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.saveManageGeoGrid';
import loadManageDispatchersGrid from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.loadManageDispatchersGrid';
import saveManageDispatchersGrid from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.saveManageDispatchersGrid';
import searchGeoCheckboxTerritories from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.searchGeoCheckboxTerritories';
import searchGeoCheckboxTeams from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.searchGeoCheckboxTeams';
import loadGeoCheckbox from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.loadGeoCheckbox';
import saveGeoCheckbox from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.saveGeoCheckbox';
import loadTechnicianEditDetails from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.loadTechnicianEditDetails';
import saveTechnicianEditDetails from '@salesforce/apex/SMAX_PS_DispatchManagementDashboard.saveTechnicianEditDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CheckboxGrid } from './checkboxGrid';

const actions = [
    { label: 'Edit', name: 'edit' },
];

const dispatcherTerritoryActions = [
    { label: 'Select Children', name: 'selectChildren' },
    { label: 'Unselect Children', name: 'unselectChildren' },
];

const dispatcherColumns = [
    { label: 'Dispatcher Name', fieldName: 'fullName' },
    { label: 'User Profile', fieldName: 'profileName' },
    { label: 'Territory', fieldName: 'territory' },
    { label: 'Is Active?', fieldName: 'isActive', type: 'boolean' },
    { type: 'action', typeAttributes: { rowActions: actions } },
];

const technicianColumns = [
    { label: 'Technician Name', fieldName: 'fullName' },
    { label: 'User Profile', fieldName: 'profileName' },
    { label: 'Territory', fieldName: 'territory' },
    { label: 'Team', fieldName: 'team' },
    { label: '# of Geographies', fieldName: 'numGeographies' },
    { type: 'action', typeAttributes: { rowActions: actions } },
];

const dispatcherTerritoryColumns = [
    { label: 'Territory', fieldName: 'label' },
    { label: 'Territory Type', fieldName: 'territoryType', initialWidth: 160 },
    { type: 'action', typeAttributes: { rowActions: dispatcherTerritoryActions } },
];

const teamColumns = [
    { label: 'Name', fieldName: 'name' },
    { label: 'Enterprise', fieldName: 'enterprise', type: 'boolean', initialWidth: 100 },
    { label: 'Active', fieldName: 'active', type: 'boolean', initialWidth: 100 },
];

export default class SmaxDispatchManagementDashboard extends NavigationMixin(LightningElement) {

    @track disableEditDispatchers = false;
    @track disableEditTechnicians = false;

    @track allTerritories = [];

    @track selectedTerritory;
    @track selectedTerritoryType;
    @track selectedTerritories = [];

    @track filterValue = [];
    @track unassignedGeographiesCount;

    @track isProcessing = false;
    @track dispatchersIsProcessing = false;
    @track techniciansIsProcessing = false;
    @track error;
    @track lookupErrors = [];
    @track filterError;

    @track dispatcherData = [];
    @track dispatcherId;
    @track dispatcherDataName;
    @track dispatcherColumns = dispatcherColumns;
    @track technicianData = [];
    @track technicianColumns = technicianColumns;

	@track territoryMultiSelect = false;
    @track technicianEditDetails;
    @track technicianEditDetailsName;
    @track technicianEditDetailsId;
    @track technicianEditDetailsTerritory;
    @track technicianEditDetailsTerritoryId;
    @track technicianSelectedTerritory = {};
    @track technicianEditDetailsTeamId;
    @track technicianSelectedTeam = {};
    @track technicianEditDetailsTeam;
    @track technicianGeographiesList;

    @track dispatcherSelectedTerritoryIds = [];
    @track dispatcherSelectedTeamIds = [];
    @track dispatcherTerritoryData = [];
    @track dispatcherTerritoryColumns = dispatcherTerritoryColumns;
    @track dispatcherTerritoryExpanded = false;
    @track dispatcherTerritoryExpandedRows = [];

    @track teamData = [];
    @track teamColumns = teamColumns;

    @track geoCheckboxValues = [];
    @track selectedGeoCheckboxTerritories = [];

	@track showDispatcherEdit;
	@track showCreateDispatcher;
	@track showTechnicianEdit;
	@track showUnassignedGeographies;

    @track manageGeosDisabled = true;
    @track manageDispatchingDisabled = true;
    @track showManageGeos = false;
    @track geoGrid = new CheckboxGrid();
    @track geoGridColumns;
    @track geoGridData;
    @track geoDraftValues;

    @track showManageDispatchers = false;
    @track disGrid = new CheckboxGrid();
    @track disGridColumns;
    @track disGridData;
    @track disDraftValues;

    //TODO @wire loadPermissions and handle permissions on the different components
    @wire(loadPermissions)
        wireLoadPermissions( { error, data } )
        {
            if (data) {
                console.log('loadPermissions data: ' + JSON.stringify(data));
                this.disableEditDispatchers = !data.editDispatchers;
                this.disableEditTechnicians = !data.editTechnicians;
            } else {
                this.error = error;
                console.log('Error @wire(loadPermissions): ' + JSON.stringify(this.error));
            }
        }

    @wire(buildWrappers)
        wireDispatcherTerritories( { error, data })
        {
            if (data) {
                // this.setExpandedRows(data); //Maybe we could add a function to get all the Ids so we can open fully expanded in the tree grid
                this.dispatcherTerritoryData = data;
                console.log('buildWrappers dispatcherTerritoryData: ' + this.dispatcherTerritoryData);
            } else {
                this.error = error;
                console.log('Error @wire(buildWrappers): ' + JSON.stringify(this.error));
            }
        }

    @wire(buildTeams)
        wireTeams( { error, data })
        {
            if (data) {
                this.teamData = data;
                console.log('buildTeam teamData: ' + this.teamData);
            } else {
                this.error = error;
                console.log('Error @wire(buildTeams): ' + JSON.stringify(this.error));
            }
        }

    @wire(getUnassignedGeographiesCount)
        wireUnassignedGeographiesCount( { error, data } )
        {
            if (data) {
                this.showUnassignedGeographies = false;
                console.log('getUnassignedGeographiesCount data: ' + data);

                if (data > 0) {
                    this.unassignedGeographiesCount = data + ' Unassigned Geographies';
                    this.showUnassignedGeographies = true;
                }

            } else {
                this.showUnassignedGeographies = false;
                this.error = error;
                console.log('Error @wire(getUnassignedGeographiesCount): ' + JSON.stringify(this.error));
            }
        }

    @wire(selectedTerrIdsTeamIdsInDispatcherAccess, {dispatcherId: '$dispatcherId'})
        wireDispatcherAccess( { error, data })
        {
            if (data) {
                this.dispatcherSelectedTerritoryIds = data.selectedTerritoryIds;
                this.dispatcherSelectedTeamIds = data.selectedTeamIds;
                console.log('selectedTerrIdsTeamIdsInDispatcherAccess dispatcherSelectedTerritoryIds: ' + this.dispatcherSelectedTerritoryIds);
                console.log('selectedTerrIdsTeamIdsInDispatcherAccess dispatcherSelectedTeamIds: ' + this.dispatcherSelectedTeamIds);
            } else {
                this.error = error;
                console.log('Error @wire(selectedTerrIdsTeamIdsInDispatcherAccess): ' + JSON.stringify(this.error));
            }
        }

    @wire(buildTreeFromSearch)
    wireItems( { error, data })
    {
        if (data) {
            this.allTerritories = data;
            console.log('allTerritories in buildTreeFromSearch: '+this.allTerritories);

        } else {
            this.error = error;
        }
    }

    handleTerritorySearch(event) {
        searchTerritories(event.detail)
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

    handleTerritorySelectionChange(event) {
        const selection = this.template.querySelector('c-custom-lookup').getSelection();
        this.selectedTerritories = selection;
        console.info('Selected Territories: ' + JSON.stringify(this.selectedTerritories));
    }


    // Navigation to Unassigned Geographies List View
    navigateToUnassignedGeographiesListView() {
        this[NavigationMixin.Navigate]({
            "type": "standard__objectPage",
            "attributes": {
                "objectApiName": "SMAX_PS_Geography__c",
                "actionName": "list"
            },
            "state": {
                "filterName": "SMAX_PS_Unassigned_Geographies"
            }
        });
    }

    handleTreeSearchClick() {
        console.log('Tree Search was Clicked')

        let selectedTerritoryIds = [];
        this.selectedTerritories.forEach(t => selectedTerritoryIds.push(t.id));
        buildTreeFromSearch({territoryIds:selectedTerritoryIds})
            .then((results) => {
                this.allTerritories = results;
                })
            .catch((error) => {
                const evt = new ShowToastEvent({
                    title: 'Search Error',
                    message: error.body.message,
                    variant: 'error',
                    mode: 'dismissible',
                });

                this.dispatchEvent(evt);
                console.error('Tree Search error', JSON.stringify(error));
                this.lookupErrors = [error];
            });
    }

    handleOnselect(event) {

        this.dispatchersIsProcessing = true;
        this.techniciansIsProcessing = true;
        this.manageDispatchingDisabled = true;
        this.selectedTerritory = event.detail.name;
        console.log('Tree item was selected: ' + this.selectedTerritory);
		let selTerritoryDetail = this.findInTree(this.selectedTerritory, this.allTerritories);
        //console.log('Full Territory Selected: ' + JSON.stringify(selTerritoryDetail));
		this.selectedTerritoryType = (selTerritoryDetail) ? selTerritoryDetail.territoryType : '';
        console.log('Territory Type Selected: ' + this.selectedTerritoryType);
        this.manageGeosDisabled = (this.selectedTerritoryType != 'Super District') || this.disableEditTechnicians;

        buildDispatcherDataTable({territoryId: this.selectedTerritory})
            .then((results) => {
                this.dispatcherData = results;
                console.log('dispatcherData: ' + this.dispatcherData);
                this.dispatchersIsProcessing = false;

                let resultsSize = Object.keys(results).length;
                if (resultsSize === 0) {
                    this.manageDispatchingDisabled = true;
                } else {
                    //this.manageDispatchingDisabled = false;
                    this.manageDispatchingDisabled = this.disableEditDispatchers;
                }
                })
            .catch((error) => {
                const evt = new ShowToastEvent({
                    title: 'Tree Select Error for Dispatcher Table',
                    message: error.body.message,
                    variant: 'error',
                    mode: 'dismissible',
                });

                this.dispatchEvent(evt);
                console.error('Tree Select error for Dispatcher Table', JSON.stringify(error));
                this.lookupErrors = [error];
                this.dispatchersIsProcessing = false;
                this.manageDispatchingDisabled = true;
            });

        buildTechnicianDataTable({territoryId:this.selectedTerritory})
            .then((results) => {
                this.technicianData = results;
                console.log('technicianData: ' + this.technicianData);
                this.techniciansIsProcessing = false;
                })
            .catch((error) => {
                const evt = new ShowToastEvent({
                    title: 'Tree Select Error for Technician Table',
                    message: error.body.message,
                    variant: 'error',
                    mode: 'dismissible',
                });

                this.dispatchEvent(evt);
                console.error('Tree Select error for Technician Table', JSON.stringify(error));
                this.lookupErrors = [error];
                this.techniciansIsProcessing = false;
            });
    }

	findInTree(val, items) {
		let result = items.find(t => t.name == val);
		if (result != null) {
		    return result;
		}
		for (const i of items) {
		    if (i.items && i.items.length > 0) {
		    	let r = this.findInTree(val, i.items); // Recursive call
				if (r != null) {
					return r;
				}
			}
		}
		return null;
	}

    clearFilter()
    {
        this.selectedTerritories = [];
        this.allTerritories = [];
        this.filterValue = [];
        this.dispatcherData = [];
        this.technicianData = [];
    }

	handleDispatcherRowAction(event) {
	    this.showDispatcherEdit = true;
	    console.log('Edit Dispatcher: ' + JSON.stringify(event.detail));
	    // {"row":{"actions":"Manage/View","fullName":"Angela Marino [SVMX PS - Customer Care]","id":"a1ZK0000004LPhdMAG","isActive":true,"territory":"United States","userId":"00530000006uIGzAAM"},"action":{"label":"Edit","name":"edit"}}
	    this.dispatcherId = event.detail.row.userId;
	    console.log('this.dispatcherId: ' + this.dispatcherId);
	    this.dispatcherDataName = event.detail.row.fullName;
	    console.log('this.dispatcherDataName: ' + this.dispatcherDataName);

	    let tempData = JSON.stringify(this.dispatcherTerritoryData);
	    tempData = tempData.replace(/items/g,'_children'); //Tree Grid requires _children instead of items
	    tempData = tempData.replace(/\"_children\":\[\]\,/g, ''); //Remove the _children that have nothing in their list
	    this.dispatcherTerritoryData = JSON.parse(tempData);
	    console.log('this.dispatcherTerritoryData: ' + this.dispatcherTerritoryData);
	}

	handleDispatcherTerritoryExpansion(event) {
	    console.log('Toggle expanding all the rows that have children');
	    let dispatcherTerritoryTreeGrid = this.template.querySelector('.dispatcher-territory-tree-grid');

        console.log('this.dispatcherSelectedTerritoryIds before:' + this.dispatcherSelectedTerritoryIds);

	    if (this.dispatcherTerritoryExpanded) {
	        dispatcherTerritoryTreeGrid.collapseAll();
	        this.dispatcherTerritoryExpanded = false;
        } else {
            dispatcherTerritoryTreeGrid.expandAll();
            this.dispatcherTerritoryExpanded = true;
            this.dispatcherTerritoryExpandedRows = dispatcherTerritoryTreeGrid.getCurrentExpandedRows();
            console.log('this.dispatcherTerritoryExpandedRows: ' + this.dispatcherTerritoryExpandedRows);
        }

        this.dispatcherSelectedTerritoryIds = [...this.dispatcherSelectedTerritoryIds];

        console.log('this.dispatcherSelectedTerritoryIds after:' + this.dispatcherSelectedTerritoryIds);
	}

    handleDispatcherTerritoryOnRowAction(event) {
        console.log('handleDispatcherTerritoryOnRowAction');
        console.log('event: ' + JSON.stringify(event, null, 2));

        let selectedRowId = event.detail.row.name;
        console.log('selectedRowId: ' + selectedRowId);
        let actionName = event.detail.action.name;
        console.log('actionName: ' + actionName);

        // Handle the RowAction to select and unselect the child tree entries
        this.isProcessing = true;

        //call apex to get the list of child record ids for the selected territory
        getChildTerritoryIds({territoryId: selectedRowId})
            .then((results) => {
                console.log('getChildTerritoryIds results: ' + results);

                if (actionName === 'selectChildren') {
                    this.dispatcherSelectedTerritoryIds = this.dispatcherSelectedTerritoryIds.concat(results);

                } else if (actionName === 'unselectChildren') {
                    results.forEach(idToRemove => {
                        let index = this.dispatcherSelectedTerritoryIds.indexOf(idToRemove);
                        if (index > -1) {
                          this.dispatcherSelectedTerritoryIds.splice(index, 1);
                        }
                    })
                }

                // Reset the value in this.dispatcherSelectedTerritoryIds so it will refresh the component
                this.dispatcherSelectedTerritoryIds = [...this.dispatcherSelectedTerritoryIds];

                console.log('this.dispatcherSelectedTerritoryIds: ' + this.dispatcherSelectedTerritoryIds);
                this.isProcessing = false;
            })
            .catch((error) => {
                const evt = new ShowToastEvent({ title: 'getChildTerritoryIds Error', message: error.body.message, variant: 'error', mode: 'sticky'});
                this.dispatchEvent(evt);
                console.error('getChildTerritoryIds Error: ', JSON.stringify(error));
                this.error = [error];
                this.isProcessing = false;
            });

    }


    handleDispatcherTerritoryOnRowSelection(event) {
        console.log('handleDispatcherTerritoryOnRowSelection');

        let selectedTerritoryRowIds = event.detail.selectedRows.map(({ name }) => name);
        console.log('selectedTerritoryRowIds: ' + selectedTerritoryRowIds);

        this.dispatcherSelectedTerritoryIds = selectedTerritoryRowIds;
    }

    handleDispatcherTeamOnRowSelection(event) {
        console.log('handleDispatcherTeamOnRowSelection');

        let selectedTeamRowIds = event.detail.selectedRows.map(({ id }) => id);
        console.log('selectedTeamRowIds: ' + selectedTeamRowIds);

        this.dispatcherSelectedTeamIds = selectedTeamRowIds;
    }

	handleDispatcherSave(event) {
	    saveDispatcherEditDetails({dispatcherId: this.dispatcherId, newTerritoryIds: this.dispatcherSelectedTerritoryIds, newTeamIds: this.dispatcherSelectedTeamIds})
            .then((message) => {
                console.log('Save Dispatcher Edit Details message = ' + message);
                this.isProcessing = false;

                const evt = new ShowToastEvent({ title: 'Save Dispatcher Edit Details', message: 'Save successful', variant: 'success'});
                this.dispatchEvent(evt);
            })
            .catch((error) => {
                let errorMessage = JSON.stringify(error).split('\"message\":\"')[1];
                console.error('Save Dispatcher Edit Details Error: ', JSON.stringify(error));
                this.isProcessing = false;
                const evt = new ShowToastEvent({ title: 'Save Dispatcher Edit Details Error', message: errorMessage, variant: 'error', mode: 'sticky'});
                this.dispatchEvent(evt);
            });

	    this.showDispatcherEdit = false;
	}

	handleDispatcherClose(event) {

	    // Force the dispatcherId to change so the wired component will reset the selected Territory and Team Row Ids
	    let tempDispatcherId = this.dispatcherId;
	    this.dispatcherId = '';
	    this.dispatcherId = tempDispatcherId;

	    this.showDispatcherEdit = false;
	}

	handleTechnicianRowAction(event) {
	    this.showTechnicianEdit = true;
	    console.log('Edit Technician: ' + JSON.stringify(event.detail));
	    // {"row":{"actions":"Manage/View","fullName":"Mark Provost [SVMX PS - Customer Care]","geographies":"USVT02, ...","id":"a7iK0000000D7UgIAK","numGeographies":"89","territory":"United States","userId":"00530000000y8nkAAA"},"action":{"label":"Edit","name":"edit"}}
	    let technicianId = event.detail.row.id;

        console.log('this.selectedTerritory: ' + this.selectedTerritory);
        let initialSearch = {"searchTerm":this.selectedTerritory,"selectedIds":[]}
        console.log('initialSearch: ' + JSON.stringify(initialSearch));
        searchTerritories(initialSearch)
            .then((results) => {
                console.log('searchTerritories results: ' + JSON.stringify(results));
                //this.selectedGeoCheckboxTerritories = results;
                this.template.querySelector('.geo-checkbox-territory').setSearchResults(results);
            })
            .catch((error) => {
                const evt = new ShowToastEvent({ title: 'Search Territories Error', message: error.body.message, variant: 'error', mode: 'sticky'});
                this.dispatchEvent(evt);
                console.error('Search Territories Error', JSON.stringify(error));
                this.lookupErrors = [error];
            });

	    // Get Options and Values for checkbox group
	    loadGeoCheckbox({technicianId: technicianId, territoryId: this.selectedTerritory})
	        .then((result) => {
                console.log('Load Geo Checkbox Result = ' + result);

                this.technicianEditDetails = result;
                this.technicianEditDetailsName = result.technicianName;
                this.technicianEditDetailsId = result.technicianId;
                this.technicianEditDetailsTerritory = result.territoryName;
                this.technicianEditDetailsTerritoryId = result.territoryId;
                this.technicianSelectedTerritory = { id: result.territoryId, sObjectType: 'SVMXC__Territory__c', icon: 'custom:custom78', title: result.territoryName, subtitle: ''};
                //this.selectedGeoCheckboxTerritories = [{"icon":"custom:custom78","id":"a8BK00000008tAHMAY","sObjectType":"SVMXC__Territory__c","subtitle":"Type: Sub Territory","title":"United States","titleFormatted":"<strong>United Stat</strong>es","subtitleFormatted":"Type: Sub Territory"}];
                this.technicianSelectedTeam = { id: result.teamId, sObjectType: 'SVMXC__Service_Group__c', icon: 'custom:custom15', title: result.teamName, subtitle: ''};
                this.technicianEditDetailsTeam = result.teamName;
                this.technicianEditDetailsTeamId = this.technicianSelectedTeam.id;

                this.geoCheckboxOptions = result.options;
                this.geoCheckboxValues = result.values;
                this.isProcessing = false;
            })
            .catch((error) => {
                console.error('Load Geo Checkbox Error: ', JSON.stringify(error));
                this.isProcessing = false;
                const evt = new ShowToastEvent({ title: 'Load Geo Checkbox Error', message: error.body.message, variant: 'error', mode: 'sticky'});
                this.dispatchEvent(evt);
            });
	}

	handleTechnicianSave(event) {
	    console.log('Saving Technician Edit Details');
	    console.log('this.geoCheckboxOptions: ' + JSON.stringify(this.geoCheckboxOptions));
	    console.log('this.geoCheckboxValues: ' + JSON.stringify(this.geoCheckboxValues));
	    console.log('this.technicianEditDetailsId: ' + this.technicianEditDetailsId);
	    console.log('this.technicianSelectedTeam: ' + this.technicianSelectedTeam);

        saveGeoCheckbox({ technicianId: this.technicianEditDetailsId, territoryId: this.technicianEditDetailsTerritoryId,
                            teamId: this.technicianEditDetailsTeamId, options: this.geoCheckboxOptions, values: this.geoCheckboxValues })
            .then((resultMsg) => {
                console.log('Save Tech Edit Details Result = ' + resultMsg);
                this.isProcessing = false;

                const evt = new ShowToastEvent({ title: 'Save Tech Edit Details', message: 'Technician successfully updated', variant: 'success'});
                this.dispatchEvent(evt);
            })
            .catch((error) => {
                let errorMessage = error?.body?.pageErrors[0]?.message;
                console.error('Save Tech Edit Details error', JSON.stringify(error));
                this.isProcessing = false;

                const evt = new ShowToastEvent({ title: 'Save Tech Edit Details Error', message: errorMessage, variant: 'error', mode: 'sticky'});
                this.dispatchEvent(evt);
            });

	    this.showTechnicianEdit = false;
	}

	handleTechnicianClose(event) {
	    this.showTechnicianEdit = false;
	}

	// -------------------------- Create Dispatcher

	handleCreateDispatcherClick(event) {
        this.showCreateDispatcher = true;
	}

	handleCreateDispatcherSuccess(event) {
	    console.log('handleCreateDispatcherSuccess Success saving: ' + event.detail.apiName);
	    this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                //message: event.detail.apiName + ' Created',
                message: 'Dispatcher Created',
                variant: 'success',
            }),
        );
        this.showCreateDispatcher = false;
    }

    handleDispatcherChange(event) {
        console.log("You selected a Dispatcher: " + event.detail.value[0]);
    }

    handleServiceTeamChange(event) {
        console.log("You selected a Service Team: " + event.detail.value[0]);
    }

    handleTerritoryChange(event) {
        console.log("You selected a Territory: " + event.detail.value[0]);
    }

	handleCreateDispatcherClose(event) {
	    this.showCreateDispatcher = false;
    }

	// -------------------------- Manage Geographies

    handleManageGeographiesClick(e) {
        this.showManageGeos = true;
        this.isProcessing = true;
        loadManageGeoGrid({ territoryId: this.selectedTerritory })
            .then((resultGrid) => {
                this.geoGrid.loadResultGrid(resultGrid, 'Technician', 100);
                this.geoGridColumns = this.geoGrid.gridColumns;
                this.geoGridData = this.geoGrid.gridData;
                this.geoDraftValues = this.geoGrid.gridDraftValues;
                this.isProcessing = false;
            })
            .catch((error) => {
                console.error('Load Tech-Geo Grid error', JSON.stringify(error));
                const evt = new ShowToastEvent({ title: 'Load Tech-Geo Grid Error', message: error.body.message, variant: 'error', mode: 'sticky'});
                this.dispatchEvent(evt);
                this.isProcessing = false;
            });
    }

    handleGeoGridCellChange(event) {
		this.geoGrid.handleGridCellChange(event);
		this.geoDraftValues = [...this.geoGrid.gridDraftValues];
    }

    handleGeoHeaderAction(event) {
        this.geoGrid.handleGridHeaderAction(event);
        this.geoDraftValues = [...this.geoGrid.gridDraftValues];
        this.geoGridColumns = [...this.geoGrid.gridColumns];
    }

    handleGeoRowSelect(event) {
        this.geoGrid.selectRows(event);
        this.geoDraftValues = [...this.geoGrid.gridDraftValues];
    }

    handleManageGeosSave(e) {
        this.geoGrid.prepareGridForSave(e);
        let gridUpdates = JSON.stringify(this.geoGrid.gridResult);
        console.log('Saving geoGrid grid = ' + gridUpdates);

        saveManageGeoGrid({ territoryId: this.selectedTerritory, updates: gridUpdates })
            .then((resultMsg) => {
                console.log('Save Tech-Geo Result = ' + resultMsg);
                this.isProcessing = false;
                this.showManageGeos = false;
            })
            .catch((error) => {
                console.error('Save Tech-Geo Grid error', JSON.stringify(error));
                this.isProcessing = false;
                this.showManageGeos = false;
                const evt = new ShowToastEvent({ title: 'Save Tech-Geo Grid Error', message: error.body.message, variant: 'error', mode: 'sticky'});
                this.dispatchEvent(evt);
            });
    }

    handleManageGeosClose(e) {
        this.showManageGeos = false;
    }

	// -------------------------- Manage Dispatcher Access

	handleManageDispatchersClick(e) {
        loadManageDispatchersGrid({ territoryId: this.selectedTerritory })
            .then((resultGrid) => {
                this.disGrid.loadResultGrid(resultGrid, 'Dispatcher', 150);
                this.disGridColumns = this.disGrid.gridColumns;
                this.disGridData = this.disGrid.gridData;
                this.disDraftValues = this.disGrid.gridDraftValues;
                this.showManageDispatchers = true;
            })
            .catch((error) => {
                console.error('Load Dispatchers Grid error', JSON.stringify(error));
                const evt = new ShowToastEvent({ title: 'Load Dispatchers Grid Error', message: error.body.message, variant: 'error', mode: 'sticky'});
                this.dispatchEvent(evt);
            });
	}

    handleDisGridCellChange(event) {
		this.disGrid.handleGridCellChange(event);
		this.disDraftValues = [...this.disGrid.gridDraftValues];
    }

    handleDisHeaderAction(event) {
        this.disGrid.handleGridHeaderAction(event);
        this.disDraftValues = [...this.disGrid.gridDraftValues];
        this.disGridColumns = [...this.disGrid.gridColumns];
    }

    handleDisRowSelect(event) {
        this.disGrid.selectRows(event);
        this.disDraftValues = [...this.disGrid.gridDraftValues];
    }

    handleManageDispatchersSave(e) {
        this.disGrid.prepareGridForSave(e);
        let gridUpdates = JSON.stringify(this.disGrid.gridResult);
        console.log('Saving disGrid grid = ' + gridUpdates);

        saveManageDispatchersGrid({ territoryId: this.selectedTerritory, updates: gridUpdates })
            .then((resultMsg) => {
                console.log('Save Dispatchers Result = ' + resultMsg);
                this.isProcessing = false;
                this.showManageDispatchers = false;
            })
            .catch((error) => {
                console.error('Save Dispatchers Grid error', JSON.stringify(error));
                this.isProcessing = false;
                this.showManageDispatchers = false;
                const evt = new ShowToastEvent({ title: 'Save Dispatchers Grid Error', message: error.body.message, variant: 'error', mode: 'sticky'});
                this.dispatchEvent(evt);
            });
    }

    handleManageDispatchersClose(e) {
        this.showManageDispatchers = false;
    }

    handleGeoCheckboxTerritorySearch(event) {
        console.log('handleGeoCheckboxTerritorySearch: ' + JSON.stringify(event.detail));
        searchGeoCheckboxTerritories(event.detail)
            .then((results) => {
                console.log('searchGeoCheckboxTerritories results: ' + JSON.stringify(results));
                this.template.querySelector('.geo-checkbox-territory').setSearchResults(results);
            })
            .catch((error) => {
                const toastEvent = new ShowToastEvent('Lookup Error', 'An error occurred while searching with the lookup field.', 'error');
                this.dispatchEvent(toastEvent);
                console.error('Lookup error', JSON.stringify(error));
                this.lookupErrors = [error];
            });
    }

    handleGeoCheckboxTeamSearch(event) {
        console.log('handleGeoCheckboxTeamSearch: ' + JSON.stringify(event.detail));

        searchGeoCheckboxTeams(event.detail)
            .then((results) => {
                console.log('searchGeoCheckboxTeams results: ' + JSON.stringify(results));
                this.template.querySelector('.geo-checkbox-team').setSearchResults(results);
            })
            .catch((error) => {
                const toastEvent = new ShowToastEvent('Lookup Error', 'An error occurred while searching with the lookup field.', 'error');
                this.dispatchEvent(toastEvent);
                console.error('Lookup error', JSON.stringify(error));
                this.lookupErrors = [error];
            });
    }

    handleGeoCheckboxTeamSelectionChange(event) {
        console.log('handleGeoCheckboxTeamSelectionChange event:' + JSON.stringify(event));
        const selection = this.template.querySelector('.geo-checkbox-team').getSelection();
        //const selection = this.template.querySelector('c-custom-lookup').getSelection();
        console.log('selection: ' + JSON.stringify(selection));
        this.selectedGeoCheckboxTeams = selection;
        this.technicianEditDetailsTeam = selection[0]?.title;
        console.info('Selected Teams: ' + JSON.stringify(this.technicianEditDetailsTeam));

        //Update the Team associated to the Technician from this selection
        if (selection[0]) {
            console.log('Team has been Selected: ' + JSON.stringify(selection[0].id));
            this.technicianEditDetailsTeamId = selection[0].id;
        } else {
            console.log('No Team was Selected');
        }
        this.isProcessing = false;
    }

    handleGeoCheckboxTerritorySelectionChange(event) {
        console.log('handleGeoCheckboxTerritorySelectionChange event:' + JSON.stringify(event));
        const selection = this.template.querySelector('.geo-checkbox-territory').getSelection();
        //const selection = this.template.querySelector('c-custom-lookup').getSelection();
        console.log('selection: ' + JSON.stringify(selection));
        this.selectedGeoCheckboxTerritories = selection;
        this.technicianEditDetailsTerritory = selection[0]?.title;
        console.info('Selected Territories: ' + JSON.stringify(this.technicianEditDetailsTerritory));

        if (selection[0]) {
            console.log('Territory has been Selected: ' + JSON.stringify(selection[0].id));
            loadGeoCheckbox({technicianId: this.technicianEditDetailsId, territoryId: selection[0].id})
                .then((result) => {
                    console.log('Load Geo Checkbox Result = ' + JSON.stringify(result));

                    this.technicianEditDetails = result;
                    this.technicianEditDetailsName = result.technicianName;
                    this.technicianEditDetailsId = result.technicianId;
                    this.technicianEditDetailsTerritoryId = result.territoryId;
                    this.technicianEditDetailsTeam = result.teamName;

                    this.geoCheckboxOptions = result.options;
                    this.geoCheckboxValues = result.values;
                    this.isProcessing = false;
                })
                .catch((error) => {
                    console.error('Load Geo Checkbox Error: ', JSON.stringify(error));
                    this.isProcessing = false;
                    const evt = new ShowToastEvent({ title: 'Load Geo Checkbox Error', message: error.body.message, variant: 'error', mode: 'sticky'});
                    this.dispatchEvent(evt);
                });
        } else {
            console.log('No Territory was Selected');
            this.geoCheckboxOptions = [];
            this.geoCheckboxValues = [];
        }
    }

    get geoCheckboxSelectedValues() {
        return this.geoCheckboxValues.join(',');
    }

    handleGeoCheckboxChange(event) {
        this.geoCheckboxValues = event.detail.value;
    }
}