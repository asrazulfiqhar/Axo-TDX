global class InvocableSendAbandonedCheckoutsToSlack {

    @InvocableMethod(label='Send Abandoned Checkouts to Slack')
    global static List<Output> sendToSlack(List<Input> requests) {
        Output result = new Output();

        try {
           
            
            // Step 1: Fetch more records for deduplication
            List<Abandoned_Checkout__c> rawCheckouts = [
                SELECT full_name__c, email__c, phone__c, AbandonedCheckoutUrl__c, latest_abandonment__c, customerid__c
                FROM Abandoned_Checkout__c
                WHERE email__c != null AND email__c != ''
                ORDER BY latest_abandonment__c DESC
                LIMIT 100
            ];
            
            // Step 2: Deduplicate based on email__c
            Map<String, Abandoned_Checkout__c> uniqueEmailMap = new Map<String, Abandoned_Checkout__c>();
            for (Abandoned_Checkout__c record : rawCheckouts) {
                if (!uniqueEmailMap.containsKey(record.email__c)) {
                    uniqueEmailMap.put(record.email__c, record);
                }
            }

        // Step 3: Store deduplicated list
        List<Abandoned_Checkout__c> abandonedCheckouts = new List<Abandoned_Checkout__c>();
        abandonedCheckouts.addAll(uniqueEmailMap.values());


            if (abandonedCheckouts.isEmpty()) {
                sendToSlackAsync('🎉 No abandoned checkouts found at the moment.');
            } else {
                String message = '*🛒 Abandoned Checkouts for Approval:*\n';
                Integer count = 1;
                Set<String> seenEmails = new Set<String>();

                for (Abandoned_Checkout__c record : abandonedCheckouts) {
                    if (String.isBlank(record.email__c) || seenEmails.contains(record.email__c)) continue;
                    seenEmails.add(record.email__c);

                    message += '\n*' + count + '. Abandoned Cart:*\n';
                    message += '• *Name:* ' + safe(record.full_name__c) + '\n';
                    message += '• *Email:* ' + safe(record.email__c) + '\n';
                    message += '• *Phone:* ' + safe(record.phone__c) + '\n';
                    message += '• *Customer ID:* ' + safe(record.customerid__c) + '\n';
                    message += '• *Date:* ' + format(record.latest_abandonment__c) + '\n';
            		message += '• *Cart Link:* ' + safe(record.AbandonedCheckoutUrl__c) + '\n';
                    count++;
                }

                message += '\n_Use `/approve-abandoned-orders` to apply discounts._';

                sendToSlackAsync(message);
            }

            result.success = '✨🎉✨🎉✨🎉✨';
        } catch (Exception e) {
            System.debug('Error in InvocableSendAbandonedCheckoutsToSlack: ' + e.getMessage());
            result.success = 'Error : ' +  e.getMessage();
        }

        return new List<Output>{ result };
    }

    // FUTURE method to send message to Slack
    @future(callout=true)
    public static void sendToSlackAsync(String message) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(System.label.webhook); // 👈 
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        String escaped = message
            .replace('\\', '\\\\')
            .replace('"', '\\"')
            .replace('\n', '\\n');

        req.setBody('{"text": "' + escaped + '"}');

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Slack response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Slack error: ' + e.getMessage());
        }
    }

    // Helper
    private static String safe(String val) {
        return String.isNotBlank(val) ? val : 'N/A';
    }

    private static String format(Datetime dt) {
        return (dt != null) ? dt.format('yyyy-MM-dd HH:mm') : 'N/A';
    }

    global class Input {
        @InvocableVariable
        public String dummyInput; // Can be used later if needed
    }

    global class Output {
        @InvocableVariable
        public String success;
    }
}