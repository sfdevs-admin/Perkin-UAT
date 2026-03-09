/*********************************************************************************************************************
 * CLASS: BD_JobSchedulerInterface
 * @author Bolt Data Consulting Group
 * @description Schedulable interface wrapper.
 *
 * -----CHANGE LOG-----
 * 2025.03.07 - ives - Created class.
 *********************************************************************************************************************/
public without sharing class BD_JobSchedulerInterface implements SchedulableContext
{
    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: getTriggerId
     * @author Bolt Data Consulting Group
     * @return The cron trigger id.
     * @description Returns the cron trigger id..
     *
     * -----CHANGE LOG-----
     * 2025.03.07 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    public Id getTriggerId()
    {
        return CronTrigger.SObjectType.getDescribe().getKeyPrefix().rightPad( 15, '0' );
    }
}