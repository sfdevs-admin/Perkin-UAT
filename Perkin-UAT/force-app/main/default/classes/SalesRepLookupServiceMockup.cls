@isTest
global class SalesRepLookupServiceMockup implements WebServiceMock{
global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
      // SalesRepLookupService.WebServices_PESFDCSalesRepLookup_Port respElement = 
        //   new SalesRepLookupService.WebServices_PESFDCSalesRepLookup_Port();
               
       SalesRepLookupService.SalesReps2 salesRep = new SalesRepLookupService.SalesReps2();
               salesRep.AssignLevel = 'PS1';
               salesRep.ProductLine = 'AA';
               salesRep.SalesRepName = 'Test Rep Name';
               salesRep.SalesRepEmail = 'test1@test.com';               
               salesRep.SalesRepsManagerEmail = 'test2@test.com';               
               salesRep.SalesRepsManagerName = 'test2om';               
      SalesRepLookupService.salesRepLookupV2Response saleRepResponse = new SalesRepLookupService.salesRepLookupV2Response();
				saleRepResponse.SalesReps2 = new List<SalesRepLookupService.SalesReps2>();
               saleRepResponse.SalesReps2.add(salesRep);
               //respElement.
       response.put('response_x', saleRepResponse); 
   }
}