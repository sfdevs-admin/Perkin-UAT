/* 
* Created By: Lister Technologies
* Created On : 22nd June, 2015
* Purpose : Controller for Notification Center Home Page
* VF Page : Notification_Center_Home_Page
*/


public class Notification_Center_HomePage_Controller
{
    public List<NotificationWrapper> toBePrinted{get;set;} //the data to be printed on the page
    public String ScrollingBanner{get;set;}
    public String ScrollingBannerColor{get;set;}
    public Integer noofColumns{get;set;}
    public Integer columnWidth{get;set;}
    public String VideoUrL{get;set;}
    
     public Notification_Center_HomePage_Controller()
     {
         toBePrinted = new List<NotificationWrapper>();
         Map<String,Notification_Center_HTML_Home_Page__c> requiredData = Notification_Center_HTML_Home_Page__c.getAll(); // getting data from the custom setting

         /** Setting the text and color the Scrolling Text **/
         ScrollingBanner=  requiredData.get('Scrolling Banner').Display_Text__c;
         ScrollingBannerColor = requiredData.get('Scrolling Banner').Color__c;
         
         
         List<String> columnHeaders = new List<String>();
         List<String> orderList = new List<String>();
         List<String> orderList1 = new List<String>();         
         Map<String,String> columnHeadersColor = new Map<String,String>();
         Map<String,String> columnHeadersBGColor = new Map<String,String>();
         
         for(String t: requiredData.keyset())
         {
             if(t.contains('Column'))
             {
                 orderList.add(t);
             }
             orderList1.add(t); 
             if(t.contains('Video'))
                 VideoUrL = requiredData.get(t).URL__c;
         }

         /** Sorting the list according to the column name **/
         columnWidth = 100/orderList.size();
         noofColumns = orderList.size();
         orderList.sort();
         orderList1.sort();
         system.debug('####'+orderList);
         for(String t: orderList)
         {
            system.debug('|||'+t);
            columnHeaders.add(requiredData.get(t).Display_Text__c);
            columnHeadersColor.put(requiredData.get(t).Display_Text__c,requiredData.get(t).Color__c) ;
            columnHeadersBGColor.put(requiredData.get(t).Display_Text__c,requiredData.get(t).Background_Color__c);
         }
         system.debug('columnHeadersColor'+columnHeadersColor);
         /*** Building the Map with related bullets for the respective column ***/ 
         
         for(String t : columnHeaders)
         {
            system.debug('^^^^'+t);
            system.debug('####'+requiredData.keyset());
            for(String a : orderList1)
            {
                system.debug('@@@@@'+a);
                if(a.contains('-'))
                {
                    if(a.split('-')[0].trim().contains(t))
                    {
                        String ColHeaders = a.split('-')[0].trim();
                        system.debug('!!!!'+ColHeaders);
                        Boolean isPresent = false;
                        for(NotificationWrapper t1 :toBePrinted)
                        {
                            if(t1.colname.contains(ColHeaders))
                                isPresent=true;
                        }
                        
                        if(isPresent)
                        {
                            for(NotificationWrapper t1 :toBePrinted)
                            {
                                if(t1.colname.contains(ColHeaders))
                                {
                                    if(requiredData.get(a) != null)
                                        t1.bulletedItems.add(requiredData.get(a));
                                }
                                 
                            }
                        }
                        else
                        {
                            NotificationWrapper c = new NotificationWrapper();
                            c.colname = ColHeaders;
                            c.colnamecolor = columnHeadersColor.get(ColHeaders);
                            c.colbackgroundcolor = columnHeadersBGColor.get(ColHeaders);
                            if(requiredData.get(a) != null)
                                  c.bulletedItems.add(requiredData.get(a));
                            system.debug(c);
                            toBePrinted.add(c);
                        }
                    }
                }
           }
        }
        system.debug('******'+toBePrinted);
    
    }

    /*** Wrapper Class ***/
    
    public class NotificationWrapper
    {
        public String colname{get;set;}
        public String colnamecolor{get;set;}
        public String colbackgroundcolor{get;set;}
        public List <Notification_Center_HTML_Home_Page__c> bulletedItems{get;set;}
        public NotificationWrapper()
        {
            bulletedItems = new List<Notification_Center_HTML_Home_Page__c>();
        }
        
    }
    
    
}