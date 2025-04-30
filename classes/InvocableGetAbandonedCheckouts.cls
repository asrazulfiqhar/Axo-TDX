global class InvocableGetAbandonedCheckouts{
    @InvocableMethod(label = 'Returns the List of Abandoned Checkouts')
    global static List<Output> handleSlackCheckout(List<Input> inputs){
        List<Output> ops = new List<Output>();
        Output op = new Output();
        
         // Step 1: Fetch more records for deduplication
            List<Abandoned_Checkout__c> rawCheckouts = [
                SELECT full_name__c, email__c, phone__c,AbandonedCheckoutUrl__c, latest_abandonment__c,customerid__c
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


        op.res = abandonedCheckouts;
        ops.add(op);
        return ops;
    }

    global class Input{
        @InvocableVariable
        public String req;
    }

    global class Output{
        @InvocableVariable
        public List<Abandoned_Checkout__c> res;

    }

}