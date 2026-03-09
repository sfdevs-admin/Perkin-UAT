public class B2B_SourcingDCInvocable {
    public class Request {
        @InvocableVariable(required=true)
        public String sourcingDC;

        @InvocableVariable(required=true)
        public List<String> productIdList;
    }

    public class Response {
        @InvocableVariable
        public List<B2B_Product_Shipping__c> productShippingList;
    }

    @InvocableMethod(label='Get Product Shipping List' description='Returns B2B_Product_Shipping__c records for given sourcingDC and productIdList')
    public static List<Response> getProductShippingList(List<Request> requests) {
        Set<String> allSourcingDCs = new Set<String>();
        Set<String> allProductIds = new Set<String>();
        Map<String, Set<String>> requestToProductIds = new Map<String, Set<String>>();

        // Collect all sourcingDCs and productIds
        for(Request req : requests) {
            if(req.sourcingDC != null) {
                List<String> sourcingDCList = req.sourcingDC.contains(';') ? req.sourcingDC.split(';') : new List<String>{req.sourcingDC};
                allSourcingDCs.addAll(sourcingDCList);
                requestToProductIds.put(req.sourcingDC, new Set<String>(req.productIdList));
                allProductIds.addAll(req.productIdList);
            }
        }

        // Query once
        List<B2B_Product_Shipping__c> allShippingRecords = [
            SELECT B2B_Estimated_Days__c, B2B_Sourcing_DC__c, B2B_Product__c
            FROM B2B_Product_Shipping__c
            WHERE B2B_Is_Active__c = true
            AND B2B_Sourcing_DC__c IN :allSourcingDCs
            AND B2B_Product__c IN :allProductIds
        ];

        // Map results for each request
        List<Response> responses = new List<Response>();
        for(Request req : requests) {
            Response res = new Response();
            List<String> sourcingDCList = req.sourcingDC.contains(';') ? req.sourcingDC.split(';') : new List<String>{req.sourcingDC};
            Set<String> productIdSet = new Set<String>(req.productIdList);

            res.productShippingList = new List<B2B_Product_Shipping__c>();
            for(B2B_Product_Shipping__c shipping : allShippingRecords) {
                if(sourcingDCList.contains(shipping.B2B_Sourcing_DC__c) && productIdSet.contains(shipping.B2B_Product__c)) {
                    res.productShippingList.add(shipping);
                }
            }
            responses.add(res);
        }
        return responses;
    }
}