global class InvocableSendCustomerPerformanceToSlack {

    @InvocableMethod(label='Send Customer Performance to Slack')
    global static List<Output> sendToSlack(List<Input> inputs) {
        Output result = new Output();

        try {
           
            if (inputs[0].customers.isEmpty()) {
                sendToSlackAsync('🎉 No Customers found at the moment. \nFor the Query : ' + inputs[0].performanceQuery);
            } else {
                String message = '';
                Integer count = 1;
				message += '\n*' + inputs[0].performanceQuery +'*\n';
                for (Customer record : inputs[0].customers) {
                    
                    message += '\n*✨✨✨ '+ count +' ✨✨✨*\n';
                    message += '• *Name:* ' + safe(record.Name) + '\n';
                    message += '• *Email:* ' + safe(record.email__c) + '\n';
                    message += '• *Category:* ' + safe(record.Category__c) + '\n';
                    message += '• *Number of orders:* ' + safe(record.Number_of_orders__c) + '\n';
                    message += '• *Amount Spent:* ' + record.Amount_Spent__c + '\n';
            		message += '• *category updated At:* ' + format(record.category_updated_At__c) + '\n';
                    
                    if(record.Previous_Category__c != null){
                        
                    message += '• *Previous Category:* ' + safe(record.Previous_Category__c) + '\n';
                    }
                    count++;
                }

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
        req.setEndpoint(System.label.webhook); //
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
        public String performanceQuery; // Can be used later if needed
          @InvocableVariable
        public List<Customer> customers; // Can be used later if needed
        
    }

    global class Output {
        @InvocableVariable
        public String success;
    }
}