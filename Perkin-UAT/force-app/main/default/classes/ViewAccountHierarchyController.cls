public class ViewAccountHierarchyController {
    
    
    public Map<Account,integer> mapAccountLevel {get;set;}
    public Map<id,List<Account>> parentChildLinkedListMap;
    public Account parent{get;set;}
    public List<Account> sortedAccountList {get;set;}
    public List<String> listOfFields {get;set;}
    public String parentName {get;set;}
    public String fieldList;
    public Map<String,String> fieldLabelMap{get;set;}
    public ViewAccountHierarchyController(ApexPages.StandardController sc){
        try{
                               
         fieldList = Custom_Account_View_Hierarchy__c.getOrgDefaults().Field_List__c;
        
        listOfFields = new List<String>();
        
        listOfFields = fieldList.split(',');
        
        fieldLabelMap = new Map<String,String>();
        
        for(String s:listOfFields){
            if(!s.contains('.'))
                fieldLabelMap.put(s,getLabel('Account',s));
            else{
                String f = s;
                if(s.contains('__r')){
                    s=s.replace('__r','');
                    
                }
                else if(s.contains('__c')){
                    s=s.replace('__c','');
                }
                fieldLabelMap.put(f,s);
            }
        }
        
        system.debug('FIELD LABELS '+fieldLabelMap);
        
        mapAccountLevel = new Map<Account,integer>();
        
        
        id pid = sc.getRecord().id;
        String query = 'Select '+fieldList+',ParentId from Account where id =: pid';
        parent = Database.query(query);
        
       // system.debug('PARENT IS '+parent.Name);
        
        parentName = parent.Name;
        
        id currentParentid=parent.ParentId;
        
        system.debug('**'+currentParentid);
        
        Account temp = new Account();
        
        while(currentParentid!=null){
            
            String queryOne = 'Select '+fieldList+',ParentId from Account where id =: currentParentid';
            temp = Database.query(queryOne);
            currentParentid = temp.ParentId;
            system.debug('**'+currentParentid);
        }
    
        
        if(parent.ParentId!=null)
            parent = temp;
            
        //system.debug('PARENT IS '+parent.Name);
        
        //find children of top parent of the account 
        mapAccountLevel.put(parent,0);
        findChildren(parent.id);
        
        sortedAccountList = new List<Account>();
        sortedAccountList.add(parent);
        if(parentChildLinkedListMap.get(parent.id)!=null)
            recursiveSortAccountHierarchy(parent.id);
        
        system.debug('SORTED '+sortedAccountList);
        
        for(Account a : sortedAccountList){
            String space = '';
            for(integer i=0;i<mapAccountLevel.get(a);i++){
                space += '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
            }
            a.Name = space + '<u>'+a.Name+'</u>';
        }
        
        }catch(Exception e){
            
        }
        
        
    }
    
    public void findChildren(id parentid)
    {
         parentChildLinkedListMap = new Map<id,List<Account>>();
        try{
    Boolean endTraversing = false;
    Integer accountLevel = 0;                                                                                                      
    String query;
    List<Account> acctList = new List<Account>(); 
    List<id> parentIdList = new List<id>();
    
    while(!endTraversing) {
        // observe closely at the WHERE clause, that's the key
        if(accountLevel == 0) {
           query = 'select Id, ParentId,'+fieldList+' from Account WHERE ParentId =:parentid';
        } else {
           query = 'select Id, ParentId,'+fieldList+' from Account WHERE ParentId IN :parentIdList';
        }
        acctList = Database.query(query);
        system.debug('acctList '+acctList);
        if(acctlist!=null){
        if(acctList.size() == 0 ) {
           endTraversing = true;
        } else {
           parentIdList.clear();
           acctList.sort();
           Account a;
           for(Integer i = 0; i < acctList.size(); i++ ) {
               a = acctList.get(i);
               parentIdList.add(a.Id);
              
              mapAccountLevel.put(a,accountLevel+1);
              
                  if(parentChildLinkedListMap.get(a.ParentId) == null) {
                       parentChildLinkedListMap.put(a.ParentId, new List<Account>()); 
                   }
                   parentChildLinkedListMap.get(a.ParentId).add(a);
                   parentChildLinkedListMap.get(a.ParentId).sort();
                
           }
           accountLevel++;
        }
        }
    }
    
    for(id i:parentChildLinkedListMap.keySet()){
    system.debug('Parent '+i+' Children'+parentChildLinkedListMap.get(i));
    }
    
        }catch(exception e){
            system.debug('exception '+e.getStackTraceString());
        }
    
}


    public void recursiveSortAccountHierarchy(id i){
     if(parentChildLinkedListMap != Null && parentChildLinkedListMap.containskey(i)){
        for(Account childAcc : parentChildLinkedListMap.get(i)){
            if(parentChildLinkedListMap.containskey(childAcc.id)){
                sortedAccountList.add(childAcc);
                recursiveSortAccountHierarchy(childAcc.id);
            }
            else{
                sortedAccountList.add(childAcc);
            }
        }
        }
    }
    
    public String getLabel(String ObjName,String FieldAPIName){
        system.debug('ObjName'+ObjName+'**'+FieldAPIName);
        String Objtype=ObjName;
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(Objtype);
        if(leadSchema.getDescribe().isCustomSetting())
        {
            return 'Custom Setting';
        }
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        String label = fieldMap.get(FieldAPIName).getDescribe().getLabel();
        
        
        return label;
    } 

}