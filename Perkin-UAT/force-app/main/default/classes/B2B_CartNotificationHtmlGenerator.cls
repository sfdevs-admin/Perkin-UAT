//Test class - B2B_CartNotificationTest
public class B2B_CartNotificationHtmlGenerator {
    
    public static String getItemRow(CartItem cartItem){
        String itemDetail = '<tr><td style="width:50%;padding: 8px; text-align: left;" width:"40%">'+
            cartItem.Product2.Name +'<br/>'+
            cartItem.Product2.B2B_Part_Number__c +
            '</td><td style="width:10%;padding: 8px; text-align: center;" width:"20%">'+
            cartItem.Quantity +
            '</td><td style="width:20%;padding: 8px; text-align: center;" width:"20%">'+
            cartItem.SalesPrice +'&nbsp;'+cartItem.CurrencyIsoCode +
            '</td><td style="width:20%;padding: 8px; text-align: center;" width:"10%">'+
            cartItem.TotalPrice +'&nbsp;'+cartItem.CurrencyIsoCode +
            '</td></tr>';
        return itemDetail;
    }
    /*public static String getSummary(Webcart webcart){
        String summary = '<table width="100%">'+
            //subtotal row
            '<tr><td style="width:50%;padding: 8px; text-align: left;"></td>'+
            '<td style="width:10%;padding: 8px; text-align: left;">'+
            '</td><td style="width:20%;padding: 8px; text-align: center;font-weight: bold; background-color: #f2f2f2;">'+
            'Subtotal</td>'+
            '<td style="width:20%;padding: 8px; text-align: center;font-weight: bold; background-color: #f2f2f2;">'+
            webcart.TotalProductAmount+'&nbsp;'+webcart.CurrencyIsoCode+
            '</td></tr>'+
            
            //shipping row
            '<tr><td style="width:50%;padding: 8px; text-align: left;"></td>'+
            '<td style="width:10%;padding: 8px; text-align: left;">'+
            '</td><td style="width:20%;padding: 8px; text-align: center;font-weight: bold; background-color: #f2f2f2;">'+
            'Shipping</td>'+
            '<td style="width:20%;padding: 8px; text-align: center;font-weight: bold; background-color: #f2f2f2;">'+
            webcart.TotalChargeAmount+'&nbsp;'+webcart.CurrencyIsoCode+
            '</td></tr>'+
            
            //tax row
            '<tr><td style="width:50%;padding: 8px; text-align: left;"></td>'+
            '<td style="width:10%;padding: 8px; text-align: left;">'+
            '</td><td style="width:20%;padding: 8px; text-align: center;font-weight: bold; background-color: #f2f2f2;">'+
            'Tax</td>'+
            '<td style="width:20%;padding: 8px; text-align: center;font-weight: bold; background-color: #f2f2f2;">'+
            webcart.TotalTaxAmount+'&nbsp;'+webcart.CurrencyIsoCode+
            '</td></tr>'+
            
            //grand total row
            '<tr><td style="width:50%;padding: 8px; text-align: left;"></td>'+
            '<td style="width:10%;padding: 8px; text-align: left;">'+
            '</td><td style="width:20%;padding: 8px; text-align: center;font-weight: bold; background-color: #f2f2f2;">'+
            'Grand Total</td>'+
            '<td style="width:20%;padding: 8px; text-align: center;font-weight: bold; background-color: #f2f2f2;">'+
            webcart.GrandTotalAmount+'&nbsp;'+webcart.CurrencyIsoCode+
            '</td></tr>'+
            '<tr><td style="width:50%;padding: 8px; text-align: left;"></td>'+
            '<td style="width:10%;padding: 8px; text-align: left;">'+
            '</td><td colspan ="2" style="width:40%;padding: 8px; text-align: center; background-color: #f2f2f2;">'+
            '*Note the Above shipping/tax amount is may vary while checkout</td>'+
            '</tr>'+
            '</table>';
        return summary;
    }*/
    
}