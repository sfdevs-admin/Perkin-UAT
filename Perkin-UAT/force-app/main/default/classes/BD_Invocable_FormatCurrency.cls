public class BD_Invocable_FormatCurrency {
    public class Request {
        @InvocableVariable(required=true)
        public Decimal totalNetPrice;
        
        @InvocableVariable(required=true)
        public String currencyCode;
    }
    
    public class Response {
        @InvocableVariable
        public String formattedPrice;
    }
    
    @InvocableMethod(label='Format Total Net Price - Brazilian Locale' description='Formats the given price into BRL currency format (pt-BR).')
    public static List<Response> formatPrice(List<Request> requests) {
        List<Response> results = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            
            // Format using the pt-BR locale
            res.formattedPrice = formatCurrency(req.totalNetPrice, req.currencyCode);
            results.add(res);
        }
        
        return results;
    }
    
    private static String formatCurrency(Decimal value, String currencyCode) {
        String formatted = value.setScale(2).format();

        formatted = formatted.replace('.', '#')   
                             .replace(',', '.')   
                             .replace('#', ',');  

        if (formatted.contains(',')) {
            List<String> parts = formatted.split(',');
            String decimals = parts[1];
            if (decimals.length() == 1) {
                formatted += '0';
            }
        } else {
            formatted += ',00';
        }

        return currencyCode + ' ' + formatted;
    }
}