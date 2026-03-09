import { LightningElement, api } from 'lwc';

export default class B2b_customSortAndFilters extends LightningElement {
    @api
    searchResults;

    @api
    sortRules;

    @api
    sortRuleId;
}