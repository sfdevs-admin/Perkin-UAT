public class StrengthSale {
    public List<Map<Object,Object>> data {get;set;}
    public StrengthSale() {
        data = new List<Map<Object,Object>>();
        Id oId=ApexPages.currentPage().getParameters().get('Id');
        
        If(oId!=null) {
            Opportunity o = [Select Id,PAIN__c,VALUE__c,POWER__c,COLLABORATE__c,VISION__c,COMPELLING_REASON_TO_ACT_CRTA__c FROM Opportunity Where Id=: oId];
            if(o.VISION__c!=null) {
                Map<Object, Object> m = new Map<Object,Object>();
                m.put('field', 'VISION');
                Integer r = 5 - Integer.valueOf(o.VISION__c);
                m.put('value', r);
                data.add(m);
            }
            if(o.VALUE__c!=null) {
                Map<Object, Object> m = new Map<Object,Object>();
                m.put('field', 'VALUE');
                Integer r = 5 - Integer.valueOf(o.VALUE__c);
                m.put('value',r);
                data.add(m);
            }
            if(o.COLLABORATE__c!=null) {
                Map<Object, Object> m = new Map<Object,Object>();
                m.put('field', 'COLLABORATE');
                Integer r = 5 - Integer.valueOf(o.COLLABORATE__c);
                m.put('value', r);
                data.add(m);
            }
            if(o.COMPELLING_REASON_TO_ACT_CRTA__c!=null){
                Map<Object, Object> m = new Map<Object,Object>();
                m.put('field', 'CRTA');
                Integer r = 5 - Integer.valueOf(o.COMPELLING_REASON_TO_ACT_CRTA__c);
                m.put('value', r);
                data.add(m);
            }
            if(o.PAIN__c!=null){
                Map<Object, Object> m = new Map<Object,Object>();
                m.put('field', 'PAIN');
                Integer r = 5 - Integer.valueOf(o.PAIN__c);
                m.put('value', r);
                data.add(m);
            }
            if(o.POWER__c!=null) {
                Map<Object, Object> m = new Map<Object,Object>();
                m.put('field', 'POWER');
                Integer r = 5 - Integer.valueOf(o.POWER__c);
                m.put('value', r);
                data.add(m);
            }
        }
    }
}