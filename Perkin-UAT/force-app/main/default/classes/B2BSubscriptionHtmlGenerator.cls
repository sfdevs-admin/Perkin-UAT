//Test class - B2BSubscriptionReminderEmailTest
public class B2BSubscriptionHtmlGenerator {
public static String getSubscriptionDetails(B2B_Subscriptions__c subscription){
        String subDetail = 'Hi '+subscription.B2B_Contact__r.FirstName+' '+ subscription.B2B_Contact__r.LastName+',<br/>'+
            '<div style="padding-top: .25rem;">Your Next Subscription Order is coming soon<br/></div>'+
            '<div style="padding-top: .25rem;">Please find below details of your B2B Subscription.<br/></div>'+
            '<div style="padding-top: .25rem;"><b>Subscription Name</b> - '+subscription.Subscription_Name__c+ '<br/></div>'+
            '<div style="padding-top: .25rem;"><b>Order Date</b> -  '+subscription.B2B_Next_Billing_Date__c.format()+'.<br/></div>';      
        return subDetail;
    }
    
    public static String getItemRow(B2B_Subscription_Items__c subscriptionitem){
        String itemDetail = '<tr><td style="width:50%;padding: 8px; text-align: left;" width:"40%">'+
            subscriptionitem.B2B_Product__r.Name +'<br/>'+
            subscriptionitem.B2B_Product__r.B2B_Part_Number__c +
            '</td><td style="width:10%;padding: 8px; text-align: center;" width:"20%">'+
            subscriptionitem.B2B_Quantity__c +
            '</td><td style="width:20%;padding: 8px; text-align: center;" width:"20%">'+
            subscriptionitem.B2B_Unit_Price__c +'&nbsp;'+subscriptionitem.CurrencyIsoCode +
            '</td><td style="width:20%;padding: 8px; text-align: center;" width:"10%">'+
            subscriptionitem.B2B_Total_Price__c +'&nbsp;'+subscriptionitem.CurrencyIsoCode +
            '</td></tr>';
        return itemDetail;
    }
    public static String getSummary(B2B_Subscriptions__c subscription){
        String summary = '<table width="100%"><tr><td style="width:50%;padding: 8px; text-align: left;"></td>'+
            '<td style="width:10%;padding: 8px; text-align: left;">'+
            '</td><td style="width:20%;padding: 8px; text-align: center;font-weight: bold; background-color: #f2f2f2;">'+
            'Grand Total</td>'+
            '<td style="width:20%;padding: 8px; text-align: center;font-weight: bold; background-color: #f2f2f2;">'+
            subscription.B2B_Total_Amount__c+'&nbsp;'+subscription.CurrencyIsoCode+
            '</td></tr>'+
            '<tr><td style="width:50%;padding: 8px; text-align: left;"></td>'+
            '<td style="width:10%;padding: 8px; text-align: left;">'+
            '</td><td colspan ="2" style="width:40%;padding: 8px; text-align: center; background-color: #f2f2f2;">'+
            '*Note the Above amount is excluding Shipping & Tax</td>'+
            '</tr>'+
            '</table>';
        return summary;
    }
    
}