public class AccountNewButtonController {
@AuraEnabled 
    public static wrapper fetchUserInfo(){
        wrapper wrp = new wrapper();
       User u = [select id,Name,PKISuperTerritory__c,PKISubTerritory__c,PKICountry__c,PKITerritory__c, GeographyValue__c from User where id =: userInfo.getUserId()];
         wrp.usr=u;
        List<Schema.RecordTypeInfo> recordtypes = Account.SObjectType.getDescribe().getRecordTypeInfos();    
        list<innerwrap> recordtypelist = new  List<innerwrap>();
        for(RecordTypeInfo rt : recordtypes){
            if(rt.getName() != 'Master'){
                innerwrap inw = new innerwrap();
                inw.recordtypeNamestr=rt.getName();
                inw.recordtypeIdstr=rt.getRecordTypeId();
                inw.isrecordtypedefault =rt.isDefaultRecordTypeMapping();
                recordtypelist.add(inw);
            }
            
        }  
        wrp.recordtypelist=recordtypelist;
        return wrp;
    }
    
    public class wrapper{
        @AuraEnabled
        public user usr{get;set;}
        @AuraEnabled
        public List<innerwrap> recordtypelist{get;set;}
    }
    Public class innerwrap{
        @AuraEnabled
        public string recordtypeIdstr{get;set;}
        @AuraEnabled
        public string recordtypeNamestr{get;set;}
        @AuraEnabled
        public boolean isrecordtypedefault{get;set;}
    }
}