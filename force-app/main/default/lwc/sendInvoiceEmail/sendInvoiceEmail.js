import { LightningElement, api } from 'lwc';
export default class SendInvoiceEmail extends LightningElement {
    @api recordIds;
    connectedCallback() {
        console.log("record ids: ", this.recordIds);
    }
}
