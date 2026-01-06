import { LightningElement, api } from 'lwc';
import LightningAlert from 'lightning/alert';
import sendInvoiceEmailFunctionality from '@salesforce/apex/SendInvoiceEmailController.sendInvoiceEmailFunctionality';
export default class SendInvoiceEmail extends LightningElement {
    @api recordIds;
    connectedCallback() {
        console.log("record ids: ", this.recordIds);
        if (this.recordIds) {
            sendInvoiceEmailFunctionality({ invoiceIds: this.recordIds })
                .then(result => {
                    this.showAlert('Success', result, 'success');
                })
                .catch(error => {
                    console.error('Error sendInvoiceEmailFunctionality : ', error);
                });
        }

    }

    async showAlert(title, message, theme = 'info') {
        await LightningAlert.open({
            message,
            theme,
            label: title
        });
    }
}
