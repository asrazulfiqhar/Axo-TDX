@RestResource(urlMapping='/getabandonmentorders')
global without sharing class SlackAbandonedCheckoutAPIAbu {

    @HttpPost
    global static String handleGetAbandonedCheckouts() {
        RestRequest req = RestContext.request;
        String responseUrl = req.params.get('response_url');

        List<Abandoned_Checkout__c> abandonedCheckouts = [
            SELECT full_name__c, email__c, phone__c, AbandonedCheckoutUrl__c, latest_abandonment__c,customerid__c 
            FROM Abandoned_Checkout__c
            WHERE email__c != null AND email__c != ''
            ORDER BY latest_abandonment__c DESC	
            LIMIT 10
        ];

        System.debug('Fetched ' + abandonedCheckouts.size() + ' records');
        if (!abandonedCheckouts.isEmpty()) {
            System.debug('First record email: ' + abandonedCheckouts[0].email__c);
        }

        if (abandonedCheckouts.isEmpty()) {
            sendSlackResponse(responseUrl, '🎉 No abandoned checkouts found at the moment.');
            return '';
        }

        String message = '*🛒 Abandoned Checkouts Summary:*\n';
        Integer count = 1;
        Set<String> seenEmails = new Set<String>();

        for (Abandoned_Checkout__c record : abandonedCheckouts) {
            System.debug('Processing record: ' + record);

            if (String.isBlank(record.email__c) || seenEmails.contains(record.email__c)) continue;
            seenEmails.add(record.email__c);

            message += '\n*' + count + '. Abandoned Cart Details:*\n';
            message += '• *Full Name:* ' + safeGet(record.full_name__c) + '\n';
            message += '• *Email:* ' + safeGet(record.email__c) + '\n';
            message += '• *Phone:* ' + safeGet(record.phone__c) + '\n';
            message += '• *Customer ID:* ' + safeGet(record.customerid__c) + '\n';
            message += '• *Created At:* ' + formatDatetime(record.latest_abandonment__c) + '\n';
            message += '• *Cart Link:* ' + safeGet(record.AbandonedCheckoutUrl__c) + '\n';
            count++;
        }

        if (count == 1) {
            message = '🎉 No *valid* abandoned checkouts found (maybe due to missing email).';
        } else {
            message += '\n_Use `/approve-abandoned-orders` to apply discounts._';
        }

        sendSlackResponse(responseUrl, message);
        return '';
    }

    private static void sendSlackResponse(String url, String message) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        String escapedMsg = message
            .replace('\\', '\\\\')
            .replace('"', '\\"')
            .replace('\n', '\\n');

        // 👇 This makes the message public in the channel
        req.setBody('{"response_type": "in_channel", "text": "' + escapedMsg + '"}');

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Slack Response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Error sending Slack message: ' + e.getMessage());
        }
    }

    private static String safeGet(String value) {
        return String.isNotBlank(value) ? value : 'N/A';
    }

    private static String formatDatetime(Datetime dt) {
        return (dt != null) ? dt.format('yyyy-MM-dd HH:mm') : 'N/A';
    }
}