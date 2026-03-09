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
* 7. Is @Invocable (Yes or No): No
*
* 8. Author Name(s):
*    - SS 22-02-2023
**************************************************************/
@isTest
public class UTIL_Import_Export_Data_Test {
	@isTest static void testflowcalled() {
        test.startTest();
        
        dca_mass_action__Mass_Action_Configuration__c currentmainst=new dca_mass_action__Mass_Action_Configuration__c();
                currentmainst.Name='Test';
                currentmainst.dca_mass_action__Active__c=false;
                currentmainst.dca_mass_action__Batch_Size__c=1;
                currentmainst.dca_mass_action__Description__c='Test';
                currentmainst.dca_mass_action__Schedule_Frequency__c='Manual';
                currentmainst.dca_mass_action__Source_Apex_Class__c='Test';
                currentmainst.dca_mass_action__Source_Type__c='SOQL';
                currentmainst.dca_mass_action__Target_Apex_Script__c='Test';
                currentmainst.dca_mass_action__Target_Type__c='Apex';
                currentmainst.dca_mass_action__DeveloperName__c='Test';
                insert currentmainst;
        
        String JsonString1=JSON.serialize(currentmainst);
        UTIL_Import_Export_Data.objInfo varInputClass= new UTIL_Import_Export_Data.objInfo();
        varInputClass.ObjAPIName='dca_mass_action__Mass_Action_Configuration__c';
        varInputClass.JsonString=JsonString1;
        varInputClass.IMPORT_or_EXPORT_action='IMPORT';
        
        UTIL_Import_Export_Data.Import_Export_MassActionsData(new list<UTIL_Import_Export_Data.objInfo>{varInputClass});
        
        currentmainst.dca_mass_action__DeveloperName__c='Test2';
        update currentmainst;
        
        UTIL_Import_Export_Data.Import_Export_MassActionsData(new list<UTIL_Import_Export_Data.objInfo>{varInputClass});
        
        varInputClass.CurrentrecordId=currentmainst.Id;
        varInputClass.IMPORT_or_EXPORT_action='EXPORT';
        
        UTIL_Import_Export_Data.Import_Export_MassActionsData(new list<UTIL_Import_Export_Data.objInfo>{varInputClass});
        
        test.stopTest();
   }
}