/**
 * Class:schedule_SIOP_Create_Data_Fields
 * Apex Test Class: SIOP_Create_Data_Fields_test
 * Author: (PWC)Vishwas
 * Created Date:29 july,2020
 * Functionality: Scheduler class for SIOP_Create_Data_Fields apex class:ticket No.ITSFDC-2405
 */
Global class schedule_SIOP_Create_Data_Fields implements Schedulable {
global void execute(SchedulableContext SC) {
    SIOP_Create_Data_Fields SCDF = new SIOP_Create_Data_Fields();
    Database.ExecuteBatch(SCDF,100);
    }
}