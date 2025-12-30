public class PdfGeneratorController {
    @AuraEnabled
    public static Sales_Invoice__c getInvoiceDetails(String invoiceId) {
        try {
            Sales_Invoice__c invoice = [SELECT Id, Name, To_Account__r.Default_Invoice_Layout__c FROM Sales_Invoice__c WHERE Id = :invoiceId LIMIT 1];
            return invoice;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}