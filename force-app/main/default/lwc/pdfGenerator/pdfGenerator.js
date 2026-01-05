import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getInvoiceDetails from '@salesforce/apex/PdfGeneratorController.getInvoiceDetails';
export default class PdfGenerator extends LightningElement {
    recordId;
    invoiceDetails = {};
    templateName = '';
    isLoading = true;
    baseUrl = '';

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef) {
            // Quick Action recordId comes from state.recordId
            this.recordId = pageRef.state?.recordId;
            this.baseUrl = window.location.origin;

            if (this.recordId) {
                console.log('Record ID from PageReference:', this.recordId);
                this.fetchDefaultInvoiceLayout();
            }
        }
    }

    fetchDefaultInvoiceLayout() {
        this.isLoading = true;
        console.log('Record ID:', this.recordId);
        getInvoiceDetails({ invoiceId: this.recordId })
            .then(result => {
                console.log('Invoice Details:', result);
                this.invoiceDetails = result;
                this.setTemplateName();
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching invoice details:', error);
                this.isLoading = false;
            });
    }

    setTemplateName() {
        this.templateName = 'Default_Layout';

        if (this.invoiceDetails?.s2p3__To_Account__r?.s2p3__Default_Invoice_Layout__c) {
            this.templateName = this.invoiceDetails.s2p3__To_Account__r.s2p3__Default_Invoice_Layout__c;
        }
        console.log('Template Name set to:', this.templateName);
    }

    get iframeUrl() {
        if (!this.invoiceDetails?.Id || !this.templateName) {
            return '';
        }

        return `/apex/InvoicePDF?templateDevName=${this.templateName}&whatId=${this.invoiceDetails.Id}`;
    }

    get showIframe() {
        console.log('iframeUrl:', this.iframeUrl);
        return !this.isLoading && this.iframeUrl;
    }

    handleSendMail() {
        console.log("Send Mail");
    }
}