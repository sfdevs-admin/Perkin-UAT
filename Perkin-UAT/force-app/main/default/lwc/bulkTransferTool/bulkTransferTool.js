import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getObjects from '@salesforce/apex/BulkTransferController.getObjects';
import getFilterFields from '@salesforce/apex/BulkTransferController.getFilterFields';
import searchRecords from '@salesforce/apex/BulkTransferController.searchRecords';
import updateOwner from '@salesforce/apex/BulkTransferController.updateOwner';
import getColumns from '@salesforce/apex/BulkTransferController.getColumns';
import searchOwners from '@salesforce/apex/BulkTransferController.searchOwners';
import searchLookupRecords from '@salesforce/apex/BulkTransferController.searchLookupRecords';

export default class BulkTransferTool extends LightningElement {

    // ========================
    // TRACKED VARIABLES
    // ========================
    @track objectOptions = [];
    @track filterOptions = [];
    @track allRecords = [];
    @track records = [];
    @track columns = [];
    @track selectedRows = [];
    @track isLoading = false; // ✅ SPINNER FLAG

    sObject = '';
    ownerType = 'User';

    currentOwnerId;
    currentOwnerName = '';
    currentOwnerResults = [];

    newOwnerType = 'User';
    newOwnerId;
    newOwnerName = '';
    newOwnerResults = [];

    showUpdateButton = false;

    ownerTypeOptions = [
        { label: 'User', value: 'User' },
        { label: 'Queue', value: 'Group' }
    ];

    connectedCallback() {
        getObjects().then(data => {
            this.objectOptions = data;
        });
    }

    // ========================
    // OBJECT CHANGE
    // ========================
    handleObjectChange(event) {
        this.sObject = event.detail.value;
        this.resetFilters();
        getFilterFields({ objectName: this.sObject })
            .then(data => {
                this.filterOptions = data.map(f => ({
                    ...f,
                    inputValue: '',
                    fromValue: '',
                    toValue: '',
                    currentValue: '', // ✅ ADDED
                    isDate: f.type === 'DATE',
                    isDateTime: f.type === 'DATETIME',
                    fromLabel: f.label + ' From',
                    toLabel: f.label + ' To',
                    isLookup: f.type === 'REFERENCE',
                    referenceTo: f.referenceTo,
                    isPicklist: f.type === 'PICKLIST',
                    picklistValues: f.picklistValues || [],
                    selectedValues: [],
                    selectedLookupRecords: [],
                    lookupResults: [],
                    lookupId: null
                }));
            });

        getColumns({ objectName: this.sObject })
            .then(data => {
                this.columns = [
                    ...data,
                    { label: 'Current Owner', fieldName: 'OwnerName', type: 'text' },
                    { label: 'New Owner', fieldName: 'NewOwnerName', type: 'text' }
                ];
            });
    }

   handleMultiPicklistChange(event) {

    const fieldApi = event.target.dataset.field;
    const value = event.detail.value;

    this.filterOptions = this.filterOptions.map(f => {

        if (f.value === fieldApi) {

            if (!f.selectedValues.includes(value)) {
                return {
                    ...f,
                    selectedValues: [...f.selectedValues, value],
                    currentValue: null   // 🔥 always reset
                };
            }

            return {
                ...f,
                currentValue: null
            };
        }

        return f;
    });

    this.filterOptions = [...this.filterOptions];
}
    removeSelectedPicklist(event) {

        const fieldApi = event.target.dataset.field;
        const valueToRemove = event.target.name;

        this.filterOptions = this.filterOptions.map(f => {

            if (f.value === fieldApi) {

                const updatedValues = f.selectedValues.filter(v => v !== valueToRemove);

                return {
                    ...f,
                    selectedValues: updatedValues,
                    currentValue: null   // 🔥 IMPORTANT FIX
                };
            }

            return f;
        });

        // 🔥 Force reactivity (extra safe)
        this.filterOptions = [...this.filterOptions];
    }

    // ========================
    // FILTER HANDLING
    // ========================
    handleDynamicFilterChange(event) {
        const fieldApi = event.target.dataset.field;
        const type = event.target.dataset.type;
        const value = event.target.value;

        this.filterOptions = this.filterOptions.map(f => {
            if (f.value === fieldApi) {
                if (type === 'from') return { ...f, fromValue: value };
                if (type === 'to') return { ...f, toValue: value };
                return { ...f, inputValue: value };
            }
            return f;
        });
    }

    // ========================
    // SEARCH RECORDS (SPINNER ADDED)
    // ========================
    searchRecords() {

        if (!this.currentOwnerId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Current Owner Required',
                    message: 'Please select a Current Owner before searching.',
                    variant: 'warning'
                })
            );
            return;
        }

        this.isLoading = true; // ✅ START SPINNER

        let filters = {};
        let isValid = true;

        this.filterOptions.forEach(f => {

            if (f.isDate || f.isDateTime) {
                if (f.fromValue && f.toValue && f.fromValue > f.toValue) {
                    isValid = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Invalid Date Range',
                            message: `${f.label}: From date must be earlier than To date`,
                            variant: 'error'
                        })
                    );
                }

                if (f.fromValue) filters[`${f.value}_from`] = f.fromValue;
                if (f.toValue) filters[`${f.value}_to`] = f.toValue;
            }

            else if (f.isLookup && f.selectedLookupRecords.length > 0) {
                const ids = f.selectedLookupRecords.map(r => r.id);
                filters[f.value] = ids.join(',');
            }

            else if (f.isPicklist && f.selectedValues.length > 0) {
                filters[f.value] = f.selectedValues.join(',');
            }

            else if (f.inputValue) {
                filters[f.value] = f.inputValue;
            }
        });

        if (!isValid) {
            this.isLoading = false;
            return;
        }

        searchRecords({
            objectName: this.sObject,
            filters: filters,
            currentOwnerId: this.currentOwnerId
        })
        .then(result => {

            this.allRecords = result.map(row => ({
                ...row,
                OwnerName: row.Owner ? row.Owner.Name : '',
                NewOwnerName: '',
                NewOwnerId: null
            }));

            this.records = [...this.allRecords]; // ✅ NO PAGINATION

        })
        .catch(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong while fetching records.',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isLoading = false; // ✅ STOP SPINNER
        });
    }

    // ========================
    // ROW SELECTION
    // ========================
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
        this.showUpdateButton = this.selectedRows.length > 0;
    }

    // ========================
    // OWNER SEARCH
    // ========================
    handleCurrentOwnerSearch(event) {
        this.currentOwnerName = event.target.value;

        if (this.currentOwnerName.length >= 3) {
            searchOwners({
                searchKey: this.currentOwnerName,
                ownerType: this.ownerType
            }).then(data => {
                this.currentOwnerResults = data || [];
            });
        } else {
            this.currentOwnerResults = [];
        }
    }

    selectCurrentOwner(event) {
        this.currentOwnerId = event.currentTarget.dataset.id;
        this.currentOwnerName = event.currentTarget.dataset.name;
        this.currentOwnerResults = [];
    }

    handleNewOwnerSearch(event) {
        this.newOwnerName = event.target.value;

        if (this.newOwnerName.length >= 3) {
            searchOwners({
                searchKey: this.newOwnerName,
                ownerType: this.newOwnerType
            }).then(data => {
                this.newOwnerResults = data || [];
            });
        } else {
            this.newOwnerResults = [];
        }
    }

    selectNewOwner(event) {
        this.newOwnerId = event.currentTarget.dataset.id;
        this.newOwnerName = event.currentTarget.dataset.name;
        this.newOwnerResults = [];
    }

    // ========================
    // UPDATE BUTTON CLICK
    // ========================
    handleUpdateClick() {
        if (!this.newOwnerId) return;

        this.allRecords = this.allRecords.map(rec => {
            if (this.selectedRows.some(sel => sel.Id === rec.Id)) {
                return {
                    ...rec,
                    NewOwnerName: this.newOwnerName,
                    NewOwnerId: this.newOwnerId
                };
            }
            return rec;
        });

        this.records = [...this.allRecords];
    }

    // ========================
    // SAVE (SPINNER ADDED)
    // ========================
    handleSave() {

        const idsToUpdate = this.allRecords
            .filter(r => r.NewOwnerId)
            .map(r => r.Id);

        if (idsToUpdate.length === 0) return;

        this.isLoading = true; // ✅ START SPINNER

        updateOwner({
            objectName: this.sObject,
            recordIds: idsToUpdate,
            newOwnerId: this.newOwnerId
        })
        .then(() => {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Owner updated successfully.',
                    variant: 'success'
                })
            );

            return this.searchRecords();
        })
        .catch(error => {
            console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong while updating owner.',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isLoading = false; // ✅ STOP SPINNER
        });
    }

    handleCancel() {
        window.location.reload();
    }

    resetFilters() {
        this.currentOwnerId = null;
        this.currentOwnerName = '';
        this.records = [];
        this.allRecords = [];
        this.selectedRows = [];
        this.showUpdateButton = false;

        this.filterOptions = this.filterOptions.map(f => ({
            ...f,
            inputValue: '',
            fromValue: '',
            toValue: '',
            currentValue: '',
            selectedValues: [],
            selectedLookupRecords: [],
            lookupResults: []
        }));
    }

    get hasRecords() {
        return this.allRecords && this.allRecords.length > 0;
    }

    get hasCurrentOwnerResults() {
        return this.currentOwnerResults && this.currentOwnerResults.length > 0;
    }

    get hasNewOwnerResults() {
        return this.newOwnerResults && this.newOwnerResults.length > 0;
    }

    get isSaveDisabled() {
        return !this.allRecords.some(r => r.NewOwnerId);
    }

    get totalRecordCount() {
        return this.allRecords ? this.allRecords.length : 0;
    }

    get selectedCount() {
        return this.selectedRows ? this.selectedRows.length : 0;
    }

    handleLookupSearch(event) {

        const fieldApi = event.target.dataset.field;
        const searchKey = event.target.value;

        if (!searchKey || searchKey.length < 3) {

            this.filterOptions = this.filterOptions.map(f =>
                f.value === fieldApi
                    ? { ...f, lookupResults: [], inputValue: searchKey }
                    : f
            );
            return;
        }

        const fieldObj = this.filterOptions.find(f => f.value === fieldApi);

        searchLookupRecords({
            objectName: fieldObj.referenceTo,
            searchKey: searchKey
        })
        .then(data => {

            this.filterOptions = this.filterOptions.map(f =>
                f.value === fieldApi
                    ? { ...f, lookupResults: data || [], inputValue: searchKey }
                    : f
            );

        })
        .catch(() => {
            console.error('Lookup search error');
        });
    }

    selectLookupRecord(event) {

        const fieldApi = event.currentTarget.dataset.field;
        const id = event.currentTarget.dataset.id;
        const name = event.currentTarget.dataset.name;

        this.filterOptions = this.filterOptions.map(f => {

            if (f.value === fieldApi) {

                const alreadyExists = f.selectedLookupRecords.some(r => r.id === id);

                if (alreadyExists) return f;

                return {
                    ...f,
                    inputValue: '',
                    lookupResults: [],
                    selectedLookupRecords: [
                        ...f.selectedLookupRecords,
                        { id: id, label: name }
                    ]
                };
            }

            return f;
        });
    }

    removeSelectedLookup(event) {

        const fieldApi = event.target.dataset.field;
        const idToRemove = event.target.name;

        this.filterOptions = this.filterOptions.map(f => {

            if (f.value === fieldApi) {
                return {
                    ...f,
                    selectedLookupRecords: f.selectedLookupRecords.filter(r => r.id !== idToRemove)
                };
            }

            return f;
        });
    }

    handleNewOwnerTypeChange(event) {
        this.newOwnerType = event.detail.value;
    }
    handleOwnerTypeChange(event) {
        this.ownerType = event.detail.value;
    }
}