import { LightningElement, api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import ERROR_REQUIRED_FIELD_TEXT from '@salesforce/label/c.B2B_Modal_ErrorRequiredFieldsText';

export default class B2bCreateNewModal extends LightningModal {
    @api modalTitle;
    @api
    get properties() {
        return this.propertyList;
    }
    set properties(value) {
        console.log('value prop ', value);
        if (value) {
            this.propertyList = value;

        }
    }
    existingRecord;
    @api existingRecordMap;
    /* get existingRecordMap() {
        return JSON.parse(JSON.stringify(this._existingRecordMap));
    }
    set existingRecordMap(value) {
        console.log('value prop ', value);
        if (value) {
            this._existingRecordMap = value;

        }
    } */
    @track _existingRecordMap;
    @track propertyList;
    errorMsg;
    /**
   * The label for the primary action. If no label is provided, the action is omitted.
   * @type {?string}
   */
    @api
    primaryActionLabel;

    record = {};
    get hasOnlyOneAction() {
        return (this.hasPrimaryAction && !this.hasSecondaryAction) || (!this.hasPrimaryAction && this.hasSecondaryAction);
    }
    /**
     * The label for the secondary action. If no label is provided, the action is omitted.
     * @type {?string}
     */
    @api
    secondaryActionLabel;
    /**
    * Whether to show the primary action.
    * @type {boolean}
    * @readonly
    * @private
    */
    get hasPrimaryAction() {
        return Boolean(this.primaryActionLabel);
    }

    /**
     * Whether to show the secondary action.
     * @type {boolean}
     * @readonly
     * @private
     */
    get hasSecondaryAction() {
        return Boolean(this.secondaryActionLabel);
    }

    /**
    * Handles the click on the primary action.
    * @readonly
    * @private
    */
    handlePrimaryAction() {
        //TODO set values if answer is unchanged
        const missingRequiredFields = this.properties.filter(
            prop => prop.isRequired === true && (!prop.selectedAnswer || prop.selectedAnswer.trim() === '')
        );
        if (missingRequiredFields?.length > 0) {
            this.errorMsg = ERROR_REQUIRED_FIELD_TEXT;
        } else {
            this.errorMsg = '';
            if (this.existingRecord) {
                this.record = this.existingRecord;
            }
            this.close(this.record);
        }
    }

    /**
     * Handles the click on the secondary action.
     * @readonly
     * @private
     */
    handleSecondaryAction() {
        this.close('close');

    }



    handleChange(event) {

        const existingRecordsList = this.properties.filter(
            prop => prop.isExisting && this.existingRecordMap && prop.selectedAnswer
        );
        if (existingRecordsList?.length > 0) {
            const selectedAnswer = event.target.dataset.id == existingRecordsList[0].propertyId ? event.target.value : existingRecordsList[0].selectedAnswer;
            this.existingRecord = this.existingRecordMap[selectedAnswer];
        }
        this.properties = this.properties.map(prop => {

            const currentPropertyId = event.target.dataset.id == prop.propertyId;
            const evaluator = new Function('existingRecord', `return ${prop.criteria};`);

            return {
                ...prop,
                selectedAnswer: currentPropertyId ? event.target.value : prop.selectedAnswer,
                style: prop.criteria ? (evaluator(this.existingRecord) ? 'display :block' : 'display :none') : prop.style
            };
        });
        console.log('this.existingRecord ', this.existingRecord);

        this.record[event.target.dataset.id] = event.target.value;

    }


    connectedCallback() {
        this.setRecord();
    }
    setRecord() {
        console.log('setRecord ');
        this.properties.map(prop => {
            if (prop.isExisting && this.existingRecordMap && prop.selectedAnswer) {
                this.existingRecord = this.existingRecordMap[prop.selectedAnswer];
            }
            this.record[prop.propertyId] = prop.selectedAnswer;


        });
        this.properties = this.properties.map(prop => {
            const evaluator = new Function('existingRecord', `return ${prop.criteria};`);
            return {
                ...prop,
                style: prop.criteria ? (evaluator(this.existingRecord) ? 'display :block' : 'display :none') : prop.style
            };
        });
        console.log('this.properties ' + JSON.stringify(this.properties));

    }
}