/******************************************************************************
 * Name:        TriggerLead
 * 
 * Purpose:     Controller class that contains all methods for the triggers on Lead object. 
 *              Also, contains functionality against Pardot/Salesforce connector to control 
 *              how prospect data is updated on the Lead record.
 * 
 * @Author:     Abdul Sattar (Magnet 360)
 * @Date:       01.19.2015
 * 
 * @Updates:    
 * 08.06.2015   Sophia Murphy (Magnet 360)
 *              Added custom setting to store default Lead Owner Id
 *              In case where the lead is owned by an inactive user, we need to reassign them
 *              Before updating.
 *              
 * 09.02.2015   Abdul Sattar (Magnet 360)
 *              Added code to allow duplicate lead creation from Sales Force UI.
 */
public with sharing class TriggerLead {
/*
    public static DateTime CURRENT_DATE = System.now(); // Current date.
    public static Boolean IS_PARDOT_CALL = false;       // Status check for tracking whether call is from PARDOT or not.
    public static Boolean RUN_ONCE = true;              // Status enforcing createLeadInterestTrack to run only once
    public static Boolean RUN_ONCE_CFQH = true;         // Status enforcing createFormsQualificationHistory to run only once
    public static Boolean RUN_ONCE_ILU = true;          // Status enforcing interceptLeadUpdates to run only once
    public static Boolean RUN_ONCE_ILUSF = true;        // Status enforcing interceptLeadUpdatesFromSF to run only once
    public static Boolean RUN_ONCE_CLT = true;          // Status enforcing createLeadAgingTrack to run only once
    
    private static final Set<String> statusUpdate = new Set<String>{
        'Open',
        'Qualified',
        'Future-Nurturing',
        'Abandoned'
    };
*/
    // Call it from before insert
    // Sets Override_Duplicate_Error__c = true to allow duplicate lead
    // creation from SF.
    public static void overrideDuplicateErrorFromSF(List<Lead> newLeads) {
  /*    System.debug('START: TriggerLead.overrideDuplicateError(LIST newleads)');

        IS_PARDOT_CALL = isPardotCall();
        System.debug('SCS: IS_PARDOT_CALL' + IS_PARDOT_CALL);

        if(IS_PARDOT_CALL) return;

        for (Lead l : newLeads) {
            l.Override_Duplicate_Error__c = true;
        }

        System.debug('START: TriggerLead.overrideDuplicateError(LIST newleads)'); */
    }

    // Call it from before insert/update. 
    // Intercepts lead updates from SFDC and applies custom logic. 
    // REQ 4
    public static void interceptLeadUpdatesFromSF (List<Lead> newleads) {
 /*       System.debug('START: TriggerLead.interceptLeadUpdatesFromSF(LIST newleads)');

        if (!RUN_ONCE_ILUSF) return;        // Only run once.
        RUN_ONCE_ILUSF = Test.isRunningTest();

        IS_PARDOT_CALL = isPardotCall();
        System.debug('SCS: IS_PARDOT_CALL' + IS_PARDOT_CALL);

        if(IS_PARDOT_CALL) return;

        Set<String> sCAPCombos = new Set<String>();
        Set<String> piURLs = new Set<String>();

        
        for (Lead newLead : newleads ) {
            if(newLead.Override_Duplicate_Error__c || newLead.Synced__c || String.isEmpty(newLead.CAPCombo__c)) {
                newLead.Override_Duplicate_Error__c = false;    
            } else {
                sCAPCombos.add(newLead.CAPCombo__c);
            }
        }

        if(sCAPCombos.isEmpty()) return;

        Map<String, Lead> capToLeadMap = new Map<String, Lead>();

        for(Lead lead : [select Id, Name, CAPCombo__c, Override_Duplicate_Error__c
                            from Lead 
                            where IsConverted = false
                            and Id not in :newLeads
                            and CAPCombo__c != null and CAPCombo__c != ''
                            and CAPCombo__c in :sCAPCombos
                            and Synced__c = true
                            and Override_Duplicate_Error__c = false
                            and CreatedDate = LAST_N_DAYS:365]) {

            if(!capToLeadMap.containsKey(lead.CAPCombo__c)) {
                capToLeadMap.put(lead.CAPCombo__c, lead);
            }
        }

        if(capToLeadMap.isEmpty()) return;

        for (Lead newLead : newleads ) {
            
            Lead lead = capToLeadMap.get(newLead.CAPCombo__c);

            if(lead == null) continue;

            newLead.addError(   'This record is a duplicate and should not be updated. ' +
                                'Please make your updates to the record associated with this link ' +
                                '<a href="/' + lead.Id + ' ">' + lead.Name + '</a>' +
                                '<br /> OR <br /> Enable / select Override Duplicate Error check box before saving to override this error.' +
                                '<script type="text/javascript"> '+ 
                                    'function clearInvalidError() { '+
                                          'document.getElementById("errorDiv_ep").innerHTML = document.getElementById("errorDiv_ep").innerHTML.replace("Error: Invalid Data.", "");'+
                                          'document.getElementById("errorDiv_ep").innerHTML = document.getElementById("errorDiv_ep").innerHTML.replace("Review all error messages below to correct your data.", "");'+
                                          'var element = document.getElementById("errorDiv_ep").getElementsByTagName("br");'+
                                          'element[0].parentNode.removeChild(element[0]);'+
                                          'element[0].parentNode.removeChild(element[0]);'+
                                    '}'+
                                    'clearInvalidError();</script>', 
                                false);
                                
            newLead.Override_Duplicate_Error__c.addError('Check/Enable to override error message.'); 
        }

        System.debug('END: TriggerLead.interceptLeadUpdatesFromSF(LIST newleads)'); */
    }

    // UA - Call it from Before insert/update. 
    // Intercepts lead updates from PARDOT and applies custom logic. 
    // REQ 2, 3, and 5
/*    public static void interceptLeadUpdates (List<Lead> newleads, Map<Id, Lead> oldLeads) {

        if(System.isFuture()) return;

        if (!RUN_ONCE_ILU) return;        // Only run once.
        RUN_ONCE_ILU = Test.isRunningTest();
        

        System.debug('START: TriggerLead.interceptLeadUpdates(LIST newleads)');

        IS_PARDOT_CALL = isPardotCall();
        System.debug('SCS: IS_PARDOT_CALL' + IS_PARDOT_CALL);

        if(!IS_PARDOT_CALL) return;                  // Only proceed when call from PARDOT API Users.

        Set<String> sCAPCombos = new Set<String>();
        Map<String, Lead> leadsToUpdate = new Map<String, Lead>();
        //Map<String, Lead> leadsToInsert = new Map<String, Lead>();
                
        Boolean recordChanged = false;
        for (Lead newLead : newleads ) {
            // Set status to 'Open'
            if(newLead.IGOR_PAC__c == oldLeads.get(newLead.Id).IGOR_PAC__c &&
                newLead.Completion_Action_Product__c == oldLeads.get(newLead.Id).Completion_Action_Product__c &&
                newLead.Email == oldLeads.get(newLead.Id).Email) {

                if(statusUpdate.contains(newLead.Status)) {
                    newLead.Status = 'Open';                    // Set status to Open
                    newLead.Create_Date__c = CURRENT_DATE;      // Set New Create Date to current date.
                }
                recordChanged = false;
            } else {
                recordChanged = true;
            }
            System.debug('newLead.Email: ' + newLead.Email);
                        System.debug('newLead.Completion_Action_Product__c: ' + newLead.Completion_Action_Product__c);
                        System.debug('newLead.IGOR_PAC__c: ' + newLead.IGOR_PAC__c);
            // Create map of CAP Combos for later use.
            String sCAPCombo =  (newLead.Email == null ? '' : newLead.Email) +
                                                    (newLead.Completion_Action_Product__c == null ? '' : newLead.Completion_Action_Product__c) +
                                                    (newLead.IGOR_PAC__c == null ? '' : newLead.IGOR_PAC__c);

                if (!String.isEmpty(sCAPCombo)) sCAPCombos.add(sCAPCombo);
        }

        System.debug('SCS: sCAPCombos.size() = ' + sCAPCombos.size());
                System.debug('SCS: sCAPCombos: ' + sCAPCombos);
                System.debug('SCS: newLeads: ' + newLeads);
                
        if(sCAPCombos.isEmpty()) return;

        // Get matching leads
        List<Lead> matchingLeads = [SELECT Id, Status, CAPCombo__c, Synced__c
                                        FROM Lead 
                                        WHERE IsConverted = false
                                        AND CAPCombo__c IN :sCAPCombos
                                        AND CreatedDate = LAST_N_DAYS:365
                                        AND Owner.IsActive = true
                                        ORDER BY LastModifiedDate DESC];
        System.debug('SCS: matchingLeads = ' + matchingLeads);

        // Prepare CAPCombo to Lead map
        Map<String, Lead> capToLeadMap = new Map<String, Lead>();
        for(Lead lead : matchingLeads) {
            if(!capToLeadMap.containsKey(lead.CAPCombo__c)) {
                capToLeadMap.put(lead.CAPCombo__c, lead);
            }
        }

        System.debug('SCS: capToLeadMap = ' + capToLeadMap);

        //Before looping through the leads - get the custom setting
        List<Pardot_Settings__c> piSettings = Pardot_Settings__c.getall().values();
        Id DefaultLeadOwnerId = piSettings[0].Default_Lead_Owner_ID__c;
        
        for (Lead newLead : newleads ) {
            
            Lead matchingLead = capToLeadMap.get(newLead.CAPCombo__c);
            system.debug('M360: matchingLead ' + matchingLead);
            system.debug('M360: capToLeadMap ' + capToLeadMap);
            system.debug('M360: newLead.CAPCombo__c ' + newLead.CAPCombo__c);
            
            Id leadId = ( matchingLead == null ? null : matchingLead.Id );

            // Only when lead is directly associated with Prospect, last modified
            // and there is no change is CAP Combo. 
            System.debug('SCS: recordChanged = ' + recordChanged);
            if(newLead.Id == leadId && !recordChanged) {
                newLead.Synced__c = true;
                if(statusUpdate.contains(newLead.Status)) {
                    newLead.Status = 'Open';                    // Set status to Open
                    newLead.Create_Date__c = CURRENT_DATE;      // Set New Create Date to current date.
                }

                Lead oldLead = oldLeads.get(newLead.Id);
                if(oldLead != NULL && !statusUpdate.contains(oldLead.Status)) {
                    // Revert changes made by prospect
                    newLead.Status = oldLead.Status;
                    newLead.Create_Date__c = oldLead.Create_Date__c;
                }

                CONTINUE;
            }

            system.debug('M360: leadId ' + leadId);
            Lead leadToUpdate = new Lead(Id=leadId);
            system.debug('M360: leadToUpdate ' + leadToUpdate);
            
            if(leadId != null) {
                leadToUpdate.Synced__c = true;    
            }

            if( ( matchingLead == null && statusUpdate.contains(leadToUpdate.Status) ) ||
               ( matchingLead != null && statusUpdate.contains(newLead.Status) && statusUpdate.contains(matchingLead.Status) )
              ) {
                  leadToUpdate.Status = 'Open';                 // Set status to Open
                  leadToUpdate.Create_Date__c = CURRENT_DATE;       // Set New Create Date to current date.
              }
            
            // Create a deep clone of Source Lead and copy values to 
            // a most recently modified lead with matching CAP Combo
            updateLead(leadToUpdate, newLead.clone(false, true, false, false));
            
            // Revert new lead to original values.
            updateLead(newLead, oldLeads.get(newLead.Id));
            
            
            //Update 04.28.2015 - make sure the "synched" checkbox is checked
            leadToUpdate.Synced__c = true;
            
            //Just before adding to list - make sure this isn't owned by an inactive user
            if(leadToUpdate.Lead_Owner_Active__c == false) {
                leadToUpdate.OwnerId = DefaultLeadOwnerId;
            }

            leadsToUpdate.put(newLead.CAPCombo__c, leadToUpdate);
        }
                
        if(!leadsToUpdate.isEmpty()) {
            System.debug('M360: ' + leadsToUpdate);
            try {
                UPSERT leadsToUpdate.values();
            } catch (Exception e) {
                //try just an update...
                System.debug('M360: ' + e.getMessage());
            }
        } 

        System.debug('END: TriggerLead.interceptLeadUpdates(LIST newleads)');
    }

    // Get & return call origin.
    public static Boolean isPardotCall() {
        List<UserRole> userRoles = [SELECT Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId() LIMIT 1 ];

        String roleName = userRoles.isEmpty() ? NULL : userRoles[0].Name;

        return roleName != null && roleName.equalsIgnoreCase(Label.Pardot_User_Role);
    }  

    private static void updateLead(Sobject destLead, Sobject sourceLead)  {
        Map<String, Schema.SObjectField> objectFields = Lead.getSObjectType().getDescribe().fields.getMap();

        for (String field : objectFields.keySet()) {  
            DescribeFieldResult result = objectFields.get(field).getDescribe();
            if(result.isAccessible() && result.isCreateable() && result.isUpdateable()) {
                String fieldName = result.getName();
                if( //fieldName == 'Id' || 
                    fieldName == 'Synced__c' ||
                    fieldName == 'pi__url__c' ||
                    fieldName == 'Status') 
                    continue;

                destLead.put(fieldName, sourceLead.get(fieldName));     
            }
            
        }
    }

    
    // Set lead auto assign flag.
    //public static void setLeadAutoAssign (List<Lead> newleads, List<Lead> oldLeads) {

    //    System.debug('START: TriggerLead.setLeadAutoAssign(LIST newleads, LIST oldLeads)');

        // Get the record type id.
    //    Id informaticsRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Informatics' LIMIT 1].Id;

        // All new leads.
    //    for (Lead newLead : newLeads) {
    //        if( informaticsRecordTypeId != null && newLead.RecordTypeId != null && 
    //            newLead.RecordTypeId == informaticsRecordTypeId && newLead.Status == 'Working')
    //            newLead.Lead_Auto_Assign__c = false;
    //        else
    //            newLead.Lead_Auto_Assign__c = true;
    //    }

    //    System.debug('END: TriggerLead.setLeadAutoAssign(LIST newleads, LIST oldLeads)');
    //}
    
    
    // Call it from Before Update.
    // Sets create date on status change.
    public static void setCreateDateOnStatusChagne (List<Lead> newleads, Map<Id, Lead> oldLeads) {

        System.debug('START: TriggerLead.setCreateDateOnStatusChagne(LIST newleads, LIST oldLeads)');

        for (Lead newLead : newLeads) {
            if(newLead.Status != oldLeads.get(newLead.Id).Status && newLead.Status == 'Open') {
                System.debug('SCS: Setting New Created Date on Status Change. ');
                newLead.Create_Date__c = CURRENT_DATE;
            }
        }

        System.debug('END: TriggerLead.setCreateDateOnStatusChagne(LIST newleads, LIST oldLeads)');
    }

    // Call it from After Update.
    // Creats lead aging track on status change.
 */   public static void createLeadAgingTrack (List<Lead> newleads, List<Lead> oldLeads) {
       /* Map<Id, Lead> oldLeadsMap = new Map<Id, Lead>(oldLeads);
        
        if (!RUN_ONCE_CLT) return;      // Only run once.
        RUN_ONCE_CLT = Test.isRunningTest();

        System.debug('START: TriggerLead.createLeadAgingTrack(LIST newleads, LIST oldLeads)');

        Set<Id> leadUserIds = new Set<Id>();       // Set of lead user ids.
        // Add all owners.
        for (Lead newLead : newLeads) {
            leadUserIds.add(newLead.OwnerId);
        }
        // Add all modified by users.
        for (Lead newLead : newLeads) {
            leadUserIds.add(newLead.LastModifiedById);
        }

        List<User> users = [SELECT Id, Username, UserType FROM User WHERE Id IN :leadUserIds];
        List<Group> queues = [SELECT Id, Name, Type FROM Group WHERE Id IN :leadUserIds AND Type = 'Queue'];
        
        // Map of lead users, modified by users & queues.
        Map<Id, LeadUser> leadUsers = new Map<Id, LeadUser>();      

        // Add all users to lead users
        for (User u : users) {
            LeadUser lu = new LeadUser(u.Id, u.Username, u.UserType);
            leadUsers.put(u.Id, lu);
        }

        // Add all queues to lead users
        for (Group q : queues) {
            LeadUser lu = new LeadUser(q.Id, q.Name, q.Type);
            leadUsers.put(q.Id, lu);
        }

        List<Lead_Agei__c> leadAgingTracksToInsert = new List<Lead_Agei__c>();

        // For all new leads
        for (Lead newLead : newLeads) {
            if( newLead.Status == 'Open' && newLead.Status != oldLeadsMap.get(newLead.Id).Status )
            {   
                // Create new lead aging track.
                Lead_Agei__c leadAgingTrack = new Lead_Agei__c( Created_Date__c = CURRENT_DATE,
                                                                Lead_Age__c = 0,
                                                                Age__c = '',
                                                                CurrencyIsoCode = newLead.CurrencyIsoCode,
                                                                Lead__c = newLead.Id,
                                                                User_Id__c = newLead.OwnerId,
                                                                User_Name__c = leadUsers.get(newLead.OwnerId).userName,
                                                                Lead_Owner_Type__c = leadUsers.get(newLead.OwnerId).userType,
                                                                Modified_By__c = leadUsers.get(newLead.LastModifiedById).userName
                                                                );
                leadAgingTracksToInsert.add(leadAgingTrack);
            }
        }

        try {
                insert leadAgingTracksToInsert;
        }
        catch (System.DmlException e) {
            System.debug('Database Error: Unable to create lead ageing track records.');
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here 
                System.debug(e.getDmlMessage(i)); 
            }
        }

        System.debug('END: TriggerLead.createLeadAgingTrack(LIST newleads, LIST oldLeads)'); */
    }


    // Call it from After Insert & Update.
    // Creats lead interest track on status change.
    // REQ 9
    // public static boolean RUN_ONCE_LIT = true; */
    public static void createLeadInterestTrack (Map<Id, Lead> newleads, Map<Id, Lead> oldLeads) {
  /*      System.debug('START: TriggerLead.createLeadInterestTrack(Map newleads, Map oldLeads)');

        if (!RUN_ONCE_LIT) return;        // Only run once.
        RUN_ONCE_LIT = Test.isRunningTest();

        if (oldLeads == null) return; // Get out.
        
        Lead oldLead = new Lead();
        List<Lead_Interest_Track__c> leadInterestTracksToInsert = new List<Lead_Interest_Track__c>();
        String primaryInterestOld, secondaryInterestOld, productInterestsOld;

        // For all new leads
        for (Lead newLead : newLeads.values()) {
             
            
            // Get old values.
            if ( oldLeads != null ) {
                oldLead = oldLeads.get(newLead.Id);         // Reference to old lead.
                primaryInterestOld = oldLead.Primary_Interest__c;
                secondaryInterestOld = oldLead.Secondary_Interest__c;
                productInterestsOld = oldLead.Product_Interests__c;
            }

            // Primary Interest
            if( newLead.Primary_Interest__c <> primaryInterestOld)
            {   
                // Create new lead aging track.
                Lead_Interest_Track__c leadInterestTrack = new Lead_Interest_Track__c( Lead__c = newLead.Id,
                                                                                    Field_Name__c = 'Primary Interest',
                                                                                    Old_Value__c = primaryInterestOld,
                                                                                    New_Value__c = newLead.Primary_Interest__c
                                                                                    );
                leadInterestTracksToInsert.add(leadInterestTrack);
            }

            // Secondary Interest.
            if( newLead.Secondary_Interest__c <> secondaryInterestOld)
            {   
                // Create new lead aging track.
                Lead_Interest_Track__c leadInterestTrack = new Lead_Interest_Track__c( Lead__c = newLead.Id,
                                                                                    Field_Name__c = 'Secondary Interest',
                                                                                    Old_Value__c = secondaryInterestOld,
                                                                                    New_Value__c = newLead.Secondary_Interest__c
                                                                                    );
                leadInterestTracksToInsert.add(leadInterestTrack);
            }

            // Product Interests.
            if( newLead.Product_Interests__c <> productInterestsOld)
            {   
                // Create new lead aging track.
                Lead_Interest_Track__c leadInterestTrack = new Lead_Interest_Track__c( Lead__c = newLead.Id,
                                                                                    Field_Name__c = 'Product Interests',
                                                                                    Old_Value__c = productInterestsOld,
                                                                                    New_Value__c = newLead.Product_Interests__c
                                                                                    );
                leadInterestTracksToInsert.add(leadInterestTrack);
            }
        }

        
        try {
            insert leadInterestTracksToInsert;
        }
        catch (System.DmlException e) {
            System.debug('Database Error: Unable to create lead interest track records.');
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here 
                System.debug(e.getDmlMessage(i)); 
            }
        }

        System.debug('END: TriggerLead.createLeadInterestTrack(Map newleads, Map oldLeads)'); */
    }

    // Call it from After Update.
    // Creates Forms Qualification History records when any of the spedified fields are updated.
    // REQ 9 - MSP-547 Updated / Additional requirements
    public static void createFormsQualificationHistory (Map<Id, Lead> newleads, Map<Id, Lead> oldLeads) {
       /* System.debug('START: TriggerLead.createFormsQualificationHistory(Map newleads, Map oldLeads)');

        if (!RUN_ONCE_CFQH) return;        // Only run once.
        RUN_ONCE_CFQH = Test.isRunningTest();

        if (oldLeads == null) return; // Get out.
        
        Lead oldLead = new Lead();
        List<Form_Qualification_History__c> fqhsToInsert = new List<Form_Qualification_History__c>();
        String newValue, oldValue;

        // For all new leads
        for (Lead newLead : newLeads.values()) {
             
            
            // Get old values.
            if ( oldLeads != null ) {
                oldLead = oldLeads.get(newLead.Id);         // Reference to old lead.
                oldValue =  oldLead.Completion_Action_Product__c + 
                            oldLead.Primary_Qualification__c +
                            oldLead.Secondary_Qualification__c +
                            oldLead.Requested_Interests__c; 
            }

            // Get new values
            newValue =  newLead.Completion_Action_Product__c + 
                        newLead.Primary_Qualification__c +
                        newLead.Secondary_Qualification__c +
                        newLead.Requested_Interests__c;

            // Compare to see if there is any chagne
            if( oldValue <> newValue )
            {   
                // Create new Form Qualification History record.
                Form_Qualification_History__c fqh = new Form_Qualification_History__c( 
                                                             CurrencyIsoCode = oldLead.CurrencyIsoCode
                                                            ,Completion_Action_Product__c = oldLead.Completion_Action_Product__c
                                                            ,Primary_Qualification__c = oldLead.Primary_Qualification__c
                                                            ,Secondary_Qualification__c = oldLead.Secondary_Qualification__c
                                                            ,Corresponding_Lead__c = newLead.Id
                                                            ,Product_Interests__c = oldLead.Requested_Interests__c
                                                            );
                fqhsToInsert.add(fqh);
            }
        }

        try {
                insert fqhsToInsert;
        }
        catch (System.DmlException e) {
            System.debug('Database Error: Unable to create Forms Qualification History records.');
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here 
                System.debug(e.getDmlMessage(i)); 
            }
        }

        System.debug('END: TriggerLead.createFormsQualificationHistory(Map newleads, Map oldLeads)'); */
    }

    // Inner class for lead user details.
    // Unsed in createLeadAgingTrack method.
    public class LeadUser {
     /* public Id       userId;
        public String   userName;
        public String   userType;

        LeadUser(Id uid, String uName, String uType) {
            this.userId = uid;
            this.userName = uname;
            this.userType = uType;
        } */
    }
    
}