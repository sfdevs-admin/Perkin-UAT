public class SVMX_FCORMA_NEW {
    String uid=System.currentPageReference().getParameters().get('uid');
    public List<FCO_Lines__c> FCOLlist = new List<FCO_Lines__c>();
    public SVMX_FCORMA_NEW(){
        try{
        FCOLlist=[select id,Name,RMA__c,Installed_Product_1__c,Installed_Product_1__r.SVMXC__Product__c, Account__c,Contact__c,Location__c,RMA_Created__c, FCO_Lines__c.FCO__r.Return_Location__c,FCO_Lines__c.FCO__r.Order_Type__c,FCO_Lines__c.FCO__r.Priority__c,
        FCO_Lines__c.FCO__r.Description__c,FCO_Lines__c.FCO__r.Description_of_FCO_for_Customer__c,Country__c,FCO_Lines__c.FCO__r.Return_Country__c
                 from FCO_Lines__c where FCO__c=:uid and RMA_Created__c = false and Status__c='Active' and (FCO_Lines__c.FCO__r.Order_Type__c='Exchange' OR FCO_Lines__c.FCO__r.Order_Type__c='Advanced Exchange')];
        }catch(Exception E){ System.debug(E.getMessage());}
    }
    
    public PageReference CreateRMA(){
        List<SVMXC__RMA_Shipment_Order__c> RMAList = new List<SVMXC__RMA_Shipment_Order__c>();
        List<FCO_Lines__c> UpdFCOLlist = new List<FCO_Lines__c>();
        if(FCOLlist.size()>0){
            RecordType rt = [select id from RecordType where SobjectType='SVMXC__RMA_Shipment_Order__c' limit 1];
            for(FCO_Lines__c FCOL:FCOLlist){
                SVMXC__RMA_Shipment_Order__c RMA = new SVMXC__RMA_Shipment_Order__c();
                RMA.RecordtypeId=rt.id;
                RMA.FCO_Lines__c=FCOL.id;
                RMA.SVMXC__Company__c=FCOL.Account__c;
                RMA.SVMXC__Contact__c=FCOL.Contact__c;
                RMA.Product__c = FCOL.Installed_Product_1__r.SVMXC__Product__c;
                RMA.SVMXC__Source_Location__c=FCOL.Location__c;
                RMA.SVMXC__Source_Country__c=FCOL.Country__c;
                RMA.SVMXC__Destination_Location__c=FCOL.FCO__r.Return_Location__c;
                RMA.SVMXC__Destination_Country__c=FCOL.FCO__r.Return_Country__c;
                RMA.SVMXC__Order_Type__c=FCOL.FCO__r.Order_Type__c;
                RMA.SVMXC__Priority__c=FCOL.FCO__r.Priority__c;
                RMA.Description__c=FCOL.FCO__r.Description__c;
                RMA.Description_for_Customer__c=FCOL.FCO__r.Description_of_FCO_for_Customer__c;
                //RMA.Installed_Product_Swap__c=FCOL.Installed_Product_1__c;
                RMAList.add(RMA);
            }
            if(RMAList.size()>0)
                insert RMAList;  
                
            for(SVMXC__RMA_Shipment_Order__c RMA:RMAList){
                FCO_Lines__c FCOL= new FCO_Lines__c(id=RMA.FCO_Lines__c);
                //for(FCO_Lines__c FCOL:FCOLlist){
                    if(FCOL.id==RMA.FCO_Lines__c){
                            FCOL.RMA__c=RMA.id;
                            FCOL.RMA_Created__c=true;
                        UpdFCOLlist.add(FCOL);
                   }
               // }
            }
            if(UpdFCOLlist.size()>0)
                update UpdFCOLlist;     
        }
        pagereference pgref= new pagereference('/'+uid);
        pgref.setRedirect(true);
        return pgref;       
        }
    }