public class SendInvoiceEmailBatch implements Database.Batchable<sObject>, Database.Stateful {
    private List<String> invoiceIds;
    private Integer successCount = 0;
    private Integer failureCount = 0;
    private List<String> errorMessages = new List<String>();

    public SendInvoiceEmailBatch(List<String> invoiceIds) {
        //List<String> listString = invoiceIds.split(',');
        this.invoiceIds = invoiceIds;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Name, To_Account__c, To_Account__r.Name,
                   To_Account__r.Default_Invoice_Layout__c, Company__r.Name
            FROM Sales_Invoice__c
            WHERE Id IN : this.invoiceIds
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Sales_Invoice__c> scope) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        for (Sales_Invoice__c invoice : scope) {
            try {
                // Get recipient contacts
                List<Contact> contacts = [
                    SELECT Id, Email
                    FROM Contact
                    WHERE AccountId = :invoice.To_Account__c
                    AND Contact_Role__c = 'Invoicing Contact'
                    AND Email != null
                ];

                if (contacts.isEmpty()) {
                    errorMessages.add('Invoice ' + invoice.Name + ': No invoicing contact found');
                    failureCount++;
                    continue;
                }

                // Get template name from account's default layout
                String invoiceTemplateName = invoice.To_Account__r.Default_Invoice_Layout__c;
                if (String.isBlank(invoiceTemplateName)) {
                    invoiceTemplateName = 'Default_Invoice_Layout'; // fallback
                }

                // Generate PDF
                PageReference pdfPage = Page.InvoicePDF;
                pdfPage.getParameters().put('templateDevName', invoiceTemplateName);
                pdfPage.getParameters().put('whatId', invoice.Id);
                pdfPage.getParameters().put('contactId', contacts[0].Id);

                Blob pdfBlob;
                if (Test.isRunningTest()) {
                    pdfBlob = Blob.valueOf('Test PDF Content');
                } else {
                    pdfBlob = pdfPage.getContentAsPDF();
                }

                // Get Email Template (use a standard one or make it dynamic)
                EmailTemplate emailTemplate = [
                    SELECT Id, Subject, Body, HtmlValue
                    FROM EmailTemplate
                    WHERE DeveloperName = 'Invoice_Email_Template' // Update this
                    LIMIT 1
                ];

                // Create email
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTemplateId(emailTemplate.Id);
                email.setTargetObjectId(contacts[0].Id);
                email.setWhatId(invoice.Id);
                email.setSaveAsActivity(false);

                // Set all recipient emails
                List<String> toEmails = new List<String>();
                for (Contact con : contacts) {
                    if (String.isNotBlank(con.Email)) {
                        toEmails.add(con.Email);
                    }
                }
                email.setToAddresses(toEmails);

                // Attach PDF
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Invoice_' + invoice.Name + '.pdf');
                attachment.setBody(pdfBlob);
                attachment.setContentType('application/pdf');
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

                emailsToSend.add(email);

            } catch (Exception e) {
                errorMessages.add('Invoice ' + invoice.Name + ': ' + e.getMessage());
                failureCount++;
            }
        }

        // Send all emails in this batch
        if (!emailsToSend.isEmpty()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend);

            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    successCount++;
                } else {
                    failureCount++;
                    String errorMsg = 'Email ' + i + ': ';
                    for (Messaging.SendEmailError error : results[i].getErrors()) {
                        errorMsg += error.getMessage() + ' ';
                    }
                    errorMessages.add(errorMsg);
                }
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        // Optional: Send summary email or create a log record
        String summary = 'Invoice Email Batch Completed\n';
        summary += 'Success: ' + successCount + '\n';
        summary += 'Failures: ' + failureCount + '\n';

        if (!errorMessages.isEmpty()) {
            summary += '\nErrors:\n' + String.join(errorMessages, '\n');
        }

        System.debug(summary);

        // Optional: Send notification to admin
        // Or create a custom log object record
    }
}