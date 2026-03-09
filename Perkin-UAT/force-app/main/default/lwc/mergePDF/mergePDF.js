/**
 * Created by mgaska001 on 01.10.2025.
 */

import { LightningElement, api, wire } from 'lwc';
import getPdfFilesAsBase64 from '@salesforce/apex/MergePDFController.getPdfFilesAsBase64';
import savePdfFileAsBase64 from '@salesforce/apex/MergePDFController.savePdfFileAsBase64';
import pdfLib from '@salesforce/resourceUrl/PdfLib';
import { loadScript } from 'lightning/platformResourceLoader';

export default class MergePDF extends LightningElement {
    @api mode; // SAVE, PREVIEW
    @api sourceIds = [];
    @api documentName;
    @api documentId;
    isLibLoaded = false;
    mergedPdfUrl;
    pdfLibInstance;

    get modePreview() {
        return (this.mode === 'PREVIEW');
    }

    get modeSave() {
        return (this.mode === 'SAVE');
    }

    renderedCallback() {
        if (this.isLibLoaded) {
            return;
        }
        loadScript(this, pdfLib + '/pdfLib/pdf-lib.min.js')
            .then(() => {
                if (window['pdfLib'] || window['PDFLib']) {
                    this.isLibLoaded = true;
                    this.pdfLibInstance = window['pdfLib'] || window['PDFLib'];
                    this.loadPdfFiles();
                } else {
                    console.error('PDF-LIB not loaded correctly.');
                }
            })
            .catch(error => {
                console.error('Error loading PDF-LIB:', error);
            });
    }

    loadPdfFiles() {
        if (this.isLibLoaded && Array.isArray(this.sourceIds) && this.sourceIds.length > 0 ) {
            getPdfFilesAsBase64({ documentIds: this.sourceIds } )
                .then(data => {
                    this.mergePdfFiles(data);
                })
                .catch(error => {
                    console.error('Error fetching PDFs:', error);
                });
        }
    }

    async mergePdfFiles(pdfFiles) {
        if (!this.pdfLibInstance) {
            console.error('PDF-LIB instance is not defined.');
            return;
        }

        const { PDFDocument } = this.pdfLibInstance;

        const mergedPdf = await PDFDocument.create();
        for (let pdfFile of pdfFiles) {
            const pdfBytes = this.base64ToBlob(pdfFile.Base64Data);
            const pdfDoc = await PDFDocument.load(pdfBytes);
            const copiedPages = await mergedPdf.copyPages(pdfDoc, pdfDoc.getPageIndices());
            copiedPages.forEach(page => mergedPdf.addPage(page));
        }

        const mergedPdfBytes = await mergedPdf.save();

        if (this.modeSave) {
            let base64Data = this.blobToBase64(mergedPdfBytes);

            this.documentId = await savePdfFileAsBase64({
                documentName: this.documentName,
                base64Data: base64Data
            });
            // Dispatch a custom event with the data
            const saveEvent = new CustomEvent('save', {
                detail: this.documentId,
                bubbles: true,
                composed: true
            });
            this.dispatchEvent(saveEvent);
        }

        if (this.modePreview) {
            this.mergedPdfUrl = URL.createObjectURL(new Blob([mergedPdfBytes], {type: 'application/pdf'}));
        }
    }

    blobToBase64(blobData) {
        let bytes = new Uint8Array(blobData);
        let len = bytes.byteLength;
        let binary = '';
        for (var i = 0; i < len; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        return btoa(binary);
    }

    base64ToBlob(base64Data) {
        return Uint8Array.from(atob(base64Data), c => c.charCodeAt(0));
    }

}