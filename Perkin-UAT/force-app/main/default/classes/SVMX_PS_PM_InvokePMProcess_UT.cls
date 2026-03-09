@isTest(SeeAllData=false)
public with sharing class SVMX_PS_PM_InvokePMProcess_UT {
  
    static void preparedata(){
        
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'SVMXC__ServiceMax_Processes__c' AND Name = 'PM Process' LIMIT 1];
        
        SVMXC__ServiceMax_Processes__c process1 = new SVMXC__ServiceMax_Processes__c(
            SVMXC__Name__c='Process1',
            RecordTypeId = rt.Id,
            SVMXC__Active__c = true
        );
        insert process1;
        
        SVMXC__ServiceMax_Processes__c process2 = new SVMXC__ServiceMax_Processes__c(
            SVMXC__Name__c='Process2',
            RecordTypeId = rt.Id,
            SVMXC__Active__c = true
        );
        insert process2;
        
    }
    
    static testmethod void testInvokePMProcess(){
        prepareData();
        
        SVMX_PS_PM_InvokePMProcess svmxInvokePMProcess = new SVMX_PS_PM_InvokePMProcess();
        svmxInvokePMProcess.isTestFlag = true;
        
        List<SelectOption> listOptions = svmxInvokePMProcess.getOptions();
        
        System.assertEquals(listOptions.size(), 2);
        
        for(SelectOption option : listOptions){
            System.debug('Value ' + option.getValue());
            svmxInvokePMProcess.listPMProcessName.add(option.getValue());
        }
        
        svmxInvokePMProcess.invokePMProcess();
    }
}