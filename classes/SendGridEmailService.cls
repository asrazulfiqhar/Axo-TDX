public with sharing class SendGridEmailService {
    private static final String SENDGRID_API_KEY = System.label.SENDGRID_API_KEY; // Prefer storing in Custom Metadata

    public static void sendEmail(String toEmail, String subject, String bodyText) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.sendgrid.com/v3/mail/send');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + SENDGRID_API_KEY);
        req.setHeader('Content-Type', 'application/json');

        String payload = JSON.serialize(new Map<String, Object>{
            'personalizations' => new List<Object>{
                new Map<String, Object>{
                    'to' => new List<Object>{ new Map<String, String>{ 'email' => toEmail } },
                    'subject' => subject
                }
            },
            'from' => new Map<String, String>{ 'email' => 'mohammed.abubakar@axolt.com' },
            'content' => new List<Object>{
                new Map<String, String>{
                    'type' => 'text/plain',
                    'value' => bodyText
                }
            }
        });

        req.setBody(payload);

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('SendGrid Response: ' + res.getBody());
            System.debug('email sent to ' + toEmail);
            if (res.getStatusCode() != 202) {

            System.debug('SendGrid Response: ' + res.getStatus());
                throw new EmailException('SendGrid error: ' + res.getStatus());
            }
        } catch (Exception e) {

            System.debug('SendGrid Response: ' + e.getMessage());
            throw new EmailException('SendGrid API call failed: ' + e.getMessage());
        }
    }

    public class EmailException extends Exception {}
}
