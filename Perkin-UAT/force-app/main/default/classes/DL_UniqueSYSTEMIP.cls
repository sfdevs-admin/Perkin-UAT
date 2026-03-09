public class DL_UniqueSYSTEMIP {

public void uniqueIP(List<Demo_Log__c> DL_List, Map<Id, Demo_Log__c> dl_map)
    {
             
        Set<String> sysIP = new Set<String>();
            for(Demo_Log__c dlList : DL_List)
            {
                if(Trigger.isInsert || (Trigger.isUpdate && dl_map.get(dlList.Id).System_s_IP__c!= dlList.System_s_IP__c))
                {
                    sysIP.add(dlList.System_s_IP__c);
                }             
            }
        if(sysIP.size()>0)
        {
        	List<Demo_Log__c> logList =[SELECT Id, System_s_IP__c FROM Demo_Log__c WHERE System_s_IP__c in : sysIP];        
        	Map<String, Demo_Log__c> map_DL = new Map<String, Demo_Log__c>();
        		for(Demo_Log__c lgList:logList)
        		{
            		map_DL.put(lgList.System_s_IP__c, lgList);
        		}
        
        		for(Demo_Log__c dl : DL_List)
        		{
   					if(map_DL.containsKey(dl.System_s_IP__c))
            		{
                		dl.addError('This System IP is already in use, Please select different System IP');
            		}
        		}
        }
     }        
 }