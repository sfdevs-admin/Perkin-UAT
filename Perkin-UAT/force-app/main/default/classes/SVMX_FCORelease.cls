public class SVMX_FCORelease {
/*
    String uid=System.currentPageReference().getParameters().get('uid');
    List<FCO_Lines__c> FCOLlist = new List<FCO_Lines__c>();
    public SVMX_FCORelease(){
        try{
        FCOLlist=[select id,Work_Order__c,Installed_Product_1__c,Account__c,Contact__c,Location__c,FCO_Lines__c.FCO__r.Order_Type__c,Name,Country__c,
        FCO_Lines__c.FCO__r.Priority__c,FCO_Lines__c.FCO__r.Name,FCO_Lines__c.FCO__r.Description__c,FCO_Lines__c.FCO__r.Description_of_FCO_for_Customer__c,FCO_Lines__c.FCO__r.Product__c
                 from FCO_Lines__c where FCO__c=:uid and Work_Order_Created__c = false and Status__c='Active'];
        }catch(Exception E){ System.debug(E.getMessage());}
    } 
    public PageReference CreateWO(){
        List<SVMXC__Service_Order__c> WOList = new List<SVMXC__Service_Order__c>();
        List<FCO_Lines__c> UpdFCOLlist = new List<FCO_Lines__c>();
        if(FCOLlist.size()>0){
            RecordType rt = [select id from RecordType where SobjectType='SVMXC__Service_Order__c' limit 1];
            for(FCO_Lines__c FCOL:FCOLlist){
                SVMXC__Service_Order__c WO = new SVMXC__Service_Order__c();
                WO.RecordtypeId=rt.id;
                WO.SVMXC__Billing_Type__c='Good Will';
                WO.SVMXC__Company__c=FCOL.Account__c;
                WO.SVMXC__Contact__c=FCOL.Contact__c;
                WO.SVMXC__Order_Type__c=FCOL.FCO__r.Order_Type__c;
                //WO.Location__c=FCOL.Location__c;
                WO.SVMXC__Site__c=FCOL.Location__c;
                //WO.Country_text__c=FCOL.Country__c;
                //WO.SVMXC__Order_Type__c='Recall Activity';
                WO.SVMXC__Priority__c=FCOL.FCO__r.Priority__c;
                WO.SVMXC__Purpose_of_Visit__c='Recall';
                WO.Subject__c=FCOL.Name;
                WO.FCO_Lines__c=FCOL.id;
                WO.SVMXC__Component__c=FCOL.Installed_Product_1__c;
                WO.Subject__c=FCOL.FCO__r.Name;
                WO.SVMXC__Problem_Description__c=FCOL.FCO__r.Description__c;
                WO.SVMXC__Customer_Failure_Feedback__c=FCOL.FCO__r.Description_of_FCO_for_Customer__c;
                WO.SVMXC__Product__c=FCOL.FCO__r.Product__c;
                WOList.add(WO);
            }
            if(WOList.size()>0){ insert WOList;  }
                
            for(SVMXC__Service_Order__c wo:WOList){
                FCO_Lines__c FCOL= new FCO_Lines__c(id=wo.FCO_Lines__c);
                //for(FCO_Lines__c FCOL:FCOLlist){
                    //if(FCOL.id==wo.FCO_Lines__c){
                        FCOL.Work_Order__c=wo.id;
                        FCOL.Work_Order_Created__c=true;
                        UpdFCOLlist.add(FCOL);
                   // }
               // }
            }
            if(UpdFCOLlist.size()>0) {update UpdFCOLlist;   }  
        }
        pagereference pgref= new pagereference('/'+uid);
        pgref.setRedirect(true);
        return pgref;       
    }  

*/

}