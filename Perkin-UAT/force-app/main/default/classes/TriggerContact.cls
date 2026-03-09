/******************************************************************************
 * Name:        TriggerContact
 * 
 * Purpose:     Controller class that contains all methods for the triggers on Contact object.
 *              Also, contains functionality against Pardot/Salesforce connector to control
 *              how prospect data is updated on the Contact / Converted Lead record.
 * 
 * @Author:     Abdul Sattar (Magnet 360)
 * @Date:       06.01.2015
 * 
 * @Updates: 
 * 06.11.2015   Abdul Sattar (Magnet 360)
 *              Added new logic to handle prospect updates to Converted Lead / Contact
 *    
 * 08.06.2015   Sophia Murphy (Magnet 360)
 *              Added custom setting to store default Lead Owner Id
 *              In case where the lead is owned by an inactive user, we need to reassign them
 *              Before updating.
 *              
 * 08.20.2015   Abdul Sattar (Magnet 360)
 *              Updated interceptContactUpdates for exception handling.
 */
public with sharing class TriggerContact {
/*
    public static DateTime CURRENT_DATE = System.now(); // Curent date.
    public static Boolean IS_PARDOT_CALL = false;
    public static Boolean RUN_ONCE_INTERCEPT_CONTACTS = true;

    private static final Set<String> statusUpdate = new Set<String>{
        'Qualified',
        'Future-Nurturing',
        'Abandoned'
    };

    public TriggerContact() {

    }
    
    /**
     * Intercepts contact updates from PARDOT and applies custom logic. 
     * Called from After insert/update. 
     * 
     * @param newContacts List of new contacts
     * @param oldContacts List of old contacts
     * 
     * @Author:     Abdul Sattar (Magnet 360)
     * @Date:       
     *
     * @Updates: 
     * 06.11.2015   Abdul Sattar (Magnet 360)
     *              - Removed old logic which restricted any updates from Pardot prospect to Contact
     *              - Started out new logic to handle prospect updates in case of Converted Lead / Contact
     *              
     * 08.20.2015   Abdul Sattar (Magnet 360)
     *              Added exception handling.
     *
*/    public static void interceptContactUpdates (List<Contact> newContacts, Map<Id, Contact> oldContacts) {
/*
        if(System.isFuture()) return;

        if (!RUN_ONCE_INTERCEPT_CONTACTS) return;        // Only run once.
        RUN_ONCE_INTERCEPT_CONTACTS = Test.isRunningTest();

        System.debug('START: TriggerContact.interceptContactUpdates()');

        IS_PARDOT_CALL = isPardotCall();
        System.debug('SCS: IS_PARDOT_CALL' + IS_PARDOT_CALL);

        if(!IS_PARDOT_CALL) return;                 // Only proceed when call from PARDOT API Users.

        TriggerLead.RUN_ONCE_ILU = false;           // Do not run TriggerLead.interceptLeadUpdates

        List<ContactToLeadMappings__c> ctol = [SELECT Id, Name, Lead_Field__c FROM ContactToLeadMappings__c];
        if (ctol.isEmpty()) return;                 // Only when there a valid contact to lead mapping available.

        Set<String> sCAPCombos = new Set<String>();
        Map<String, Lead> leadsToUpdate = new Map<String, Lead>();
                
        Boolean recordChanged = false;
        for (Contact newContact : newContacts ) {

            // Set status to 'Open'
            if(newContact.IGOR_PAC__c == oldContacts.get(newContact.Id).IGOR_PAC__c &&
                newContact.Completion_Action_Product__c == oldContacts.get(newContact.Id).Completion_Action_Product__c &&
                newContact.Email == oldContacts.get(newContact.Id).Email) {
                recordChanged = false;
            } else {
                recordChanged = true;
            }

            System.debug('newContact.Email: ' + newContact.Email);
            System.debug('newContact.Completion_Action_Product__c: ' + newContact.Completion_Action_Product__c);
            System.debug('newContact.IGOR_PAC__c: ' + newContact.IGOR_PAC__c);

            // Create map of CAP Combos for later use.
            String sCAPCombo =  (newContact.Email == null ? '' : newContact.Email) +
                                (newContact.Completion_Action_Product__c == null ? '' : newContact.Completion_Action_Product__c) +
                                (newContact.IGOR_PAC__c == null ? '' : newContact.IGOR_PAC__c);

            if (!String.isEmpty(sCAPCombo)) sCAPCombos.add(sCAPCombo);
        }

        System.debug('SCS: sCAPCombos.size() = ' + sCAPCombos.size());
        System.debug('SCS: sCAPCombos: ' + sCAPCombos);
        System.debug('SCS: newContacts: ' + newContacts);
                
        if(sCAPCombos.isEmpty()) return;

        // Get matching leads
        List<Lead> matchingLeads = [SELECT Id, Status, CAPCombo__c, Synced__c
                                        FROM Lead 
                                        WHERE IsConverted = false
                                        AND CAPCombo__c IN :sCAPCombos
                                        AND CreatedDate = LAST_N_DAYS:365
                                        ORDER BY LastModifiedDate DESC];
        System.debug('SCS: matchingLeads = ' + matchingLeads);

        // Prepare CAPCombo to Lead map
        Map<String, Id> capToLeadMap = new Map<String, Id>();
        for(Lead lead : matchingLeads) {

            if(!capToLeadMap.containsKey(lead.CAPCombo__c)) {
                capToLeadMap.put(lead.CAPCombo__c, lead.Id);
            }
        }

        System.debug('SCS: capToLeadMap = ' + capToLeadMap);

        for (Contact newContact : newContacts ) {
            
            Id leadId = capToLeadMap.get(newContact.CAPCombo__c);

            Lead leadToUpdate = new Lead(Id=leadId);

            if(leadId != null) {
                leadToUpdate.Synced__c = true;    
            }
            
            if(recordChanged && statusUpdate.contains(leadToUpdate.Status)) {
                leadToUpdate.Status = 'Open';                   // Set status
                leadToUpdate.Create_Date__c = CURRENT_DATE;     // Set New Create Date to current date.
            } 

            // Copy values from Contact to the most recently modified or new lead with matching CAP Combo
            updateLead(leadToUpdate, newContact, ctol);
            
            leadToUpdate.Synced__c = true;
            
            leadsToUpdate.put(newContact.CAPCombo__c, leadToUpdate);
        }
        
        if(!leadsToUpdate.isEmpty()) {
            try {
                UPSERT leadsToUpdate.values();  
            }
            catch (System.DmlException e) {
                System.debug('Database Error: Upsert failed.');
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    System.debug(e.getDmlMessage(i)); 
                }
            }
        } 

        System.debug('END: TriggerContact.interceptContactUpdates()');
    }

    // Get & return call origin.
    public static Boolean isPardotCall() {
        List<UserRole> userRoles = [SELECT Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId() LIMIT 1 ];

        String roleName = userRoles.isEmpty() ? NULL : userRoles[0].Name;

        return roleName != null && roleName.equalsIgnoreCase(Label.Pardot_User_Role);
    } 

    private static void updateLead(Lead destLead, Contact sourceContact, List<ContactToLeadMappings__c> ctol)  {
        System.debug('SCS: Updating Lead: ' + destLead.Id + '  From Contact: ' + sourceContact.Id);

        Map<String, Schema.SObjectField> leadFields = Lead.getSObjectType().getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> contFields = Contact.getSObjectType().getDescribe().fields.getMap();

        for (ContactToLeadMappings__c m : ctol) {  
            DescribeFieldResult lfr = leadFields.get(m.Lead_Field__c).getDescribe();
            DescribeFieldResult cfr = contFields.get(m.Name).getDescribe();

            if( cfr.isAccessible() && lfr.isAccessible() && lfr.isCreateable() && lfr.isUpdateable() ) {
                if( m.Lead_Field__c == 'Id' || 
                    m.Lead_Field__c == 'Synced__c' ||
                    m.Lead_Field__c == 'pi__url__c' ||
                    m.Lead_Field__c == 'Status') 
                        continue;

                destLead.put(m.Lead_Field__c, sourceContact.get(m.Name));

                if(String.isBlank(destLead.Company)) destLead.Company = 'Company';     
            }
        } */
    } 
    
}