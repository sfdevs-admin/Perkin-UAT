/**
 * Created by mgaska001 on 20.11.2025.
 */

import {api, LightningElement, wire} from 'lwc';
import {getFieldValue, getRecord, updateRecord} from 'lightning/uiRecordApi';
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import NAME_FIELD from "@salesforce/schema/SBQQ__Quote__c.Name";
import IS_BRAZIL_FIELD from "@salesforce/schema/SBQQ__Quote__c.Is_Brazil_Entity__c";
import MergePDFModal from 'c/mergePDFModal';
import prepareSections from '@salesforce/apex/QuoteDocumentController.prepareSections';
import saveSection from '@salesforce/apex/QuoteDocumentController.saveSection';
import checkJobStatus from '@salesforce/apex/QuoteDocumentController.checkJobStatus';
import getSectionIds from '@salesforce/apex/QuoteDocumentController.getSectionIds';
import deleteSections from '@salesforce/apex/QuoteDocumentController.deleteSections';
import linkMergedAndDeleteSections from '@salesforce/apex/QuoteDocumentController.linkMergedAndDeleteSections';


const FIELDS = [
    NAME_FIELD, IS_BRAZIL_FIELD
];

export default class QuoteDocument extends NavigationMixin(LightningElement) {
    @api recordId;
    @api mode = 'PREVIEW';
    showSpinner = true;
    quote;

    jobs = [];
    sections = [];
    sectionIndex = 0;
    // 'Load', 'Collect', 'Generate', 'Combine', 'Preview', 'Save', 'Error'
    processing = 'Load';
    // 'Preview', 'Save', 'SaveEmail'
    action;
    sourceIds = [];
    documentName;
    mergedDocumentName;
    mergedDocumentId;

    @wire(CurrentPageReference)
    wiredCurrentPageReference(currentPageReference) {
        if (currentPageReference.state) {
            this.recordId = currentPageReference.state.c__recordId;
            let mode = currentPageReference.state.c__mode;
            if (mode === 'SAVE' || mode === 'PREVIEW') {
                this.mode = mode;
                this.processing = 'Load';
                this.documentName = null;
                this.mergedDocumentName = null;
                this.mergedDocumentId = null;
            }
        }
    }

    @wire(getRecord, {
        recordId: "$recordId",
        fields: FIELDS
    })
    wiredRecord({ error, data }) {
        if (data) {
            this.quote = data;
            if (!this.documentName) {
                this.documentName = this.quoteName + '-' + this.formatDate(false) + '-' + this.makeRandomSuffix();
                if (this.mode === 'SAVE') {
                    this.mergedDocumentName = this.quoteName + '-' + this.formatDate(true);
                } else {
                    this.mergedDocumentName = null;
                }
            }
        } else if (error) {
            console.error('wiredRecord: ' + JSON.stringify(error));
            this.handleError('Error loading quote', this.combineMessage(error));
        }
    }

    get quoteName() {
        return getFieldValue(this.quote, NAME_FIELD);
    }

    get quoteFileName() {
        return this.mergedDocumentName + '.pdf';
    }

    get quoteIsBrazil() {
        return getFieldValue(this.quote, IS_BRAZIL_FIELD);
    }

    get quoteIsNotBrazil() {
        return !this.quoteIsBrazil;
    }

    get modePreview() {
        return (this.mode === 'PREVIEW');
    }

    get modeSave() {
        return (this.mode === 'SAVE');
    }

    get processingLoad() {
        return (this.processing === 'Load');
    }

    get processingSave() {
        return (this.processing === 'Save');
    }

    handleOnLoad() {
        if (this.processingLoad) {
            this.showSpinner = false;
        }
    }

    handleSave() {
        this.action = 'Save';
        this.processQuoteDocument();
    }

    handleSaveEmail() {
        this.action = 'SaveEmail';
        this.processQuoteDocument();
    }

    handlePreview() {
        this.action = 'Preview';
        this.processQuoteDocument();
    }

    async processQuoteDocument() {
        try {
            if (!this.checkQuoteData()) {
                return;
            }
            this.showSpinner = true;
            this.processing = 'Generate';
            await this.updateQuoteData();
            await this.prepareQuoteDocumentSections();
            if (this.sections.length > 0) {
                // Start polling sections one by one
                this.sectionIndex = 0;
                setTimeout(this.processQuoteDocumentSection.bind(this), 50);
            } else {
                this.handleError('Error processing quote', 'Missing quote document sections');
            }
        } catch (error) {
            console.error('processQuoteDocument: ' + JSON.stringify(error));
            this.handleError('Error processing quote', this.combineMessage(error));
        }
    }

    handleChangeDocumentName(event) {
        this.mergedDocumentName = event.detail.value;
    }

    checkQuoteData() {
        if (this.modeSave) {
            if (!this.mergedDocumentName) {
                return false;
            }
        }
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        let validated = true;
        if (inputFields) {
            inputFields.forEach(field => {
                if (field.fieldName === "SBQQ__QuoteLanguage__c" || field.fieldName === "Quote_Type__c") {
                    if (!field.value) {
                        field.reportValidity();
                        validated = false;
                    }
                }
            });
        }
        return validated;
    }

    async updateQuoteData() {
        let fields = {};
        fields['Id'] = this.recordId;
        fields['Quote_Page__c'] = true;
        // clear unapplicable options
        if (this.quoteIsBrazil) {
            fields['Show_Quantity__c'] = false;
            fields['Show_Quote_Line_Item_Prices__c'] = false;
            fields['Show_Quote_Line_Discounts__c'] = false;
            fields['Show_Quote_Line_Total_Prices__c'] = false;
            fields['Show_Quote_Line_Total_After_Taxes__c'] = false;
            fields['Show_Line_Tax_Amount__c'] = false;
        }
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach(field => {
                fields[field.fieldName] = field.value;
            });
        }
        const recordInput = { fields };
        await updateRecord(recordInput);
    }

    async prepareQuoteDocumentSections() {
        let result = await prepareSections({
            quoteId: this.recordId,
            documentName: this.documentName
        });
        let sectionParams = JSON.parse(result);
        this.sections = [];
        for (let params of sectionParams) {
            params.jobId = null;
            params.status = null;
            this.sections.push(params);
        }
    }

    async processQuoteDocumentSection() {
        try {
            let section = this.sections[this.sectionIndex];
            if (section.jobId) {
                section.status = await checkJobStatus({
                    jobId: section.jobId
                });
                if (section.status === 'Completed') {
                    this.sectionIndex++;
                    if (this.sectionIndex >= this.sections.length) {
                        // All sections Completed - Finish processing
                        this.processing = 'Combine';
                        await this.combineQuoteDocumentSections();
                    } else {
                        setTimeout(this.processQuoteDocumentSection.bind(this), 50);
                    }
                } else if (section.status === 'Aborted' || section.status === 'Failed') {
                    // Error processing section
                    this.processing = 'Error';
                    this.handleError('Error generating document section', 'Job status ' + section.status);
                } else {
                    // Wait for completion 2 sek
                    setTimeout(this.processQuoteDocumentSection.bind(this), 2000);
                }
            } else {
                // Init next section processing
                section.jobId = await saveSection({
                        quoteId: this.recordId,
                        templateId: section.templateId,
                        fileName: section.fileName,
                        language: section.language
                    }
                )
                // Wait for completion 2 sek
                setTimeout(this.processQuoteDocumentSection.bind(this), 2000);
            }
        } catch (error) {
            console.error('processQuoteDocumentSection: ' + JSON.stringify(error));
            //this.handleError('Error processing quote', this.combineMessage(error));
        }
    }

    async combineQuoteDocumentSections() {
        this.sourceIds = await getSectionIds({
            quoteId: this.recordId,
            documentName: this.documentName
        });
        if (this.sourceIds.length > 0) {
            if (this.action === 'Preview') {
                this.processing = 'Preview';
                this.showSpinner = false;
                // Open modal Merge PDF for preview
                // mergePDF LWC component wrapped in mergePDFModal
                await MergePDFModal.open({
                    mode: 'PREVIEW',
                    sourceIds: this.sourceIds,
                    documentName: this.quoteFileName,
                    label: 'Merge PDF',
                    size: 'large',
                });
                this.showSpinner = true;
                await deleteSections({
                    quoteId: this.recordId,
                    documentName: this.documentName
                });
                this.handleCancel();
            }
            if (this.action === 'Save' || this.action === 'SaveEmail') {
                this.processing = 'Save';
                // Merge PDF for save in the background
                // mergePDF LWC component used directly (see HTML template)
            }
        } else {
            this.handleError('Error processing quote', 'Missing quote document sections');
        }
    }

    async handleSaveDocument(e) {
        try {
            e.stopPropagation();
            this.mergedDocumentId = e.detail;
            if (this.mode === 'SAVE' && this.mergedDocumentId) {
                let quoteDocument = await linkMergedAndDeleteSections({
                    quoteId: this.recordId,
                    documentName: this.documentName,
                    documentId: this.mergedDocumentId,
                    mergedDocumentName: this.mergedDocumentName
                });
                if (quoteDocument) {
                    this.showSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success!',
                            message: 'Quote document {0} was successfully generated.',
                            messageData: [
                               this.mergedDocumentName
                            ],
                            variant: 'success',
                        }),
                    );
                    if (this.action === 'Save') {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: quoteDocument.Id,
                                objectApiName: "SBQQ__QuoteDocument__c",
                                actionName: "view",
                            },
                        });
                    }
                    if (this.action === 'SaveEmail') {
                        let emailUrl = '/_ui/core/email/author/EmailAuthor?rtype=003';
                        emailUrl += '&doc_id=' + this.mergedDocumentId;
                        emailUrl += '&p3_lkid=' + quoteDocument.SBQQ__Opportunity__c;
                        emailUrl += '&p2_lkid=' + quoteDocument.SBQQ__Quote__r.SBQQ__PrimaryContact__c;
                        emailUrl += '&retURL=%2F' + quoteDocument.Id;
                        emailUrl += '&saveURL=%2F' + quoteDocument.Id;
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                url: emailUrl
                            }
                        }, false);
                    }
                } else {
                    this.handleCancel();
                }
            }
        } catch (error) {
            console.error('handleSaveDocument: ' + JSON.stringify(error));
            this.handleError('Error processing quote', this.combineMessage(error));
        }
    }

    handleCancel() {
        this.showSpinner = false;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: "SBQQ__Quote__c",
                actionName: "view",
            },
        });
    }

    makeRandomSuffix() {
        let result = '';
        const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        const charactersLength = characters.length;
        const length = 4;
        for ( let i = 0; i < length; i++ ) {
            result += characters.charAt(Math.floor(Math.random() * charactersLength));
        }
        return result;
    }

    formatDate(withTime) {
        const dt = new Date();
        let pad = n => `0${n}`.slice(-2);
        const dtp = {
            year: `${dt.getFullYear()}`,
            month: `${pad(dt.getMonth() + 1)}`,  /* Month range is [0,11]. Force 2 digits in numbers. */
            day: `${pad(dt.getDate())}`,
            hours: `${pad(dt.getHours())}`,
            minutes: `${pad(dt.getMinutes())}`
        };
        let result = dtp.year + dtp.month + dtp.day;
        if (withTime) {
            result += '-' + dtp.hours + dtp.minutes
        }
        return result;
    }

    combineMessage(error) {
        console.log(JSON.stringify(error));
        return "Unknown error";
    }

    handleError(title, message) {
        new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error',
        });
        this.handleCancel();
    }

}