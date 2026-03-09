import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import gtmScript from '@salesforce/resourceUrl/pkiGoogleTagManagerScript';

export default class B2bGoogleTagManagerScript extends LightningElement {

    connectedCallback() {
        Promise.all([
            loadScript(this, gtmScript),
        ]).then(() => {
            console.log('Google Tag Manager script loaded successfully');
        });
    }
}