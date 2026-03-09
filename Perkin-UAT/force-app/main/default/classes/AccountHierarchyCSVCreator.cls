public class AccountHierarchyCSVCreator {
    
    public List<SObject> CSVData{get;set;}
    
    public List<String> fieldSet{get;set;}
    public String textdata{get;set;}
    public String PDFData{get;set;}
    public String fileName{get;set;}
    public String header{get;set;}
    public List<String> headerList{get;set;}
    public Static Set<Id> accountHierarchyList = new Set<id>();
    public Static Map<id,account> accountDetailsMap = new Map<id,account>();
    public Static Map<id,List<Account>> parentChildLinkedListMap =  new Map<id,List<Account>>();
   public AccountHierarchyCSVCreator()
   {
	   	
	   	
	   	String accName = ApexPages.currentPage().getParameters().get('accName');
	   	String accId = ApexPages.currentPage().getParameters().get('accId');
	   	String baseObject = ApexPages.currentPage().getParameters().get('basObj');
	   	String sortColumn = ApexPages.currentPage().getParameters().get('sortColumn');
	   	String sortOrder = ApexPages.currentPage().getParameters().get('sortOrder');
	   	
	   	
	   	Account__c tabSetting =  [SELECT Tab_Name__c,Field_List__c,Object_API_Name__c 
	                                  FROM Account__c where Tab_Name__c=:baseObject limit 1
	                                  ];
	                                  
		fileName = accName+' - '+tabSetting.Object_API_Name__c+' Hierarchy -'+String.ValueOf(date.today());
        
        system.debug('id print'+accId);
        //accId = ApexPages.currentPage().getParameters().get('id');
        
        Account acc = [select id from Account where id =:accId];
        accountDetailsMap.put(acc.id,acc);
        
        accountHierarchyList.add(acc.id);
        //finding the hierarchy of accounts
        system.debug('accountHierarchyList'+accountHierarchyList);
        findChildren(acc.id);
        header='';
        String accFieldName='AccountId';
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
                      
        
	    String query = 'Select '+tabSetting.Field_List__c+' from '+ tabSetting.Object_API_Name__c+ ' where '+accFieldName+' IN: accountHierarchyList order by '+sortColumn+' '+sortOrder;
	    system.debug('query is**'+query);
	    system.debug('sort order '+sortOrder);
	    Map<String,String> apitoLabel = new Map<String,String>();
        for(String field : tabSetting.Field_List__c.split(','))
        {
        	if(field.contains('.'))
        	{
        		string fieldName = field;
        		if(fieldName.contains('__r')){
        			fieldName.replace('__r','');
        			
        		}
        		else if(fieldName.contains('__c')){
        			fieldName.replace('__c','');
        		}
        		apitoLabel.put(field,fieldName);
        	}
        	else
        	{
        		apitoLabel.put(field,getLabel(tabSetting.Object_API_Name__c,field));
        	}
        }
        system.debug('apitoLabel');
	//    header=tabSetting.Field_List__c.trim();
		for(String t: apitoLabel.values())
		{
			header +=t+','; 
		}
	    fieldSet = tabSetting.Field_List__c.split(',');
	    headerList = header.split(',');
	    CSVData = Database.query(query);
	    
	    textdata = header+'\n';
	   for(SObject iterable: CSVData)
	    {
	    	for(String field : fieldSet)
	    	{
	    		if(field.contains('.'))
				{
					String value = '';
					List<String> attNames=field.split('\\.');
					system.debug('attNames'+attNames);
					Sobject newObj = iterable.getSobject(attNames[0]);
					system.debug('newObj'+newObj);
					if(newObj != null)
						value = (String) newObj.get(attNames[1]);
					
					if(value != null && value != '')
                    {
                        textData += value + ',';   
                    }
                    else
                    {
                        textData += '' + ',';
                    }
				}
				else
				{	
					 	if(iterable.get(field) != null)
							textData += iterable.get(field) + ',';
						else
							textData += '' + ',';
				}
	    	}
	    	textdata+='\n';
	    }
	    
	    
	   
   }
   public static void findChildren(id parentid)
   {
        try
		{
			Boolean endTraversing = false;
			Integer accountLevel = 0;                                                                                                      
			String query;
			List<Account> acctList = new List<Account>(); 
			List<id> parentIdList = new List<id>();
			while(!endTraversing) 
			{
				// observe closely at the WHERE clause, that's the key
				if(accountLevel == 0) 
				{
					query = 'select Id, Name, ParentId from Account WHERE ParentId =:parentid';
				} 
				else 
				{
					query = 'select Id, Name, ParentId from Account WHERE ParentId IN :parentIdList';
				}
				acctList = Database.query(query);
				system.debug('acctList '+acctList);
				if(acctlist!=null)
				{
					if(acctList.size() == 0 ) 
					{
						endTraversing = true;
					} 
					else 
					{
						parentIdList.clear();
						acctList.sort();
						Account a;
						for(Integer i = 0; i < acctList.size(); i++ ) 
						{
							a = acctList.get(i);
							parentIdList.add(a.Id);
							accountDetailsMap.put(a.Id, a);
							if(parentChildLinkedListMap.get(a.ParentId) == null) 
							{
								parentChildLinkedListMap.put(a.ParentId, new List<Account>()); 
							}
							parentChildLinkedListMap.get(a.ParentId).add(a);
							parentChildLinkedListMap.get(a.ParentId).sort();
                        }
						accountLevel++;
					}
				}
			}
			for(List<Account> accList : parentChildLinkedListMap.values())
			{
		        for(Account act : accList)
		        {
		            if(!accountHierarchyList.contains(act.id)){
		                accountHierarchyList.add(act.id);
		                
		            }
		        }
		    }
		}
		catch(Exception e)
		{
			system.debug('Exception'+e.getMessage());
		}
   	}
    public static String getLabel(String ObjName,String FieldAPIName)
    {
        
        String Objtype=ObjName;
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(Objtype);
        
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        String label = fieldMap.get(FieldAPIName).getDescribe().getLabel();
        return label;
    } 
   
    
}