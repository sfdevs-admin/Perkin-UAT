global class TabComponentController {
	global Boolean displayRelatedListSection {get;set;}
    global String getTabList() {
        //Get all the releated Objects for the current record.Serialize it and send it to the Page
        List<Account__c> tabSettingList = new List<Account__c>();
        
        tabSettingList =  [SELECT Tab_Name__c,Object_API_Name__c,Field_List__c,Sort_Order__c 
                                  FROM Account__c
                                  ORDER BY Sort_Order__c ASC];
 
 		system.debug('tabsettinglist '+tabSettingList);
        return JSON.serialize(tabSettingList);
    }
    
    global void loadRelatedList() {
        displayRelatedListSection = true;
    }
    
}