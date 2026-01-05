public class PdfGeneratorController {
    public String templateHtml { get; set; }
    
    public PdfGeneratorController() {
        Id contactId   = ApexPages.currentPage().getParameters().get('contactId');
        Id whatId      = ApexPages.currentPage().getParameters().get('whatId');
        String devName = ApexPages.currentPage().getParameters().get('templateDevName');
        
        if (String.isNotBlank(devName)) {
            Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName LIMIT 1].Id;
            Messaging.SingleEmailMessage mail =
                Messaging.renderStoredEmailTemplate(templateId, contactId, whatId);
            templateHtml = mail.getHtmlBody();
        }
    }
    
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