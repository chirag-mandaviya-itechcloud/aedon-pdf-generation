public class SendInvoiceEmailController {
    @AuraEnabled
    public static string sendInvoiceEmailFunctionality(String invoiceIds){
        try {
            if (string.isEmpty(invoiceIds)) {
                throw new AuraHandledException('No invoices selected');
            }
            List<String> invoiceIdList = invoiceIds.split(',');
            // Start the batch
            SendInvoiceEmailBatch batch = new SendInvoiceEmailBatch(invoiceIdList);
            Database.executeBatch(batch, 10); // Process 10 records at a time

            return 'Invoice email process initiated for ' + invoiceIdList.size() + ' invoice(s).';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}