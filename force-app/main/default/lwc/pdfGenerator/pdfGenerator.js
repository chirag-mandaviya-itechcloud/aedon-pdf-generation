import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInvoiceDetails from '@salesforce/apex/PdfGeneratorController.getInvoiceDetails';
import getRecipientEmail from '@salesforce/apex/PdfGeneratorController.getRecipientEmail';
import sendInvoiceEmailWithTemplate from '@salesforce/apex/PdfGeneratorController.sendInvoiceEmailWithTemplate';
export default class PdfGenerator extends LightningElement {
    recordId;
    invoiceDetails = {};
    templateName = '';
    @track isLoading = true;
    baseUrl = '';
    @track isSendingEmail = false;
    recipientEmail = [];
    recipientId = '';
    emailTemplateName = 'Invoice_Email_Template';

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
                this.getRecipientEmail();
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

    getRecipientEmail() {
        const accId = this.invoiceDetails?.s2p3__To_Account__c;
        if (accId) {
            getRecipientEmail({ accountId: accId })
                .then(result => {
                    console.log("recipient emails: ", result);
                    this.recipientEmail = result.map(con => {
                        return con.Email
                    });
                    this.recipientId = result[0].Id;
                }).catch(error => {
                    console.error('Error fetching recipient emails:', error);
                    this.isLoading = false;
                });
        }
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

    get sendButtonLabel() {
        return this.isSendingEmail ? 'Sending...' : 'Send Mail'
    }

    handleSendMail() {
        console.log("Send Mail to:", this.recipientEmail);

        if (!this.recipientEmail) {
            this.showToast('Warning', 'Please enter a recipient email address', 'warning');
            return;
        }

        // Basic email validation
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(this.recipientEmail)) {
            this.showToast('Warning', 'Please enter a valid email address', 'warning');
            return;
        }

        this.isSendingEmail = true;

        sendInvoiceEmailWithTemplate({
            invoiceId: this.recordId,
            invoiceTemplateName: this.templateName,
            emailTemplateName: this.emailTemplateName,
            toEmail: this.recipientEmail,
            conId: this.recipientId
        })
            .then(result => {
                console.log('Email sent successfully:', result);
                this.showToast('Success', result, 'success');
                this.isSendingEmail = false;
            })
            .catch(error => {
                console.error('Error sending email:', error);
                this.showToast('Error', error.body?.message || 'Failed to send email', 'error');
                this.isSendingEmail = false;
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}
