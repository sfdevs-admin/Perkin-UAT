/**
* Description : Service class to Display Record count for objects
* Created by : (PwC)Deepak Rajan
* Created Date : 22 Jan 2021
*/
public without sharing class GenericRollupCounterController { 
    
    /**
    * wrapper class used to enable final output for dislaying in UI
    */    
    public class Result {
        @AuraEnabled
        public Boolean isError;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public List<ResultantRollup> rollUps;
        
        public result(String m, List<ResultantRollup> o) {
            this.message = m;
            this.rollUps = (o != null) ? o : new list<ResultantRollup>(); 
            this.isError = false;
        }
    }
   
    /**
    * wrapper class used to enable certain pattern for dislaying in UI
    */
    public class ResultantRollup {       
        @AuraEnabled
        public String objectName{get;set;}
        @AuraEnabled
        public String iconName{get;set;}
        @AuraEnabled
        public Decimal count{get;set;}
        
        public ResultantRollup(String objectName, String iconName, Decimal count) {
            this.objectName = objectName;
            this.iconName   = iconName;
            this.count      = (count == null) ? 0 : count;
        }   
    }
    
    /**
    * wrapper class used to enable extensible inputs to the logic
    */
    @testVisible
    public class Inputs {
        public string recId; // passed in for recordId
        public string metadataLabel; // used to pull relevant data from custom metadata
    } 
    
    /*
    * @description: method to get record couters
    * @date: 22/01/2021 
    * @author: (PwC)Deepak 
    * @created 
    */
    @AuraEnabled
    public static String getCounterRecords(String payload) {
        Inputs attr = (inputs)JSON.deserialize(payload, inputs.class); // deserialise into attributes
        List<ResultantRollup> rollupResult = new List<ResultantRollup>();
        Result res = new Result('no results', new list<ResultantRollup>()); // default response
        res.message = '';
        List<Rollup_Counter_Mapping__mdt> fieldMapSource2Target = getMetaDataInfo(attr.metadataLabel);
        
        for(Rollup_Counter_Mapping__mdt recData : fieldMapSource2Target) {              
            String filterCriteria = mergeObjectToString(attr.recId, recData.Filter_Criteria__c);              
            String query = 'SELECT '+recData.Aggregate_Operation__c+' ('+recData.Aggregate_Column__c+')recCount From '+recData.Target_Object_API__c+' WHERE '+filterCriteria; 
            try {                
                AggregateResult groupedResults = Database.query(query);
                Decimal output = recData.Aggregate_Operation__c.equals('Count')? (Integer)groupedResults.get('recCount') : (Decimal)groupedResults.get('recCount');
                rollupResult.add(new ResultantRollup(recData.Display_Label__c,recData.SLDS_icon__c,output));  
            }
            catch (DMLexception e) {
                res.isError = true;
                res.message = 'DML exception:'+e.getMessage();                
            }  catch (QueryException e) {
                res.isError = true;
                res.message = 'Error occured during retrieval of records. Check query string fields.';
            }
        }  
        
        if(String.isBlank(res.message))  res.rollUps = rollupResult;        
        return JSON.serialize(res);
    }

    /*
    * @description: Return Field Mapping Metadata
    * @date: 22/01/2021 
    * @author: (PwC)Deepak 
    * @created 
    */
    public static List<SObject> getMetaDataInfo(String metaDataLabel) {
        List<String> masterLabelList = metaDataLabel.split(';');
        String str = 'SELECT Display_Order__c, Aggregate_Operation__c, Aggregate_Column__c, Display_Label__c, SLDS_icon__c, Filter_Criteria__c, Source_Object_API__c, Target_Object_API__c, Target_Object_Field__c FROM Rollup_Counter_Mapping__mdt WHERE Mapping_For__c IN :masterLabelList order by Display_Order__c';
        return Database.query(str);     
    }    
    
    /*
    * @description: method to process merge fields into a label string
    * @date: 22/01/2021 
    * @author: (PwC)Deepak 
    * @created 
    */
    public static String mergeObjectToString(String parameter, String mergeString) {        
        mergeString = mergeString.toLowerCase();
        String finalMergeText ='';
        while(mergeString.contains('{{')) {
            string fld = mergeString.substringBetween('{{','}}').toLowerCase();           
            String mergeText = (String.valueOf(parameter) > '') ? String.valueOf(parameter) : '';          
            mergeString = mergeString.replace('{{'+fld+'}}', '\''+mergeText + '\''); 
            finalMergeText += mergeString ;
        }
        return finalMergeText;        
    }
}