/**
 * Created by tony on 4/7/20.
 */

public with sharing class SMAX_PS_ServiceContract_TxNumController {
    public SVMXC__Service_Contract__c con;
    public Boolean isRunning { get; set; }
    
    public SMAX_PS_ServiceContract_TxNumController(ApexPages.StandardController stdController)
    {
        con = [SELECT Id,Name,RecordType.name
        FROM SVMXC__Service_Contract__c
        WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
    }

    // ITSFDC-1219 - Schedule Service Contract TxnNum Batch for this Service Contract
    public void scheduleServiceContractTxnNumBatch()
    {
        this.isRunning = TRUE;
        Database.executeBatch(new SMAX_PS_ServiceContract_TxnNum_Batch(SMAX_PS_ServiceContract_TxnNum_Batch.STEP_1_ITEMS, Datetime.now(), con.Id));
    }
}