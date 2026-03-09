@isTest (seeAllData = true)
private class SVMX_PS_ES_Email_Handler_Files_UT
{
    private static final String DEFAULT_CONTACT_ID = 'Default Contact ID';
    private static final String EMAIL_SERVICE_REPORT_FUNCT = 'Email Service Report Functionality';
    private static final String EXTENSIONS_SUPPORTED = 'Extensions Supported';
    private static final String OBJECTS_SUPPORTED = 'Objects Supported';
    private static final String SERVICE_REPORT_NAME = 'Service Report Name';
    private static final String STOP_BCC = 'Stop BCC';
    private static final String STOP_BCC_TO_ADDITIONAL_PEOPLE = 'Stop BCC to Additional People';
    private static final String STOP_BCC_TO_CURRENTUSER = 'Stop BCC to Current User';
    private static final String STOP_BCC_TO_OWNER = 'Stop BCC to Owner';
    private static final String STOP_CC = 'Stop CC';
    private static final String STOP_CC_TO_ADDTIONAL_PEOPLE = 'Stop CC to Additional People';
    private static final String STOP_CC_TO_CURRENT_USER = 'Stop CC to Current User';
    private static final String STOP_CC_TO_OWNER = 'Stop CC to Owner';
    private static final String STOP_EMAIL = 'Stop Email';
    private static final String STOP_EMAIL_TO_ADDITIONAL_PEOPLE = 'Stop Email to Additional People';
    private static final String STOP_EMAIL_TO_CONTACT = 'Stop Email to Contact';
    private static final String STOP_EMAIL_TO_CUSTOMER = 'Stop Email to Customer';
    private static final String STOP_EMAIL_TO_OWNER = 'Stop Email to Owner';
    private static final String SAVE_EMAIL_AS_ACTIVTIY = 'Save Send Email as Activity';
    private static final String GROUP_EMAILS = 'Group Emails';
    private static final String DEFAULT_EMAIL_ADDRESS = 'Default Email Address';
    private static final String SEND_TO_DEFAULT_EMAIL_ADDRESS = 'Send To Default Email Address';
    private static final String DEFAULT_BATCH_SIZE = 'Default Batch Size';

    /*
     * Tests if custom setting for email functionality is not active then no emails should be sent.
     */
    static testMethod void testEmailHandler0() {
        List<SVMX_PS_Services_Register__c> emailNotificationSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(emailNotificationSetting != null){
            for(SVMX_PS_Services_Register__c emailNotification : emailNotificationSetting){
                if(emailNotification.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    emailNotification.SVMX_PS_Is_Active__c = false;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update emailNotificationSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = false;
            insert newSetting;
        }

        SVMX_PS_ES_Email_Handler_Files_UT.createData();

        Test.StartTest();
        SVMX_PS_ES_Email_Handler_Files emailhandler = new SVMX_PS_ES_Email_Handler_Files();
        Database.executebatch(emailhandler, 8);
        Test.StopTest();
    }

    /*
     * Tests if custom setting for stop email is set then no emails should be sent.
     */
    static testMethod void testEmailHandler1() {
        List<SVMX_PS_Services_Register__c> emailNotificationSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(emailNotificationSetting != null){
            for(SVMX_PS_Services_Register__c emailNotification : emailNotificationSetting){
                if(emailNotification.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    emailNotification.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update emailNotificationSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_ES_Service_Report_Settings__c> emailServiceSetting = SVMX_PS_ES_Service_Report_Settings__c.getall().values();
        if(emailServiceSetting != null){
            delete emailServiceSetting;
        }
        emailServiceSetting = SVMX_PS_ES_Email_Handler_Files_UT.createEmailHandlerSettings();
        for(SVMX_PS_ES_Service_Report_Settings__c emailService : emailServiceSetting){
            if(emailService.Name.equals(STOP_EMAIL)){
                emailService.SVMX_PS_ES_Value__c = true;
            }
        }
        insert emailServiceSetting;

        SVMX_PS_ES_Email_Handler_Files_UT.createData();

        Test.StartTest();
        SVMX_PS_ES_Email_Handler_Files emailhandler = new SVMX_PS_ES_Email_Handler_Files();
        Database.executebatch(emailhandler, 8);
        Test.StopTest();
    }

    /*
     * Tests that if custom setting all to addresses are set, emails should be sent. Cc and Bcc Settings are off.
     */
    static testMethod void testEmailHandler2() {
        List<SVMX_PS_Services_Register__c> serviceRegisterSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(serviceRegisterSetting != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSetting){
                if(serviceRegister.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_ES_Org_Wide_Address_Settings__c> orgWideSettingList = SVMX_PS_ES_Org_Wide_Address_Settings__c.getall().values();
        isFound = false;
        if(orgWideSettingList != null){
            for(SVMX_PS_ES_Org_Wide_Address_Settings__c  orgWideSetting : orgWideSettingList){
                if((orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c != null &&
                        !orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c'))
                        || orgWideSetting.SVMX_PS_ES_Default__c){
                    isFound = true;
                    break;
                }
            }
        }
        if(!isFound){
            List<OrgWideEmailAddress> availableOrgWideEmailAddress = [SELECT DisplayName,Id,IsAllowAllProfiles
            FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = true];
            if(availableOrgWideEmailAddress != null && availableOrgWideEmailAddress.size() > 0){
                SVMX_PS_ES_Org_Wide_Address_Settings__c  newSetting = new SVMX_PS_ES_Org_Wide_Address_Settings__c   ();
                newSetting.Name = 'WorkOrderTestingXXX';
                newSetting.SVMX_PS_ES_Default__c = true;
                newSetting.SVMX_PS_ES_Org_Wide_Address__c = availableOrgWideEmailAddress.get(0).Id;
                newSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
                insert newSetting;
            }
        }


        List<SVMX_PS_ES_Service_Report_Settings__c> emailNotificationSetting = SVMX_PS_ES_Service_Report_Settings__c.getall().values();
        String contactId = null;
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailService : emailNotificationSetting){
                if(emailService.Name.equals(DEFAULT_CONTACT_ID)){
                    contactId = emailService.SVMX_PS_ES_Text_Value__c;
                }
            }

            delete emailNotificationSetting;
        }
        emailNotificationSetting = SVMX_PS_ES_Email_Handler_Files_UT.createEmailHandlerSettings();
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailService : emailNotificationSetting){
                if(emailService.Name.equals(STOP_BCC)){
                    emailService.SVMX_PS_ES_Value__c = true;
                }

                if(emailService.Name.equals(STOP_CC)){
                    emailService.SVMX_PS_ES_Value__c = true;
                }

                if(emailService.Name.equals(STOP_EMAIL_TO_ADDITIONAL_PEOPLE)){
                    emailService.SVMX_PS_ES_Value__c = true;
                }

                if(emailService.Name.equals(STOP_EMAIL_TO_CONTACT)){
                    emailService.SVMX_PS_ES_Value__c =  false;
                }

                if(emailService.Name.equals(STOP_EMAIL_TO_CUSTOMER)){
                    emailService.SVMX_PS_ES_Value__c =  false;
                }

                if(emailService.Name.equals(STOP_EMAIL_TO_OWNER)){
                    emailService.SVMX_PS_ES_Value__c =  false;
                }

                if(emailService.Name.equals(STOP_EMAIL)){
                    emailService.SVMX_PS_ES_Value__c =  false;
                }

                if(emailService.Name.equals(GROUP_EMAILS)){
                    emailService.SVMX_PS_ES_Value__c =  true;
                }

                if(emailService.Name.equals(EXTENSIONS_SUPPORTED)){
                    emailService.SVMX_PS_ES_Text_Value__c = 'PDF';
                }

                if(emailService.Name.equals(OBJECTS_SUPPORTED)){
                    emailService.SVMX_PS_ES_Text_Value__c = 'SVMXC__Service_Order__c';
                }

                if(emailService.Name.equals(DEFAULT_CONTACT_ID)){
                    emailService.SVMX_PS_ES_Text_Value__c = contactId;
                }
            }
        }
        insert emailNotificationSetting;

        boolean foundsetting = false;
        List<SVMX_PS_ES_Contact_Field_Mapping_Setting__c> contactFieldMappingList = SVMX_PS_ES_Contact_Field_Mapping_Setting__c.getall().values();
        if(contactFieldMappingList!= null && contactFieldMappingList.size() > 0){
            for(SVMX_PS_ES_Contact_Field_Mapping_Setting__c emailContactFieldMapSetting : contactFieldMappingList){
                if(emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c != null &&
                        !emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.equals('SVMXC__Contact__c') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c')){
                    foundsetting = true;
                    break;
                }
            }
        }
        if(!foundsetting){
            SVMX_PS_ES_Contact_Field_Mapping_Setting__c setting = new SVMX_PS_ES_Contact_Field_Mapping_Setting__c();
            setting.SVMX_PS_ES_Contact_Field_API_Name__c = 'SVMXC__Contact__c';
            setting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            setting.Name = 'WorkOrder1';
            insert setting;
        }

        SVMX_PS_ES_Service_Report_Name_Settings__c serviceReportSetting = null;
        List<SVMX_PS_ES_Service_Report_Name_Settings__c> emailServiceReportSettingsList = SVMX_PS_ES_Service_Report_Name_Settings__c.getAll().values();
        if(emailServiceReportSettingsList!= null && emailServiceReportSettingsList.size() > 0){
            for(SVMX_PS_ES_Service_Report_Name_Settings__c emailServiceReportNameSetting : emailServiceReportSettingsList){
                if(emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c != null
                        && !emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('')
                        && emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c == 'SVMXC__Service_Order__c'
                        && emailServiceReportNameSetting.SVMX_PS_ES_Record_Type_Name__c == null){
                    serviceReportSetting = emailServiceReportNameSetting;
                }
            }
        }
        if(serviceReportSetting == null){
            serviceReportSetting = new SVMX_PS_ES_Service_Report_Name_Settings__c();
            serviceReportSetting.Name = 'WorkOrderTestingXXX';
            serviceReportSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            serviceReportSetting.SVMX_PS_ES_Service_Report_Name__c = 'Service_Test_Report_XXX';
            insert serviceReportSetting;
        }else{
            serviceReportSetting.SVMX_PS_ES_Service_Report_Name__c = 'Service_Test_Report_XXX';
            update serviceReportSetting;
        }

        SVMX_PS_ES_Last_Run_Setting__c serviceLastRunSetting = null;
        List<SVMX_PS_ES_Last_Run_Setting__c> serviceLastRunSettingList = SVMX_PS_ES_Last_Run_Setting__c.getAll().values();
        if(serviceLastRunSettingList!= null && serviceLastRunSettingList.size() > 0){
            for(SVMX_PS_ES_Last_Run_Setting__c lastRunSetting : serviceLastRunSettingList){
                serviceLastRunSetting = lastRunSetting;
            }
        }
        if(serviceLastRunSetting == null){
            serviceLastRunSetting = new SVMX_PS_ES_Last_Run_Setting__c();
            serviceLastRunSetting.Name = 'Email Scheduler Last Run Time';
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = null;
            insert serviceLastRunSetting;
        }else{
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = null;
            update serviceLastRunSetting;
        }

        SVMXC__Service_Order__c wo = SVMX_PS_ES_Email_Handler_Files_UT.createData();
        wo.SVMX_PS_ES_Email_To_Customer__c = 'test@serviceuser.com';
        wo.SVMX_PS_ES_Send_Service_Report_To_Cust__c   = true;
        wo.SVMX_PS_ES_Send_Service_Report_To_Owner__c = true;
        wo.SVMX_PS_ES_Send_Service_ReportTo_Contact__c = true;
        wo.SVMX_PS_ES_Email_To_Additional_People__c = 'test1@serviceuser.com,test2@serviceuser.com,test3@serviceuser.com';
        wo.SVMX_PS_ES_Send_To_Additional_People__c = true;
        update wo;

        Test.StartTest();
        SVMX_PS_ES_Email_Handler_Files emailhandler = new SVMX_PS_ES_Email_Handler_Files();
        Database.executebatch(emailhandler, 8);
        Test.StopTest();
    }

    /*
     * Tests that if custom setting To addresses and Cc addresses are set,emails should be sent. Bcc Settings are off.
     */
    static testMethod void testEmailHandler3() {
        List<SVMX_PS_Services_Register__c> serviceRegisterSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(serviceRegisterSetting != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSetting){
                if(serviceRegister.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_ES_Org_Wide_Address_Settings__c> orgWideSettingList = SVMX_PS_ES_Org_Wide_Address_Settings__c.getall().values();
        isFound = false;
        if(orgWideSettingList != null){
            for(SVMX_PS_ES_Org_Wide_Address_Settings__c  orgWideSetting : orgWideSettingList){
                if((orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c != null &&
                        !orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c'))
                        || orgWideSetting.SVMX_PS_ES_Default__c){
                    isFound = true;
                    break;
                }
            }
        }
        if(!isFound){
            List<OrgWideEmailAddress> availableOrgWideEmailAddress = [SELECT DisplayName,Id,IsAllowAllProfiles
            FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = true];
            if(availableOrgWideEmailAddress != null && availableOrgWideEmailAddress.size() > 0){
                SVMX_PS_ES_Org_Wide_Address_Settings__c  newSetting = new SVMX_PS_ES_Org_Wide_Address_Settings__c   ();
                newSetting.Name = 'WorkOrderTestingXXX';
                newSetting.SVMX_PS_ES_Default__c = true;
                newSetting.SVMX_PS_ES_Org_Wide_Address__c = availableOrgWideEmailAddress.get(0).Id;
                newSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
                insert newSetting;
            }
        }

        List<SVMX_PS_ES_Service_Report_Settings__c> emailNotificationSetting = SVMX_PS_ES_Service_Report_Settings__c.getall().values();
        String contactId = null;
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailService : emailNotificationSetting){
                if(emailService.Name.equals(DEFAULT_CONTACT_ID)){
                    contactId = emailService.SVMX_PS_ES_Text_Value__c;
                }
            }

            delete emailNotificationSetting;
        }
        emailNotificationSetting = SVMX_PS_ES_Email_Handler_Files_UT.createEmailHandlerSettings();
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailNotification : emailNotificationSetting){
                if(emailNotification.Name.equals(STOP_BCC)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CONTACT)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CUSTOMER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_ADDTIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_CURRENT_USER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(GROUP_EMAILS)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(EXTENSIONS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'PDF';
                }
                else if(emailNotification.Name.equals(OBJECTS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'SVMXC__Service_Order__c';
                }
                else if(emailNotification.Name.equals(DEFAULT_CONTACT_ID)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = contactId;
                }
            }
        }
        insert emailNotificationSetting;

        boolean foundsetting = false;
        List<SVMX_PS_ES_Contact_Field_Mapping_Setting__c> contactFieldMappingList = SVMX_PS_ES_Contact_Field_Mapping_Setting__c.getall().values();
        if(contactFieldMappingList!= null && contactFieldMappingList.size() > 0){
            for(SVMX_PS_ES_Contact_Field_Mapping_Setting__c emailContactFieldMapSetting : contactFieldMappingList){
                if(emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c != null &&
                        !emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.equals('SVMXC__Contact__c') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c')){
                    foundsetting = true;
                    break;
                }
            }
        }
        if(!foundsetting){
            SVMX_PS_ES_Contact_Field_Mapping_Setting__c setting = new SVMX_PS_ES_Contact_Field_Mapping_Setting__c();
            setting.SVMX_PS_ES_Contact_Field_API_Name__c = 'SVMXC__Contact__c';
            setting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            setting.Name = 'WorkOrder1';
            insert setting;
        }

        SVMX_PS_ES_Service_Report_Name_Settings__c serviceReportSetting = null;
        List<SVMX_PS_ES_Service_Report_Name_Settings__c> emailServiceReportSettingsList = SVMX_PS_ES_Service_Report_Name_Settings__c.getAll().values();
        if(emailServiceReportSettingsList!= null && emailServiceReportSettingsList.size() > 0){
            for(SVMX_PS_ES_Service_Report_Name_Settings__c emailServiceReportNameSetting : emailServiceReportSettingsList){
                if(emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c != null
                        && !emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('')
                        && emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c == 'SVMXC__Service_Order__c'
                        && emailServiceReportNameSetting.SVMX_PS_ES_Record_Type_Name__c == null){
                    serviceReportSetting = emailServiceReportNameSetting;
                }
            }
        }
        if(serviceReportSetting == null){
            serviceReportSetting = new SVMX_PS_ES_Service_Report_Name_Settings__c();
            serviceReportSetting.Name = 'WorkOrderTestingXXX';
            serviceReportSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            serviceReportSetting.SVMX_PS_ES_Service_Report_Name__c = 'Service_Test_Report_XXX';
            insert serviceReportSetting;
        }else{
            serviceReportSetting.SVMX_PS_ES_Service_Report_Name__c = 'Service_Test_Report_XXX';
            update serviceReportSetting;
        }

        SVMX_PS_ES_Last_Run_Setting__c serviceLastRunSetting = null;
        List<SVMX_PS_ES_Last_Run_Setting__c> serviceLastRunSettingList = SVMX_PS_ES_Last_Run_Setting__c.getAll().values();
        if(serviceLastRunSettingList!= null && serviceLastRunSettingList.size() > 0){
            for(SVMX_PS_ES_Last_Run_Setting__c lastRunSetting : serviceLastRunSettingList){
                serviceLastRunSetting = lastRunSetting;
            }
        }
        if(serviceLastRunSetting != null){
            delete serviceLastRunSetting;
        }

        SVMXC__Service_Order__c wo = SVMX_PS_ES_Email_Handler_Files_UT.createData();
        wo.SVMX_PS_ES_Email_To_Customer__c = 'test@serviceuser.com';
        wo.SVMX_PS_ES_Send_Service_Report_To_Cust__c  = true;
        wo.SVMX_PS_ES_Send_Service_Report_To_Owner__c = true;
        wo.SVMX_PS_ES_Send_Service_ReportTo_Contact__c = true;
        wo.SVMX_PS_ES_Email_To_Additional_People__c = 'test1@serviceuser.com,test2@serviceuser.com,test3@serviceuser.com';
        wo.SVMX_PS_ES_Send_To_Additional_People__c = true;
        wo.SVMX_PS_ES_Cc_Current_User__c = true;
        wo.SVMX_PS_ES_Cc_Owner__c = true;
        wo.SVMX_PS_ES_Cc_Email_Additional_People__c = 'test4@serviceuser.com,test5@serviceuser.com,test6@serviceuser.com';
        wo.SVMX_PS_ES_Cc_Additional_People__c = true;
        update wo;

        Test.StartTest();
        SVMX_PS_ES_Email_Handler_Files emailhandler = new SVMX_PS_ES_Email_Handler_Files();
        Database.executebatch(emailhandler, 8);
        Test.StopTest();
    }

    /*
     * Tests that if custom setting To addresses, Cc and Bcc addresses are set, emails should be sent.
     */
    static testMethod void testEmailHandler4() {
        List<SVMX_PS_Services_Register__c> serviceRegisterSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(serviceRegisterSetting != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSetting){
                if(serviceRegister.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_ES_Org_Wide_Address_Settings__c> orgWideSettingList = SVMX_PS_ES_Org_Wide_Address_Settings__c.getall().values();
        isFound = false;
        if(orgWideSettingList != null){
            for(SVMX_PS_ES_Org_Wide_Address_Settings__c  orgWideSetting : orgWideSettingList){
                if((orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c != null &&
                        !orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c'))
                        || orgWideSetting.SVMX_PS_ES_Default__c){
                    isFound = true;
                    break;
                }
            }
        }
        if(!isFound){
            List<OrgWideEmailAddress> availableOrgWideEmailAddress = [SELECT DisplayName,Id,IsAllowAllProfiles
            FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = true];
            if(availableOrgWideEmailAddress != null && availableOrgWideEmailAddress.size() > 0){
                SVMX_PS_ES_Org_Wide_Address_Settings__c  newSetting = new SVMX_PS_ES_Org_Wide_Address_Settings__c   ();
                newSetting.Name = 'WorkOrderTestingXXX';
                newSetting.SVMX_PS_ES_Default__c = true;
                newSetting.SVMX_PS_ES_Org_Wide_Address__c = availableOrgWideEmailAddress.get(0).Id;
                newSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
                insert newSetting;
            }
        }

        List<SVMX_PS_ES_Service_Report_Settings__c> emailNotificationSetting = SVMX_PS_ES_Service_Report_Settings__c.getall().values();
        String contactId = null;
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailService : emailNotificationSetting){
                if(emailService.Name.equals(DEFAULT_CONTACT_ID)){
                    contactId = emailService.SVMX_PS_ES_Text_Value__c;
                }
            }

            delete emailNotificationSetting;
        }
        emailNotificationSetting = SVMX_PS_ES_Email_Handler_Files_UT.createEmailHandlerSettings();
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailNotification : emailNotificationSetting){
                if(emailNotification.Name.equals(STOP_EMAIL_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CONTACT)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CUSTOMER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_ADDTIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_CURRENT_USER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_CURRENTUSER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(GROUP_EMAILS)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(EXTENSIONS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'PDF';
                }
                else if(emailNotification.Name.equals(OBJECTS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'SVMXC__Service_Order__c';
                }
                else if(emailNotification.Name.equals(DEFAULT_CONTACT_ID)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = contactId;
                }
            }
        }
        insert emailNotificationSetting;

        boolean foundsetting = false;
        List<SVMX_PS_ES_Contact_Field_Mapping_Setting__c> contactFieldMappingList = SVMX_PS_ES_Contact_Field_Mapping_Setting__c.getall().values();
        if(contactFieldMappingList!= null && contactFieldMappingList.size() > 0){
            for(SVMX_PS_ES_Contact_Field_Mapping_Setting__c emailContactFieldMapSetting : contactFieldMappingList){
                if(emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c != null &&
                        !emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.equals('SVMXC__Contact__c') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c')){
                    foundsetting = true;
                    break;
                }
            }
        }
        if(!foundsetting){
            SVMX_PS_ES_Contact_Field_Mapping_Setting__c setting = new SVMX_PS_ES_Contact_Field_Mapping_Setting__c();
            setting.SVMX_PS_ES_Contact_Field_API_Name__c = 'SVMXC__Contact__c';
            setting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            setting.Name = 'WorkOrder1';
            insert setting;
        }

        SVMX_PS_ES_Service_Report_Name_Settings__c serviceReportSetting = null;
        List<SVMX_PS_ES_Service_Report_Name_Settings__c> emailServiceReportSettingsList = SVMX_PS_ES_Service_Report_Name_Settings__c.getAll().values();
        if(emailServiceReportSettingsList!= null && emailServiceReportSettingsList.size() > 0){
            for(SVMX_PS_ES_Service_Report_Name_Settings__c emailServiceReportNameSetting : emailServiceReportSettingsList){
                if(emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c != null
                        && !emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('')
                        && emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c == 'SVMXC__Service_Order__c'
                        && emailServiceReportNameSetting.SVMX_PS_ES_Record_Type_Name__c == null){
                    serviceReportSetting = emailServiceReportNameSetting;
                }
            }
        }
        if(serviceReportSetting == null){
            serviceReportSetting = new SVMX_PS_ES_Service_Report_Name_Settings__c();
            serviceReportSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            serviceReportSetting.SVMX_PS_ES_Service_Report_Name__c = 'Service_Test_Report_XXX';
            serviceReportSetting.Name = 'WorkOrderTestingXXX';
            insert serviceReportSetting;
        }else{
            serviceReportSetting.SVMX_PS_ES_Service_Report_Name__c = 'Service_Test_Report_XXX';
            update serviceReportSetting;
        }

        SVMX_PS_ES_Last_Run_Setting__c serviceLastRunSetting = null;
        List<SVMX_PS_ES_Last_Run_Setting__c> serviceLastRunSettingList = SVMX_PS_ES_Last_Run_Setting__c.getAll().values();
        if(serviceLastRunSettingList!= null && serviceLastRunSettingList.size() > 0){
            for(SVMX_PS_ES_Last_Run_Setting__c lastRunSetting : serviceLastRunSettingList){
                serviceLastRunSetting = lastRunSetting;
            }
        }
        if(serviceLastRunSetting == null){
            serviceLastRunSetting = new SVMX_PS_ES_Last_Run_Setting__c();
            serviceLastRunSetting.Name = 'Email Scheduler Last Run Time';
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            insert serviceLastRunSetting;
        }else{
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            update serviceLastRunSetting;
        }

        SVMXC__Service_Order__c wo = SVMX_PS_ES_Email_Handler_Files_UT.createData();
        wo.SVMX_PS_ES_Email_To_Customer__c = 'test@serviceuser.com';
        wo.SVMX_PS_ES_Send_Service_Report_To_Cust__c  = true;
        wo.SVMX_PS_ES_Send_Service_Report_To_Owner__c = false;
        wo.SVMX_PS_ES_Send_Service_ReportTo_Contact__c = false;
        wo.SVMX_PS_ES_Email_To_Additional_People__c = 'test1@serviceuser.com,test2@serviceuser.com,test3@serviceuser.com';
        wo.SVMX_PS_ES_Send_To_Additional_People__c = true;
        wo.SVMX_PS_ES_Cc_Current_User__c = false;
        wo.SVMX_PS_ES_Cc_Owner__c = false;
        wo.SVMX_PS_ES_Cc_Email_Additional_People__c = 'test4@serviceuser.com,test5@serviceuser.com,test6@serviceuser.com';
        wo.SVMX_PS_ES_Cc_Additional_People__c = true;
        wo.SVMX_PS_ES_Bcc_Current_User__c  = true;
        wo.SVMX_PS_ES_Bcc_Owner__c  = true;
        wo.SVMX_PS_ES_Bcc_Email_Additional_People__c = 'test7@serviceuser.com,test8@serviceuser.com,test9@serviceuser.com';
        wo.SVMX_PS_ES_Bcc_Additional_People__c  = true;
        update wo;

        Test.StartTest();
        SVMX_PS_ES_Email_Handler_Files emailhandler = new SVMX_PS_ES_Email_Handler_Files();
        Database.executebatch(emailhandler, 8);
        Test.StopTest();
    }

    /*
     * Tests that if custom setting To addresses, Cc and Bcc addresses are set, emails should be sent.
     * No tasks should be created and emails should not be grouped.
     */
    static testMethod void testEmailHandler5() {
        List<SVMX_PS_Services_Register__c> serviceRegisterSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(serviceRegisterSetting != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSetting){
                if(serviceRegister.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_ES_Org_Wide_Address_Settings__c> orgWideSettingList = SVMX_PS_ES_Org_Wide_Address_Settings__c.getall().values();
        isFound = false;
        if(orgWideSettingList != null){
            for(SVMX_PS_ES_Org_Wide_Address_Settings__c  orgWideSetting : orgWideSettingList){
                if((orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c != null &&
                        !orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c'))
                        || orgWideSetting.SVMX_PS_ES_Default__c){
                    isFound = true;
                    break;
                }
            }
        }
        if(!isFound){
            List<OrgWideEmailAddress> availableOrgWideEmailAddress = [SELECT DisplayName,Id,IsAllowAllProfiles
            FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = true];
            if(availableOrgWideEmailAddress != null && availableOrgWideEmailAddress.size() > 0){
                SVMX_PS_ES_Org_Wide_Address_Settings__c  newSetting = new SVMX_PS_ES_Org_Wide_Address_Settings__c   ();
                newSetting.Name = 'WorkOrderTestingXXX';
                newSetting.SVMX_PS_ES_Default__c = true;
                newSetting.SVMX_PS_ES_Org_Wide_Address__c = availableOrgWideEmailAddress.get(0).Id;
                newSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
                insert newSetting;
            }
        }

        List<SVMX_PS_ES_Service_Report_Settings__c> emailNotificationSetting = SVMX_PS_ES_Service_Report_Settings__c.getall().values();
        String contactId = null;
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailService : emailNotificationSetting){
                if(emailService.Name.equals(DEFAULT_CONTACT_ID)){
                    contactId = emailService.SVMX_PS_ES_Text_Value__c;
                }
            }

            delete emailNotificationSetting;
        }
        emailNotificationSetting = SVMX_PS_ES_Email_Handler_Files_UT.createEmailHandlerSettings();
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailNotification : emailNotificationSetting){
                if(emailNotification.Name.equals(STOP_EMAIL_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CONTACT)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CUSTOMER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_ADDTIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_CURRENT_USER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_CURRENTUSER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(SAVE_EMAIL_AS_ACTIVTIY)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(GROUP_EMAILS)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(EXTENSIONS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'PDF';
                }
                else if(emailNotification.Name.equals(OBJECTS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'SVMXC__Service_Order__c';
                }
                else if(emailNotification.Name.equals(DEFAULT_EMAIL_ADDRESS)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'testvalue@test.com';
                }
                else if(emailNotification.Name.equals(SEND_TO_DEFAULT_EMAIL_ADDRESS)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(DEFAULT_CONTACT_ID)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = contactId;
                }
            }
        }
        insert emailNotificationSetting;

        boolean foundsetting = false;
        List<SVMX_PS_ES_Contact_Field_Mapping_Setting__c> contactFieldMappingList = SVMX_PS_ES_Contact_Field_Mapping_Setting__c.getall().values();
        if(contactFieldMappingList!= null && contactFieldMappingList.size() > 0){
            for(SVMX_PS_ES_Contact_Field_Mapping_Setting__c emailContactFieldMapSetting : contactFieldMappingList){
                if(emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c != null &&
                        !emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.equals('SVMXC__Contact__c') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c')){
                    foundsetting = true;
                    break;
                }
            }
        }
        if(!foundsetting){
            SVMX_PS_ES_Contact_Field_Mapping_Setting__c setting = new SVMX_PS_ES_Contact_Field_Mapping_Setting__c();
            setting.SVMX_PS_ES_Contact_Field_API_Name__c = 'SVMXC__Contact__c';
            setting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            setting.Name = 'WorkOrder1';
            insert setting;
        }

        SVMX_PS_ES_Service_Report_Name_Settings__c serviceReportSetting = null;
        List<SVMX_PS_ES_Service_Report_Name_Settings__c> emailServiceReportSettingsList = SVMX_PS_ES_Service_Report_Name_Settings__c.getAll().values();
        if(emailServiceReportSettingsList!= null && emailServiceReportSettingsList.size() > 0){
            for(SVMX_PS_ES_Service_Report_Name_Settings__c emailServiceReportNameSetting : emailServiceReportSettingsList){
                if(emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c != null
                        && !emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('')
                        && emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c == 'SVMXC__Service_Order__c'
                        && emailServiceReportNameSetting.SVMX_PS_ES_Record_Type_Name__c == null){
                    serviceReportSetting = emailServiceReportNameSetting;
                }
            }
        }
        if(serviceReportSetting == null){
            serviceReportSetting = new SVMX_PS_ES_Service_Report_Name_Settings__c();
            serviceReportSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            serviceReportSetting.SVMX_PS_ES_Service_Report_Name__c = 'Service_Test_Report_XXX';
            serviceReportSetting.Name = 'WorkOrderTestingXXX';
            insert serviceReportSetting;
        }else{
            serviceReportSetting.SVMX_PS_ES_Service_Report_Name__c = 'Service_Test_Report_XXX';
            update serviceReportSetting;
        }

        SVMX_PS_ES_Last_Run_Setting__c serviceLastRunSetting = null;
        List<SVMX_PS_ES_Last_Run_Setting__c> serviceLastRunSettingList = SVMX_PS_ES_Last_Run_Setting__c.getAll().values();
        if(serviceLastRunSettingList!= null && serviceLastRunSettingList.size() > 0){
            for(SVMX_PS_ES_Last_Run_Setting__c lastRunSetting : serviceLastRunSettingList){
                serviceLastRunSetting = lastRunSetting;
            }
        }
        if(serviceLastRunSetting == null){
            serviceLastRunSetting = new SVMX_PS_ES_Last_Run_Setting__c();
            serviceLastRunSetting.Name = 'Email Scheduler Last Run Time';
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            insert serviceLastRunSetting;
        }else{
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            update serviceLastRunSetting;
        }

        SVMXC__Service_Order__c wo = SVMX_PS_ES_Email_Handler_Files_UT.createData();
        wo.SVMX_PS_ES_Email_To_Customer__c = 'test@serviceuser.com';
        wo.SVMX_PS_ES_Send_Service_Report_To_Cust__c  = true;
        wo.SVMX_PS_ES_Send_Service_Report_To_Owner__c = true;
        wo.SVMX_PS_ES_Send_Service_ReportTo_Contact__c = true;
        wo.SVMX_PS_ES_Email_To_Additional_People__c = 'test1@serviceuser.com,test2@serviceuser.com,test3@serviceuser.com';
        wo.SVMX_PS_ES_Send_To_Additional_People__c = true;
        wo.SVMX_PS_ES_Cc_Current_User__c = true;
        wo.SVMX_PS_ES_Cc_Owner__c = true;
        wo.SVMX_PS_ES_Cc_Email_Additional_People__c = 'test4@serviceuser.com,test5@serviceuser.com,test6@serviceuser.com';
        wo.SVMX_PS_ES_Cc_Additional_People__c = true;
        wo.SVMX_PS_ES_Bcc_Current_User__c  = true;
        wo.SVMX_PS_ES_Bcc_Owner__c  = true;
        wo.SVMX_PS_ES_Bcc_Email_Additional_People__c = 'test7@serviceuser.com,test8@serviceuser.com,test9@serviceuser.com';
        wo.SVMX_PS_ES_Bcc_Additional_People__c  = true;
        update wo;

        Test.StartTest();
        SVMX_PS_ES_Email_Handler_Files emailhandler = new SVMX_PS_ES_Email_Handler_Files();
        Database.executebatch(emailhandler, 8);
        Test.StopTest();
    }

    /*
     * Tests if custom setting To addresses, Cc and Bcc addresses are set, emails should be sent
     * But no tasks should be created and emails should be grouped
     * Extensions supported are JPEG and PNG
     * Send email to default address
     */
    static testMethod void testEmailHandler6() {
        List<SVMX_PS_Services_Register__c> serviceRegisterSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(serviceRegisterSetting != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSetting){
                if(serviceRegister.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_ES_Org_Wide_Address_Settings__c> orgWideSettingList = SVMX_PS_ES_Org_Wide_Address_Settings__c.getall().values();
        isFound = false;
        if(orgWideSettingList != null){
            for(SVMX_PS_ES_Org_Wide_Address_Settings__c  orgWideSetting : orgWideSettingList){
                if((orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c != null &&
                        !orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c'))
                        || orgWideSetting.SVMX_PS_ES_Default__c){
                    isFound = true;
                    break;
                }
            }
        }
        if(!isFound){
            List<OrgWideEmailAddress> availableOrgWideEmailAddress = [SELECT DisplayName,Id,IsAllowAllProfiles
            FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = true];
            if(availableOrgWideEmailAddress != null && availableOrgWideEmailAddress.size() > 0){
                SVMX_PS_ES_Org_Wide_Address_Settings__c  newSetting = new SVMX_PS_ES_Org_Wide_Address_Settings__c   ();
                newSetting.Name = 'WorkOrderTestingXXX';
                newSetting.SVMX_PS_ES_Default__c = true;
                newSetting.SVMX_PS_ES_Org_Wide_Address__c = availableOrgWideEmailAddress.get(0).Id;
                newSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
                insert newSetting;
            }
        }

        List<SVMX_PS_ES_Service_Report_Settings__c> emailNotificationSetting = SVMX_PS_ES_Service_Report_Settings__c.getall().values();
        String contactId = null;
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailService : emailNotificationSetting){
                if(emailService.Name.equals(DEFAULT_CONTACT_ID)){
                    contactId = emailService.SVMX_PS_ES_Text_Value__c;
                }
            }

            delete emailNotificationSetting;
        }
        emailNotificationSetting = SVMX_PS_ES_Email_Handler_Files_UT.createEmailHandlerSettings();
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailNotification : emailNotificationSetting){
                if(emailNotification.Name.equals(STOP_EMAIL_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CONTACT)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CUSTOMER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_ADDTIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_CURRENT_USER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_CURRENTUSER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(SAVE_EMAIL_AS_ACTIVTIY)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(GROUP_EMAILS)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(EXTENSIONS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'JPEG,PNG';
                }
                else if(emailNotification.Name.equals(DEFAULT_EMAIL_ADDRESS)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'testvalue@test.com';
                }
                else if(emailNotification.Name.equals(SEND_TO_DEFAULT_EMAIL_ADDRESS)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(OBJECTS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'SVMXC__Service_Order__c';
                }
                else if(emailNotification.Name.equals(DEFAULT_CONTACT_ID)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = contactId;
                }
            }
        }
        insert emailNotificationSetting;

        boolean foundsetting = false;
        List<SVMX_PS_ES_Contact_Field_Mapping_Setting__c> contactFieldMappingList = SVMX_PS_ES_Contact_Field_Mapping_Setting__c.getall().values();
        if(contactFieldMappingList!= null && contactFieldMappingList.size() > 0){
            for(SVMX_PS_ES_Contact_Field_Mapping_Setting__c emailContactFieldMapSetting : contactFieldMappingList){
                if(emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c != null &&
                        !emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.equals('SVMXC__Contact__c') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c')){
                    foundsetting = true;
                    break;
                }
            }
        }
        if(!foundsetting){
            SVMX_PS_ES_Contact_Field_Mapping_Setting__c setting = new SVMX_PS_ES_Contact_Field_Mapping_Setting__c();
            setting.SVMX_PS_ES_Contact_Field_API_Name__c = 'SVMXC__Contact__c';
            setting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            setting.Name = 'WorkOrder1';
            insert setting;
        }

        SVMX_PS_ES_Service_Report_Name_Settings__c serviceReportSetting = null;
        List<SVMX_PS_ES_Service_Report_Name_Settings__c> emailServiceReportSettingsList = SVMX_PS_ES_Service_Report_Name_Settings__c.getAll().values();
        if(emailServiceReportSettingsList!= null && emailServiceReportSettingsList.size() > 0){
            for(SVMX_PS_ES_Service_Report_Name_Settings__c emailServiceReportNameSetting : emailServiceReportSettingsList){
                if(emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c != null
                        && !emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('')
                        && emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c == 'SVMXC__Service_Order__c'
                        && emailServiceReportNameSetting.SVMX_PS_ES_Record_Type_Name__c == null){
                    serviceReportSetting = emailServiceReportNameSetting;
                }
            }
        }
        if(serviceReportSetting == null){
            serviceReportSetting = new SVMX_PS_ES_Service_Report_Name_Settings__c();
            serviceReportSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            serviceReportSetting.SVMX_PS_ES_Service_Report_Name__c = 'Service_Test_Report_XXX';
            serviceReportSetting.Name = 'WorkOrderTestingXXX';
            insert serviceReportSetting;
        }else{
            serviceReportSetting.SVMX_PS_ES_Service_Report_Name__c = 'Service_Test_Report_XXX';
            update serviceReportSetting;
        }

        SVMX_PS_ES_Last_Run_Setting__c serviceLastRunSetting = null;
        List<SVMX_PS_ES_Last_Run_Setting__c> serviceLastRunSettingList = SVMX_PS_ES_Last_Run_Setting__c.getAll().values();
        if(serviceLastRunSettingList!= null && serviceLastRunSettingList.size() > 0){
            for(SVMX_PS_ES_Last_Run_Setting__c lastRunSetting : serviceLastRunSettingList){
                serviceLastRunSetting = lastRunSetting;
            }
        }
        if(serviceLastRunSetting == null){
            serviceLastRunSetting = new SVMX_PS_ES_Last_Run_Setting__c();
            serviceLastRunSetting.Name = 'Email Scheduler Last Run Time';
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            insert serviceLastRunSetting;
        }else{
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            update serviceLastRunSetting;
        }

        String emailTemplateId = null;
        List<SVMX_PS_ES_Template_Settings__c> emailtemplateSettingsList = SVMX_PS_ES_Template_Settings__c.getAll().values();
        if(emailtemplateSettingsList!= null && emailtemplateSettingsList.size() > 0){
            for(SVMX_PS_ES_Template_Settings__c emailTemplateSetting : emailtemplateSettingsList){
                if(emailTemplateSetting.SVMX_PS_ES_Template_Unique_Name__c != null
                        && !emailTemplateSetting.SVMX_PS_ES_Template_Unique_Name__c.trim().equals('')){
                    emailTemplateId = emailTemplateSetting.SVMX_PS_ES_Template_Unique_Name__c ;
                    break;
                }
            }
            if(emailTemplateId != null && !emailTemplateId.trim().equals('')){
                delete emailtemplateSettingsList;
            }else{
                List<EmailTemplate> emailTemplateBaseList = [Select Id, Name, DeveloperName
                from EmailTemplate where DeveloperName = 'Work_Order_Service_Report_Email'];
                if(emailTemplateBaseList != null && emailTemplateBaseList.size() > 0){
                    emailTemplateId = emailTemplateBaseList.get(0).Id;
                }else{
                    emailTemplateBaseList = [Select Id, Name, DeveloperName from EmailTemplate Limit 2];
                    if(emailTemplateBaseList != null && emailTemplateBaseList.size() > 0){
                        emailTemplateId = emailTemplateBaseList.get(0).Id;
                    }
                }
            }
        }

        if(emailTemplateId != null){
            SVMX_PS_ES_Template_Settings__c emailTemplateSetting = new SVMX_PS_ES_Template_Settings__c();
            emailTemplateSetting.Name = 'Test1';
            emailTemplateSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            emailTemplateSetting.SVMX_PS_ES_Template_Unique_Name__c = emailTemplateId;
            emailTemplateSetting.SVMX_PS_ES_Default__c = true;
            insert emailTemplateSetting;
        }

        SVMXC__Service_Order__c wo = SVMX_PS_ES_Email_Handler_Files_UT.createData();
        wo.SVMX_PS_ES_Email_To_Customer__c = 'test@serviceuser.com';
        wo.SVMX_PS_ES_Send_Service_Report_To_Cust__c  = true;
        wo.SVMX_PS_ES_Send_Service_Report_To_Owner__c = false;
        wo.SVMX_PS_ES_Send_Service_ReportTo_Contact__c = false;
        wo.SVMX_PS_ES_Email_To_Additional_People__c = 'test1@serviceuser.com,test2@serviceuser.com,test3@serviceuser.com';
        wo.SVMX_PS_ES_Send_To_Additional_People__c = true;
        wo.SVMX_PS_ES_Cc_Current_User__c = false;
        wo.SVMX_PS_ES_Cc_Owner__c = false;
        wo.SVMX_PS_ES_Cc_Email_Additional_People__c = 'test4@serviceuser.com,test5@serviceuser.com,test6@serviceuser.com';
        wo.SVMX_PS_ES_Cc_Additional_People__c = true;
        wo.SVMX_PS_ES_Bcc_Current_User__c  = true;
        wo.SVMX_PS_ES_Bcc_Owner__c  = true;
        wo.SVMX_PS_ES_Bcc_Email_Additional_People__c = 'test7@serviceuser.com,test8@serviceuser.com,test9@serviceuser.com';
        wo.SVMX_PS_ES_Bcc_Additional_People__c  = true;
        update wo;

        Test.StartTest();
        SVMX_PS_ES_Email_Handler_Files emailhandler = new SVMX_PS_ES_Email_Handler_Files();
        Database.executebatch(emailhandler, 8);
        Test.StopTest();
    }

    /*
     * Tests if custom setting sets no To addresses, but Cc and Bcc addresses are set, emails should not be sent.
     */
    static testMethod void testEmailHandler7() {
        List<SVMX_PS_Services_Register__c> serviceRegisterSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(serviceRegisterSetting != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSetting){
                if(serviceRegister.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_ES_Org_Wide_Address_Settings__c> orgWideSettingList = SVMX_PS_ES_Org_Wide_Address_Settings__c.getall().values();
        isFound = false;
        if(orgWideSettingList != null){
            for(SVMX_PS_ES_Org_Wide_Address_Settings__c  orgWideSetting : orgWideSettingList){
                if((orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c != null &&
                        !orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c'))
                        || orgWideSetting.SVMX_PS_ES_Default__c){
                    isFound = true;
                    break;
                }
            }
        }
        if(!isFound){
            List<OrgWideEmailAddress> availableOrgWideEmailAddress = [SELECT DisplayName,Id,IsAllowAllProfiles
            FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = true];
            if(availableOrgWideEmailAddress != null && availableOrgWideEmailAddress.size() > 0){
                SVMX_PS_ES_Org_Wide_Address_Settings__c  newSetting = new SVMX_PS_ES_Org_Wide_Address_Settings__c   ();
                newSetting.Name = 'WorkOrderTestingXXX';
                newSetting.SVMX_PS_ES_Default__c = true;
                newSetting.SVMX_PS_ES_Org_Wide_Address__c = availableOrgWideEmailAddress.get(0).Id;
                newSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
                insert newSetting;
            }
        }

        List<SVMX_PS_ES_Service_Report_Settings__c> emailNotificationSetting = SVMX_PS_ES_Service_Report_Settings__c.getall().values();
        String contactId = null;
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailService : emailNotificationSetting){
                if(emailService.Name.equals(DEFAULT_CONTACT_ID)){
                    contactId = emailService.SVMX_PS_ES_Text_Value__c;
                }
            }

            delete emailNotificationSetting;
        }
        emailNotificationSetting = SVMX_PS_ES_Email_Handler_Files_UT.createEmailHandlerSettings();
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailNotification : emailNotificationSetting){
                if(emailNotification.Name.equals(STOP_EMAIL_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CONTACT)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CUSTOMER)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(STOP_CC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_ADDTIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_CURRENT_USER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_CURRENTUSER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(GROUP_EMAILS)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(EXTENSIONS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'PDF';
                }
                else if(emailNotification.Name.equals(OBJECTS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'SVMXC__Service_Order__c';
                }
                else if(emailNotification.Name.equals(DEFAULT_CONTACT_ID)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = contactId;
                }
            }
        }
        insert emailNotificationSetting;

        boolean foundsetting = false;
        List<SVMX_PS_ES_Contact_Field_Mapping_Setting__c> contactFieldMappingList = SVMX_PS_ES_Contact_Field_Mapping_Setting__c.getall().values();
        if(contactFieldMappingList!= null && contactFieldMappingList.size() > 0){
            for(SVMX_PS_ES_Contact_Field_Mapping_Setting__c emailContactFieldMapSetting : contactFieldMappingList){
                if(emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c != null &&
                        !emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.equals('SVMXC__Contact__c') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c')){
                    foundsetting = true;
                    break;
                }
            }
        }
        if(!foundsetting){
            SVMX_PS_ES_Contact_Field_Mapping_Setting__c setting = new SVMX_PS_ES_Contact_Field_Mapping_Setting__c();
            setting.SVMX_PS_ES_Contact_Field_API_Name__c = 'SVMXC__Contact__c';
            setting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            setting.Name = 'WorkOrder1';
            insert setting;
        }

        SVMX_PS_ES_Service_Report_Name_Settings__c serviceReportSetting = null;
        List<SVMX_PS_ES_Service_Report_Name_Settings__c> emailServiceReportSettingsList = SVMX_PS_ES_Service_Report_Name_Settings__c.getAll().values();
        if(emailServiceReportSettingsList!= null && emailServiceReportSettingsList.size() > 0){
            for(SVMX_PS_ES_Service_Report_Name_Settings__c emailServiceReportNameSetting : emailServiceReportSettingsList){
                if(emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c != null
                        && !emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('')
                        && emailServiceReportNameSetting.SVMX_PS_ES_Object_API_Name__c == 'SVMXC__Service_Order__c'
                        && emailServiceReportNameSetting.SVMX_PS_ES_Record_Type_Name__c == null){
                    serviceReportSetting = emailServiceReportNameSetting;
                }
            }
        }
        if(serviceReportSetting == null){
            serviceReportSetting = new SVMX_PS_ES_Service_Report_Name_Settings__c();
            serviceReportSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            serviceReportSetting.SVMX_PS_ES_Service_Report_Name__c = 'Service_Test_Report_XXX';
            serviceReportSetting.Name = 'WorkOrderTestingXXX';
            insert serviceReportSetting;
        }else{
            serviceReportSetting.SVMX_PS_ES_Service_Report_Name__c = 'Service_Test_Report_XXX';
            update serviceReportSetting;
        }

        SVMX_PS_ES_Last_Run_Setting__c serviceLastRunSetting = null;
        List<SVMX_PS_ES_Last_Run_Setting__c> serviceLastRunSettingList = SVMX_PS_ES_Last_Run_Setting__c.getAll().values();
        if(serviceLastRunSettingList!= null && serviceLastRunSettingList.size() > 0){
            for(SVMX_PS_ES_Last_Run_Setting__c lastRunSetting : serviceLastRunSettingList){
                serviceLastRunSetting = lastRunSetting;
            }
        }
        if(serviceLastRunSetting == null){
            serviceLastRunSetting = new SVMX_PS_ES_Last_Run_Setting__c();
            serviceLastRunSetting.Name = 'Email Scheduler Last Run Time';
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            insert serviceLastRunSetting;
        }else{
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            update serviceLastRunSetting;
        }

        SVMXC__Service_Order__c wo = SVMX_PS_ES_Email_Handler_Files_UT.createData();
        wo.SVMX_PS_ES_Email_To_Customer__c = 'test@serviceuser.com';
        wo.SVMX_PS_ES_Send_Service_Report_To_Cust__c = true;
        wo.SVMX_PS_ES_Send_Service_Report_To_Owner__c = false;
        wo.SVMX_PS_ES_Send_Service_ReportTo_Contact__c = false;
        wo.SVMX_PS_ES_Email_To_Additional_People__c = 'test1@serviceuser.com,test2@serviceuser.com,test3@serviceuser.com';
        wo.SVMX_PS_ES_Send_To_Additional_People__c = true;
        wo.SVMX_PS_ES_Cc_Current_User__c = false;
        wo.SVMX_PS_ES_Cc_Owner__c = false;
        wo.SVMX_PS_ES_Cc_Email_Additional_People__c = 'test4@serviceuser.com,test5@serviceuser.com,test6@serviceuser.com';
        wo.SVMX_PS_ES_Cc_Additional_People__c = true;
        wo.SVMX_PS_ES_Bcc_Current_User__c  = true;
        wo.SVMX_PS_ES_Bcc_Owner__c  = true;
        wo.SVMX_PS_ES_Bcc_Email_Additional_People__c = 'test7@serviceuser.com,test8@serviceuser.com,test9@serviceuser.com';
        wo.SVMX_PS_ES_Bcc_Additional_People__c  = true;
        update wo;

        Test.StartTest();
        SVMX_PS_ES_Email_Handler_Files emailhandler = new SVMX_PS_ES_Email_Handler_Files();
        Database.executebatch(emailhandler, 8);
        Test.StopTest();
    }

    /*
     * Tests if custom setting for email functionality is active but no files are identified, no emails should be sent.
     */
    static testMethod void testEmailHandler8() {
        List<SVMX_PS_Services_Register__c> serviceRegisterSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(serviceRegisterSetting != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSetting){
                if(serviceRegister.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_ES_Org_Wide_Address_Settings__c> orgWideSettingList = SVMX_PS_ES_Org_Wide_Address_Settings__c.getall().values();
        isFound = false;
        if(orgWideSettingList != null){
            for(SVMX_PS_ES_Org_Wide_Address_Settings__c  orgWideSetting : orgWideSettingList){
                if((orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c != null &&
                        !orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c'))
                        || orgWideSetting.SVMX_PS_ES_Default__c){
                    isFound = true;
                    break;
                }
            }
        }
        if(!isFound){
            List<OrgWideEmailAddress> availableOrgWideEmailAddress = [SELECT DisplayName,Id,IsAllowAllProfiles
            FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = true];
            if(availableOrgWideEmailAddress != null && availableOrgWideEmailAddress.size() > 0){
                SVMX_PS_ES_Org_Wide_Address_Settings__c  newSetting = new SVMX_PS_ES_Org_Wide_Address_Settings__c   ();
                newSetting.Name = 'WorkOrderTestingXXX';
                newSetting.SVMX_PS_ES_Default__c = true;
                newSetting.SVMX_PS_ES_Org_Wide_Address__c = availableOrgWideEmailAddress.get(0).Id;
                newSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
                insert newSetting;
            }
        }

        List<SVMX_PS_ES_Service_Report_Settings__c> emailNotificationSetting = SVMX_PS_ES_Service_Report_Settings__c.getall().values();
        String contactId = null;
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailService : emailNotificationSetting){
                if(emailService.Name.equals(DEFAULT_CONTACT_ID)){
                    contactId = emailService.SVMX_PS_ES_Text_Value__c;
                }
            }

            delete emailNotificationSetting;
        }
        emailNotificationSetting = SVMX_PS_ES_Email_Handler_Files_UT.createEmailHandlerSettings();
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailService : emailNotificationSetting){
                if(emailService.Name.equals(STOP_EMAIL)){
                    emailService.SVMX_PS_ES_Value__c = true;
                }
                else if(emailService.Name.equals(STOP_EMAIL)){
                    emailService.SVMX_PS_ES_Text_Value__c = contactId;
                }
            }
        }
        insert emailNotificationSetting;

        SVMX_PS_ES_Last_Run_Setting__c serviceLastRunSetting = null;
        List<SVMX_PS_ES_Last_Run_Setting__c> serviceLastRunSettingList = SVMX_PS_ES_Last_Run_Setting__c.getAll().values();
        if(serviceLastRunSettingList!= null && serviceLastRunSettingList.size() > 0){
            for(SVMX_PS_ES_Last_Run_Setting__c lastRunSetting : serviceLastRunSettingList){
                serviceLastRunSetting = lastRunSetting;
            }
        }
        if(serviceLastRunSetting == null){
            serviceLastRunSetting = new SVMX_PS_ES_Last_Run_Setting__c();
            serviceLastRunSetting.Name = 'Email Scheduler Last Run Time';
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            insert serviceLastRunSetting;
        }else{
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            update serviceLastRunSetting;
        }

        Test.StartTest();
        SVMX_PS_ES_Email_Handler_Files emailhandler = new SVMX_PS_ES_Email_Handler_Files();
        Database.executebatch(emailhandler, 8);
        Test.StopTest();
    }

    /*
     * Sets the org wide address and email template defaults to work details and does not set anything for work order and tests email functionality.
     */
    static testmethod void testEmailHandler9() {
        List<SVMX_PS_Services_Register__c> serviceRegisterSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(serviceRegisterSetting != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSetting){
                if(serviceRegister.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_ES_Org_Wide_Address_Settings__c> orgWideSettingList = SVMX_PS_ES_Org_Wide_Address_Settings__c.getall().values();
        isFound = false;
        if(orgWideSettingList != null){
            for(SVMX_PS_ES_Org_Wide_Address_Settings__c  orgWideSetting : orgWideSettingList){
                if((orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c != null &&
                        !orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c'))
                        || orgWideSetting.SVMX_PS_ES_Default__c){
                    isFound = true;
                    break;
                }
            }
        }
        if(!isFound){
            List<OrgWideEmailAddress> availableOrgWideEmailAddress = [SELECT DisplayName,Id,IsAllowAllProfiles
            FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = true];
            if(availableOrgWideEmailAddress != null && availableOrgWideEmailAddress.size() > 0){
                SVMX_PS_ES_Org_Wide_Address_Settings__c  newSetting = new SVMX_PS_ES_Org_Wide_Address_Settings__c   ();
                newSetting.Name = 'WorkOrderTestingXXX';
                newSetting.SVMX_PS_ES_Default__c = true;
                newSetting.SVMX_PS_ES_Org_Wide_Address__c = availableOrgWideEmailAddress.get(0).Id;
                newSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
                insert newSetting;
            }
        }

        List<SVMX_PS_ES_Service_Report_Settings__c> emailNotificationSetting = SVMX_PS_ES_Service_Report_Settings__c.getall().values();
        String contactId = null;
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailService : emailNotificationSetting){
                if(emailService.Name.equals(DEFAULT_CONTACT_ID)){
                    contactId = emailService.SVMX_PS_ES_Text_Value__c;
                }
            }

            delete emailNotificationSetting;
        }
        emailNotificationSetting = SVMX_PS_ES_Email_Handler_Files_UT.createEmailHandlerSettings();
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailNotification : emailNotificationSetting){
                if(emailNotification.Name.equals(STOP_EMAIL_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CONTACT)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CUSTOMER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_ADDTIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_CURRENT_USER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_CURRENTUSER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(SAVE_EMAIL_AS_ACTIVTIY)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(GROUP_EMAILS)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(EXTENSIONS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'JPEG,PNG';
                }
                else if(emailNotification.Name.equals(DEFAULT_EMAIL_ADDRESS)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'testvalue@test.com';
                }
                else if(emailNotification.Name.equals(SEND_TO_DEFAULT_EMAIL_ADDRESS)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(OBJECTS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'SVMXC__Service_Order__c';
                }
                else if(emailNotification.Name.equals(DEFAULT_CONTACT_ID)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = contactId;
                }
            }
        }
        insert emailNotificationSetting;

        boolean foundsetting = false;
        List<SVMX_PS_ES_Contact_Field_Mapping_Setting__c> contactFieldMappingList = SVMX_PS_ES_Contact_Field_Mapping_Setting__c.getall().values();
        if(contactFieldMappingList!= null && contactFieldMappingList.size() > 0){
            for(SVMX_PS_ES_Contact_Field_Mapping_Setting__c emailContactFieldMapSetting : contactFieldMappingList){
                if(emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c != null &&
                        !emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.equals('SVMXC__Contact__c') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c')){
                    foundsetting = true;
                    break;
                }
            }
        }
        if(!foundsetting){
            SVMX_PS_ES_Contact_Field_Mapping_Setting__c setting = new SVMX_PS_ES_Contact_Field_Mapping_Setting__c();
            setting.SVMX_PS_ES_Contact_Field_API_Name__c = 'SVMXC__Contact__c';
            setting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            setting.Name = 'WorkOrder1';
            insert setting;
        }

        List<SVMX_PS_ES_Service_Report_Name_Settings__c> emailServiceReportSettingsList = SVMX_PS_ES_Service_Report_Name_Settings__c.getAll().values();
        if(emailServiceReportSettingsList!= null && emailServiceReportSettingsList.size() > 0){
            delete emailServiceReportSettingsList;
        }
        SVMX_PS_ES_Service_Report_Name_Settings__c serviceReportSetting = new SVMX_PS_ES_Service_Report_Name_Settings__c();
        serviceReportSetting.Name = 'Test1';
        serviceReportSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
        serviceReportSetting.SVMX_PS_ES_Service_Report_Name__c = 'Service_Test_Report_XXX';
        insert serviceReportSetting;

        String emailTemplateId = null;
        List<SVMX_PS_ES_Template_Settings__c> emailtemplateSettingsList = SVMX_PS_ES_Template_Settings__c.getAll().values();
        if(emailtemplateSettingsList!= null && emailtemplateSettingsList.size() > 0){
            for(SVMX_PS_ES_Template_Settings__c emailTemplateSetting : emailtemplateSettingsList){
                if(emailTemplateSetting.SVMX_PS_ES_Template_Unique_Name__c != null
                        && !emailTemplateSetting.SVMX_PS_ES_Template_Unique_Name__c.trim().equals('')){
                    emailTemplateId = emailTemplateSetting.SVMX_PS_ES_Template_Unique_Name__c ;
                    break;
                }
            }
            if(emailTemplateId != null && !emailTemplateId.trim().equals('')){
                delete emailtemplateSettingsList;
            }else{
                List<EmailTemplate> emailTemplateBaseList = [Select Id, Name, DeveloperName
                from EmailTemplate where DeveloperName = 'Work_Order_Service_Report_Email'];
                if(emailTemplateBaseList != null && emailTemplateBaseList.size() > 0){
                    emailTemplateId = emailTemplateBaseList.get(0).Id;
                }else{
                    emailTemplateBaseList = [Select Id, Name, DeveloperName from EmailTemplate Limit 2];
                    if(emailTemplateBaseList != null && emailTemplateBaseList.size() > 0){
                        emailTemplateId = emailTemplateBaseList.get(0).Id;
                    }
                }
            }
        }
        if(emailTemplateId != null){
            SVMX_PS_ES_Template_Settings__c emailTemplateSetting = new SVMX_PS_ES_Template_Settings__c();
            emailTemplateSetting.Name = 'Test1';
            emailTemplateSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order_Line__c';
            emailTemplateSetting.SVMX_PS_ES_Template_Unique_Name__c = emailTemplateId;
            emailTemplateSetting.SVMX_PS_ES_Default__c = true;
            insert emailTemplateSetting;
        }

        SVMX_PS_ES_Last_Run_Setting__c serviceLastRunSetting = null;
        List<SVMX_PS_ES_Last_Run_Setting__c> serviceLastRunSettingList = SVMX_PS_ES_Last_Run_Setting__c.getAll().values();
        if(serviceLastRunSettingList!= null && serviceLastRunSettingList.size() > 0){
            for(SVMX_PS_ES_Last_Run_Setting__c lastRunSetting : serviceLastRunSettingList){
                serviceLastRunSetting = lastRunSetting;
            }
        }
        if(serviceLastRunSetting == null){
            serviceLastRunSetting = new SVMX_PS_ES_Last_Run_Setting__c();
            serviceLastRunSetting.Name = 'Email Scheduler Last Run Time';
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            insert serviceLastRunSetting;
        }else{
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            update serviceLastRunSetting;
        }

        SVMXC__Service_Order__c wo = SVMX_PS_ES_Email_Handler_Files_UT.createData();
        wo.SVMX_PS_ES_Email_To_Customer__c = 'test@serviceuser.com';
        wo.SVMX_PS_ES_Send_Service_Report_To_Cust__c = true;
        wo.SVMX_PS_ES_Send_Service_Report_To_Owner__c = false;
        wo.SVMX_PS_ES_Send_Service_ReportTo_Contact__c = false;
        wo.SVMX_PS_ES_Email_To_Additional_People__c = 'test1@serviceuser.com,test2@serviceuser.com,test3@serviceuser.com';
        wo.SVMX_PS_ES_Send_To_Additional_People__c = true;
        wo.SVMX_PS_ES_Cc_Current_User__c = false;
        wo.SVMX_PS_ES_Cc_Owner__c = false;
        wo.SVMX_PS_ES_Cc_Email_Additional_People__c = 'test4@serviceuser.com,test5@serviceuser.com,test6@serviceuser.com';
        wo.SVMX_PS_ES_Cc_Additional_People__c = true;
        wo.SVMX_PS_ES_Bcc_Current_User__c  = true;
        wo.SVMX_PS_ES_Bcc_Owner__c  = true;
        wo.SVMX_PS_ES_Bcc_Email_Additional_People__c = 'test7@serviceuser.com,test8@serviceuser.com,test9@serviceuser.com';
        wo.SVMX_PS_ES_Bcc_Additional_People__c  = true;
        update wo;

        Test.StartTest();
        SVMX_PS_ES_Email_Handler_Files emailhandler = new SVMX_PS_ES_Email_Handler_Files();
        Database.executebatch(emailhandler, 8);
        Test.StopTest();
    }

    /*
     * Does not add anything to Service Report Name settings, adds a default service report name in Email Service Report Setting
     * which is chosen as default if not found.
     * Configures rest of all settings and tests email functionality.
     */
    static testmethod void testEmailHandler10() {
        List<SVMX_PS_Services_Register__c> serviceRegisterSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(serviceRegisterSetting != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSetting){
                if(serviceRegister.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_ES_Org_Wide_Address_Settings__c> orgWideSettingList = SVMX_PS_ES_Org_Wide_Address_Settings__c.getall().values();
        isFound = false;
        if(orgWideSettingList != null){
            for(SVMX_PS_ES_Org_Wide_Address_Settings__c  orgWideSetting : orgWideSettingList){
                if((orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c != null &&
                        !orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c'))
                        || orgWideSetting.SVMX_PS_ES_Default__c){
                    isFound = true;
                    break;
                }
            }
        }
        if(!isFound){
            List<OrgWideEmailAddress> availableOrgWideEmailAddress = [SELECT DisplayName,Id,IsAllowAllProfiles
            FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = true];
            if(availableOrgWideEmailAddress != null && availableOrgWideEmailAddress.size() > 0){
                SVMX_PS_ES_Org_Wide_Address_Settings__c  newSetting = new SVMX_PS_ES_Org_Wide_Address_Settings__c   ();
                newSetting.Name = 'WorkOrderTestingXXX';
                newSetting.SVMX_PS_ES_Default__c = true;
                newSetting.SVMX_PS_ES_Org_Wide_Address__c = availableOrgWideEmailAddress.get(0).Id;
                newSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
                insert newSetting;
            }
        }

        List<SVMX_PS_ES_Service_Report_Settings__c> emailNotificationSetting = SVMX_PS_ES_Service_Report_Settings__c.getall().values();
        String contactId = null;
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailService : emailNotificationSetting){
                if(emailService.Name.equals(DEFAULT_CONTACT_ID)){
                    contactId = emailService.SVMX_PS_ES_Text_Value__c;
                }
            }

            delete emailNotificationSetting;
        }
        emailNotificationSetting = SVMX_PS_ES_Email_Handler_Files_UT.createEmailHandlerSettings();
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailNotification : emailNotificationSetting){
                if(emailNotification.Name.equals(STOP_EMAIL_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CONTACT)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CUSTOMER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_ADDTIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_CURRENT_USER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_CURRENTUSER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(SAVE_EMAIL_AS_ACTIVTIY)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(GROUP_EMAILS)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(EXTENSIONS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'JPEG,PNG';
                }
                else if(emailNotification.Name.equals(DEFAULT_EMAIL_ADDRESS)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'testvalue@test.com';
                }
                else if(emailNotification.Name.equals(SEND_TO_DEFAULT_EMAIL_ADDRESS)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(OBJECTS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'SVMXC__Service_Order__c';
                }
                else if(emailNotification.Name.equals(SERVICE_REPORT_NAME)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'Service_Test_Report_XXX';
                }
                else if(emailNotification.Name.equals(DEFAULT_CONTACT_ID)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = contactId;
                }
            }
        }
        insert emailNotificationSetting;

        boolean foundsetting = false;
        List<SVMX_PS_ES_Contact_Field_Mapping_Setting__c> contactFieldMappingList = SVMX_PS_ES_Contact_Field_Mapping_Setting__c.getall().values();
        if(contactFieldMappingList!= null && contactFieldMappingList.size() > 0){
            for(SVMX_PS_ES_Contact_Field_Mapping_Setting__c emailContactFieldMapSetting : contactFieldMappingList){
                if(emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c != null &&
                        !emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.equals('SVMXC__Contact__c') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c')){
                    foundsetting = true;
                    break;
                }
            }
        }
        if(!foundsetting){
            SVMX_PS_ES_Contact_Field_Mapping_Setting__c setting = new SVMX_PS_ES_Contact_Field_Mapping_Setting__c();
            setting.SVMX_PS_ES_Contact_Field_API_Name__c = 'SVMXC__Contact__c';
            setting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            setting.Name = 'WorkOrder1';
            insert setting;
        }

        List<SVMX_PS_ES_Service_Report_Name_Settings__c> emailServiceReportSettingsList = SVMX_PS_ES_Service_Report_Name_Settings__c.getAll().values();
        if(emailServiceReportSettingsList!= null && emailServiceReportSettingsList.size() > 0){
            delete emailServiceReportSettingsList;
        }

        String emailTemplateId = null;
        List<SVMX_PS_ES_Template_Settings__c> emailtemplateSettingsList = SVMX_PS_ES_Template_Settings__c.getAll().values();
        if(emailtemplateSettingsList!= null && emailtemplateSettingsList.size() > 0){
            delete emailtemplateSettingsList;
        }

        SVMX_PS_ES_Last_Run_Setting__c serviceLastRunSetting = null;
        List<SVMX_PS_ES_Last_Run_Setting__c> serviceLastRunSettingList = SVMX_PS_ES_Last_Run_Setting__c.getAll().values();
        if(serviceLastRunSettingList!= null && serviceLastRunSettingList.size() > 0){
            for(SVMX_PS_ES_Last_Run_Setting__c lastRunSetting : serviceLastRunSettingList){
                serviceLastRunSetting = lastRunSetting;
            }
        }
        if(serviceLastRunSetting == null){
            serviceLastRunSetting = new SVMX_PS_ES_Last_Run_Setting__c();
            serviceLastRunSetting.Name = 'Email Scheduler Last Run Time';
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            insert serviceLastRunSetting;
        }else{
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            update serviceLastRunSetting;
        }

        SVMXC__Service_Order__c wo = SVMX_PS_ES_Email_Handler_Files_UT.createData();
        wo.SVMX_PS_ES_Email_To_Customer__c = 'test@serviceuser.com';
        wo.SVMX_PS_ES_Send_Service_Report_To_Cust__c  = true;
        wo.SVMX_PS_ES_Send_Service_Report_To_Owner__c = false;
        wo.SVMX_PS_ES_Send_Service_ReportTo_Contact__c = false;
        wo.SVMX_PS_ES_Email_To_Additional_People__c = 'test1@serviceuser.com,test2@serviceuser.com,test3@serviceuser.com';
        wo.SVMX_PS_ES_Send_To_Additional_People__c = true;
        wo.SVMX_PS_ES_Cc_Current_User__c = false;
        wo.SVMX_PS_ES_Cc_Owner__c = false;
        wo.SVMX_PS_ES_Cc_Email_Additional_People__c = 'test4@serviceuser.com,test5@serviceuser.com,test6@serviceuser.com';
        wo.SVMX_PS_ES_Cc_Additional_People__c = true;
        wo.SVMX_PS_ES_Bcc_Current_User__c  = true;
        wo.SVMX_PS_ES_Bcc_Owner__c  = true;
        wo.SVMX_PS_ES_Bcc_Email_Additional_People__c = 'test7@serviceuser.com,test8@serviceuser.com,test9@serviceuser.com';
        wo.SVMX_PS_ES_Bcc_Additional_People__c  = true;
        update wo;

        Test.StartTest();
        SVMX_PS_ES_Email_Handler_Files emailhandler = new SVMX_PS_ES_Email_Handler_Files();
        Database.executebatch(emailhandler, 8);
        Test.StopTest();
    }

    /*
     * Tests Schedulable method with no default batch size setting defined.
     */
    static testMethod void testEmailHandler11() {
        List<SVMX_PS_Services_Register__c> serviceRegisterSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(serviceRegisterSetting != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSetting){
                if(serviceRegister.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = false;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = false;
            insert newSetting;
        }

        List<SVMX_PS_ES_Org_Wide_Address_Settings__c> orgWideSettingList = SVMX_PS_ES_Org_Wide_Address_Settings__c.getall().values();
        isFound = false;
        if(orgWideSettingList != null){
            for(SVMX_PS_ES_Org_Wide_Address_Settings__c  orgWideSetting : orgWideSettingList){
                if((orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c != null &&
                        !orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c'))
                        || orgWideSetting.SVMX_PS_ES_Default__c){
                    isFound = true;
                    break;
                }
            }
        }
        if(!isFound){
            List<OrgWideEmailAddress> availableOrgWideEmailAddress = [SELECT DisplayName,Id,IsAllowAllProfiles
            FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = true];
            if(availableOrgWideEmailAddress != null && availableOrgWideEmailAddress.size() > 0){
                SVMX_PS_ES_Org_Wide_Address_Settings__c  newSetting = new SVMX_PS_ES_Org_Wide_Address_Settings__c   ();
                newSetting.Name = 'WorkOrderTestingXXX';
                newSetting.SVMX_PS_ES_Default__c = true;
                newSetting.SVMX_PS_ES_Org_Wide_Address__c = availableOrgWideEmailAddress.get(0).Id;
                newSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
                insert newSetting;
            }
        }

        List<SVMX_PS_ES_Service_Report_Settings__c> emailNotificationSetting = SVMX_PS_ES_Service_Report_Settings__c.getall().values();
        if(emailNotificationSetting != null){
            delete emailNotificationSetting;
        }

        SVMX_PS_ES_Email_Handler_Files_UT.createData();

        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = System.schedule('Rapid_Email_Funcationality__XX', CRON_EXP, new SVMX_PS_ES_Email_Handler_Files() );
        Test.stopTest();
    }

    /*
     * Tests Schedulable method with default batch size setting defined.
     */
    static testMethod void testEmailHandler12() {
        List<SVMX_PS_Services_Register__c> serviceRegisterSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(serviceRegisterSetting != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSetting){
                if(serviceRegister.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = false;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = false;
            insert newSetting;
        }

        List<SVMX_PS_ES_Org_Wide_Address_Settings__c> orgWideSettingList = SVMX_PS_ES_Org_Wide_Address_Settings__c.getall().values();
        isFound = false;
        if(orgWideSettingList != null){
            for(SVMX_PS_ES_Org_Wide_Address_Settings__c  orgWideSetting : orgWideSettingList){
                if((orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c != null &&
                        !orgWideSetting.SVMX_PS_ES_Org_Wide_Address__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        orgWideSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c'))
                        || orgWideSetting.SVMX_PS_ES_Default__c){
                    isFound = true;
                    break;
                }
            }
        }
        if(!isFound){
            List<OrgWideEmailAddress> availableOrgWideEmailAddress = [SELECT DisplayName,Id,IsAllowAllProfiles
            FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = true];
            if(availableOrgWideEmailAddress != null && availableOrgWideEmailAddress.size() > 0){
                SVMX_PS_ES_Org_Wide_Address_Settings__c  newSetting = new SVMX_PS_ES_Org_Wide_Address_Settings__c   ();
                newSetting.Name = 'WorkOrderTestingXXX';
                newSetting.SVMX_PS_ES_Default__c = true;
                newSetting.SVMX_PS_ES_Org_Wide_Address__c = availableOrgWideEmailAddress.get(0).Id;
                newSetting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
                insert newSetting;
            }
        }

        List<SVMX_PS_ES_Service_Report_Settings__c> emailNotificationSetting = SVMX_PS_ES_Service_Report_Settings__c.getall().values();
        if(emailNotificationSetting != null){
            delete emailNotificationSetting;
        }

        SVMX_PS_ES_Service_Report_Settings__c setting = new SVMX_PS_ES_Service_Report_Settings__c();
        setting.SVMX_PS_ES_Text_Value__c = '8';
        setting.Name = DEFAULT_BATCH_SIZE;
        insert setting;

        SVMX_PS_ES_Email_Handler_Files_UT.createData();

        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = System.schedule('Rapid_Email_Funcationality__XX', CRON_EXP, new SVMX_PS_ES_Email_Handler_Files() );
        Test.stopTest();
    }

    /*
     * Does not add any org wide address. Configures rest of all settings and tests email functionality.
     */
    static testmethod void testEmailHandler14() {
        List<SVMX_PS_Services_Register__c> serviceRegisterSetting = SVMX_PS_Services_Register__c.getall().values();
        boolean isFound = false;
        if(serviceRegisterSetting != null){
            for(SVMX_PS_Services_Register__c serviceRegister : serviceRegisterSetting){
                if(serviceRegister.Name.equals(EMAIL_SERVICE_REPORT_FUNCT)){
                    serviceRegister.SVMX_PS_Is_Active__c = true;
                    isFound = true;
                }
            }
        }
        if(isFound){
            update serviceRegisterSetting;
        }else{
            SVMX_PS_Services_Register__c newSetting = new SVMX_PS_Services_Register__c();
            newSetting.Name = EMAIL_SERVICE_REPORT_FUNCT;
            newSetting.SVMX_PS_Is_Active__c = true;
            insert newSetting;
        }

        List<SVMX_PS_ES_Service_Report_Settings__c> emailNotificationSetting = SVMX_PS_ES_Service_Report_Settings__c.getall().values();
        String contactId = null;
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailService : emailNotificationSetting){
                if(emailService.Name.equals(DEFAULT_CONTACT_ID)){
                    contactId = emailService.SVMX_PS_ES_Text_Value__c;
                }
            }

            delete emailNotificationSetting;
        }
        emailNotificationSetting = SVMX_PS_ES_Email_Handler_Files_UT.createEmailHandlerSettings();
        if(emailNotificationSetting != null){
            for(SVMX_PS_ES_Service_Report_Settings__c emailNotification : emailNotificationSetting){
                if(emailNotification.Name.equals(STOP_EMAIL_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CONTACT)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_CUSTOMER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_ADDTIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_CURRENT_USER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_CC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_ADDITIONAL_PEOPLE)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_CURRENTUSER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(STOP_BCC_TO_OWNER)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(SAVE_EMAIL_AS_ACTIVTIY)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(GROUP_EMAILS)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(EXTENSIONS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'JPEG,PNG';
                }
                else if(emailNotification.Name.equals(DEFAULT_EMAIL_ADDRESS)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'testvalue@test.com';
                }
                else if(emailNotification.Name.equals(SEND_TO_DEFAULT_EMAIL_ADDRESS)){
                    emailNotification.SVMX_PS_ES_Value__c = true;
                }
                else if(emailNotification.Name.equals(STOP_EMAIL)){
                    emailNotification.SVMX_PS_ES_Value__c = false;
                }
                else if(emailNotification.Name.equals(OBJECTS_SUPPORTED)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'SVMXC__Service_Order__c';
                }
                else if(emailNotification.Name.equals(SERVICE_REPORT_NAME)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = 'Service_Test_Report_XXX';
                }
                else if(emailNotification.Name.equals(DEFAULT_CONTACT_ID)){
                    emailNotification.SVMX_PS_ES_Text_Value__c = contactId;
                }
            }
        }
        insert emailNotificationSetting;

        boolean foundsetting = false;
        List<SVMX_PS_ES_Contact_Field_Mapping_Setting__c> contactFieldMappingList = SVMX_PS_ES_Contact_Field_Mapping_Setting__c.getall().values();
        if(contactFieldMappingList!= null && contactFieldMappingList.size() > 0){
            for(SVMX_PS_ES_Contact_Field_Mapping_Setting__c emailContactFieldMapSetting : contactFieldMappingList){
                if(emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c != null &&
                        !emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Contact_Field_API_Name__c.equals('SVMXC__Contact__c') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c != null &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.trim().equals('') &&
                        emailContactFieldMapSetting.SVMX_PS_ES_Object_API_Name__c.equals('SVMXC__Service_Order__c')){
                    foundsetting = true;
                    break;
                }
            }
        }
        if(!foundsetting){
            SVMX_PS_ES_Contact_Field_Mapping_Setting__c setting = new SVMX_PS_ES_Contact_Field_Mapping_Setting__c();
            setting.SVMX_PS_ES_Contact_Field_API_Name__c = 'SVMXC__Contact__c';
            setting.SVMX_PS_ES_Object_API_Name__c = 'SVMXC__Service_Order__c';
            setting.Name = 'WorkOrder1';
            insert setting;
        }

        List<SVMX_PS_ES_Service_Report_Name_Settings__c> emailServiceReportSettingsList = SVMX_PS_ES_Service_Report_Name_Settings__c.getAll().values();
        if(emailServiceReportSettingsList!= null && emailServiceReportSettingsList.size() > 0){
            delete emailServiceReportSettingsList;
        }

        List<SVMX_PS_ES_Org_Wide_Address_Settings__c> emailOrgWideSettingsList = SVMX_PS_ES_Org_Wide_Address_Settings__c.getAll().values();
        if(emailOrgWideSettingsList!= null && emailOrgWideSettingsList.size() > 0){
            delete emailOrgWideSettingsList;
        }

        List<SVMX_PS_ES_Template_Settings__c> emailtemplateSettingsList = SVMX_PS_ES_Template_Settings__c.getAll().values();
        if(emailtemplateSettingsList!= null && emailtemplateSettingsList.size() > 0){
            delete emailtemplateSettingsList;
        }

        SVMX_PS_ES_Last_Run_Setting__c serviceLastRunSetting = null;
        List<SVMX_PS_ES_Last_Run_Setting__c> serviceLastRunSettingList = SVMX_PS_ES_Last_Run_Setting__c.getAll().values();
        if(serviceLastRunSettingList!= null && serviceLastRunSettingList.size() > 0){
            for(SVMX_PS_ES_Last_Run_Setting__c lastRunSetting : serviceLastRunSettingList){
                serviceLastRunSetting = lastRunSetting;
            }
        }
        if(serviceLastRunSetting == null){
            serviceLastRunSetting = new SVMX_PS_ES_Last_Run_Setting__c();
            serviceLastRunSetting.Name = 'Email Scheduler Last Run Time';
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            insert serviceLastRunSetting;
        }else{
            serviceLastRunSetting.SVMX_PS_ES_Last_Run_Time__c = System.Now();
            update serviceLastRunSetting;
        }

        SVMXC__Service_Order__c wo = SVMX_PS_ES_Email_Handler_Files_UT.createData();
        wo.SVMX_PS_ES_Email_To_Customer__c = 'test@serviceuser.com';
        wo.SVMX_PS_ES_Send_Service_Report_To_Cust__c  = true;
        wo.SVMX_PS_ES_Send_Service_Report_To_Owner__c = false;
        wo.SVMX_PS_ES_Send_Service_ReportTo_Contact__c = false;
        wo.SVMX_PS_ES_Email_To_Additional_People__c = 'test1@serviceuser.com,test2@serviceuser.com,test3@serviceuser.com';
        wo.SVMX_PS_ES_Send_To_Additional_People__c = true;
        wo.SVMX_PS_ES_Cc_Current_User__c = false;
        wo.SVMX_PS_ES_Cc_Owner__c = false;
        wo.SVMX_PS_ES_Cc_Email_Additional_People__c = 'test4@serviceuser.com,test5@serviceuser.com,test6@serviceuser.com';
        wo.SVMX_PS_ES_Cc_Additional_People__c = true;
        wo.SVMX_PS_ES_Bcc_Current_User__c  = true;
        wo.SVMX_PS_ES_Bcc_Owner__c  = true;
        wo.SVMX_PS_ES_Bcc_Email_Additional_People__c = 'test7@serviceuser.com,test8@serviceuser.com,test9@serviceuser.com';
        wo.SVMX_PS_ES_Bcc_Additional_People__c  = true;
        update wo;

        Test.StartTest();
        SVMX_PS_ES_Email_Handler_Files emailhandler = new SVMX_PS_ES_Email_Handler_Files();
        Database.executebatch(emailhandler, 8);
        Test.StopTest();
    }

    /*
     * Tests startBackLogScheduler method.
     */
    static testMethod void testEmailHandler15() {
        SVMX_PS_ES_Email_Handler_Files.startBackLogScheduler();
    }

    static SVMXC__Service_Order__c createData(){
        //Create Account
        Account testAccount = SVMX_PS_TestUtil.createAccount(true);

        //Create Contact
        Contact testContact = SVMX_PS_TestUtil.generateContact(testAccount.Id);
        insert testContact;

        //Create Location
        SVMXC__Site__c site = SVMX_PS_TestUtil.createCustomerLocation(testAccount.Id, true);

        //Create User
        User usr = SVMX_PS_TestUtil.generateSystemAdminUser();
        usr.EmployeeNumber = '87414214';
        insert usr;

//        //Create Case
//        Case cs = SVMX_PS_TestUtil.generateCase();
//        cs.Status ='New';
//        cs.Priority = 'Medium';
//        cs.Origin = 'Email';
//        cs.ContactId =testContact.Id;
//        cs.AccountId=testAccount.Id;
//        insert cs;

        //Create Case
        Case cs = new Case();
        cs.Status ='New';
        cs.Priority = 'Medium';
        cs.Origin = 'Email';
        cs.ContactId =testContact.Id;
        cs.AccountId=testAccount.Id;
        insert cs;

        //Create Work Order
        SVMXC__Service_Order__c wo = SVMX_PS_TestUtil.createWorkOrder(testAccount.Id, 'New', false);
        wo.SVMXC__Order_Type__c='Field Service';
        wo.SVMXC__Street__c = '16260 Monterey St.';
        wo.SVMXC__City__c = 'Morgan Hill';
        wo.SVMXC__State__c = 'California';
        wo.SVMXC__Zip__c = '95037';
        wo.SVMXC__Country__c = 'USA';
        wo.SVMXC__Site__c = site.Id;
        wo.SVMXC__Priority__c = 'Medium';
        wo.SVMXC__Case__c = cs.Id;
        wo.SVMXC__Contact__c = testContact.id;
        insert wo;

        SVMX_PS_TestUtil.generateFile(wo.Id, 'Service_Test_Report_XXX_1', 'Service_Test_Report_XXX_1.pdf');
        SVMX_PS_TestUtil.generateFile(wo.Id, 'Service_Test_Report_XXX_2', 'Service_Test_Report_XXX_2.doc');
        SVMX_PS_TestUtil.generateFile(wo.Id, 'Service_Test_Report_XXX_3', 'Service_Test_Report_XXX_3.xxx');
        SVMX_PS_TestUtil.generateFile(wo.Id, 'Service_Test_Report_XXX_4', 'Service_Test_Report_XXX_4.jpeg');
        SVMX_PS_TestUtil.generateFile(wo.Id, 'Service_Test_Report_XXX_5', 'Service_Test_Report_XXX_5.png');
        SVMX_PS_TestUtil.generateFile(wo.Id, 'Service_Test_Report_XXX_6', 'Service_Test_Report_XXX_6.pdf');
        SVMX_PS_TestUtil.generateFile(wo.Id, 'Service_Test_Report_XXX_7', 'Service_Test_Report_XXX_7.png');
        SVMX_PS_TestUtil.generateFile(wo.Id, 'Service_Test_Report_XXX_8', 'Service_Test_Report_XXX_8.pdf');

        return wo;
    }

    static List<SVMX_PS_ES_Service_Report_Settings__c>  createEmailHandlerSettings(){
        List<SVMX_PS_ES_Service_Report_Settings__c> emailNotificationSettingList = new List<SVMX_PS_ES_Service_Report_Settings__c> ();

        SVMX_PS_ES_Service_Report_Settings__c emailNotification1 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification1.Name=OBJECTS_SUPPORTED;
        emailNotification1.SVMX_PS_ES_Text_Value__c = 'SVMXC__Service_Order__c';
        emailNotificationSettingList.add(emailNotification1);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification2 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification2.Name=EXTENSIONS_SUPPORTED;
        emailNotification2.SVMX_PS_ES_Text_Value__c = 'PDF';
        emailNotificationSettingList.add(emailNotification2);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification3 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification3.Name=DEFAULT_CONTACT_ID;
        emailNotification3.SVMX_PS_ES_Text_Value__c = '';
        emailNotificationSettingList.add(emailNotification3);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification4 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification4.Name=STOP_BCC;
        emailNotification4.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification4);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification5 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification5.Name=STOP_BCC_TO_ADDITIONAL_PEOPLE;
        emailNotification5.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification5);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification6 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification6.Name=STOP_BCC_TO_CURRENTUSER;
        emailNotification6.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification6);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification7 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification7.Name=STOP_BCC_TO_OWNER;
        emailNotification7.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification7);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification8 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification8.Name=STOP_CC;
        emailNotification8.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification8);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification9 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification9.Name=STOP_CC_TO_ADDTIONAL_PEOPLE;
        emailNotification9.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification9);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification10 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification10.Name=STOP_CC_TO_CURRENT_USER;
        emailNotification10.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification10);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification11 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification11.Name=STOP_CC_TO_OWNER;
        emailNotification11.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification11);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification12 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification12.Name=STOP_EMAIL;
        emailNotification12.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification12);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification13 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification13.Name=STOP_EMAIL_TO_ADDITIONAL_PEOPLE;
        emailNotification13.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification13);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification14 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification14.Name=STOP_EMAIL_TO_CONTACT;
        emailNotification14.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification14);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification15 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification15.Name=STOP_EMAIL_TO_CUSTOMER;
        emailNotification15.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification15);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification16 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification16.Name=STOP_EMAIL_TO_OWNER;
        emailNotification16.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification16);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification17 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification17.Name=SAVE_EMAIL_AS_ACTIVTIY;
        emailNotification17.SVMX_PS_ES_Value__c = false;
        emailNotificationSettingList.add(emailNotification17);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification18 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification18.Name=GROUP_EMAILS;
        emailNotification18.SVMX_PS_ES_Value__c = true;
        emailNotificationSettingList.add(emailNotification18);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification19 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification19.Name=DEFAULT_EMAIL_ADDRESS;
        emailNotification19.SVMX_PS_ES_Text_Value__c = '';
        emailNotificationSettingList.add(emailNotification19);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification20 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification20.Name=SEND_TO_DEFAULT_EMAIL_ADDRESS;
        emailNotification20.SVMX_PS_ES_Value__c = true;
        emailNotificationSettingList.add(emailNotification20);

        SVMX_PS_ES_Service_Report_Settings__c emailNotification21 = new SVMX_PS_ES_Service_Report_Settings__c();
        emailNotification21.Name=SERVICE_REPORT_NAME;
        emailNotification21.SVMX_PS_ES_Text_Value__c = '';
        emailNotificationSettingList.add(emailNotification21);

        return emailNotificationSettingList;
    }
}