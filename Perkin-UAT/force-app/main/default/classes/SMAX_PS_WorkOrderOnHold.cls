/**
 * Created by tony on 4/17/20.
 * ITSFDC-1240 Depot WOs on hold-Credit status issue
 */

public with sharing class SMAX_PS_WorkOrderOnHold {

    /**
	 *  when the order status is On Hold - Credit and old OwnerId = "00G%" (owned by group) then OwnerId cannot be changed to a user
	 *  Should be called in the "before" trigger(s)
	 */
    public static void validateOwnerChange(List<SVMXC__Service_Order__c> woList, Map<Id, SVMXC__Service_Order__c> oldMap)
    {
        System.debug('Entered SMAX_PS_WorkOrderOnHold.validateOwnerChange');
        for (SVMXC__Service_Order__c wo : woList)
        {
            System.debug('Order Status: ' + wo.SVMXC__Order_Status__c + '  Old OwnerId: ' + String.valueOf(oldMap.get(wo.Id).OwnerId).left(3) + '  New OwnerId: ' + String.valueOf(wo.OwnerId).left(3));
            if (wo.SVMXC__Order_Status__c == 'On Hold - Credit'
                    && String.valueOf(oldMap.get(wo.Id).OwnerId).left(3) == '00G'
                    && String.valueOf(wo.OwnerId).left(3) != '00G')
            {
                // 5/26/2020 Tony - Removed per request in ITSFDC-1240
                //wo.addError('You cannot change the Owner on a Work Order in "On Hold - Credit" status.');
            }
        }
    }
}