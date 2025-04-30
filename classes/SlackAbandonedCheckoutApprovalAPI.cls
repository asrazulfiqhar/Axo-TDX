@RestResource(urlMapping='/approveAbandonedOrders')
global without sharing class SlackAbandonedCheckoutApprovalAPI {

    @HttpPost
    global static String handleApprovalSendEmails() {
        RestRequest req = RestContext.request;
        String responseUrl = req.params.get('response_url');

        System.debug('📬 Request received. response_url = ' + responseUrl);

        // Respond quickly to Slack
        if (!String.isBlank(responseUrl)) {
            sendSlackResponse(responseUrl, 
                '⏳ *Hang tight...* Sending emails to recently abandoned checkouts. Summary coming soon!'
            );
        }

        // Call async email processor
        SlackEmailAsyncProcessor.processEmailsAsync(responseUrl);

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

        req.setBody('{"response_type": "in_channel", "text": "' + escapedMsg + '"}');

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('✅ Slack response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('❌ Error sending Slack message: ' + e.getMessage());
        }
    }
}