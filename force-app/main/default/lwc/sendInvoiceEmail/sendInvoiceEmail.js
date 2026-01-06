import { LightningElement, api } from 'lwc';
import LightningAlert from 'lightning/alert';
import sendInvoiceEmailFunctionality from '@salesforce/apex/SendInvoiceEmailController.sendInvoiceEmailFunctionality';
export default class SendInvoiceEmail extends LightningElement {
    @api recordIds;
    connectedCallback() {
        console.log("record ids: ", this.recordIds);
        this.checkRecordsIsSelected();
        if (this.recordIds) {
            sendInvoiceEmailFunctionality({ invoiceIds: this.recordIds })
                .then(result => {
                    this.showAlertAndReturn('Success', result, 'success');
                })
                .catch(error => {
                    console.error('Error sendInvoiceEmailFunctionality : ', error);
                });
        }

    }

    checkRecordsIsSelected() {
        if (!this.recordIds) {
            this.showAlertAndReturn('Error', 'Please Select Invoices', 'error');
        }
    }

    redirectToListView() {
        url = `/lightning/o/s2p3__Sales_Invoice__c/list?filterName=s2p3__All`
        window.location.replace(url);
    }

    async showAlertAndReturn(title, message, theme = 'success') {
        await LightningAlert.open({
            message,
            theme,
            label: title
        });
        setTimeout(() => {
            this.redirectToListView();
        }, 300);
    }
}
