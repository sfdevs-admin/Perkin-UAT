import { LightningElement, api } from 'lwc';
import getAllConditions from '@salesforce/apex/SAPPricingConditionController.getAllConditions';
import getPreSelectedCodes from '@salesforce/apex/SAPPricingConditionController.getPreSelectedCodes';

export default class SapPricingConditionSelector extends LightningElement {
    @api numberOfRowsPerColumn = 5;
    @api preSelectedCodes = '';
    @api descriptionMaxLength = 40;
    @api productName = '';
    @api minSearchLength = 2;

    searchTerm = '';


    _quoteLineId;
    @api
    get quoteLineId() {
        return this._quoteLineId;
    }
    set quoteLineId(value) {
        this._quoteLineId = value;
        if(value) {
            this.loadAllData();
        }
    }

    @api selectedCodes = '';
    @api get selectedCodesList() {
        return this.selectedCodes ? this.selectedCodes.split(',') : [];
    }

    allConditions = [];
    filteredOptions = [];
    organizedColumns = [];
    selectedCodesSet = new Set();
    isLoading = true;
    error;

    connectedCallback() {
        this.loadAllData();
    }

    async loadAllData() {
        this.isLoading = true;
        this.error = undefined;

        try {

            const conditions = await getAllConditions();

            if(!conditions || conditions.length === 0) {
                this.allConditions = [];
                this.filteredOptions = [];
                this.organizedColumns = [];
                this.isLoading = false;
                return;
            }

            this.allConditions = conditions.map(item => {
                if(!item) {
                    return null;
                }

                return {
                    label: this.createDisplayLabel(item.code, item.description),
                    value: item.code || '',
                    developerName: item.developerName || '',
                    isPrimary: item.isPrimary || false,
                    description: item.description || '',
                    code: item.code || ''
                };
            }).filter(item => item !== null && item.code); // Remove null items and items without code

            if (this._quoteLineId) {

                try {
                    const preSelectedCodesArray = await getPreSelectedCodes({
                        quoteLineId: this._quoteLineId
                    });

                    if (preSelectedCodesArray && preSelectedCodesArray.length > 0) {
                        this.selectedCodesSet = new Set(preSelectedCodesArray.map(code => code.trim()));
                    }

                } catch (preSelectError) {
                    console.error('Error loading pre-selected codes:', preSelectError);
                }

            } else if (this.preSelectedCodes) {
                const codes = this.preSelectedCodes.split(',').map(code => code.trim()).filter(code => code);
                this.selectedCodesSet = new Set(codes);
            }

            this.updateSelectedCodes();

            this.applyFilters();

        } catch (error) {
            this.error = error;
            this.allConditions = [];
            this.filteredOptions = [];
            this.organizedColumns = [];
        } finally {
            this.isLoading = false;
        }
    }
    createDisplayLabel(code, description) {

        if (!code) {
            return '';
        }

        if (!description || description.trim().length === 0) {
            return code;
        }

        const trimmedDesc = this.trimDescription(description);
        const result = `${code} ${trimmedDesc}`;
        return result;
    }

    trimDescription(description) {
        if (!description) return '';

        const maxLength = parseInt(this.descriptionMaxLength, 10) || 40;

        if (description.length <= maxLength) {
            return description;
        }

        return description.substring(0, maxLength) + '...';
    }

    applyFilters() {

        if(!this.allConditions || this.allConditions.length === 0) {
            this.filteredOptions = [];
            this.organizedColumns = [];
            return;
        }

        let filtered = [];

        if(this.searchTerm && this.searchTerm.trim().length >= this.minSearchLength) {
            const searchLower = this.searchTerm.toLowerCase().trim();
            filtered = this.allConditions.filter(option => {
                if(!option) return false;

                const labelMatch = option.label ? option.label.toLowerCase().includes(searchLower) : false;
                const codeMatch = option.code ? option.code.toLowerCase().includes(searchLower) : false;
                const descMatch = option.description ?
                    option.description.toLowerCase().includes(searchLower) : false;
                return labelMatch || codeMatch || descMatch;
            });

        }
        // If there are selections, show primaries + selected
        else if(this.selectedCodesSet.size > 0) {
            filtered = this.allConditions.filter(option => {
                if(!option) return false;
                return option.isPrimary || this.selectedCodesSet.has(option.value);
            });
        }
        // Default: show only primaries
        else {
            filtered = this.allConditions.filter(option => {
                if(!option) return false;
                return option.isPrimary;
            });
        }

        this.filteredOptions = filtered;
        this.organizeIntoColumns();
    }

    handleSearchChange(event) {
        const inputValue = event.target.value;

        // Only apply search if meets minimum length requirement
        if (inputValue.trim().length >= this.minSearchLength || inputValue.trim().length === 0) {
            this.searchTerm = inputValue;
            this.applyFilters();
        } else {
            // Still update the input value but don't trigger search yet
            this.searchTerm = '';
            this.applyFilters();
        }
    }

    organizeIntoColumns() {

        // Guard clause - ensure we have valid data
        if(!this.filteredOptions || !Array.isArray(this.filteredOptions) || this.filteredOptions.length === 0) {
            this.organizedColumns = [];
            return;
        }

        try {
            const columns = [];
            const totalOptions = this.filteredOptions.length;
            const rowsPerColumn = parseInt(this.numberOfRowsPerColumn, 10) || 5;

            for (let i = 0; i < totalOptions; i += rowsPerColumn) {
                const slice = this.filteredOptions.slice(i, i + rowsPerColumn);

                if(!slice || slice.length === 0) {
                    continue;
                }

                const columnItems = slice.map((option, index) => {
                    if(!option || !option.value) {
                        return null;
                    }

                    const isChecked = this.selectedCodesSet.has(option.value);

                    return {
                        label: option.label || option.code || 'Unknown',
                        value: option.value,
                        code: option.code || '',
                        developerName: option.developerName || '',
                        isPrimary: option.isPrimary || false,
                        description: option.description || '',
                        checked: isChecked,
                        uniqueKey: `checkbox-${option.value}-${i}-${index}`
                    };
                }).filter(item => item !== null && item.uniqueKey); // Ensure uniqueKey exists

                if(columnItems.length > 0) {
                    columns.push({
                        id: `column-${i}`,
                        items: columnItems
                    });
                }
            }

            this.organizedColumns = columns;

        } catch(error) {
            this.organizedColumns = [];
        }
    }

    handleCheckboxChange(event) {
        const value = event.target.value;
        const isChecked = event.target.checked;

        if (isChecked) {
            this.selectedCodesSet.add(value);
        } else {
            this.selectedCodesSet.delete(value);
        }

        this.updateSelectedCodes();

        // Re-apply filters to adjust visible items
        this.applyFilters();
    }

    updateSelectedCodes() {
        this.selectedCodes = Array.from(this.selectedCodesSet).sort().join(',');
    }

    @api selectAll() {
        if(this.filteredOptions && this.filteredOptions.length > 0) {
            this.filteredOptions.forEach(option => {
                if(option && option.value) {
                    this.selectedCodesSet.add(option.value);
                }
            });
            this.updateSelectedCodes();
            this.applyFilters();
        }
    }

    @api deselectAll() {
        this.selectedCodesSet.clear();
        this.updateSelectedCodes();
        this.applyFilters();
    }

    @api validate() {
        if (this.selectedCodesSet.size === 0) {
            return {
                isValid: false,
                errorMessage: 'Please select at least one pricing condition code.'
            };
        }
        return { isValid: true };
    }

    @api reset() {
        this.deselectAll();
    }

    get hasRecords() {
        return this.organizedColumns && this.organizedColumns.length > 0;
    }

    get hasError() {
        return this.error !== undefined;
    }

    get errorMessage() {
        return this.error ?
            (this.error.body?.message || this.error.message || 'Unknown error occurred') :
            '';
    }

    get selectedCount() {
        return this.selectedCodesSet.size;
    }

    get hasSelections() {
        return this.selectedCount > 0;
    }

    get displayMode() {
        const count = this.filteredOptions ? this.filteredOptions.length : 0;

        if(this.searchTerm && this.searchTerm.trim().length > 0) {
            return `Search Results (${count} found)`;
        } else if(this.selectedCount > 0) {
            return `Primary + Selected Codes (${count} total)`;
        } else {
            return `Primary Codes Only (${count} codes)`;
        }
    }

    get totalCodesCount() {
        return this.allConditions ? this.allConditions.length : 0;
    }
}