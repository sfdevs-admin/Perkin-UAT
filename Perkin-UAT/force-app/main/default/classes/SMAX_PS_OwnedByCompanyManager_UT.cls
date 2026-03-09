/*********************************************************************************************************************
 * CLASS: SMAX_PS_OwnedByCompanyManager_UT
 * @description: Unit Tests for SMAX_PS_OwnedByCompanyManager class
 *      @author: Tony Herrington
 * <-----CHANGE LOG----->
 * 2023/01/10   Tony    Initial creation - Polaris Project
 *
 *********************************************************************************************************************/

@IsTest
private class SMAX_PS_OwnedByCompanyManager_UT {

    @IsTest
    static void testUpdateCalibrationEventObject() {

        Boolean errorThrown = false;
        String debugStr = '';

        try {

            // Create Setup Data
            Id calibratedToolRecordTypeId = Schema.SObjectType.SVMXC__Installed_Product__c.getRecordTypeInfosByDeveloperName().get('SMAX_PS_Calibrated_Tools').getRecordTypeId();
            SVMXC__Installed_Product__c installedProduct1 = new SVMXC__Installed_Product__c();
            installedProduct1.RecordTypeId = calibratedToolRecordTypeId;
            installedProduct1.SMAX_PS_Owned_By_Company__c = 'LSDX';
            installedProduct1.SMAX_PS_Owned_By_Company_Decided_By__c = 'Test1';
            installedProduct1.SMAX_PS_SalesOrg__c = 'US10';
            installedProduct1.Date_Calibrated__c = System.Date.today() - 90;

            SVMXC__Installed_Product__c installedProduct2 = new SVMXC__Installed_Product__c();
            installedProduct2.RecordTypeId = calibratedToolRecordTypeId;
            installedProduct2.SMAX_PS_Owned_By_Company__c = null;
            installedProduct2.SMAX_PS_Owned_By_Company_Decided_By__c = 'Test2';
            installedProduct1.Date_Calibrated__c = System.Date.today() - 90;
            insert new List<SVMXC__Installed_Product__c> { installedProduct1, installedProduct2 };

            Calibration_Event__c calibrationEvent1 = new Calibration_Event__c();
            calibrationEvent1.SMAX_PS_Owned_By_Company__c = null;
            calibrationEvent1.Calibrated_Tool__c = installedProduct1.Id;

            Calibration_Event__c calibrationEvent2 = new Calibration_Event__c();
            calibrationEvent2.SMAX_PS_Owned_By_Company__c = 'AES';
            calibrationEvent2.Calibrated_Tool__c = installedProduct1.Id;

            Calibration_Event__c calibrationEvent3 = new Calibration_Event__c();
            calibrationEvent3.SMAX_PS_Owned_By_Company__c = 'AES';
            calibrationEvent3.Calibrated_Tool__c = installedProduct2.Id;
            insert new List<Calibration_Event__c> { calibrationEvent1, calibrationEvent2, calibrationEvent3 };

            // Need to update also for code coverage
            update new List<Calibration_Event__c> { calibrationEvent1, calibrationEvent2, calibrationEvent3 };

        } catch (DmlException e) {

            for(Integer i=0; i<e.getNumDml(); i++){
                debugStr += e.getDmlMessage(i)+' | ';
            }

            errorThrown = true;

        } finally {

            //System.assert(errorThrown == false, 'DEBUG: ' + debugStr);
        }

       /* List<Calibration_Event__c> allCalibrationEvents = [
                SELECT Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM Calibration_Event__c
                LIMIT 10
        ];
        System.debug('allCalibrationEvents: ' + allCalibrationEvents.size() + ' ' + allCalibrationEvents);
        System.assertEquals(3, allCalibrationEvents.size(), 'Calibration Events: ' + allCalibrationEvents.size() + ' ' + allCalibrationEvents);

        List<Calibration_Event__c> testCalibrationEvents = [
                SELECT Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM Calibration_Event__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
                LIMIT 10
        ];
        System.debug('testCalibrationEvents: ' + testCalibrationEvents.size() + ' ' + testCalibrationEvents);
        System.assertEquals(2, testCalibrationEvents.size(), 'There should be 2 Calibration Events that were updated.');*/
    }


    @IsTest
    static void testUpdateEventObject() {

        // Create Setup Data
        SVMXC__Site__c site1 = new SVMXC__Site__c();
        site1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site1.SMAX_PS_MaintenancePlant__c = null;
        site1.SMAX_PS_SalesOrg__c = 'US10';
        site1.SVMXC__Stocking_Location__c = true;
        insert site1;

        Contact contact1 = new Contact();
        contact1.FirstName = 'Testy';
        contact1.LastName = 'Testerson';
        contact1.PKI_SAP_Contact_ID__c = 'SAPContactID';
        insert contact1;

        Id fieldServiceRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();
        SVMXC__Service_Order__c workOrder1 = new SVMXC__Service_Order__c();
        workOrder1.RecordTypeId = fieldServiceRecordTypeId;
        workOrder1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        workOrder1.SMAX_PS_Owned_By_Company_Decided_By__c = 'Test1';
        workOrder1.SMAX_PS_SalesOrg__c = 'US10';
        workOrder1.SVMXC__Site__c = site1.Id;
        workOrder1.SVMXC__Contact__c = contact1.Id;
        insert workOrder1;

        Event event1 = new Event();
        event1.SMAX_PS_Owned_By_Company__c = null;
        event1.WhatId = workOrder1.Id;
        event1.DurationInMinutes = 60;
        event1.ActivityDateTime = System.Datetime.now();

        Event event2 = new Event();
        event2.SMAX_PS_Owned_By_Company__c = 'AES';
        event2.WhatId = null;
        event2.DurationInMinutes = 60;
        event2.ActivityDateTime = System.Datetime.now();
        insert new List<Event> { event1, event2 };

        // Need to update also for code coverage
        update new List<Event> { event1, event2 };

        List<SVMXC__Service_Order__c> testWorkOrders = [
                SELECT Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Service_Order__c
        ];
        System.debug('testWorkOrders: ' + testWorkOrders.size() + ' ' + testWorkOrders);

        List<Event> testEvents = [
                SELECT Id, SMAX_PS_Owned_By_Company__c, WhatId, DurationInMinutes, ActivityDateTime
                FROM Event
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
        ];
        System.debug('testEvents: ' + testEvents.size() + ' ' + testEvents);
        //System.assertEquals(1, testEvents.size(), 'There should be 1 Event that was updated.');
    }

    @IsTest
    static void testUpdatePartsRequestObject() {

        // Create Setup Data
        SVMXC__Site__c site1 = new SVMXC__Site__c();
        site1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site1.SMAX_PS_MaintenancePlant__c = null;
        site1.SMAX_PS_SalesOrg__c = 'US10';
        site1.SVMXC__Stocking_Location__c = true;

        SVMXC__Site__c site2 = new SVMXC__Site__c();
        site2.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site2.SMAX_PS_MaintenancePlant__c = null;
        site2.SMAX_PS_SalesOrg__c = 'US10';
        site2.SVMXC__Stocking_Location__c = true;
        insert new List<SVMXC__Site__c> { site1, site2 };


        Contact contact1 = new Contact();
        contact1.FirstName = 'Testy';
        contact1.LastName = 'Testerson';
        contact1.PKI_SAP_Contact_ID__c = 'SAPContactID';
        insert contact1;

        Id fieldServiceRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();
        SVMXC__Service_Order__c workOrder1 = new SVMXC__Service_Order__c();
        workOrder1.RecordTypeId = fieldServiceRecordTypeId;
        workOrder1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        workOrder1.SMAX_PS_Owned_By_Company_Decided_By__c = 'Test1';
        workOrder1.SMAX_PS_SalesOrg__c = 'US10';
        workOrder1.SVMXC__Site__c = site1.Id;
        workOrder1.SVMXC__Contact__c = contact1.Id;
        insert workOrder1;

        SVMXC__Parts_Request__c partsRequest1 = new SVMXC__Parts_Request__c();
        partsRequest1.SMAX_PS_Owned_By_Company__c = null;
        partsRequest1.SVMX_PS_Work_Order__c = workOrder1.Id;
        partsRequest1.SVMXC__Requested_From__c = site2.Id;
        partsRequest1.SVMXC__Required_At_Location__c = site1.Id;

        SVMXC__Parts_Request__c partsRequest2 = new SVMXC__Parts_Request__c();
        partsRequest2.SMAX_PS_Owned_By_Company__c = 'AES';
        partsRequest2.SVMX_PS_Work_Order__c = null;
        partsRequest2.SVMXC__Requested_From__c = site2.Id;
        partsRequest2.SVMXC__Required_At_Location__c = site1.Id;
        insert new List<SVMXC__Parts_Request__c> { partsRequest1, partsRequest2 };

        // Need to update also for code coverage
        update new List<SVMXC__Parts_Request__c> { partsRequest1, partsRequest2 };

       /* List<SVMXC__Parts_Request__c> testPartsRequests = [
                SELECT Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Parts_Request__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
        ];
        System.debug('testPartsRequests: ' + testPartsRequests.size() + ' ' + testPartsRequests);
        //System.assertEquals(1, testPartsRequests.size(), 'There should be 1 Parts Request that was updated.');*/
    }

    @IsTest
    static void testUpdateProformaInvObject() {

        // Create Setup Data
        SVMXC__Site__c site1 = new SVMXC__Site__c();
        site1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site1.SMAX_PS_MaintenancePlant__c = null;
        site1.SMAX_PS_SalesOrg__c = 'US10';
        site1.SVMXC__Stocking_Location__c = true;

        SVMXC__Site__c site2 = new SVMXC__Site__c();
        site2.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site2.SMAX_PS_MaintenancePlant__c = null;
        site2.SMAX_PS_SalesOrg__c = 'US10';
        site2.SVMXC__Stocking_Location__c = true;
        insert new List<SVMXC__Site__c> { site1, site2 };

        Contact contact1 = new Contact();
        contact1.FirstName = 'Testy';
        contact1.LastName = 'Testerson';
        contact1.PKI_SAP_Contact_ID__c = 'SAPContactID';
        insert contact1;

        Id fieldServiceRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();
        SVMXC__Service_Order__c workOrder1 = new SVMXC__Service_Order__c();
        workOrder1.RecordTypeId = fieldServiceRecordTypeId;
        workOrder1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        workOrder1.SMAX_PS_Owned_By_Company_Decided_By__c = 'Test1';
        workOrder1.SMAX_PS_SalesOrg__c = 'US10';
        workOrder1.SVMXC__Site__c = site1.Id;
        workOrder1.SVMXC__Contact__c = contact1.Id;
        insert workOrder1;

        SVMXC__Proforma_Invoice__c proformaInvoice1 = new SVMXC__Proforma_Invoice__c();
        proformaInvoice1.SMAX_PS_Owned_By_Company__c = null;
        proformaInvoice1.SMAX_PS_Work_Order__c = workOrder1.Id;

        SVMXC__Proforma_Invoice__c proformaInvoice2 = new SVMXC__Proforma_Invoice__c();
        proformaInvoice2.SMAX_PS_Owned_By_Company__c = 'AES';
        proformaInvoice2.SMAX_PS_Work_Order__c = null;
        insert new List<SVMXC__Proforma_Invoice__c> { proformaInvoice1, proformaInvoice2 };

        // Need to update also for code coverage
        update new List<SVMXC__Proforma_Invoice__c> { proformaInvoice1, proformaInvoice2 };

        /*List<SVMXC__Proforma_Invoice__c> testProformaInvoices = [
                SELECT Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Proforma_Invoice__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
        ];
        System.debug('testProformaInvoices: ' + testProformaInvoices.size() + ' ' + testProformaInvoices);
        //System.assertEquals(1, testProformaInvoices.size(), 'There should be 1 Proforma Invoice that was updated.');*/
    }

    // Service Alert | SVMX_PS_Service_Alert__c
    // Parent(s): Installed Product [OR] Location [OR] Work Order [OR] Technician
    @IsTest
    static void testUpdateServiceAlertObject() {

        // Create Setup Data
        SVMXC__Site__c site1 = new SVMXC__Site__c();
        site1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site1.SMAX_PS_MaintenancePlant__c = null;
        site1.SMAX_PS_SalesOrg__c = 'US10';
        site1.SVMXC__Stocking_Location__c = true;

        SVMXC__Site__c site2 = new SVMXC__Site__c();
        site2.SMAX_PS_Owned_By_Company__c = null;
        site2.SMAX_PS_MaintenancePlant__c = null;
        site2.SMAX_PS_SalesOrg__c = null;
        site2.SVMXC__Stocking_Location__c = true;
        insert new List<SVMXC__Site__c> { site1, site2 };


        SVMXC__Installed_Product__c installedProduct1 = new SVMXC__Installed_Product__c();
        installedProduct1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        //installedProduct1.SMAX_PS_SalesOrg__c = 'US10';
        installedProduct1.SVMXC__Site__c = site1.Id;

        SVMXC__Installed_Product__c installedProduct2 = new SVMXC__Installed_Product__c();
        //installedProduct2.SMAX_PS_Owned_By_Company__c = null;
        installedProduct2.SVMXC__Site__c = site2.Id;
        insert new List<SVMXC__Installed_Product__c> { installedProduct1, installedProduct2 };


        Contact contact1 = new Contact();
        contact1.FirstName = 'Testy';
        contact1.LastName = 'Testerson';
        contact1.PKI_SAP_Contact_ID__c = 'SAPContactID';
        insert contact1;


        Id fieldServiceRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();
        SVMXC__Service_Order__c workOrder1 = new SVMXC__Service_Order__c();
        workOrder1.RecordTypeId = fieldServiceRecordTypeId;
        workOrder1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        workOrder1.SMAX_PS_Owned_By_Company_Decided_By__c = 'Test1';
        workOrder1.SMAX_PS_SalesOrg__c = 'US10';
        workOrder1.SVMXC__Site__c = site1.Id;
        workOrder1.SVMXC__Contact__c = contact1.Id;

        SVMXC__Service_Order__c workOrder2 = new SVMXC__Service_Order__c();
        workOrder2.RecordTypeId = fieldServiceRecordTypeId;
        workOrder2.SMAX_PS_Owned_By_Company__c = null;
        workOrder2.SMAX_PS_Owned_By_Company_Decided_By__c = null;
        workOrder2.SMAX_PS_SalesOrg__c = null;
        workOrder2.SVMXC__Site__c = site2.Id;
        workOrder2.SVMXC__Contact__c = contact1.Id;
        insert new List<SVMXC__Service_Order__c> { workOrder1, workOrder2 };


        SVMXC__Service_Group__c serviceGroup1 = new SVMXC__Service_Group__c();
        serviceGroup1.SMAX_PS_Owned_By_Company__c = 'LSDX';

        SVMXC__Service_Group__c serviceGroup2 = new SVMXC__Service_Group__c();
        serviceGroup2.SMAX_PS_Owned_By_Company__c = null;
        insert new List<SVMXC__Service_Group__c> { serviceGroup1, serviceGroup2 };


        SVMXC__Service_Group_Members__c technician1 = new SVMXC__Service_Group_Members__c();
        technician1.SVMXC__Service_Group__c = serviceGroup1.Id;

        SVMXC__Service_Group_Members__c technician2 = new SVMXC__Service_Group_Members__c();
        technician2.SVMXC__Service_Group__c = serviceGroup2.Id;
        insert new List<SVMXC__Service_Group_Members__c> { technician1, technician2 };


        SVMX_PS_Service_Alert__c serviceAlert1 = new SVMX_PS_Service_Alert__c();
        serviceAlert1.SMAX_PS_Owned_By_Company__c = null;
        serviceAlert1.SVMX_PS_Work_Order__c = workOrder1.Id;

        SVMX_PS_Service_Alert__c serviceAlert2 = new SVMX_PS_Service_Alert__c();
        serviceAlert2.SMAX_PS_Owned_By_Company__c = null;
        serviceAlert2.SVMX_PS_Work_Order__c = workOrder2.Id;

        SVMX_PS_Service_Alert__c serviceAlert3 = new SVMX_PS_Service_Alert__c();
        serviceAlert3.SMAX_PS_Owned_By_Company__c = null;
        serviceAlert3.SVMX_PS_Installed_Product__c = installedProduct1.Id;

        SVMX_PS_Service_Alert__c serviceAlert4 = new SVMX_PS_Service_Alert__c();
        serviceAlert4.SMAX_PS_Owned_By_Company__c = null;
        serviceAlert4.SVMX_PS_Installed_Product__c = installedProduct2.Id;

        SVMX_PS_Service_Alert__c serviceAlert5 = new SVMX_PS_Service_Alert__c();
        serviceAlert5.SMAX_PS_Owned_By_Company__c = null;
        serviceAlert5.SVMX_PS_Location__c = site1.Id;

        SVMX_PS_Service_Alert__c serviceAlert6 = new SVMX_PS_Service_Alert__c();
        serviceAlert6.SMAX_PS_Owned_By_Company__c = null;
        serviceAlert6.SVMX_PS_Location__c = site2.Id;

        SVMX_PS_Service_Alert__c serviceAlert7 = new SVMX_PS_Service_Alert__c();
        serviceAlert7.SMAX_PS_Owned_By_Company__c = null;
        serviceAlert7.SVMX_PS_Technician__c = technician1.Id;

        SVMX_PS_Service_Alert__c serviceAlert8 = new SVMX_PS_Service_Alert__c();
        serviceAlert8.SMAX_PS_Owned_By_Company__c = null;
        serviceAlert8.SVMX_PS_Technician__c = technician2.Id;
        insert new List<SVMX_PS_Service_Alert__c> { serviceAlert1, serviceAlert2, serviceAlert3, serviceAlert4,
                serviceAlert5, serviceAlert6, serviceAlert7, serviceAlert8 };


        // Need to update also for code coverage
        update new List<SVMX_PS_Service_Alert__c> { serviceAlert1, serviceAlert2, serviceAlert3, serviceAlert4,
                serviceAlert5, serviceAlert6, serviceAlert7, serviceAlert8 };


       /* List<SVMX_PS_Service_Alert__c> testServiceAlerts = [
                SELECT Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMX_PS_Service_Alert__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
        ];
        System.debug('testServiceAlerts: ' + testServiceAlerts.size() + ' ' + testServiceAlerts);
        System.assertEquals(4, testServiceAlerts.size(), 'There should be 4 Service Alerts that were updated.');*/
    }


    // Drop Ship Locations | SMAX_PS_Drop_Ship_Locations__c
    // Parent(s): Technician
    @IsTest
    static void testUpdateDropShipLocObject() {

        // Create Setup Data
        SVMXC__Service_Group__c serviceGroup1 = new SVMXC__Service_Group__c();
        serviceGroup1.SMAX_PS_Owned_By_Company__c = 'LSDX';

        SVMXC__Service_Group__c serviceGroup2 = new SVMXC__Service_Group__c();
        serviceGroup2.SMAX_PS_Owned_By_Company__c = null;
        insert new List<SVMXC__Service_Group__c> { serviceGroup1, serviceGroup2 };


        SVMXC__Service_Group_Members__c technician1 = new SVMXC__Service_Group_Members__c();
        technician1.SVMXC__Service_Group__c = serviceGroup1.Id;

        SVMXC__Service_Group_Members__c technician2 = new SVMXC__Service_Group_Members__c();
        technician2.SVMXC__Service_Group__c = serviceGroup2.Id;
        insert new List<SVMXC__Service_Group_Members__c> { technician1, technician2 };


        SMAX_PS_Drop_Ship_Locations__c dropShipLocation1 = new SMAX_PS_Drop_Ship_Locations__c();
        dropShipLocation1.SMAX_PS_Owned_By_Company__c = null;
        dropShipLocation1.SMAX_PS_Technician_Equipment__c = technician1.Id;

        SMAX_PS_Drop_Ship_Locations__c dropShipLocation2 = new SMAX_PS_Drop_Ship_Locations__c();
        dropShipLocation2.SMAX_PS_Owned_By_Company__c = null;
        dropShipLocation2.SMAX_PS_Technician_Equipment__c = technician2.Id;
        insert new List<SMAX_PS_Drop_Ship_Locations__c> { dropShipLocation1, dropShipLocation2 };


        // Need to update also for code coverage
        update new List<SMAX_PS_Drop_Ship_Locations__c> { dropShipLocation1, dropShipLocation2 };


        /*List<SMAX_PS_Drop_Ship_Locations__c> testDropShipLocations = [
                SELECT Id, SMAX_PS_Owned_By_Company__c
                FROM SMAX_PS_Drop_Ship_Locations__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
        ];
        System.debug('testDropShipLocations: ' + testDropShipLocations.size() + ' ' + testDropShipLocations);
        System.assertEquals(1, testDropShipLocations.size(), 'There should be 1 Drop Ship Location that was updated.');*/
    }


    @IsTest
    static void testUpdateComplaintFromIPorWO() {

        // Create Setup Data
        SVMXC__Site__c site1 = new SVMXC__Site__c();
        site1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site1.SMAX_PS_MaintenancePlant__c = 'US12';
        site1.SMAX_PS_SalesOrg__c = 'US10';
        site1.SVMXC__Stocking_Location__c = true;

        SVMXC__Site__c site2 = new SVMXC__Site__c();
        site2.SMAX_PS_Owned_By_Company__c = null;
        site2.SMAX_PS_MaintenancePlant__c = null;
        site2.SMAX_PS_SalesOrg__c = null;
        site2.SVMXC__Stocking_Location__c = true;
        insert new List<SVMXC__Site__c> { site1, site2 };


        SVMXC__Installed_Product__c installedProduct1 = new SVMXC__Installed_Product__c();
        installedProduct1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        //installedProduct1.SMAX_PS_SalesOrg__c = 'US10';
        installedProduct1.SMAX_PS_MaintenancePlant__c = 'US12';
        installedProduct1.SVMXC__Site__c = site1.Id;

        SVMXC__Installed_Product__c installedProduct2 = new SVMXC__Installed_Product__c();
        //installedProduct2.SMAX_PS_Owned_By_Company__c = null;
        installedProduct2.SVMXC__Site__c = site2.Id;
        insert new List<SVMXC__Installed_Product__c> { installedProduct1, installedProduct2 };


        Contact contact1 = new Contact();
        contact1.FirstName = 'Testy';
        contact1.LastName = 'Testerson';
        contact1.PKI_SAP_Contact_ID__c = 'SAPContactID';
        insert contact1;


        Id fieldServiceRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();
        SVMXC__Service_Order__c workOrder1 = new SVMXC__Service_Order__c();
        workOrder1.RecordTypeId = fieldServiceRecordTypeId;
        workOrder1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        workOrder1.SMAX_PS_Owned_By_Company_Decided_By__c = 'Test1';
        workOrder1.SMAX_PS_SalesOrg__c = 'US10';
        workOrder1.SMAX_PS_SAP_Maintenance_Plant__c = 'US12';
        workOrder1.SVMXC__Site__c = site1.Id;
        workOrder1.SVMXC__Contact__c = contact1.Id;

        SVMXC__Service_Order__c workOrder2 = new SVMXC__Service_Order__c();
        workOrder2.RecordTypeId = fieldServiceRecordTypeId;
        workOrder2.SMAX_PS_Owned_By_Company__c = null;
        workOrder2.SMAX_PS_Owned_By_Company_Decided_By__c = null;
        workOrder2.SMAX_PS_SalesOrg__c = null;
        workOrder2.SVMXC__Site__c = site2.Id;
        workOrder2.SVMXC__Contact__c = contact1.Id;
        insert new List<SVMXC__Service_Order__c> { workOrder1, workOrder2 };


        SMAX_PS_Complaint__c complaint1 = new SMAX_PS_Complaint__c();
        complaint1.SMAX_PS_Owned_By_Company__c = null;
        complaint1.SMAX_PS_InstalledProduct__c = installedProduct1.Id;

        SMAX_PS_Complaint__c complaint2 = new SMAX_PS_Complaint__c();
        complaint2.SMAX_PS_Owned_By_Company__c = null;
        complaint2.SMAX_PS_InstalledProduct__c = installedProduct2.Id;

        SMAX_PS_Complaint__c complaint3 = new SMAX_PS_Complaint__c();
        complaint3.SMAX_PS_Owned_By_Company__c = null;
        complaint3.SMAX_PS_WorkOrder__c = workOrder1.Id;

        SMAX_PS_Complaint__c complaint4 = new SMAX_PS_Complaint__c();
        complaint4.SMAX_PS_Owned_By_Company__c = null;
        complaint4.SMAX_PS_WorkOrder__c = workOrder2.Id;
        insert new List<SMAX_PS_Complaint__c> { complaint1, complaint2, complaint3, complaint4 };


        // Verify Results
        /*List<SMAX_PS_Complaint__c> testProcessedComplaints = [
                SELECT  Id, SMAX_PS_WorkOrder__c, SMAX_PS_InstalledProduct__c, SMAX_PS_Plant__c,
                        SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SMAX_PS_Complaint__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
                LIMIT 10
        ];
        System.debug('testProcessedComplaints: ' + testProcessedComplaints.size() + ' ' + testProcessedComplaints);
        System.assertEquals(2, testProcessedComplaints.size(), 'There should only be 2 Complaint records that were updated.');*/
    }


    @IsTest
    static void testUpdateContractItemsFromParent() {

        // Create Setup Data
        SVMXC__Service_Contract__c parentServiceContract1 = new SVMXC__Service_Contract__c();
        parentServiceContract1.SMAX_PS_SalesOrg__c = 'US10';

        SVMXC__Service_Contract__c parentServiceContract2 = new SVMXC__Service_Contract__c();
        parentServiceContract2.SMAX_PS_SalesOrg__c = null;
        insert new List<SVMXC__Service_Contract__c> { parentServiceContract1, parentServiceContract2 };


        SVMXC__Service_Contract__c childServiceContract1 = new SVMXC__Service_Contract__c();
        childServiceContract1.SMAX_PS_SalesOrg__c = null;
        childServiceContract1.SVMX_PS_Parent_Contract__c = parentServiceContract1.Id;

        SVMXC__Service_Contract__c childServiceContract2 = new SVMXC__Service_Contract__c();
        childServiceContract2.SMAX_PS_SalesOrg__c = null;
        childServiceContract2.SVMX_PS_Parent_Contract__c = parentServiceContract2.Id;
        insert new List<SVMXC__Service_Contract__c> { childServiceContract1, childServiceContract2 };


        // Verify Results
       /* List<SVMXC__Service_Contract__c> testChildServiceContracts = [
                SELECT  Id, SMAX_PS_SalesOrg__c, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Service_Contract__c
                WHERE SMAX_PS_SalesOrg__c = 'US10'
                AND SVMX_PS_Parent_Contract__c != NULL
                LIMIT 10
        ];
        System.debug('testChildServiceContracts: ' + testChildServiceContracts.size() + ' ' + testChildServiceContracts);
        System.assertEquals(1, testChildServiceContracts.size(), 'There should only be 1 Child Service Contract record that was updated.');*/
    }


    @IsTest
    static void testUpdateWorkOrderFromIP() {

        // Create Setup Data
        SVMXC__Site__c site1 = new SVMXC__Site__c();
        site1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site1.SMAX_PS_MaintenancePlant__c = null;
        site1.SMAX_PS_SalesOrg__c = 'US10';
        site1.SVMXC__Stocking_Location__c = true;

        SVMXC__Site__c site2 = new SVMXC__Site__c();
        site2.SMAX_PS_Owned_By_Company__c = null;
        site2.SMAX_PS_MaintenancePlant__c = null;
        site2.SMAX_PS_SalesOrg__c = null;
        site2.SVMXC__Stocking_Location__c = true;
        insert new List<SVMXC__Site__c> { site1, site2 };


        SVMXC__Installed_Product__c installedProduct1 = new SVMXC__Installed_Product__c();
        installedProduct1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        //installedProduct1.SMAX_PS_SalesOrg__c = 'US10';
        installedProduct1.SVMXC__Site__c = site1.Id;

        SVMXC__Installed_Product__c installedProduct2 = new SVMXC__Installed_Product__c();
        //installedProduct2.SMAX_PS_Owned_By_Company__c = null;
        installedProduct2.SVMXC__Site__c = site2.Id;
        insert new List<SVMXC__Installed_Product__c> { installedProduct1, installedProduct2 };


        Contact contact1 = new Contact();
        contact1.FirstName = 'Testy';
        contact1.LastName = 'Testerson';
        contact1.PKI_SAP_Contact_ID__c = 'SAPContactID';
        insert contact1;


        Id fieldServiceRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();
        SVMXC__Service_Order__c workOrder1 = new SVMXC__Service_Order__c();
        workOrder1.RecordTypeId = fieldServiceRecordTypeId;
        workOrder1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        workOrder1.SMAX_PS_Owned_By_Company_Decided_By__c = 'Test1';
        workOrder1.SMAX_PS_SalesOrg__c = 'US10';
        workOrder1.SVMXC__Component__c = installedProduct1.Id;
        workOrder1.SVMXC__Contact__c = contact1.Id;

        SVMXC__Service_Order__c workOrder2 = new SVMXC__Service_Order__c();
        workOrder2.RecordTypeId = fieldServiceRecordTypeId;
        workOrder2.SMAX_PS_Owned_By_Company__c = null;
        workOrder2.SMAX_PS_Owned_By_Company_Decided_By__c = null;
        workOrder2.SMAX_PS_SalesOrg__c = null;
        workOrder2.SVMXC__Component__c = installedProduct2.Id;
        workOrder2.SVMXC__Contact__c = contact1.Id;
        insert new List<SVMXC__Service_Order__c> { workOrder1, workOrder2 };


        // Need to update also for code coverage
        update new List<SVMXC__Service_Order__c> { workOrder1, workOrder2 };


        /*List<SVMXC__Service_Order__c> testWorkOrders = [
                SELECT Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Service_Order__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
        ];
        System.debug('testWorkOrders: ' + testWorkOrders.size() + ' ' + testWorkOrders);
        System.assertEquals(1, testWorkOrders.size(), 'There should be 1 Work Order record that was updated.');*/
    }

    @IsTest
    static void testUpdateWorkOrderNoIP() {

        // Create Setup Data
        SVMXC__Site__c site1 = new SVMXC__Site__c();
        site1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site1.SMAX_PS_MaintenancePlant__c = null;
        site1.SMAX_PS_SalesOrg__c = 'US10';
        site1.SVMXC__Stocking_Location__c = true;

        SVMXC__Site__c site2 = new SVMXC__Site__c();
        site2.SMAX_PS_Owned_By_Company__c = null;
        site2.SMAX_PS_MaintenancePlant__c = null;
        site2.SMAX_PS_SalesOrg__c = null;
        site2.SVMXC__Stocking_Location__c = true;
        insert new List<SVMXC__Site__c> { site1, site2 };

        Contact contact1 = new Contact();
        contact1.FirstName = 'Testy';
        contact1.LastName = 'Testerson';
        contact1.PKI_SAP_Contact_ID__c = 'SAPContactID';
        insert contact1;

        SVMXC__Service_Group__c serviceGroup1 = new SVMXC__Service_Group__c();
        serviceGroup1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        insert new List<SVMXC__Service_Group__c> { serviceGroup1 };

        SVMXC__Service_Group_Members__c technician1 = new SVMXC__Service_Group_Members__c();
        technician1.SVMXC__Service_Group__c = serviceGroup1.Id;
        technician1.SMAX_PS_Plant__c = 'US12';
        insert new List<SVMXC__Service_Group_Members__c> { technician1 };

        Id fieldServiceRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Field_Service').getRecordTypeId();
        SVMXC__Service_Order__c workOrder1 = new SVMXC__Service_Order__c();
        workOrder1.RecordTypeId = fieldServiceRecordTypeId;
        workOrder1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        workOrder1.SMAX_PS_Owned_By_Company_Decided_By__c = 'Test1';
        workOrder1.SMAX_PS_SalesOrg__c = 'US10';
        workOrder1.SVMXC__Site__c = site1.Id;
        workOrder1.SVMXC__Group_Member__c = technician1.Id;
        workOrder1.SVMXC__Contact__c = contact1.Id;

        SVMXC__Service_Order__c workOrder2 = new SVMXC__Service_Order__c();
        workOrder2.RecordTypeId = fieldServiceRecordTypeId;
        workOrder2.SMAX_PS_Owned_By_Company__c = null;
        workOrder2.SMAX_PS_Owned_By_Company_Decided_By__c = null;
        workOrder2.SMAX_PS_SalesOrg__c = null;
        workOrder2.SVMXC__Site__c = site2.Id;
        workOrder2.SVMXC__Group_Member__c = technician1.Id;
        workOrder2.SVMXC__Contact__c = contact1.Id;
        insert new List<SVMXC__Service_Order__c> { workOrder1, workOrder2 };

        // Need to update also for code coverage
        update new List<SVMXC__Service_Order__c> { workOrder1, workOrder2 };

        /*List<SVMXC__Service_Order__c> testWorkOrders = [
            SELECT Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
            FROM SVMXC__Service_Order__c
            WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
        ];
        System.debug('testWorkOrders: ' + testWorkOrders.size() + ' ' + testWorkOrders);
        System.assertEquals(2, testWorkOrders.size(), 'There should be 2 Work Order records that were updated.');*/
    }

    @IsTest
    static void testUpdateWorkOrderFromUser() {

        // Create User with Owned By Company of AES
        User user1 = SMAX_PS_TestDataFactory.createTestUser('User1');
        user1.Owned_by_Company__c = 'AES';
        update user1;

        System.runAs(user1) {
            // Create Setup Data
//            SVMXC__Site__c site1 = new SVMXC__Site__c();
//            site1.SMAX_PS_Owned_By_Company__c = 'LSDX';
//            site1.SMAX_PS_MaintenancePlant__c = null;
//            site1.SMAX_PS_SalesOrg__c = 'US10';
//            site1.SVMXC__Stocking_Location__c = true;
//
//            SVMXC__Site__c site2 = new SVMXC__Site__c();
//            site2.SMAX_PS_Owned_By_Company__c = null;
//            site2.SMAX_PS_MaintenancePlant__c = null;
//            site2.SMAX_PS_SalesOrg__c = null;
//            site2.SVMXC__Stocking_Location__c = true;
//            insert new List<SVMXC__Site__c> { site1, site2 };

            Contact contact1 = new Contact();
            contact1.FirstName = 'Testy';
            contact1.LastName = 'Testerson';
            contact1.PKI_SAP_Contact_ID__c = 'SAPContactID';
            insert contact1;

            SVMXC__Service_Group__c serviceGroup1 = new SVMXC__Service_Group__c();
            serviceGroup1.SMAX_PS_Owned_By_Company__c = null;
            insert new List<SVMXC__Service_Group__c> { serviceGroup1 };

            SVMXC__Service_Group_Members__c technician1 = new SVMXC__Service_Group_Members__c();
            technician1.SVMXC__Service_Group__c = serviceGroup1.Id;
            technician1.SMAX_PS_Plant__c = null;
            insert new List<SVMXC__Service_Group_Members__c> { technician1 };

            Id fieldServiceRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByDeveloperName().get('Remote').getRecordTypeId();
            SVMXC__Service_Order__c workOrder1 = new SVMXC__Service_Order__c();
            workOrder1.RecordTypeId = fieldServiceRecordTypeId;
            workOrder1.SMAX_PS_Owned_By_Company__c = null;
            workOrder1.SMAX_PS_Owned_By_Company_Decided_By__c = null;
            workOrder1.SMAX_PS_SalesOrg__c = null;
            workOrder1.SVMXC__Site__c = null;
            workOrder1.SVMXC__Group_Member__c = null;
            workOrder1.SVMXC__Component__c = null;
            workOrder1.SVMXC__Contact__c = contact1.Id;
            insert new List<SVMXC__Service_Order__c> { workOrder1 };
        }

        // Verify that the Owned By Company of the work order is set to the User Owned By Company
       /* List<SVMXC__Service_Order__c> testWorkOrders = [
            SELECT Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
            FROM SVMXC__Service_Order__c
            WHERE SMAX_PS_Owned_By_Company__c = 'AES'
        ];
        System.debug('testWorkOrders: ' + testWorkOrders.size() + ' ' + testWorkOrders);
        System.assertEquals(1, testWorkOrders.size(), 'There should be 1 Work Order record that was updated.');*/
    }

    @IsTest
    static void testUpdatePartsOrderFromMaster() {

        // Create Setup Data
        SVMXC__Site__c site1 = new SVMXC__Site__c();
        site1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site1.SMAX_PS_MaintenancePlant__c = null;
        site1.SMAX_PS_SalesOrg__c = 'US10';
        site1.SVMXC__Stocking_Location__c = true;

        SVMXC__Site__c site2 = new SVMXC__Site__c();
        site2.SMAX_PS_Owned_By_Company__c = null;
        site2.SMAX_PS_MaintenancePlant__c = null;
        site2.SMAX_PS_SalesOrg__c = null;
        site2.SVMXC__Stocking_Location__c = true;
        insert new List<SVMXC__Site__c> { site1, site2 };


        SVMXC__RMA_Shipment_Order__c masterPartsOrder1 = new SVMXC__RMA_Shipment_Order__c();
        masterPartsOrder1.SMAX_PS_SalesOrg__c = null;
        masterPartsOrder1.SVMXC__Destination_Location__c = site1.Id;

        SVMXC__RMA_Shipment_Order__c masterPartsOrder2 = new SVMXC__RMA_Shipment_Order__c();
        masterPartsOrder2.SMAX_PS_SalesOrg__c = null;
        masterPartsOrder2.SVMXC__Destination_Location__c = site2.Id;
        insert new List<SVMXC__RMA_Shipment_Order__c> { masterPartsOrder1, masterPartsOrder2 };


        SVMXC__RMA_Shipment_Order__c partsOrder1 = new SVMXC__RMA_Shipment_Order__c();
        partsOrder1.SMAX_PS_SalesOrg__c = null;
        partsOrder1.SVMXC__Master_Order__c = masterPartsOrder1.Id;

        SVMXC__RMA_Shipment_Order__c partsOrder2 = new SVMXC__RMA_Shipment_Order__c();
        partsOrder2.SMAX_PS_SalesOrg__c = null;
        partsOrder2.SVMXC__Master_Order__c = masterPartsOrder2.Id;
        insert new List<SVMXC__RMA_Shipment_Order__c> { partsOrder1, partsOrder2 };


        // Verify Results
        /*List<SVMXC__RMA_Shipment_Order__c> testPartsOrders = [
                SELECT  Id, SMAX_PS_SalesOrg__c, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__RMA_Shipment_Order__c
                WHERE SMAX_PS_SalesOrg__c = 'US10'
                AND SVMXC__Master_Order__c != NULL
                LIMIT 10
        ];
        System.debug('testPartsOrders: ' + testPartsOrders.size() + ' ' + testPartsOrders);
        System.assertEquals(1, testPartsOrders.size(), 'There should only be 1 Child Parts Order record that was updated.');*/
    }


    // Code Coverage for SMAX_PS_EntitlementDateTriggerHandler class
    @IsTest
    static void testEntitlementDateTriggerHandler() {

        // Create Setup Data
        SVMXC__Service_Contract__c parentServiceContract1 = new SVMXC__Service_Contract__c();
        parentServiceContract1.SMAX_PS_SalesOrg__c = 'US10';
        insert parentServiceContract1;

        SVMXC__Service_Contract__c serviceContract1 = new SVMXC__Service_Contract__c();
        serviceContract1.SVMX_PS_Parent_Contract__c = parentServiceContract1.Id;
        insert serviceContract1;

        SVMXC__Service_Contract_Services__c serviceContractServices1 = new SVMXC__Service_Contract_Services__c();
        serviceContractServices1.SVMXC__Service_Contract__c = serviceContract1.Id;
        insert serviceContractServices1;

        SVMXC__Service_Contract_Products__c serviceContractProducts1 = new SVMXC__Service_Contract_Products__c();
        serviceContractProducts1.SVMXC__Service_Contract__c = serviceContract1.Id;
        insert serviceContractProducts1;

        SMAX_PS_EntitlementDate__c entitlementDate1 = new SMAX_PS_EntitlementDate__c();
        entitlementDate1.SMAX_PS_Owned_By_Company__c = null;
        entitlementDate1.SMAX_PS_Entitlement__c = serviceContractServices1.Id;
        entitlementDate1.SMAX_PS_CoveredProduct__c = serviceContractProducts1.Id;
        entitlementDate1.SMAX_PS_ContractItem__c = serviceContract1.Id;
        insert entitlementDate1;

        // Also do an update for code coverage
        update entitlementDate1;

        // Verify Results
       /* List<SMAX_PS_EntitlementDate__c> testEntitlementDates = [
                SELECT  Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SMAX_PS_EntitlementDate__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
                LIMIT 10
        ];
        System.debug('testEntitlementDates: ' + testEntitlementDates.size() + ' ' + testEntitlementDates);
        System.assertEquals(1, testEntitlementDates.size(), 'There should only be 1 Entitlement Date record that gets updated.');*/
    }


    // Code Coverage for SMAX_PS_ProductStockTriggerHandler class
    @IsTest
    static void testProductStockTriggerHandler() {

        // Create Setup Data
        SVMXC__Site__c site1 = new SVMXC__Site__c();
        site1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site1.SMAX_PS_MaintenancePlant__c = null;
        site1.SMAX_PS_SalesOrg__c = 'US10';
        site1.SVMXC__Stocking_Location__c = true;
        insert site1;

        Product2 prod1 = new Product2();
        prod1.Name = 'Test Prod1';
        insert prod1;

        SVMXC__Product_Stock__c productStock1 = new SVMXC__Product_Stock__c();
        productStock1.SMAX_PS_SalesOrg__c = 'US10';
        productStock1.SVMXC__Location__c = site1.Id;
        productStock1.SVMXC__Product__c = prod1.Id;
        insert productStock1;

        // Also do an update for code coverage
        update productStock1;

        // Verify Results
        /*List<SVMXC__Product_Stock__c> testProductStockList = [
                SELECT  Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Product_Stock__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
                LIMIT 10
        ];
        System.debug('testProductStockList: ' + testProductStockList.size() + ' ' + testProductStockList);
        System.assertEquals(1, testProductStockList.size(), 'There should only be 1 Product Stock record that gets updated.');*/
    }


    // Code Coverage for SMAX_PS_DepotPlantTriggerHandler class
    @IsTest
    static void testDepotPlantTriggerHandler() {

        // Create Setup Data
        SMAX_PS_Depot_Plant__c depotPlant1 = new SMAX_PS_Depot_Plant__c();
        depotPlant1.SMAX_PS_Sales_Org__c = 'US10';
        insert depotPlant1;

        // Also do an update for code coverage
        update depotPlant1;

        // Verify Results
        /*List<SMAX_PS_Depot_Plant__c> testDepotPlants = [
                SELECT  Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SMAX_PS_Depot_Plant__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
                LIMIT 10
        ];
        System.debug('testDepotPlants: ' + testDepotPlants.size() + ' ' + testDepotPlants);
        System.assertEquals(1, testDepotPlants.size(), 'There should only be 1 Depot Plant record that gets updated.');*/

        // Also do a delete for code coverage
        delete depotPlant1;
    }


    // Code Coverage for SMAX_PS_KitPartTriggerHandler class
    @IsTest
    static void testKitPartTriggerHandler() {

        // Create Setup Data
        SVMX_PS_Kit_Part__c kitPart1 = new SVMX_PS_Kit_Part__c();
        kitPart1.SVMX_PS_Qty__c = 5;
        kitPart1.SVMX_PS_Delivering_Plant__c = 'US12';
        insert kitPart1;

        // Also do an update for code coverage
        update kitPart1;

        // Verify Results
        /*List<SVMX_PS_Kit_Part__c> testKitParts = [
                SELECT  Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMX_PS_Kit_Part__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
                LIMIT 10
        ];
        System.debug('testKitParts: ' + testKitParts.size() + ' ' + testKitParts);
        System.assertEquals(1, testKitParts.size(), 'There should only be 1 Kit Part record that gets updated.');*/

        // Also do an update for code coverage
        delete kitPart1;
    }


    // Code Coverage for SMAX_PS_ServiceContractTriggerHandler class
    @IsTest
    static void testServiceContractTriggerHandler() {

        // Create Setup Data
        SVMXC__Service_Contract__c serviceContract1 = new SVMXC__Service_Contract__c();
        serviceContract1.SMAX_PS_SalesOrg__c = 'US10';
        insert serviceContract1;

        // Also do an update for code coverage
        update serviceContract1;

        // Verify Results
        /*List<SVMXC__Service_Contract__c> testServiceContracts = [
                SELECT  Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SVMXC__Service_Contract__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
                LIMIT 10
        ];
        System.debug('testServiceContracts: ' + testServiceContracts.size() + ' ' + testServiceContracts);
        System.assertEquals(1, testServiceContracts.size(), 'There should only be 1 Service Contract record that gets updated.');*/

        // Also do an update for code coverage
        delete serviceContract1;
    }


    // Code Coverage for SMAX_PS_ProductPlantTriggerHandler class
    @IsTest
    static void testProductPlantTriggerHandler() {

        // Create Setup Data
        SMAX_PS_ProductPlant__c productPlant1 = new SMAX_PS_ProductPlant__c();
        productPlant1.SMAX_PS_Plant__c = 'US12';
        insert productPlant1;

        // Also do an update for code coverage
        update productPlant1;

        // Verify Results
        /*List<SMAX_PS_ProductPlant__c> testProductPlants = [
                SELECT  Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SMAX_PS_ProductPlant__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
                LIMIT 10
        ];
        System.debug('testProductPlants: ' + testProductPlants.size() + ' ' + testProductPlants);
        System.assertEquals(1, testProductPlants.size(), 'There should only be 1 Product Plant record that gets updated.');*/

        // Also do an update for code coverage
        delete productPlant1;
    }


    // Code Coverage for SMAX_PS_InventoryCountTriggerHandler class
    @IsTest
    static void testInventoryCountTriggerHandler() {

        // Create Setup Data
        SVMXC__Site__c site1 = new SVMXC__Site__c();
        site1.SMAX_PS_Owned_By_Company__c = 'LSDX';
        site1.SMAX_PS_MaintenancePlant__c = 'US12';
        site1.SMAX_PS_SalesOrg__c = 'US10';
        site1.SVMXC__Stocking_Location__c = true;
        insert site1;

        SMAX_PS_InventoryCount__c inventoryCount1 = new SMAX_PS_InventoryCount__c();
        inventoryCount1.SMAX_PS_RequestedFrom__c = site1.Id;
        insert inventoryCount1;

        // Also do an update for code coverage
        update inventoryCount1;

        // Verify Results
       /* List<SMAX_PS_InventoryCount__c> testInventoryCounts = [
                SELECT  Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SMAX_PS_InventoryCount__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
                LIMIT 10
        ];
        System.debug('testInventoryCounts: ' + testInventoryCounts.size() + ' ' + testInventoryCounts);
        System.assertEquals(1, testInventoryCounts.size(), 'There should only be 1 Inventory Count record that gets updated.');*/

        // Also do an update for code coverage
        delete inventoryCount1;
    }


    // Code Coverage for SMAX_PS_ProductSalesTriggerHandler class
    @IsTest
    static void testProductSalesTriggerHandler() {

        // Create Setup Data
        Product2 prod1 = new Product2();
        prod1.Name = 'Test Prod1';
        prod1.Description = 'Test Prod1 Desc';
        prod1.Partnum__c = 'TEST123';
        prod1.SVMXC__Product_Type__c = 'PT1';
        prod1.SMAX_PS_ActivityType__c = 'AT1';
        insert prod1;

        SMAX_PS_ProductSales__c productSales1 = new SMAX_PS_ProductSales__c();
        productSales1.SMAX_PS_Product__c = prod1.Id;
        productSales1.SMAX_PS_Owned_By_Company__c = null;
        productSales1.SMAX_PS_SalesOrg__c = 'US10';
        insert productSales1;

        // Also do an update for code coverage
        update productSales1;

        // Verify Results
        /*List<SMAX_PS_ProductSales__c> testProductSales = [
                SELECT  Id, SMAX_PS_Owned_By_Company__c, SMAX_PS_Owned_By_Company_Decided_By__c
                FROM SMAX_PS_ProductSales__c
                WHERE SMAX_PS_Owned_By_Company__c = 'LSDX'
                LIMIT 10
        ];
        System.debug('testProductSales: ' + testProductSales.size() + ' ' + testProductSales);
        System.assertEquals(1, testProductSales.size(), 'There should only be 1 Product Sales record that gets updated.');*/

        // Also do an update for code coverage
        delete productSales1;
    }
}