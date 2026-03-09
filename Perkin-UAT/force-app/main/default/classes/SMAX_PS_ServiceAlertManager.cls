/**
 * Created by tony on 11/9/20.
 *
 * Updates:
 * 01/23/2023   tony    ITSVMX-1123 Custom Metadata types - Service Alert CRC Email Address updates on new CRC email addresses
 */

public without sharing class SMAX_PS_ServiceAlertManager {

    private SMAX_PS_ServiceAlertManager() {
    }

    public static void updateServiceAlerts(List<SVMX_PS_Service_Alert__c> serviceAlertList, Map<Id, SVMX_PS_Service_Alert__c> oldMap) {

        // Get any Service Alert records
        Map<Id, SVMX_PS_Service_Alert__c> ownerIdToServiceAlertMap = new Map<Id, SVMX_PS_Service_Alert__c>();
        Map<Id, SVMX_PS_Service_Alert__c> techIdToServiceAlertMap = new Map<Id, SVMX_PS_Service_Alert__c>();

        for (SVMX_PS_Service_Alert__c serviceAlert :serviceAlertList) {
            Id oldTechId = (oldMap == null) ? null : oldMap.get(serviceAlert.Id).SVMX_PS_Technician__c;
            if ((serviceAlert.SVMX_PS_Technician__c != null && oldTechId == null) ||
                    (serviceAlert.SVMX_PS_Technician__c != null && oldTechId != serviceAlert.SVMX_PS_Technician__c)) {
                techIdToServiceAlertMap.put(serviceAlert.SVMX_PS_Technician__c, serviceAlert);
            } else {
                ownerIdToServiceAlertMap.put(serviceAlert.OwnerId, serviceAlert);
            }
        }
        System.debug('ownerIdToServiceAlertMap: ' + ownerIdToServiceAlertMap);
        System.debug('techIdToServiceAlertMap: ' + techIdToServiceAlertMap);


        // Get list of Technician records that match the ownerIdServiceAlertMap Ids or the techIdToServiceAlertMap Ids
        List<SVMXC__Service_Group_Members__c> technicianList = new List<SVMXC__Service_Group_Members__c>([
                SELECT Id, SVMXC__Salesforce_User__c
                FROM SVMXC__Service_Group_Members__c
                WHERE Id IN :techIdToServiceAlertMap.keySet() OR SVMXC__Salesforce_User__c IN :ownerIdToServiceAlertMap.keySet()
        ]);
        System.debug('technicianList: ' + technicianList);

        Map<Id, Id> techIdToUserIdMap = new Map<Id, Id>();
        Map<Id, Id> userIdToTechIdMap = new Map<Id, Id>();
        for (SVMXC__Service_Group_Members__c tech :technicianList) {
            if (tech.SVMXC__Salesforce_User__c != null) {
                userIdToTechIdMap.put(tech.SVMXC__Salesforce_User__c, tech.Id);
            }
            techIdToUserIdMap.put(tech.Id, tech.SVMXC__Salesforce_User__c);

        }
        System.debug('techIdToUserIdMap: ' + techIdToUserIdMap);
        System.debug('userIdToTechIdMap: ' + userIdToTechIdMap);

        // 01/29/2025 Don't change the OwnerId for Technical Support Request records
        Id techSupportRequestRecordTypeId = Schema.SObjectType.SVMX_PS_Service_Alert__c.getRecordTypeInfosByName().get('Technical Support Request').getRecordTypeId();

        // Update the OwnerId for records that had a Technician already set
        for (SVMX_PS_Service_Alert__c serviceAlert :techIdToServiceAlertMap.values()) {

            Id newOwnerId = techIdToUserIdMap.get(serviceAlert.SVMX_PS_Technician__c);

            // 01/29/2025 Don't change the OwnerId for Technical Support Request records
            if(newOwnerId != null && serviceAlert.RecordTypeId != techSupportRequestRecordTypeId){
                serviceAlert.OwnerId = newOwnerId;
            }

            //if (newOwnerId != null) {
            //    serviceAlert.OwnerId = newOwnerId;
            //}
        }
        System.debug('techIdToServiceAlertMap: ' + techIdToServiceAlertMap);

        // Update the SVMX_PS_Technician__c for records that had an OwnerId but no Technician
        for (SVMX_PS_Service_Alert__c serviceAlert :ownerIdToServiceAlertMap.values()) {

            Id newTechId = userIdToTechIdMap.get(serviceAlert.OwnerId);
            // 01/29/2025 Don't change the Technician for Technical Support Request records
            //if (newTechId != null) {
            if(newTechId != null && serviceAlert.RecordTypeId != techSupportRequestRecordTypeId){
                serviceAlert.SVMX_PS_Technician__c = newTechId;
            }
        }
        System.debug('ownerIdToServiceAlertMap: ' + ownerIdToServiceAlertMap);

        // Get the User Ids for the Service Alerts including the ones we just updated
        Set<Id> userIds = new Set<Id>();
        for (SVMX_PS_Service_Alert__c serviceAlert : serviceAlertList) {
            userIds.add(serviceAlert.OwnerId);
        }
        System.debug('userIds: ' + userIds);

        Map<Id, User> userMap = new Map<Id, User>([
                SELECT Id, Region__c, Sub_Region__c
                FROM User
                WHERE Id IN : userIds
        ]);
        System.debug('userMap :' + userMap);

        // The Region and Sub Region of the Service Alerts will be set to the Owner's Region and Sub Region
        for (SVMX_PS_Service_Alert__c serviceAlert : serviceAlertList) {

            User user = userMap.get(serviceAlert.OwnerId);
            if (user != null) {
                serviceAlert.SVMX_PS_Region__c = user.Region__c;
                serviceAlert.SVMX_PS_Sub_Region__c = user.Sub_Region__c;
                System.debug('Setting the Region and Sub Region: ' + serviceAlert.SVMX_PS_Region__c + ' / ' + serviceAlert.SVMX_PS_Sub_Region__c);
            }
        }
        System.debug('serviceAlertList to be updated:' + serviceAlertList);

        // ITSVMX-454 Sarala Lakkireddy - Ability to skip the managerial approval and go directly to BU approval
        // If condition executed when Approval Action taken by Manager directly but in coming status is set to BU approved/rejected
        for (SVMX_PS_Service_Alert__c serviceAlert :serviceAlertList) {
            SVMX_PS_Service_Alert__c old = (oldMap == null) ? null : oldMap.get(serviceAlert.Id);

            //If the current logged in user id is same as manager approval user id SVMX_PS_Manager_Approval_User__c and then if the incoming status is 
            // is showing as Quality Approved/Rejected then it needs to be Manager Approved/Rejected
            
            // System.debug('Before lakk Replacement approval after update is triggered, SVMX_PS_Stage__c:' + serviceAlert.SVMX_PS_Stage__c + ' SVMX_PS_Status__c:' + serviceAlert.SVMX_PS_Status__c
            //  + ' LastModifiedById' + serviceAlert.LastModifiedById + ' SVMX_Current_User_IsManager_user__c:'+serviceAlert.SVMX_Current_User_IsManager_user__c + ' old.SVMX_PS_Status__c:' + old.SVMX_PS_Status__c +
            //   ' serviceAlert.LastApprovedUser:' + serviceAlert.SVMX_PS_Last_Approved_By__c + ' old.SVMX_PS_Manager_Approval_User__c' + old.SVMX_PS_Manager_Approval_User__c
            //   + ' serviceAlert.SVMX_PS_Manager_Approval_User__c' + serviceAlert.SVMX_PS_Manager_Approval_User__c + ' Current logged in User id:' + UserInfo.getUserId());
            if(serviceAlert.SVMX_PS_Manager_Approval_User__c != null && 
               UserInfo.getUserId() != null &&
               serviceAlert.SVMX_PS_Manager_Approval_User__c == UserInfo.getUserId() &&
               serviceAlert.SVMX_PS_Record_Type_form__c == 'Replacement Alert'){
                // System.debug('Replacement approval after update is triggered, SVMX_PS_Stage__c:' + serviceAlert.SVMX_PS_Stage__c + ' SVMX_PS_Status__c:' + serviceAlert.SVMX_PS_Status__c
                                                                            //  + 'LastModifiedById' + serviceAlert.LastModifiedById);
                if(serviceAlert.SVMX_PS_Status__c != null && serviceAlert.SVMX_PS_Status__c == 'Quality Approved' &&
                   old.SVMX_PS_Status__c != null && old.SVMX_PS_Status__c == 'Pending Manager Approval'){
                    serviceAlert.SVMX_PS_Status__c =  'Manager Approved';
                    // System.debug('Replacement manager approval condition reached:' + UserInfo.getUserId() );
                }
                if(serviceAlert.SVMX_PS_Status__c != null && serviceAlert.SVMX_PS_Status__c == 'Quality Rejected' &&
                old.SVMX_PS_Status__c != null && old.SVMX_PS_Status__c == 'Pending Manager Approval'){
                    serviceAlert.SVMX_PS_Status__c =  'Manager Rejected';
                    // System.debug('Replacement manager rejected condition reached:' + UserInfo.getUserId() );
                }
            }
        }        
    }

    public static void updatePath(List<SVMX_PS_Service_Alert__c> serviceAlertList, Map<Id, SVMX_PS_Service_Alert__c> oldMap) {

        // Get the Custom Metadata Type settings
        List<SMAX_PS_Service_Alert_Setting__mdt> serviceAlertSettings = [
                SELECT SMAX_PS_Alert_Status__c, SMAX_PS_Path_Stage__c
                FROM SMAX_PS_Service_Alert_Setting__mdt
        ];

        if (serviceAlertSettings.size() < 1) {
            System.debug('Custom Metadata Type [Service Alert Setting] records need to be created.');
            return;
        }

        // Create Alert Status to Path Stage mapping
        Map<String, String> statusToStageMap = new Map<String, String>();
        for (SMAX_PS_Service_Alert_Setting__mdt serviceAlertSetting : serviceAlertSettings) {

            statusToStageMap.put(serviceAlertSetting.SMAX_PS_Alert_Status__c, serviceAlertSetting.SMAX_PS_Path_Stage__c);
        }
        System.debug('statusToStageMap: '  + statusToStageMap);

        // Update the Path Stage if the Alert Status has changed
        for (SVMX_PS_Service_Alert__c serviceAlert :serviceAlertList) {
            String oldStatus = (oldMap == null) ? null : oldMap.get(serviceAlert.Id).SVMX_PS_Status__c;
            if (oldStatus == null || (serviceAlert.SVMX_PS_Status__c != null && serviceAlert.SVMX_PS_Status__c != oldStatus)) {

                String newStatus = statusToStageMap.get(serviceAlert.SVMX_PS_Status__c);
                if (newStatus != null) {
                    serviceAlert.SVMX_PS_Stage__c = newStatus;
                    System.debug('Setting Stage to: ' + newStatus);
                }
            }
        }
    }

    // ITSVMX-209 tony - Service Alerts Customer Care Email Notification
    // Should be called from AfterUpdate event trigger
    public static void sendServiceAlertNotifications(List<SVMX_PS_Service_Alert__c> serviceAlertList, Map<Id, SVMX_PS_Service_Alert__c> oldMap){
        System.debug('Entering SMAX_PS_ServiceAlertManager.sendServiceAlertNotifications()');
        System.debug('About to process Service Alerts: ' + serviceAlertList.size() + serviceAlertList);

        // You have to have at least 1 contact record or the merge fields will not work properly
        List<Contact> mergeContacts = [
                SELECT Id, FirstName, LastName, Email
                FROM Contact
                WHERE LastName = 'Service Alert Email Notification'
                LIMIT 1
        ];
        if (mergeContacts.size() <> 1) {
            System.debug('ERROR: No Service Alert Email Notification contact has been created. '
                    + 'Please create a new contact with a LastName = "Service Alert Email Notification"');
            return;
        }

        // Get the CRC Service Alert Distribution Lists
        List<SMAX_PS_Service_Alert_CRC_Email_Address__mdt> distributionList = [
                SELECT  Id, DeveloperName, SMAX_PS_Email_Addresses__c, SMAX_PS_Service_Alert_Country__c,
                        SMAX_PS_Service_Alert_Region__c, SMAX_PS_Service_Alert_Sub_Region__c, SMAX_PS_Owned_By_Company__c, SMAX_PS_Indirect_CRC__c
                FROM SMAX_PS_Service_Alert_CRC_Email_Address__mdt
        ];
        System.debug('distributionList: ' + distributionList);

        if (distributionList.size() == 0) {
            System.debug('ERROR: No Service Alert CRC Email Address custom metadata has been setup');
            return;
        }

        // Get the PL Service Alert Distribution Lists
        List<SMAX_PS_Service_Alert_PL_Email_Address__mdt> saDistributionList = [
                SELECT  Id, DeveloperName, SMAX_PS_Email_Addresses__c, SMAX_PS_Product_Line__c, SMAX_PS_Ignore_Product_Line__c
                FROM SMAX_PS_Service_Alert_PL_Email_Address__mdt
        ];
        System.debug('saDistributionList: ' + saDistributionList);

        if (saDistributionList.size() == 0) {
            System.debug('ERROR: No Service Alert PL Email Address custom metadata has been setup');
            return;
        }

        // Create Lookup Maps
        Map<String, SMAX_PS_Service_Alert_CRC_Email_Address__mdt> countryToDistributionListMap = new Map<String, SMAX_PS_Service_Alert_CRC_Email_Address__mdt>();
        Map<String, SMAX_PS_Service_Alert_CRC_Email_Address__mdt> subRegionToDistributionListMap = new Map<String, SMAX_PS_Service_Alert_CRC_Email_Address__mdt>();
        for (SMAX_PS_Service_Alert_CRC_Email_Address__mdt dl :distributionList) {
            // 01/23/2023 ITSVMX-1123 Include the Owned By Company in the mappings
//            countryToDistributionListMap.put(dl.SMAX_PS_Service_Alert_Country__c, dl);
            countryToDistributionListMap.put(dl.SMAX_PS_Service_Alert_Country__c + '-' + dl.SMAX_PS_Owned_By_Company__c, dl);
            if (dl.SMAX_PS_Indirect_CRC__c == true) {
//                subRegionToDistributionListMap.put(dl.SMAX_PS_Service_Alert_Sub_Region__c, dl);
                subRegionToDistributionListMap.put(dl.SMAX_PS_Service_Alert_Sub_Region__c + '-' + dl.SMAX_PS_Owned_By_Company__c, dl);
            }
        }
        System.debug('countryToDistributionListMap: ' + countryToDistributionListMap.size() + ' ' + countryToDistributionListMap);
        System.debug('subRegionToDistributionListMap: ' + subRegionToDistributionListMap.size() + ' ' + subRegionToDistributionListMap);

        // Create Product Line Lookup Map and Ignore Product Line distribution list
        List<SMAX_PS_Service_Alert_PL_Email_Address__mdt> ignorePLDistributionList = new List<SMAX_PS_Service_Alert_PL_Email_Address__mdt>();
        Map<String, SMAX_PS_Service_Alert_PL_Email_Address__mdt> productLineToDistributionListMap = new Map<String, SMAX_PS_Service_Alert_PL_Email_Address__mdt>();
        for (SMAX_PS_Service_Alert_PL_Email_Address__mdt dl :saDistributionList) {

            if (dl.SMAX_PS_Ignore_Product_Line__c == true) {
                ignorePLDistributionList.add(dl);
            } else {
                productLineToDistributionListMap.put(dl.SMAX_PS_Product_Line__c, dl);
            }
        }

        // 01/29/2024 Added new email templates for new flows
        // Email Templates
        String serviceAlertApprovedTemplate = 'SVMX_PS_Service_Alert_Approved';
        String techSupportSaAutoResponseTemplate = 'Technical_Support_SA_Auto_Response_for_Flow_1736958826198';
        String techSupportServiceAlertResponseTemplate = 'Technical_Support_Service_Alert_Response_1732743092384';

        // Get Email Templates
        List<EmailTemplate> emailTemplates = [
                SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body
                FROM EmailTemplate
                WHERE DeveloperName = :serviceAlertApprovedTemplate
                OR DeveloperName = :techSupportSaAutoResponseTemplate
                OR DeveloperName = :techSupportServiceAlertResponseTemplate
                //LIMIT 1
        ];
        System.debug('emailTemplates: ' + emailTemplates);

        Map<String, EmailTemplate> typeToEmailTemplate = new Map<String, EmailTemplate>();
        for (EmailTemplate emailTemplate :emailTemplates) {
            typeToEmailTemplate.put(emailTemplate.DeveloperName, emailTemplate);
        }

        if (typeToEmailTemplate.get(serviceAlertApprovedTemplate) == null) {
            System.debug('ERROR: Email Template named [' + serviceAlertApprovedTemplate + '] does not exist.');
            return;
        }

        if (typeToEmailTemplate.get(techSupportSaAutoResponseTemplate) == null) {
            System.debug('ERROR: Email Template named [' + techSupportSaAutoResponseTemplate + '] does not exist.');
            return;
        }

        // 01/29/2024 Added new email templates for new flows
        if (typeToEmailTemplate.get(techSupportServiceAlertResponseTemplate) == null) {
            System.debug('ERROR: Email Template named [' + techSupportServiceAlertResponseTemplate + '] does not exist.');
            return;
        }

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();

        // Loop over Service Alerts
        for (SVMX_PS_Service_Alert__c serviceAlert :serviceAlertList) {
            SVMX_PS_Service_Alert__c old = (oldMap == null) ? null : oldMap.get(serviceAlert.Id);

            // If the Service Alert status has changed and been set to approved,
            // send Notification to Customer Care distribution list.
            System.debug('Inside Loop processing Service Alert: ' + serviceAlert);
            if (serviceAlert.SVMX_PS_Status__c == 'Quality Approved'
                    && (old.SVMX_PS_Status__c != serviceAlert.SVMX_PS_Status__c)) {

                System.debug('Quality Approved Service Alert: ' + serviceAlert);
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setTargetObjectId(mergeContacts[0].Id); // You have to have a Contact or merge fields won't work
                message.setSenderDisplayName('Service Alert Notification');
                message.setReplyTo('no-reply@perkinelmer.com');
                message.setUseSignature(false);
                message.setBccSender(false);
                message.setSaveAsActivity(false);
                //message.setTemplateId(emailTemplates[0].Id);
                message.setTemplateId(typeToEmailTemplate.get(serviceAlertApprovedTemplate).Id);
                message.setWhatId(serviceAlert.Id); //This is important for the merge fields in template to work

                // Get the Customer Care Distribution List for this Service Alert
                String emailAddresses;
                // 01/23/2023 ITSVMX-1123 Include the Owned By Company in the mappings
//                SMAX_PS_Service_Alert_CRC_Email_Address__mdt distList = countryToDistributionListMap.get(serviceAlert.SVMX_PS_Country__c);
//                SMAX_PS_Service_Alert_CRC_Email_Address__mdt distList2 = subRegionToDistributionListMap.get(serviceAlert.SVMX_PS_Sub_Region__c);
                System.debug('Country Key: ' + serviceAlert.SVMX_PS_Country__c + '-' + serviceAlert.SMAX_PS_Owned_By_Company__c);
                System.debug('Sub Region Key: ' + serviceAlert.SVMX_PS_Sub_Region__c + '-' + serviceAlert.SMAX_PS_Owned_By_Company__c);
                SMAX_PS_Service_Alert_CRC_Email_Address__mdt distList = countryToDistributionListMap.get(serviceAlert.SVMX_PS_Country__c + '-' + serviceAlert.SMAX_PS_Owned_By_Company__c);
                SMAX_PS_Service_Alert_CRC_Email_Address__mdt distList2 = subRegionToDistributionListMap.get(serviceAlert.SVMX_PS_Sub_Region__c + '-' + serviceAlert.SMAX_PS_Owned_By_Company__c);
                if (distList != null) {
                    emailAddresses = distList.SMAX_PS_Email_Addresses__c;
                    System.debug('Country-Owned By Company Match Found - emailAddresses: ' + emailAddresses);
                } else if (distList2 != null) {
                    emailAddresses = distList2.SMAX_PS_Email_Addresses__c;
                    System.debug('Sub Region-Owned By Company Match Found - emailAddresses: ' + emailAddresses);
                }

                if (emailAddresses != null && emailAddresses != '') {
                    message.toAddresses = new List<String>(emailAddresses.split(','));
                    //message.toAddresses = new String[] {'tony.herrington@bolt-data.com', 'infoman5@gmail.com'};
                    messages.add(message);
                    System.debug('Adding message to list: ' + message);
                } else {
                    System.debug('No Match found for Country-Owned By Company or Sub Region-Owned By Company in Service Alert CRC Email Address custom metadata');
                }
            }

            // 01/29/2025 Added new email templates for new flows
            if (serviceAlert.SVMX_PS_Record_Type_form__c == 'Technical Support Request') {

                System.debug('Technical Support SA Auto Response Alert: ' + serviceAlert);
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setTargetObjectId(mergeContacts[0].Id); // You have to have a Contact or merge fields won't work
                message.setSenderDisplayName('Service Alert Notification');
                message.setReplyTo('no-reply@perkinelmer.com');
                message.setUseSignature(false);
                message.setBccSender(false);
                message.setSaveAsActivity(false);
                message.setWhatId(serviceAlert.Id); //This is important for the merge fields in template to work

                // Send Notification to Product Line distribution list using the email template for General Alerts or Replacement Alerts
                if (serviceAlert.SMAX_PS_Technical_Support_Response__c != old.SMAX_PS_Technical_Support_Response__c && serviceAlert.SMAX_PS_Technical_Support_Response__c != null) {
                    System.debug('Technical Support SA Auto Response: ' + serviceAlert);
                    message.setTemplateId(typeToEmailTemplate.get(techSupportSaAutoResponseTemplate).Id);
                }
                // 01/29/2025 Added new email templates for new flows
                else if (old.SMAX_PS_Initial_Response_Email__c != serviceAlert.SMAX_PS_Initial_Response_Email__c && serviceAlert.SMAX_PS_Initial_Response_Email__c == true) {
                    System.debug('Technical Support Service Alert Response: ' + serviceAlert);
                    message.setTemplateId(typeToEmailTemplate.get(techSupportServiceAlertResponseTemplate).Id);
                }

                System.debug('message TemplateId: ' + message.getTemplateId());

                // 01/29/2025 Added new email templates for new flows
                if(message.getTemplateId() == null) {
                    System.debug('No Email Template found for Service Alert Record Type: ' + serviceAlert.SVMX_PS_Record_Type_form__c);
                    return;
                }

                String emailAddresses = '';

                // Set email address to the Technician's email address on the Service Alert
                if (serviceAlert.BD_Technician_Email__c != null) {
                    message.toAddresses = new String[] {serviceAlert.BD_Technician_Email__c};
                    emailAddresses = serviceAlert.BD_Technician_Email__c;
                }

//                // Get the Distribution List for this Service Alert
//                SMAX_PS_Service_Alert_PL_Email_Address__mdt distList = productLineToDistributionListMap.get(serviceAlert.SVMX_PS_Product_Line__c);
//
//                if (distList != null) {
//                    emailAddresses = distList.SMAX_PS_Email_Addresses__c;
//                    System.debug('Product Line Match Found - emailAddresses: ' + emailAddresses);
//                }
//
//                // Add the Ignore Product Line email addresses
//                if (ignorePLDistributionList.size() > 0) {
//                    for (SMAX_PS_Service_Alert_PL_Email_Address__mdt dl :ignorePLDistributionList) {
//                        emailAddresses = emailAddresses + ',' + dl.SMAX_PS_Email_Addresses__c;
//                    }
//                    emailAddresses = emailAddresses.removeStart(',');
//                }
                System.debug('emailAddresses: ' + emailAddresses);

                if (emailAddresses != null && emailAddresses != '') {
                    message.toAddresses = new List<String>(emailAddresses.split(','));

                    // 3/11/21 Tony - added as Unit Test will fail if there is not a Email body value found
                    if(Test.isRunningTest()){
                        message.plainTextBody = 'Test';
                    }

                    messages.add(message);
                    System.debug('Adding message to list: ' + message);
                } else {
                    //System.debug('No Match found for Product Line in Service Alert PL Email Address custom metadata');
                    System.debug('No Technician Email Address found for Service Alert');
                }
            }
        }

        if (messages.size() > 0) {
            System.debug('About to sendEmail: ' + messages);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

            for (Messaging.SendEmailResult result :results) {
                if (result.success) {
                    System.debug('The email was sent successfully.');
                } else {
                    System.debug('The email failed to send: ' +  result.errors[0].message);
                }
            }
        } else {
            System.debug('No messages to email: ' + messages);
        }
    }

    // ITSVMX-242 tony - Service Alert Notification Setup
    // Should be called from AfterInsert event trigger
    public static void sendServiceAlertCreationNotifications(List<SVMX_PS_Service_Alert__c> serviceAlertList){
        System.debug('Entering SMAX_PS_ServiceAlertManager.sendServiceAlertCreationNotifications()');
        System.debug('About to process Service Alerts: ' + serviceAlertList);

        // You have to have at least 1 contact record or the merge fields will not work properly
        List<Contact> mergeContacts = [
                SELECT Id, FirstName, LastName, Email
                FROM Contact
                WHERE LastName = 'Service Alert Email Notification'
                LIMIT 1
        ];
        if (mergeContacts.size() <> 1) {
            System.debug('ERROR: No Service Alert Email Notification contact has been created. '
                    + 'Please create a new contact with a LastName = "Service Alert Email Notification"');
            return;
        }

        // Get the Distribution Lists
        List<SMAX_PS_Service_Alert_PL_Email_Address__mdt> distributionList = [
                SELECT  Id, DeveloperName, SMAX_PS_Email_Addresses__c, SMAX_PS_Product_Line__c, SMAX_PS_Ignore_Product_Line__c
                FROM SMAX_PS_Service_Alert_PL_Email_Address__mdt
        ];
        System.debug('distributionList: ' + distributionList);

        if (distributionList.size() == 0) {
            System.debug('ERROR: No Service Alert PL Email Address custom metadata has been setup');
            return;
        }

        // Create Product Line Lookup Map and Ignore Product Line distribution list
        List<SMAX_PS_Service_Alert_PL_Email_Address__mdt> ignorePLDistributionList = new List<SMAX_PS_Service_Alert_PL_Email_Address__mdt>();
        Map<String, SMAX_PS_Service_Alert_PL_Email_Address__mdt> productLineToDistributionListMap = new Map<String, SMAX_PS_Service_Alert_PL_Email_Address__mdt>();
        for (SMAX_PS_Service_Alert_PL_Email_Address__mdt dl :distributionList) {

            if (dl.SMAX_PS_Ignore_Product_Line__c == true) {
                ignorePLDistributionList.add(dl);
            } else {
                productLineToDistributionListMap.put(dl.SMAX_PS_Product_Line__c, dl);
            }
        }

        // Get Email Templates
        String generalServiceAlertTemplate = 'SMAX_PS_General_Service_Alert_Created';
        String replacementServiceAlertTemplate = 'SMAX_PS_Replacement_Service_Alert_Created';
        String tsrAlertTemplate = 'SMAX_PS_TSR_Alert_Created';

        List<EmailTemplate> emailTemplates = [
                SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body
                FROM EmailTemplate
                WHERE DeveloperName = :generalServiceAlertTemplate
                OR DeveloperName = :replacementServiceAlertTemplate
            	OR DeveloperName = :tsrAlertTemplate
        ];
        System.debug('emailTemplates: ' + emailTemplates);

        Map<String, EmailTemplate> typeToEmailTemplate = new Map<String, EmailTemplate>();
        for (EmailTemplate emailTemplate :emailTemplates) {
            typeToEmailTemplate.put(emailTemplate.DeveloperName, emailTemplate);
        }

        if (typeToEmailTemplate.get(generalServiceAlertTemplate) == null) {
            System.debug('ERROR: Classic Email Template named [' + generalServiceAlertTemplate + '] does not exist.');
            return;
        }

        if (typeToEmailTemplate.get(replacementServiceAlertTemplate) == null) {
            System.debug('ERROR: Classic Email Template named [' + replacementServiceAlertTemplate + '] does not exist.');
            return;
        }

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();

        // Loop over Service Alerts
        for (SVMX_PS_Service_Alert__c serviceAlert :serviceAlertList) {

            System.debug('Inside Loop processing Service Alert: ' + serviceAlert);

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setTargetObjectId(mergeContacts[0].Id); // You have to have a Contact or merge fields won't work
            message.setSenderDisplayName('Service Alert Notification');
            message.setReplyTo('no-reply@perkinelmer.com');
            message.setUseSignature(false);
            message.setBccSender(false);
            message.setSaveAsActivity(false);
            message.setWhatId(serviceAlert.Id); //This is important for the merge fields in template to work

            // Send Notification to Product Line distribution list using the email template for General Alerts or Replacement Alerts
            if (serviceAlert.SVMX_PS_Record_Type_form__c == 'General Alert') {
                System.debug('General Service Alert: ' + serviceAlert);
                message.setTemplateId(typeToEmailTemplate.get(generalServiceAlertTemplate).Id);
            } else if (serviceAlert.SVMX_PS_Record_Type_form__c == 'Replacement Alert') {
                System.debug('Replacement Service Alert: ' + serviceAlert);
                message.setTemplateId(typeToEmailTemplate.get(replacementServiceAlertTemplate).Id);
            } else if (serviceAlert.SVMX_PS_Record_Type_form__c == 'Technical Support Request') {
                System.debug('TSR Alert: ' + serviceAlert);
                message.setTemplateId(typeToEmailTemplate.get(tsrAlertTemplate).Id);
            }
            System.debug('message TemplateId: ' + message.getTemplateId());

            // 01/29/2025 Added new email templates for new flows
            if(message.getTemplateId() == null) {
                System.debug('No Email Template found for Service Alert Record Type: ' + serviceAlert.SVMX_PS_Record_Type_form__c);
                return;
            }

            // Get the Distribution List for this Service Alert
            String emailAddresses = '';
            SMAX_PS_Service_Alert_PL_Email_Address__mdt distList = productLineToDistributionListMap.get(serviceAlert.SVMX_PS_Product_Line__c);

            if (distList != null) {
                emailAddresses = distList.SMAX_PS_Email_Addresses__c;
                System.debug('Product Line Match Found - emailAddresses: ' + emailAddresses);
            }

            // Add the Ignore Product Line email addresses
            if (ignorePLDistributionList.size() > 0) {
                for (SMAX_PS_Service_Alert_PL_Email_Address__mdt dl :ignorePLDistributionList) {
                    emailAddresses = emailAddresses + ',' + dl.SMAX_PS_Email_Addresses__c;
                }
                emailAddresses = emailAddresses.removeStart(',');
            }
            System.debug('emailAddresses: ' + emailAddresses);

            if (emailAddresses != null && emailAddresses != '') {
                message.toAddresses = new List<String>(emailAddresses.split(','));

                // 3/11/21 Tony - added as Unit Test will fail if there is not a Email body value found
                if(Test.isRunningTest()){
                    message.plainTextBody = 'Test';
                }

                messages.add(message);
                System.debug('Adding message to list: ' + message);
            } else {
                System.debug('No Match found for Product Line in Service Alert PL Email Address custom metadata');
            }
        }

        if (messages.size() > 0) {
            System.debug('About to sendEmail: ' + messages);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

            for (Messaging.SendEmailResult result :results) {
                if (result.success) {
                    System.debug('The email was sent successfully.');
                } else {
                    System.debug('The email failed to send: ' +  result.errors[0].message);
                }
            }
        } else {
            System.debug('No messages to email: ' + messages);
        }
    }

    // ITSVMX-242 tony - Service Alert Notification Setup
    // Called when Custom Action SFM updates the SVMX_PS_Manager_Approval_User__c field
    public static void submitServiceAlertForApproval(List<SVMX_PS_Service_Alert__c> serviceAlerts, Map<Id, SVMX_PS_Service_Alert__c> oldMap){

        for (SVMX_PS_Service_Alert__c serviceAlert :serviceAlerts) {
            SVMX_PS_Service_Alert__c old = (oldMap == null) ? null : oldMap.get(serviceAlert.Id);

            // ITSVMX-409 5/4/21 tony - Approve/Reject/Recall tab of replacement alert are missing when re-submit to approval
//            if (serviceAlert.SVMX_PS_Manager_Approval_User__c != null && old.SVMX_PS_Manager_Approval_User__c == null) {
            if (serviceAlert.SVMX_PS_Manager_Approval_User__c != null
                    && serviceAlert.SVMX_PS_Manager_Approval_User__c != old.SVMX_PS_Manager_Approval_User__c) {

                // Create an approval request for Service Alert
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments(serviceAlert.SVMX_PS_Submitter_Comments__c);
                req.setObjectId(serviceAlert.Id);
                req.setNextApproverIds(new Id[] {serviceAlert.SVMX_PS_Manager_Approval_User__c});
                //req.setSubmitterId();

                // Submit the approval request for the Service Alert
                Approval.ProcessResult result = Approval.process(req);
                System.debug('submitServiceAlertForApproval result: ' + result);
            }
        }
    }
 
}