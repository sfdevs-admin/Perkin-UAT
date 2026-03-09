/**************************************************************
* 1. Jira Ticket(s) that relates to this class
     
*
* 2. Description - This class helps in moving M.Action from Source Org to Target Org.
*
*
*
* 3. Objects referenced
*    -Mass Action Configuration
*
* 4. Callouts to additional Components (including their methods) or None:
*    - None
*
* 5. Dependant Class(es):
     - None
*
* 6. Test Class Name: UTIL_Import_Export_Data_Test
*
* 7. Is @Invocable (Yes or No): Yes
*
* 8. Author Name(s):
*    - SS 22-02-2023
*************************************************************/
public class UTIL_Import_Export_Data {
    public class objInfo{
        
        @InvocableVariable(required=true) public String ObjAPIName;
        @InvocableVariable(required=false) public String JsonString;
        @InvocableVariable(required=false) public ID CurrentrecordId;
        @InvocableVariable(required=true) public String IMPORT_or_EXPORT_action;//Should store IMPORT or EXPORT
        
    }
    
    @InvocableMethod(label='IMPORT EXPORT Current MassActions Record As JSON')
    public static List<String> Import_Export_MassActionsData(List<objInfo> objinfolst) {
        String objApiName;
        String JsonString;
        List<String> strngjsonlst=new List<String>();
        ID CurrentrecordId;
        String action;
        IF(objinfolst.size()==1){
            objApiName=objinfolst[0].ObjAPIName;
            JsonString=objinfolst[0].JsonString;
            CurrentrecordId=objinfolst[0].CurrentrecordId;
            action=objinfolst[0].IMPORT_or_EXPORT_action;
        }  
        IF(action=='EXPORT'){
            dca_mass_action__Mass_Action_Configuration__c ma=[Select dca_mass_action__Active__c,dca_mass_action__Batch_Size__c,dca_mass_action__Description__c,dca_mass_action__Last_Run_Completed_Date__c,dca_mass_action__Last_Run_Completed_With_Errors__c,Name,dca_mass_action__DeveloperName__c,
                                                              dca_mass_action__Named_Credential__c,dca_mass_action__Schedule_Cron__c,dca_mass_action__Schedule_DayOfMonth__c,dca_mass_action__Schedule_Frequency__c,dca_mass_action__Source_Apex_Class__c,dca_mass_action__Source_List_View_ID__c,
                                                              dca_mass_action__Schedule_HourOfDay__c,dca_mass_action__Schedule_MinuteOfHour__c,dca_mass_action__Schedule_MonthOfYear__c,dca_mass_action__Schedule_SecondOfMinute__c,dca_mass_action__Schedule_DayOfWeek__c,dca_mass_action__Source_Report_Column_Name__c,dca_mass_action__Source_Report_ID__c,
                                                              dca_mass_action__Source_SOQL_Query__c,dca_mass_action__Source_Type__c,dca_mass_action__Target_Action_Name__c,dca_mass_action__Target_Apex_Script__c,dca_mass_action__Target_SObject_Type__c,dca_mass_action__Target_Type__c
                                                              from dca_mass_action__Mass_Action_Configuration__c where Id=:CurrentrecordId]; 
            JsonString=JSON.serialize(ma);
            strngjsonlst.add(JsonString);   
        }
        IF(action=='IMPORT'){
            List<dca_mass_action__Mass_Action_Configuration__c> currentma=new List<dca_mass_action__Mass_Action_Configuration__c>();
            dca_mass_action__Mass_Action_Configuration__c ma=(dca_mass_action__Mass_Action_Configuration__c)JSON.deserialize(JsonString, dca_mass_action__Mass_Action_Configuration__c.Class);
            system.debug('@@'+ma);
            system.debug('@@ma.dca_mass_action__DeveloperName__c'+ma.dca_mass_action__DeveloperName__c);
            
            If(ma.dca_mass_action__DeveloperName__c!=null){
                system.debug('@@ma.dca_mass_action__DeveloperName__c'+ma.dca_mass_action__DeveloperName__c);
                currentma=[Select id,dca_mass_action__Active__c,dca_mass_action__Batch_Size__c,dca_mass_action__Description__c,dca_mass_action__Last_Run_Completed_Date__c,dca_mass_action__Last_Run_Completed_With_Errors__c,Name,dca_mass_action__DeveloperName__c,
                           dca_mass_action__Named_Credential__c,dca_mass_action__Schedule_Cron__c,dca_mass_action__Schedule_DayOfMonth__c,dca_mass_action__Schedule_Frequency__c,dca_mass_action__Source_Apex_Class__c,dca_mass_action__Source_List_View_ID__c,
                           dca_mass_action__Schedule_HourOfDay__c,dca_mass_action__Schedule_MinuteOfHour__c,dca_mass_action__Schedule_MonthOfYear__c,dca_mass_action__Schedule_SecondOfMinute__c,dca_mass_action__Schedule_DayOfWeek__c,dca_mass_action__Source_Report_Column_Name__c,dca_mass_action__Source_Report_ID__c,
                           dca_mass_action__Source_SOQL_Query__c,dca_mass_action__Source_Type__c,dca_mass_action__Target_Action_Name__c,dca_mass_action__Target_Apex_Script__c,dca_mass_action__Target_SObject_Type__c,dca_mass_action__Target_Type__c
                           from dca_mass_action__Mass_Action_Configuration__c where dca_mass_action__DeveloperName__c=:ma.dca_mass_action__DeveloperName__c];
            }
            system.debug('@@currentma'+currentma);
            //Developername exists and should be updated
            if(currentma.size() > 0){
                currentma[0].Name=ma.Name;
                system.debug('@@47ma.name'+ma.Name);
                system.debug('@@currentma[0].Name'+currentma[0].Name);
                currentma[0].dca_mass_action__Active__c=ma.dca_mass_action__Active__c;
                currentma[0].dca_mass_action__Batch_Size__c=ma.dca_mass_action__Batch_Size__c;
                currentma[0].dca_mass_action__Description__c=ma.dca_mass_action__Description__c;
                currentma[0].dca_mass_action__Last_Run_Completed_Date__c=ma.dca_mass_action__Last_Run_Completed_Date__c;
                currentma[0].dca_mass_action__Last_Run_Completed_With_Errors__c=ma.dca_mass_action__Last_Run_Completed_With_Errors__c;
                currentma[0].dca_mass_action__Named_Credential__c=ma.dca_mass_action__Named_Credential__c;
                currentma[0].dca_mass_action__Schedule_Cron__c=ma.dca_mass_action__Schedule_Cron__c;
                currentma[0].dca_mass_action__Schedule_DayOfMonth__c=ma.dca_mass_action__Schedule_DayOfMonth__c;
                currentma[0].dca_mass_action__Schedule_Frequency__c=ma.dca_mass_action__Schedule_Frequency__c;
                currentma[0].dca_mass_action__Schedule_HourOfDay__c=ma.dca_mass_action__Schedule_HourOfDay__c;
                currentma[0].dca_mass_action__Schedule_MinuteOfHour__c=ma.dca_mass_action__Schedule_MinuteOfHour__c;
                currentma[0].dca_mass_action__Schedule_MonthOfYear__c=ma.dca_mass_action__Schedule_MonthOfYear__c;
                currentma[0].dca_mass_action__Schedule_SecondOfMinute__c=ma.dca_mass_action__Schedule_SecondOfMinute__c;
                currentma[0].dca_mass_action__Schedule_DayOfWeek__c=ma.dca_mass_action__Schedule_DayOfWeek__c;
                currentma[0].dca_mass_action__Source_Apex_Class__c=ma.dca_mass_action__Source_Apex_Class__c;
                currentma[0].dca_mass_action__Source_List_View_ID__c=ma.dca_mass_action__Source_List_View_ID__c;
                currentma[0].dca_mass_action__Source_Report_Column_Name__c=ma.dca_mass_action__Source_Report_Column_Name__c;
                currentma[0].dca_mass_action__Source_Report_ID__c=ma.dca_mass_action__Source_Report_ID__c;
                currentma[0].dca_mass_action__Source_SOQL_Query__c=ma.dca_mass_action__Source_SOQL_Query__c;
                currentma[0].dca_mass_action__Source_Type__c=ma.dca_mass_action__Source_Type__c;
                currentma[0].dca_mass_action__Target_Action_Name__c=ma.dca_mass_action__Target_Action_Name__c;
                currentma[0].dca_mass_action__Target_Apex_Script__c=ma.dca_mass_action__Target_Apex_Script__c;
                currentma[0].dca_mass_action__Target_SObject_Type__c=ma.dca_mass_action__Target_SObject_Type__c;
                currentma[0].dca_mass_action__Target_Type__c=ma.dca_mass_action__Target_Type__c;
                
                update currentma;
                JsonString='Updated';
                strngjsonlst.add(JsonString);
                system.debug('@@Update');
            }
            else{
                dca_mass_action__Mass_Action_Configuration__c currentmainst=new dca_mass_action__Mass_Action_Configuration__c();
                system.debug('@@'+ma);
                system.debug('@@47ma.name'+ma.Name);
                currentmainst.Name=ma.Name;
                system.debug('@@47ma.name'+ma.Name);
                system.debug('@@currentmainst.Name'+currentmainst.Name);
                currentmainst.dca_mass_action__Active__c=ma.dca_mass_action__Active__c;
                currentmainst.dca_mass_action__Batch_Size__c=ma.dca_mass_action__Batch_Size__c;
                currentmainst.dca_mass_action__Description__c=ma.dca_mass_action__Description__c;
                currentmainst.dca_mass_action__Last_Run_Completed_Date__c=ma.dca_mass_action__Last_Run_Completed_Date__c;
                currentmainst.dca_mass_action__Last_Run_Completed_With_Errors__c=ma.dca_mass_action__Last_Run_Completed_With_Errors__c;
                currentmainst.dca_mass_action__Named_Credential__c=ma.dca_mass_action__Named_Credential__c;
                currentmainst.dca_mass_action__Schedule_Cron__c=ma.dca_mass_action__Schedule_Cron__c;
                currentmainst.dca_mass_action__Schedule_DayOfMonth__c=ma.dca_mass_action__Schedule_DayOfMonth__c;
                currentmainst.dca_mass_action__Schedule_Frequency__c=ma.dca_mass_action__Schedule_Frequency__c;
                currentmainst.dca_mass_action__Schedule_HourOfDay__c=ma.dca_mass_action__Schedule_HourOfDay__c;
                currentmainst.dca_mass_action__Schedule_MinuteOfHour__c=ma.dca_mass_action__Schedule_MinuteOfHour__c;
                currentmainst.dca_mass_action__Schedule_MonthOfYear__c=ma.dca_mass_action__Schedule_MonthOfYear__c;
                currentmainst.dca_mass_action__Schedule_SecondOfMinute__c=ma.dca_mass_action__Schedule_SecondOfMinute__c;
                currentmainst.dca_mass_action__Schedule_DayOfWeek__c=ma.dca_mass_action__Schedule_DayOfWeek__c;
                currentmainst.dca_mass_action__Source_Apex_Class__c=ma.dca_mass_action__Source_Apex_Class__c;
                currentmainst.dca_mass_action__Source_List_View_ID__c=ma.dca_mass_action__Source_List_View_ID__c;
                currentmainst.dca_mass_action__Source_Report_Column_Name__c=ma.dca_mass_action__Source_Report_Column_Name__c;
                currentmainst.dca_mass_action__Source_Report_ID__c=ma.dca_mass_action__Source_Report_ID__c;
                currentmainst.dca_mass_action__Source_SOQL_Query__c=ma.dca_mass_action__Source_SOQL_Query__c;
                currentmainst.dca_mass_action__Source_Type__c=ma.dca_mass_action__Source_Type__c;
                currentmainst.dca_mass_action__Target_Action_Name__c=ma.dca_mass_action__Target_Action_Name__c;
                currentmainst.dca_mass_action__Target_Apex_Script__c=ma.dca_mass_action__Target_Apex_Script__c;
                currentmainst.dca_mass_action__Target_SObject_Type__c=ma.dca_mass_action__Target_SObject_Type__c;
                currentmainst.dca_mass_action__Target_Type__c=ma.dca_mass_action__Target_Type__c;
                currentmainst.dca_mass_action__DeveloperName__c=ma.dca_mass_action__DeveloperName__c;
                system.debug('@@Insert'+currentmainst);
                insert currentmainst;


                JsonString='Inserted';
                strngjsonlst.add(JsonString);
                system.debug('@@Insert');
            }  
        }
        return strngjsonlst;
    }
    
}