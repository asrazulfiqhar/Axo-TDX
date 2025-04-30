@RestResource(urlMapping='/approveAbandonedOrders')
global without sharing class SlackAbandonedCheckoutApprovalAPI {

    @HttpPost
    global static String handleApprovalSendEmails() {
        RestRequest req = RestContext.request;
        String body = req.requestBody.toString();
        Map<String, String> formData = parseFormData(body);
        String responseUrl = formData.get('response_url');

        System.debug('📬 Request received. response_url = ' + responseUrl);

        // Respond quickly to Slack
        if (!String.isBlank(responseUrl)) {
            sendSlackResponse(responseUrl, 
                '⏳ *Hang tight...* Sending emails to recently abandoned checkouts. Summary coming soon!'
            );
        } else {
            System.debug('⚠️ response_url was null or blank.');
        }

        // Offload email processing to async method
        try {
            SlackEmailAsyncProcessor.processEmailsAsync(responseUrl);
        } catch (Exception e) {
            System.debug('❌ Error starting async processing: ' + e.getMessage());
        }

        return ''; // Return quickly to avoid Slack timeout
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

        req.setBody('{"response_type": "in_channel", "text": "' + escapedMsg + '"}');

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('✅ Slack response sent. Status: ' + res.getStatus() + ' Body: ' + res.getBody());
        } catch (Exception e) {
            System.debug('❌ Error sending Slack message: ' + e.getMessage());
        }
    }

    private static Map<String, String> parseFormData(String body) {
        Map<String, String> data = new Map<String, String>();
        for (String pair : body.split('&')) {
            List<String> kv = pair.split('=');
            if (kv.size() == 2) {
                String key = EncodingUtil.urlDecode(kv[0], 'UTF-8');
                String value = EncodingUtil.urlDecode(kv[1], 'UTF-8');
                data.put(key, value);
            }
        }
        return data;
    }
}