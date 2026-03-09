global class AccountHierarchyController {
    
    global static Set<id> accountHierarchyList;
    global static Map<id,List<Account>> parentChildLinkedListMap;
    public Account act;
    public String sortOrder{get;set;}
    public String sortColumn{get;set;}
    public String sortBaseObject{get;set;}
    transient global static Object deserializedList;
    transient global static List<sObject> dataList;
    public String accname;
    public AccountHierarchyController(ApexPages.StandardController std){
    	
    }
    
    public pagereference exportToCSV(){
        
        Account__c tabSetting =  [SELECT Tab_Name__c,Field_List__c,Object_API_Name__c 
                                  FROM Account__c where Tab_Name__c=:sortBaseObject limit 1
                                  ];
        String accId = ApexPages.currentPage().getParameters().get('id');
        act = [Select id,Name from Account where id=:accId];
        
        String sortcol = tabSetting.Field_List__c.split(',')[Integer.ValueOf(sortColumn)];
        
        
        PageReference CSVPage = new PageReference('/apex/AccountHierarchyCSVPage');
        CSVPage.getParameters().put('sortOrder',sortOrder);
        CSVPage.getParameters().put('basObj',sortBaseObject);
        CSVPage.getParameters().put('sortColumn',sortcol);
        CSVPage.getParameters().put('accId',ApexPages.currentPage().getParameters().get('id'));
        CSVPage.getParameters().put('accName',act.Name);
        system.debug('CSVPage'+CSVPage);
        return CSVPage;
        
        
        
    }
    
    public static void findChildren(id parentid)
    {
        try{
    Boolean endTraversing = false;
    Integer accountLevel = 0;                                                                                                      
    String query;
    List<Account> acctList = new List<Account>(); 
    List<id> parentIdList = new List<id>();
    
    while(!endTraversing) {
        // observe closely at the WHERE clause, that's the key
        if(accountLevel == 0) {
           query = 'select Id, Name, ParentId from Account WHERE ParentId =:parentid';
        } else {
           query = 'select Id, Name, ParentId from Account WHERE ParentId IN :parentIdList';
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
    
    for(List<Account> accList : parentChildLinkedListMap.values()){
        for(Account act : accList){
            if(!accountHierarchyList.contains(act.id)){
                accountHierarchyList.add(act.id);
                
            }
        }
        
        parentChildLinkedListMap =  new Map<id,List<Account>>();
    } 
        }catch(exception e){
            system.debug('exception '+e.getStackTraceString());
        }
    
}

@RemoteAction
global static Object getDataList(String baseObject,string accId){
    
    accountHierarchyList = new Set<id>();
        parentChildLinkedListMap =  new Map<id,List<Account>>();
        
        system.debug('id print'+accId);
        //
        
        Account acc = [select id from Account where id =:accId];
        
        
        accountHierarchyList.add(acc.id);
        //finding the hierarchy of accounts
        findChildren(acc.id);
        
    dataList = new List<sObject>();
     String accFieldName;                     
      
    Account__c tabSetting = new Account__c(); 
        tabSetting =  [SELECT Tab_Name__c,Field_List__c,Object_API_Name__c 
                                  FROM Account__c where Tab_Name__c=:baseObject limit 1
                                  ];
        
      
    	accFieldName='AccountId';
       
          
        Schema.DescribeSObjectResult R = Account.SObjectType.getDescribe();
		List<Schema.ChildRelationship> C = R.getChildRelationships(); 
		for(Schema.ChildRelationship temp : C)
		{
			Schema.SObjectType s = temp.getChildSObject();
			
			if(s.getDescribe().getLocalName()== tabSetting.Object_API_Name__c){
			    Schema.SObjectField parentField = temp.getField();
			    Schema.DescribeFieldResult desparentField = parentField.getDescribe();
			    accFieldName = desparentField.getLocalName();
			    system.debug('**'+temp.getChildSObject()+'***field'+desparentField.getLocalName());
			    break;
			}
		    //system.debug('**'+temp.getChildSObject()+'***'+desparentField.getLocalName());
		}
		
		 if(tabSetting.Object_API_Name__c == 'Account'){
       	accFieldName='Id';
       }   
       
       String query = 'Select '+tabSetting.Field_List__c+' from '+ tabSetting.Object_API_Name__c+ ' where '+accFieldName+' IN: accountHierarchyList';
       system.debug('QUERY '+query);
       
        //dataList = Database.query('Select AccountId, Account.AccountNumber, Account.Name, FirstName, LastName, Phone, Email from Contact where AccountId =\'001n0000008hPvH\'');
        dataList = Database.query(query);
        accountHierarchyList = new Set<id>();
        String type=tabSetting.Object_API_Name__c;
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(type);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        
        for (String fieldName: fieldMap.keySet()) {
        System.debug('##Field API Name='+fieldName);// list of all field API name
         
        fieldMap.get(fieldName).getDescribe().getLabel();//It provides to get the object fields label.
        }
        Map<String,String> apitoLabel = new Map<String,String>();
        for(String field : tabSetting.Field_List__c.split(','))
        {
        	if(field.contains('.'))
        	{
        		string fieldName = field;
        		if(fieldName.contains('__r')){
        			fieldName=fieldName.replace('__r','');
        			
        		}
        		else if(fieldName.contains('__c')){
        			fieldName=fieldName.replace('__c','');
        		}
        		system.debug('field '+field+'****'+fieldName);
        		apitoLabel.put(field,fieldName);
        	}
        	else
        	{
        		apitoLabel.put(field,getLabel(tabSetting.Object_API_Name__c,field));
        	}
        }
        //return JSON.serialize(dataList);
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartArray();
        for(Sobject temp : dataList)
        {	
            generator.writeStartObject();
            for(String field : tabSetting.Field_List__c.split(','))
            {
                if(field.contains('.'))
                {
                    String value = '';
                    List<String> valueWithLink = new List<String>();
                    List<String> attNames=field.split('\\.');
                    system.debug('attNames'+attNames);
                    Sobject newObj = temp.getSobject(attNames[0]);
                    system.debug('newObj'+newObj);
                    if(newObj != null){
                        value = (String) newObj.get(attNames[1]);
                    	valueWithLink.add(value);
                    	system.debug('OBJECT IS'+newObj);
                    	valueWithLink.add('/'+newObj.id);
                    }
                    if(value != null && value != '' && newObj.id!=null)
                    {
                        generator.writeObjectField(apitoLabel.get(field),valueWithLink);    
                    }
                    else
                    {
                        generator.writeObjectField(apitoLabel.get(field),'');
                    }
                }
                else
                {
                    if(temp.get(field) != null)
                    {
                    	List<String> valueWithLink = new List<String>();
                    	valueWithLink.add(String.valueOf(temp.get(field)));
                    	valueWithLink.add('/'+temp.id);
                        generator.writeObjectField(apitoLabel.get(field),valueWithLink);
                    }
                    else
                    {
                        generator.writeObjectField(apitoLabel.get(field),'');
                    }
                }
            }
            generator.writeEndObject();
            
        }
         generator.writeEndArray();
         String jsonString = generator.getAsString();
         system.debug('jsonString'+jsonString);
         deserializedList = JSON.deserializeUntyped(jsonString);
         system.debug('deserializedList');
         
         dataList = new List<sObject>();
         
        return deserializedList;
    }
    public static String getLabel(String ObjName,String FieldAPIName){
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
        /*for (String fieldName: fieldMap.keySet()) {
        System.debug('##Field API Name='+fieldName);// list of all field API name
         
        fieldMap.get(fieldName).getDescribe().getLabel();//It provides to get the object fields label.
        }*/
    } 

    
}