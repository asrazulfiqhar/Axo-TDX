public class SlackEmailAsyncProcessor {

    @future(callout=true)
    public static void processEmailsAsync(String responseUrl) {
        List<Abandoned_Checkout__c> abandonedCheckouts = [
            SELECT Id, full_name__c, email__c, AbandonedCheckoutUrl__c, latest_abandonment__c, 
                   Discount_Approved__c, Email_Sent__c
            FROM Abandoned_Checkout__c
            WHERE email__c != null AND email__c != ''
            ORDER BY latest_abandonment__c DESC
            LIMIT 10
        ];

        Integer emailCount = 0;
        Integer failedCount = 0;
        String discountCode = System.label.discountCode;

        List<Abandoned_Checkout__c> toUpdate = new List<Abandoned_Checkout__c>();

        for (Abandoned_Checkout__c record : abandonedCheckouts) {
            if (String.isBlank(record.email__c) || record.Email_Sent__c == true) continue;

            String formattedDate = (record.latest_abandonment__c != null)
                ? record.latest_abandonment__c.format('MMMM dd, yyyy')
                : 'a few days ago';

            String body = 
                'Hi ' + record.full_name__c + ',\n\n' +
                'We noticed you left some awesome products in your cart around *' + formattedDate + '*.\n\n' +
                'As a thank-you, here’s a special discount just for you! 🎁\n\n' +
                '*Use code: ' + discountCode + '* to get **10% OFF** your total cart amount.\n\n' + 
                'Click below to return to your cart and complete your purchase:\n' + record.AbandonedCheckoutUrl__c +
                '\n\nHappy Shopping!\n— Your Friendly Shop Team';

            try {
                SendGridEmailService.sendEmail(
                    record.email__c, 
                    '👋 You left something behind — enjoy 10% off!', 
                    body
                );

                emailCount++;
                record.Discount_Code_Sent__c = discountCode;
                record.Email_Sent__c = true;
                record.Discount_Sent_At__c = System.now();
                record.Discount_Approved__c = true;

                toUpdate.add(record);
            } catch (Exception e) {
                failedCount++;
                System.debug('❌ SendGrid failed for ' + record.email__c + ': ' + e.getMessage());
            }
        }

            
                
     
            
        

        // Final Slack Summary
        if (!String.isBlank(responseUrl)) {
            String summary;
            if (emailCount > 0) {
                summary = '*✅ Email Summary:*\nSent cart reminder emails with discount codes to *' + emailCount + '* customers.';
            } else if (failedCount > 0) {
                summary = '*⚠️ Email Failure:*\nAll emails failed to send. Please check SendGrid logs or API config.';
            } else {
                summary = '*ℹ️ No emails were sent.* Customers may already have received emails or had no address.';
            }

            postToSlack(responseUrl, summary);
            
              	if (!toUpdate.isEmpty()) {
            try {
             	 upsert toUpdate;
                }
             catch (Exception e) {
                System.debug('⚠️ DML failed: ' + e.getMessage());
            }
                 }
        }
    }

    private static void postToSlack(String url, String message) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        String escapedMsg = message
            .replace('\\', '\\\\')
            .replace('"', '\\"')
            .replace('\n', '\\n');

        req.setBody('{"response_type": "in_channel", "text": "' + escapedMsg + '"}');

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Slack follow-up response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('❌ Error sending final Slack message: ' + e.getMessage());
        }
    }
}