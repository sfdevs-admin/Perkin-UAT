/**
 * Created by tony on 6/15/21.
 */

import LightningDatatable from 'lightning/datatable';
import DatatablePicklistTemplate from './picklist-template.html';
import { loadStyle } from 'lightning/platformResourceLoader';
import ExtendedLightningDatatablecssResource from '@salesforce/resourceUrl/ExtendedLightningDatatablecss';

export default class ExtendedLightningDatatable extends LightningDatatable {
    static customTypes = {
        picklist: {
            template: DatatablePicklistTemplate,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context'],
        },
    };

    constructor() {
            super();
            Promise.all([
                loadStyle(this, ExtendedLightningDatatablecssResource),
            ]).then(() => {})
        }
}