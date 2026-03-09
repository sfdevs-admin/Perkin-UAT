/**
 * Created by mgaska001 on 04.03.2026.
 */

global class PricingRequestForceJob implements Schedulable {
    public static final String STATUS_FORCE = 'Force';
    public static final String STATUS_REQUESTED = 'Requested';

    public static final String ACTION_PRICE_REQUEST = 'PRICE REQUEST';

    global void execute(SchedulableContext sc) {
        // 1. Publish platform event for Get SAP Prices for Quotes with Price_Request_Force__c = TRUE
        // Trigger recalculation in chunks of 20 Quotes
        List<SBQQ__Quote__c> quotes = [
            SELECT Id, Price_Request_Status__c
            FROM SBQQ__Quote__c
            WHERE Price_Request_Status__c = :STATUS_FORCE
            ORDER BY CreatedDate
            LIMIT 20
        ];
        if (!quotes.isEmpty()) {
            Datetime requestStamp = Datetime.now();
            for (SBQQ__Quote__c quote : quotes) {
                quote.Price_Request_Status__c = STATUS_REQUESTED;
                quote.Price_Request_Stamp__c = requestStamp;
                quote.Price_Response_Error__c = null;
            }
            // Save Quote price request fields and collect Quote.Id for publishing platform events
            List<BD_Quote_Event__e> quoteEvents = new List<BD_Quote_Event__e>();
            Database.SaveResult[] results = Database.update(quotes, false);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    // Operation failed, so get all errors
                    for(Database.Error err : sr.getErrors()) {
                        System.debug(sr.getId() + ' - ' + err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Fields that affected this error: ' + err.getFields());
                    }
                } else {
                    BD_Quote_Event__e event = new BD_Quote_Event__e();
                    event.BD_Quote_Id__c = sr.getId();
                    event.BD_Action__c = ACTION_PRICE_REQUEST;
                    quoteEvents.add(event);
                }
            }
            // Publish BD_Quote_Event__e events
            EventBus.publish(quoteEvents);

            if (!Test.isRunningTest()) {
                // 2. Schedule the next run 1 minute from now to process next chunk of Quotes
                PricingRequestForceJob nextJob = new PricingRequestForceJob();
                String cronStr = '0 ' + Datetime.now().addMinutes(1).minute() + ' * * * ?';
                System.schedule('PricingRequestForce' + Datetime.now(), cronStr, nextJob);
            }
        }

        // 3. Abort the current job
        System.abortJob(sc.getTriggerId());
    }
}