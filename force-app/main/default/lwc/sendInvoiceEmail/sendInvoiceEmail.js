import { LightningElement, api } from 'lwc';
import LightningAlert from 'lightning/alert';
export default class SendInvoiceEmail extends LightningElement {
    @api recordIds;
    connectedCallback() {
        console.log("record ids: ", this.recordIds);
        this.showAlert('Success', 'Email sending process initiated', 'success');
    }

    async showAlert(title, message, theme = 'info') {
        await LightningAlert.open({
            message,
            theme,
            label: title
        });
    }
}
