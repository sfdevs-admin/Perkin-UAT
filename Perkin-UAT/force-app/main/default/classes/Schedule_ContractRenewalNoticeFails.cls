Global class Schedule_ContractRenewalNoticeFails implements schedulable{
	global void execute(Schedulablecontext Batch_ContractRenewalNoticeFails){
        Batch_ContractRenewalNoticeFails batchJob = new Batch_ContractRenewalNoticeFails();
        Database.executeBatch(batchJob,200);
    }
}