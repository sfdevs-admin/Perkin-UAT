@isTest
public class BD_Invocable_FormatCurrencyTest {

    @isTest
    static void testUSDFormatting() {
        BD_Invocable_FormatCurrency.Request req = new BD_Invocable_FormatCurrency.Request();
        req.totalNetPrice = 400;
        req.currencyCode = 'USD';
        
        List<BD_Invocable_FormatCurrency.Request> requests = new List<BD_Invocable_FormatCurrency.Request>{ req };
            
        Test.startTest();
        	List<BD_Invocable_FormatCurrency.Response> responses = BD_Invocable_FormatCurrency.formatPrice(requests);
        Test.stopTest();
        
        Assert.areEqual('USD 400,00', responses[0].formattedPrice);
    }
    
    @isTest
    static void testUSDFormatting2() {
        BD_Invocable_FormatCurrency.Request req = new BD_Invocable_FormatCurrency.Request();
        req.totalNetPrice = 400.02;
        req.currencyCode = 'USD';
        
        List<BD_Invocable_FormatCurrency.Request> requests = new List<BD_Invocable_FormatCurrency.Request>{ req };
            
        Test.startTest();
        	List<BD_Invocable_FormatCurrency.Response> responses = BD_Invocable_FormatCurrency.formatPrice(requests);
        Test.stopTest();
        
        Assert.areEqual('USD 400,02', responses[0].formattedPrice);
    }
    
    @isTest
    static void testBRLFormatting() {
        BD_Invocable_FormatCurrency.Request req = new BD_Invocable_FormatCurrency.Request();
        req.totalNetPrice = 100812.4;
        req.currencyCode = 'BRL';
        
        List<BD_Invocable_FormatCurrency.Request> requests = new List<BD_Invocable_FormatCurrency.Request>{ req };
            
        Test.startTest();
        	List<BD_Invocable_FormatCurrency.Response> responses = BD_Invocable_FormatCurrency.formatPrice(requests);
        Test.stopTest();
        
        Assert.areEqual('BRL 100.812,40', responses[0].formattedPrice);
    }
}