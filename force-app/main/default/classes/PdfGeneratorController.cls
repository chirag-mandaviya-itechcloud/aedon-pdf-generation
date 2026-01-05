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

    @AuraEnabled
    public static List<Contact> getRecipientEmail(String accountId){
        try {
            List<Contact> contacts = [SELECT Id, Email FROM Contact WHERE s2p3__Contact_Role__c = 'Invoicing Contact' AND AccountId = :accountId];

            return contacts;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String sendInvoiceEmailWithTemplate(
        String invoiceId,
        String invoiceTemplateName,
        String emailTemplateName,
        List<String> toEmail,
        String conId
    ) {
        try {
            // Get Invoice details
            Sales_Invoice__c invoice = [
                SELECT Id, Name, To_Account__r.Name, To_Account__c, Company__r.Name
                FROM Sales_Invoice__c
                WHERE Id = :invoiceId
                LIMIT 1
            ];

            // Generate PDF using the INVOICE template
            PageReference pdfPage = Page.InvoicePDF;
            pdfPage.getParameters().put('templateDevName', invoiceTemplateName);
            pdfPage.getParameters().put('whatId', invoiceId);

            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Test PDF Content');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }

            // Get Email Template ID
            EmailTemplate emailTemplate = [
                SELECT Id, Subject, Body, HtmlValue
                FROM EmailTemplate
                WHERE DeveloperName = :emailTemplateName
                LIMIT 1
            ];

            // Create email using EMAIL template
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTemplateId(emailTemplate.Id);
            email.setTargetObjectId(conId);
            email.setWhatId(invoiceId);
            // email.setSubject('Your Invoice from '+invoice.s2p3__Company__r.Name);

            // Set recipient
            if (toEmail.size() > 0) {
                email.setToAddresses(toEmail);
            } else {
                throw new AuraHandledException('Recipient email address is required');
            }

            // Important: setSaveAsActivity must be set before setTemplateId in some API versions
            email.setSaveAsActivity(false);

            // Attach the PDF generated from invoice template
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('Invoice_' + invoice.Name + '.pdf');
            attachment.setBody(pdfBlob);
            attachment.setContentType('application/pdf');
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

            // Send email
            Messaging.SendEmailResult[] results = Messaging.sendEmail(
                new Messaging.SingleEmailMessage[] { email }
            );

            if (results[0].isSuccess()) {
                return 'Success: Email sent successfully to ' + toEmail;
            } else {
                String errorMsg = 'Error: ';
                for (Messaging.SendEmailError error : results[0].getErrors()) {
                    errorMsg += error.getMessage() + ' ';
                }
                throw new AuraHandledException(errorMsg);
            }

        } catch (Exception e) {
            throw new AuraHandledException('Error sending email: ' + e.getMessage());
        }
    }
}
