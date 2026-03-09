public with sharing class OverrideDealDeskNewButtonController {
    public String oppId {get;set;}
    public OverrideDealDeskNewButtonController(ApexPages.StandardController controller){
       oppId = ApexPages.CurrentPage().getparameters().get('id');
    }

    @auraEnabled
    public static  List<String> getRequestForValues(){
        List<String> pickListValuesList = new List<String>();
        Schema.DescribeFieldResult fieldResult = Deal_Desk__c.Request_For__c.getDescribe();
		for(Schema.PicklistEntry pickListVal : fieldResult.getPicklistValues()){
			pickListValuesList.add(pickListVal.getLabel());
		}   
        System.debug('pickListValuesList--->'+pickListValuesList);
        return pickListValuesList;
    } 

    @auraEnabled
    public static String checkAvailableDealDesk(String oppId){
        String returnStr;
        List<Opportunity> listofOpp = [SELECT Id, Name, (SELECT Id, Name FROM Deal_Desk__r WHERE Status__c != 'Cancelled') FROM Opportunity WHERE Id =: oppId];
        if(listofOpp != null && listofOpp.size() > 0){
            for(Opportunity iterOpp : listofOpp){
                if(iterOpp.Deal_Desk__r != null && iterOpp.Deal_Desk__r.size() > 0){
                    returnStr = 'ERROR';
                } else{
                    returnStr = 'SUCCESS';
                }
            }
        }
        return returnStr;
    }

    @auraEnabled
    public static String currentDDStatus(String dealdeskId){
        Deal_Desk__c ddObj = [SELECT Id, Name, Status__c FROM Deal_Desk__c WHERE Id =: dealdeskId];
        if(ddObj != null)
            return ddObj.Status__c;
        else
            return '';
    }

    @auraEnabled
    public static String currentUserProfile(){
        try{
            User userInfos = [select id, name, profileName__c from user where id =: userInfo.getUserId()];
            List<PermissionSetAssignment> psetAssign = [SELECT AssigneeId,PermissionSet.Name FROM PermissionSetAssignment where AssigneeId =: userInfo.getUserId() and PermissionSet.Name = 'Deal_desk_for_Approvers'];
            if((psetAssign != null && psetAssign.size() == 1)){
                return 'Approvers access';
            }else{
                return '';
            }
          }catch(Exception e){
            throw new AuraHandledException(e.getMessage()); 
          }
    }
}