public class SendInvoiceEmailController {
    @AuraEnabled
    public static string sendInvoiceEmailFunctionality(List<String> invoiceIds){
        try {
            if (invoiceIds == null || invoiceIds.isEmpty()) {
                throw new AuraHandledException('No invoices selected');
            }
            // Start the batch
            SendInvoiceEmailBatch batch = new SendInvoiceEmailBatch(invoiceIds);
            Database.executeBatch(batch, 10); // Process 10 records at a time

            return 'Invoice email process initiated for ' + invoiceIds.size() + ' invoice(s).';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
