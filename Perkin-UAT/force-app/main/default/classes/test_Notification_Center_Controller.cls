@isTest
private class test_Notification_Center_Controller
 {
    
    public static Notification_Center_HTML_Home_Page__c customSettingData1;
    public static Notification_Center_HTML_Home_Page__c customSettingData2;
    public static Notification_Center_HTML_Home_Page__c customSettingData3;
    public static Notification_Center_HTML_Home_Page__c customSettingData4;            
    public static Notification_Center_HTML_Home_Page__c customSettingData5;
    public static Notification_Center_HTML_Home_Page__c customSettingData6;
    public static Notification_Center_HTML_Home_Page__c customSettingData7;
    public static Notification_Center_HTML_Home_Page__c customSettingData8;
    public static Notification_Center_HTML_Home_Page__c customSettingData9;
    
    
    static 
    {
        customSettingData1 = new Notification_Center_HTML_Home_Page__c ();
        customSettingData1.Name='Column1';
        customSettingData1.Background_Color__c='#6CB442';
        customSettingData1.Color__c='White';
        customSettingData1.Display_Text__c='TIPS & HINTS';
        customSettingData1.Mail_To__c='';
        customSettingData1.URL__c='';

        customSettingData2 = new Notification_Center_HTML_Home_Page__c ();
        customSettingData2.Name='Column2';
        customSettingData2.Background_Color__c='#0055A6';
        customSettingData2.Color__c='White';
        customSettingData2.Display_Text__c='NEWS & UPDATES';
        customSettingData2.Mail_To__c='';
        customSettingData2.URL__c='';
        
        customSettingData3 = new Notification_Center_HTML_Home_Page__c ();
        customSettingData3.Name='Column3';
        customSettingData3.Background_Color__c='#E9A100';
        customSettingData3.Color__c='White';
        customSettingData3.Display_Text__c='FEEDBACK & HELP';
        customSettingData3.Mail_To__c='';
        customSettingData3.URL__c='';
        
        customSettingData4 = new Notification_Center_HTML_Home_Page__c ();
        customSettingData4.Name='Column4';
        customSettingData4.Background_Color__c='#A90061';
        customSettingData4.Color__c='White';
        customSettingData4.Display_Text__c='FEATURED VIDEOS';
        customSettingData4.Mail_To__c='';
        customSettingData4.URL__c='';

        customSettingData5 = new Notification_Center_HTML_Home_Page__c ();
        customSettingData5.Name='FEATURED VIDEOS - 1';
        customSettingData5.Background_Color__c='';
        customSettingData5.Color__c='White';
        customSettingData5.Display_Text__c='Using the Sales Cloud';
        customSettingData5.Mail_To__c='';
        customSettingData5.URL__c='https://lms.cfs-api.com/v1/12/lms.aspx?hash=WUlRa1pjd0RRUDc2bW01cW9nSTdFVVd4TGFIYURsMzJFSnpNdmFrNWd3OFdyN21VRXVyRDZOUTRrc1h6Z0JVSnU3ZW1USGs5YjRsd3VMSWZDVGxkSEpnN1ltS09sb0RINkNCamRkOHVLbjRndll2SGd1bXlwbFc2VXFMUitBK21mN2w1alhiV05mMlp2ZWdmTjRiNm9nPT0=';
        
        customSettingData6 = new Notification_Center_HTML_Home_Page__c ();
        customSettingData6.Name='FEEDBACK & HELP - 1';
        customSettingData6.Background_Color__c='';
        customSettingData6.Color__c='Red';
        customSettingData6.Display_Text__c='Submit an Idea';
        customSettingData6.Mail_To__c='mailto:0f9v0000000clmfkak@post.v-6t9qnmaa.cs12.chatter.sandbox.salesforce.com?Subject=My Idea For Salesforce';
        customSettingData6.URL__c='';
        
        customSettingData7 = new Notification_Center_HTML_Home_Page__c ();
        customSettingData7.Name='NEWS & UPDATES - 1';
        customSettingData7.Background_Color__c='';
        customSettingData7.Color__c='White';
        customSettingData7.Display_Text__c='NEW "5 Star" Profile';
        customSettingData7.Mail_To__c='https://perkinelmeremea.box.com/s/bjwctbo8yodokq6wmbltyidgh20er4yk';
        customSettingData7.URL__c='';
        
        customSettingData8 = new Notification_Center_HTML_Home_Page__c ();
        customSettingData8.Name='TIPS & HINTS - 1';
        customSettingData8.Background_Color__c='#A90061';
        customSettingData8.Color__c='White';
        customSettingData8.Display_Text__c='Leveraging Account Teams';
        customSettingData8.Mail_To__c='';
        customSettingData8.URL__c='https://perkinelmeremea.box.com/s/uen9y8pr1ln18t1kr7q63p9dfowyk2ub';
        
        customSettingData9 = new Notification_Center_HTML_Home_Page__c ();
        customSettingData9.Name='Scrolling Banner';
        customSettingData9.Background_Color__c='';
        customSettingData9.Color__c='Red';
        customSettingData9.Display_Text__c='Welcome to the NEW Homepage Notification Center';
        customSettingData9.Mail_To__c='';
        customSettingData9.URL__c='';
        
        insert new List<Notification_Center_HTML_Home_Page__c>{customSettingData1,customSettingData2,customSettingData3,customSettingData4,customSettingData5,customSettingData6,customSettingData7,customSettingData8,customSettingData9};
            
    }

    static testMethod void myUnitTest() {
        
        Notification_Center_HomePage_Controller controller = new Notification_Center_HomePage_Controller();
        
    
    }
}