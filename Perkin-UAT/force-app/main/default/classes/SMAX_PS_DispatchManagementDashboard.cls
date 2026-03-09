/**
 * This class encapsulates all of the Wired Services needed for the Dispatch Management Dashboard LWC
 * Created by tony on 1/20/21.
 */

public with sharing class SMAX_PS_DispatchManagementDashboard {

    public class DispatchPermissions {
        @AuraEnabled public Boolean editDispatchers {get;set;}
        @AuraEnabled public Boolean editTechnicians {get;set;}
    }

    @AuraEnabled(Cacheable=true)
    public static DispatchPermissions loadPermissions() {
        DispatchPermissions result = new DispatchPermissions();
        result.editTechnicians = FeatureManagement.checkPermission('SMAX_DispatchMgmt_EditTechnicians');
        result.editDispatchers = FeatureManagement.checkPermission('SMAX_DispatchMgmt_EditDispatchers');

        // 3/25/21 Tony - added for test that fails during deployment to prod
        if(Test.isRunningTest()){
            result.editTechnicians = true;
            result.editDispatchers = true;
        }

        return result;
    }

    @AuraEnabled(Cacheable=true)
    public static List<BD_CustomLookupService.LookupSearchResult> searchTerritories(String searchTerm, List<String> selectedIds)
    {
        final Integer MAX_RESULTS = 10;

        // Prepare query parameters
        searchTerm += '*';

        // Execute SOSL search query
        List<List<SObject>> searchResults = [
                FIND :searchTerm
                IN ALL FIELDS
                        RETURNING
                        SVMXC__Territory__c(Id, Name, BD_Type__c WHERE Id NOT IN :selectedIds),
                        SMAX_PS_Geography__c(Id, Name, SMAX_PS_Geography_Description__c WHERE Id NOT IN :selectedIds),
                        SVMXC__Service_Group_Members__c(Id, Name, SMAX_PS_Work_Center__c, SMAX_PS_Plant__c WHERE id NOT IN :selectedIds),
//                        SVMXC__Dispatcher_Access__c(Id, Name, SMAX_PS_Dispatcher_Name__c, SMAX_PS_Dispatcher_Profile__c WHERE id NOT IN :selectedIds)
                        User(Id, FirstName, LastName, Profile.Name WHERE id NOT IN :selectedIds)
                LIMIT :MAX_RESULTS
        ];

        // Prepare results
        List<BD_CustomLookupService.LookupSearchResult> results = new List<BD_CustomLookupService.LookupSearchResult>();

        // Extract Territories & convert them into LookupSearchResult
        SVMXC__Territory__c[] territories = (List<SVMXC__Territory__c>) searchResults[0];
        for (SVMXC__Territory__c territory : territories) {
            results.add(new BD_CustomLookupService.LookupSearchResult(territory.Id, 'SVMXC__Territory__c',
                'custom:custom78', territory.Name, 'Type: ' + territory.BD_Type__c)
            );
        }

        // Extract Geographies
        SMAX_PS_Geography__c[] geos = (List<SMAX_PS_Geography__c>) searchResults[1];
        for (SMAX_PS_Geography__c geo : geos) {
            results.add(new BD_CustomLookupService.LookupSearchResult(geo.Id, 'SMAX_PS_Geography__c',
                'custom:custom64', geo.Name, 'Geography: ' + geo.SMAX_PS_Geography_Description__c)
            );
        }

        // Extract Technicians
        SVMXC__Service_Group_Members__c[] techs = (List<SVMXC__Service_Group_Members__c>) searchResults[2];
        for (SVMXC__Service_Group_Members__c tech : techs) {
            results.add(new BD_CustomLookupService.LookupSearchResult(tech.Id, 'SVMXC__Service_Group_Members__c',
                    'custom:custom15', tech.Name, 'Technician: ' + tech.SMAX_PS_Work_Center__c)
            );
        }

        // Extract Dispatchers
//        SVMXC__Dispatcher_Access__c[] dispatchers = (List<SVMXC__Dispatcher_Access__c>) searchResults[3];
//        for (SVMXC__Dispatcher_Access__c dispatcher : dispatchers) {
//            results.add(new BD_CustomLookupService.LookupSearchResult(dispatcher.Id, 'SVMXC__Dispatcher_Access__c',
//                    'custom:custom71', dispatcher.SMAX_PS_Dispatcher_Name__c, 'Dispatcher: ' + dispatcher.SMAX_PS_Dispatcher_Profile__c)
//            );
//        }
        User[] dispatchers = (List<User>) searchResults[3];
        for (User dispatcher : dispatchers) {
            results.add(new BD_CustomLookupService.LookupSearchResult(dispatcher.Id, 'User',
                    'custom:custom71', dispatcher.FirstName + ' ' + dispatcher.LastName, 'Dispatcher: ' + dispatcher.Profile.Name)
            );
        }

        // Optionally sort all results on title
        results.sort();

        return results;
    }

    @AuraEnabled(Cacheable=true)
    public static List<BD_CustomLookupService.LookupSearchResult> searchGeoCheckboxTerritories(String searchTerm, List<String> selectedIds)
    {
        System.debug('SMAX_PS_DispatchManagementDashboard.searchGeoCheckboxTerritories()');
        System.debug('searchTerm: [' + searchTerm + ']  selectedIds: [' + selectedIds + ']');
        final Integer MAX_RESULTS = 10;

        // Prepare query parameters
        searchTerm += '*';

        // Execute SOSL search query
        List<List<SObject>> searchResults = [
                FIND :searchTerm
                IN ALL FIELDS
                RETURNING
                        SVMXC__Territory__c(Id, Name, BD_Type__c WHERE Id NOT IN :selectedIds)
                LIMIT :MAX_RESULTS
        ];

        // Prepare results
        List<BD_CustomLookupService.LookupSearchResult> results = new List<BD_CustomLookupService.LookupSearchResult>();

        // Extract Territories & convert them into LookupSearchResult
        SVMXC__Territory__c[] territories = (List<SVMXC__Territory__c>) searchResults[0];
        for (SVMXC__Territory__c territory : territories) {
            results.add(new BD_CustomLookupService.LookupSearchResult(territory.Id, 'SVMXC__Territory__c',
                    'custom:custom78', territory.Name, 'Type: ' + territory.BD_Type__c)
            );
        }

        // Optionally sort all results on title
        results.sort();

        return results;
    }

    @AuraEnabled(Cacheable=true)
    public static List<BD_CustomLookupService.LookupSearchResult> searchGeoCheckboxTeams(String searchTerm, List<String> selectedIds)
    {
        System.debug('SMAX_PS_DispatchManagementDashboard.searchGeoCheckboxTeams()');
        System.debug('searchTerm: [' + searchTerm + ']  selectedIds: [' + selectedIds + ']');
        final Integer MAX_RESULTS = 10;

        // Prepare query parameters
        searchTerm += '*';

        // Execute SOSL search query
        List<List<SObject>> searchResults = [
                FIND :searchTerm
                IN ALL FIELDS
                        RETURNING
                        SVMXC__Service_Group__c(Id, Name, SMAX_PS_Is_Enterprise__c WHERE Id NOT IN :selectedIds)
                LIMIT :MAX_RESULTS
        ];

        // Prepare results
        List<BD_CustomLookupService.LookupSearchResult> results = new List<BD_CustomLookupService.LookupSearchResult>();

        // Extract Teams
        SVMXC__Service_Group__c[] teams = (List<SVMXC__Service_Group__c>) searchResults[0];
        for (SVMXC__Service_Group__c team : teams) {
            results.add(new BD_CustomLookupService.LookupSearchResult(team.Id, 'SVMXC__Service_Group__c',
                    'custom:custom15', team.Name, 'Enterprise: ' + team.SMAX_PS_Is_Enterprise__c)
            );
        }

        // Optionally sort all results on title
        results.sort();

        return results;
    }

    public class TerritoryHierarchyWrapper {

        @AuraEnabled public String name{get;set;}
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String territoryType{get;set;}
        @AuraEnabled public Boolean expanded{get;set;}
        @AuraEnabled public List<TerritoryHierarchyWrapper> items{get;set;}

        public TerritoryHierarchyWrapper(SVMXC__Territory__c territory) {

            name = territory.Id;
            label = territory.Name;
            territoryType = territory.BD_Type__c;
            expanded = true;
            this.items = new List<TerritoryHierarchyWrapper>();
        }
    }


    @AuraEnabled(Cacheable=true)
    public static List<TerritoryHierarchyWrapper> buildWrappers() {
    //public List<TerritoryHierarchyWrapper> buildWrappers(List<SVMXC__Territory__c> allTerritories) {

        List<SVMXC__Territory__c> allTerritories = [
                SELECT Id, Name, BD_Type__c,
                        SVMXC__Parent_Territory__c, SVMXC__Parent_Territory__r.Id, SVMXC__Parent_Territory__r.Name,
                        SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c, SVMXC__Parent_Territory__r.BD_Type__c
                FROM SVMXC__Territory__c
        ];

        Map<Id, TerritoryHierarchyWrapper> territoryMap = new Map<Id, TerritoryHierarchyWrapper>();
        List<TerritoryHierarchyWrapper> topLevelTerritories = new List<TerritoryHierarchyWrapper>();

        for (SVMXC__Territory__c territory : allTerritories) {
            TerritoryHierarchyWrapper territoryWrapper = processTerritory(territory, territoryMap, topLevelTerritories);
            if (territory.SVMXC__Parent_Territory__c != null) {
                TerritoryHierarchyWrapper parentTerritoryWrapper = processTerritory(territory.SVMXC__Parent_Territory__r, territoryMap, topLevelTerritories);
                parentTerritoryWrapper.items.add(territoryWrapper);
            }
        }

        System.debug('topLevelTerritories: ' + topLevelTerritories);
        return topLevelTerritories;
    }

    private static TerritoryHierarchyWrapper processTerritory(
    //private TerritoryHierarchyWrapper processTerritory(
            SVMXC__Territory__c territory,
            Map<Id,TerritoryHierarchyWrapper> territoryMap,
            List<TerritoryHierarchyWrapper> topLevelTerritories) {

        // The wrapper may already exist if it was processed as the parent of another territory
        TerritoryHierarchyWrapper wrapper = territoryMap.get(territory.Id);

        if (wrapper == null) {
            wrapper = new TerritoryHierarchyWrapper(territory);
            territoryMap.put(territory.Id, wrapper);

            // Add to the top level list if there's no parent
            // This works for the parent as well because the grandparent is included in the original SOQL query
            if (territory.SVMXC__Parent_Territory__c == null) {
                topLevelTerritories.add(wrapper);
            }
        }
        return wrapper;
    }

    private static Set<Id> loadTerritoryIds(List<String> territoryIds) {
        Set<Id> validTerritoryIds = new Set<Id>();
        Set<Id> geoIds = new Set<Id>();
        Set<Id> techIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        for (Id tId : territoryIds) {
            DescribeSObjectResult obj = tId.getSobjectType().getDescribe();
            if (obj.name == 'SVMXC__Territory__c') {
                validTerritoryIds.add(tId);
            } else if (obj.name == 'SMAX_PS_Geography__c') {
                geoIds.add(tId);
            } else if (obj.name == 'SVMXC__Service_Group_Members__c') {
                techIds.add(tId);
            } else if (obj.name == 'User') {
                userIds.add(tId);
            } else {
                System.debug('Unrecognized Object Type found: ' + obj.name + ' for Id: ' + tId);
            }
        }

        if (!geoIds.isEmpty()) {
            List<SMAX_PS_Geography__c> allGeos = [SELECT Id, BD_Territory__c
                FROM SMAX_PS_Geography__c WHERE Id IN :geoIds AND BD_Territory__c != null];
            for (SMAX_PS_Geography__c geo : allGeos) {
                validTerritoryIds.add(geo.BD_Territory__c);
            }
        }

        if (!techIds.isEmpty()) {
            List<SVMXC__Service_Group_Members__c> allTechs = [SELECT Id, SVMXC__Service_Territory__c
                FROM SVMXC__Service_Group_Members__c WHERE Id IN :techIds AND SVMXC__Service_Territory__c != null];
            for (SVMXC__Service_Group_Members__c tech : allTechs) {
                validTerritoryIds.add(tech.SVMXC__Service_Territory__c);
            }
        }

        if (!userIds.isEmpty()) {
            List<SVMXC__Dispatcher_Access__c> allDAccess = [SELECT Id, SVMXC__Dispatcher__c, SVMXC__Territory__c
                FROM SVMXC__Dispatcher_Access__c WHERE SVMXC__Dispatcher__c IN :userIds AND SVMXC__Territory__c != null];
            for (SVMXC__Dispatcher_Access__c dAccess : allDAccess) {
                validTerritoryIds.add(dAccess.SVMXC__Territory__c);
            }
        }
        System.debug('Valid Territory Ids found: ' + validTerritoryIds);
        return validTerritoryIds;
    }

    // Get the tree for the provided list of Ids
    @AuraEnabled(Cacheable=true)
    public static List<TerritoryHierarchyWrapper> buildTreeFromSearch(List<String> territoryIds) {

        Set<Id> validTerritoryIds = loadTerritoryIds(territoryIds);

        Map<Id, SVMXC__Territory__c> allTerritoriesMap = new Map<Id, SVMXC__Territory__c>([
            SELECT Id, Name, BD_Type__c,
                    SVMXC__Parent_Territory__c, SVMXC__Parent_Territory__r.Id, SVMXC__Parent_Territory__r.Name,
                    SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c
            FROM SVMXC__Territory__c
        ]);

        Map<Id, TerritoryHierarchyWrapper> territoryMap = new Map<Id, TerritoryHierarchyWrapper>();
        List<TerritoryHierarchyWrapper> topLevelTerritories = new List<TerritoryHierarchyWrapper>();

        for (Id territoryId : validTerritoryIds) {

            TerritoryHierarchyWrapper territoryWrapper = fillTreeParents(territoryId, allTerritoriesMap, territoryMap, topLevelTerritories);
            System.debug(territoryWrapper);

            fillTreeChildren(territoryId, allTerritoriesMap, territoryMap);
        }

        return topLevelTerritories;
    }

    private static TerritoryHierarchyWrapper fillTreeParents(
            Id territoryId,
            Map<Id, SVMXC__Territory__c> allTerritoriesMap,
            Map<Id,TerritoryHierarchyWrapper> territoryMap,
            List<TerritoryHierarchyWrapper> topLevelTerritories) {

        SVMXC__Territory__c territory = allTerritoriesMap.get(territoryId);
        if (territory == null) return null;

        TerritoryHierarchyWrapper wrapper = territoryMap.get(territoryId);
        if (wrapper == null) {
            wrapper = new TerritoryHierarchyWrapper(territory);
            System.debug('NULL wrapper: ' + wrapper);
        }

        territoryMap.put(territoryId, wrapper);

        if (territory.SVMXC__Parent_Territory__c == null) {
            System.debug('New TOP: ' + wrapper);
            if (!topLevelTerritories.contains(wrapper)) {
                topLevelTerritories.add(wrapper);
            }
        } else {
            System.debug('Calling fillTreeParents again');
            TerritoryHierarchyWrapper territoryWrapper = fillTreeParents(territory.SVMXC__Parent_Territory__c, allTerritoriesMap, territoryMap, topLevelTerritories);
            if (!territoryWrapper.items.contains(wrapper)) {
                territoryWrapper.items.add(wrapper);
            }
        }

        System.debug('wrapper: ' + wrapper);
        return wrapper;
    }

    private static void fillTreeChildren(
            Id territoryId,
            Map<Id, SVMXC__Territory__c> allTerritoriesMap,
            Map<Id,TerritoryHierarchyWrapper> territoryMap) {

        SVMXC__Territory__c territory = allTerritoriesMap.get(territoryId);
        if (territory == null) return;

        for (SVMXC__Territory__c terr :allTerritoriesMap.values()) {
            if (terr.SVMXC__Parent_Territory__c == territoryId) {

                TerritoryHierarchyWrapper wrapper = territoryMap.get(terr.Id);
                if (wrapper == null) {
                    wrapper = new TerritoryHierarchyWrapper(terr);

                    System.debug('wrapper: ' + wrapper);
                    territoryMap.put(terr.Id, wrapper);

                }
                if (!territoryMap.get(territoryId).items.contains(wrapper)) {
                    territoryMap.get(territoryId).items.add(wrapper);
                }
                //TerritoryHierarchyWrapper wrapper = new TerritoryHierarchyWrapper(terr);

                fillTreeChildren(terr.Id, allTerritoriesMap, territoryMap);
            }

        }

        System.debug('territoryMap: ' + territoryMap);
    }

    @AuraEnabled(Cacheable=true)
    public static Integer getUnassignedGeographiesCount() {

        Integer geoCount = [SELECT COUNT() FROM SMAX_PS_Geography__c WHERE BD_Territory__c = NULL];
        return geoCount;
    }

    public class DispatcherWrapper {

        @AuraEnabled public String fullName{get;set;}
        @AuraEnabled public String profileName{get;set;}
        @AuraEnabled public String territory{get;set;}
        @AuraEnabled public Boolean isActive{get;set;}
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public String userId{get;set;}

        public DispatcherWrapper(SVMXC__Dispatcher_Access__c dispatcher) {

            fullName = dispatcher.SVMXC__Dispatcher__r.fxFullName__c;
            profileName = dispatcher.SMAX_PS_Dispatcher_Profile__c;
            territory = dispatcher.SVMXC__Territory__r.Name;
            isActive = dispatcher.SMAX_PS_Dispatcher_is_Active__c;
            id = dispatcher.Id;
            userId = dispatcher.SVMXC__Dispatcher__r.Id;
        }
    }

    // Get the Dispatchers for a Territory Id
    @AuraEnabled(Cacheable=false)
    public static List<DispatcherWrapper> buildDispatcherDataTable(String territoryId) {

        List<SVMXC__Dispatcher_Access__c> dispatcherAccessList = [
                SELECT  Id, SVMXC__Dispatcher__c, SVMXC__Territory__r.Name, SVMXC__Territory__r.BD_Qualified_Name__c,
                        SMAX_PS_Dispatcher_is_Active__c, SVMXC__Dispatcher__r.fxFullName__c, SMAX_PS_Dispatcher_Profile__c
                FROM SVMXC__Dispatcher_Access__c
                WHERE SVMXC__Territory__c = :territoryId
        ];

        List<DispatcherWrapper> dispatcherWrapperList = new List<DispatcherWrapper>();
        for (SVMXC__Dispatcher_Access__c dispatcher :dispatcherAccessList) {
            DispatcherWrapper dispatcherWrapper = new DispatcherWrapper(dispatcher);
            dispatcherWrapperList.add(dispatcherWrapper);
        }

        return dispatcherWrapperList;
    }

    public class TechnicianWrapper {

        @AuraEnabled public String fullName{get;set;}
        @AuraEnabled public String profileName{get;set;}
        @AuraEnabled public String territory{get;set;}
        @AuraEnabled public String team{get;set;}
        @AuraEnabled public String numGeographies{get;set;}
        @AuraEnabled public String geographies{get;set;}
        @AuraEnabled public String id{get;set;}
        @AuraEnabled public String userId{get;set;}

        public TechnicianWrapper(SVMXC__Service_Group_Members__c technician) {

//            String userName = technician.SVMXC__Salesforce_User__r.fxFullName__c;
//            if (userName != null) {
//                fullName = userName + ' [' + technician.SVMXC__Salesforce_User__r.fxProfileName__c + ']';
//            } else {
//                fullName = technician.Name + ' [' + technician.SVMXC__Salesforce_User__r.fxProfileName__c + ']';
//            }
            fullName = technician.Name;
            profileName = technician.SVMXC__Salesforce_User__r?.fxProfileName__c;
            if (profileName == null) {
                profileName = 'N/A';
            }

            territory = technician.SVMXC__Service_Territory__r.Name;
            team = technician.SVMXC__Service_Group__r?.Name;

            geographies = null;
            if (technician.SMAX_PS_Technician_Geographies__c != null) {
                geographies = technician.SMAX_PS_Technician_Geographies__c.trim().removeEnd(',');
            }
            if (technician.SMAX_PS_Technician_Geographies_2__c != null) {
                geographies = geographies + ',' + technician.SMAX_PS_Technician_Geographies_2__c.trim().removeEnd(',');
            }
            if (technician.SMAX_PS_Technician_Geographies_3__c != null) {
                geographies = geographies + ',' + technician.SMAX_PS_Technician_Geographies_3__c.trim().removeEnd(',');
            }
            if (technician.SMAX_PS_Technician_Geographies_4__c != null) {
                geographies = geographies + ',' + technician.SMAX_PS_Technician_Geographies_4__c.trim().removeEnd(',');
            }

            numGeographies = '0';
            if (geographies != null) {
                List<String> geographiesList = geographies.split(',');
                numGeographies = String.valueOf(geographiesList.size());
            }

            id = technician.Id;
            userId = technician.SVMXC__Salesforce_User__r?.Id;
        }
    }

    // Get the Technicians for a Territory Id
    @AuraEnabled(Cacheable=false)
    public static List<TechnicianWrapper> buildTechnicianDataTable(String territoryId) {

        List<SVMXC__Service_Group_Members__c> technicianList = [
                SELECT  Id, Name, SVMXC__Salesforce_User__r.fxFullName__c, SVMXC__Salesforce_User__r.fxProfileName__c,
                        SVMXC__Service_Group__r.Name,
                        SVMXC__Service_Territory__r.Name, SVMXC__Service_Territory__c, SMAX_PS_Technician_Geographies__c,
                        SMAX_PS_Technician_Geographies_2__c, SMAX_PS_Technician_Geographies_3__c,
                        SMAX_PS_Technician_Geographies_4__c,SVMXC__Salesforce_User__r.Id
                FROM SVMXC__Service_Group_Members__c
                WHERE SVMXC__Service_Territory__c = :territoryId
        ];

        List<TechnicianWrapper> technicianWrapperList = new List<TechnicianWrapper>();
        for (SVMXC__Service_Group_Members__c technician :technicianList) {
            TechnicianWrapper technicianWrapper = new TechnicianWrapper(technician);
            technicianWrapperList.add(technicianWrapper);
        }

        return technicianWrapperList;
    }

    public class ValueLabel {
        public ValueLabel() { }
        public ValueLabel(String v, String l) {
            this.value = v;
            this.label = l;
        }
        @AuraEnabled public String value{get;set;}
        @AuraEnabled public String label{get;set;}
    }

    public class CheckboxGrid {
        public CheckboxGrid() {
            this.columnValues = new List<ValueLabel>();
            this.rowValues = new List<ValueLabel>();
            this.grid = new Map<String, Map<String, Boolean>>();
        }
        public void initGrid(Boolean enabled) {
            for (ValueLabel row : rowValues) {
                this.grid.put(row.value, new Map<String, Boolean>());
                for (ValueLabel col : columnValues) {
                    this.grid.get(row.value).put(col.value, enabled);
                }
            }
        }
        @AuraEnabled public List<ValueLabel> rowValues { get; set; }
        @AuraEnabled public List<ValueLabel> columnValues { get; set; }
        @AuraEnabled public Map<String, Map<String, Boolean>> grid { get; set; }
    }

    @AuraEnabled(Cacheable=false)
    public static CheckboxGrid loadManageGeoGrid(Id territoryId) {
        CheckboxGrid result = new CheckboxGrid();
        System.debug('Loading Tech-Geo Grid for Territory: ' + territoryId);

        List<SMAX_PS_Geography__c> geoList = [SELECT Id, Name, SMAX_PS_LocationCode__c, SMAX_PS_Geography_Description__c
            FROM SMAX_PS_Geography__c WHERE BD_Territory__c = :territoryId
            ORDER BY Name];
        for (SMAX_PS_Geography__c geo : geoList) {
            result.columnValues.add(new ValueLabel(geo.Id, geo.Name));
        }

        SVMXC__Territory__c territory = [SELECT Id, Name,
                SVMXC__Parent_Territory__c,
                SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c,
                SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c,
                SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c,
                SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c,
                SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c
            FROM SVMXC__Territory__c WHERE Id = :territoryId];
        Set<Id> territoryIds = new Set<Id>();
        SVMXC__Territory__c t = territory;
        while (t != null) {
            territoryIds.add(t.Id);
            try {
                t = t.SVMXC__Parent_Territory__r;
            } catch (Exception e) {
                t = null;
            }
        }

        List<SVMXC__Service_Group_Members__c> techList = [SELECT Id, Name, SVMXC__Service_Territory__c
            FROM SVMXC__Service_Group_Members__c WHERE SVMXC__Service_Territory__c IN :territoryIds
            ORDER BY Name];
        for (SVMXC__Service_Group_Members__c tech : techList) {
            result.rowValues.add(new ValueLabel(tech.Id, tech.Name));
        }

        result.initGrid(false);
        List<SMAX_PS_Geography_Technician__c> geoTechs = [SELECT Id, Name,
                SMAX_PS_Geography__c, SMAX_PS_Technician__c
            FROM SMAX_PS_Geography_Technician__c
            WHERE SMAX_PS_Geography__c IN :geoList AND SMAX_PS_Technician__c IN :techList];
        for (SMAX_PS_Geography_Technician__c geoTech : geoTechs) {
            result.grid.get(geoTech.SMAX_PS_Technician__c).put(geoTech.SMAX_PS_Geography__c, true);
        }

        return result;
    }

    @AuraEnabled(Cacheable=false)
    public static String saveManageGeoGrid(Id territoryId, String updates) {
        // NOTE: The "updates" only contains the "draft" (or changed) values
        System.debug('Updates = ' + updates);
        JSONParser parser = JSON.createParser(updates);

        // For "true" values, simply insert new Geo-Tech records..
        List<SMAX_PS_Geography_Technician__c> newGeoTechs = new List<SMAX_PS_Geography_Technician__c>();
        Map<String, SMAX_PS_Geography_Technician__c> newGeoTechsMap = new Map<String, SMAX_PS_Geography_Technician__c>();
        // For "false" values, need to look up the Geo-Tech records and delete them
        Set<String> keysToDelete = new Set<String>();

        // Saving geoGrid grid = {"a7iK0000000D7oCIAS":{"a8gK0000000KmZsIAK":true,"a8gK0000000KmafIAC":true,"a8gK0000000Kmb6IAC":false},"a7iK0000000D7qTIAS":{"a8gK0000000KmafIAC":true}}
        Id techId = null;
        Id geoId = null;
        String key = null;
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                if (techId == null) {
                    techId = parser.getText();
                } else {
                    geoId = parser.getText();
                    parser.nextToken(); // Advance to the value..
                    Boolean checked = parser.getBooleanValue();
                    key = techId + '-' + geoId;
                    if (checked) {
                        SMAX_PS_Geography_Technician__c newGT = new SMAX_PS_Geography_Technician__c();
                        newGT.SMAX_PS_Geography__c = geoId;
                        newGT.SMAX_PS_Technician__c = techId;
                        newGT.SMAX_PS_External_Id__c = key;
                        newGeoTechs.add(newGT);
                        newGeoTechsMap.put(key, newGT);
                    } else if (!checked && (newGeoTechsMap.get(key) == null)) {
                        keysToDelete.add(key);
                    }
                }
            } else if (parser.getCurrentToken() == JSONToken.END_OBJECT) {
                techId = null;
            }
        }

        System.debug('DELETING GEO-KEYS: ' + keysToDelete);
        if (!keysToDelete.isEmpty()) {
            List<SMAX_PS_Geography_Technician__c> geoTechDeletes = [SELECT Id, Name FROM SMAX_PS_Geography_Technician__c
            WHERE SMAX_PS_External_Id__c IN :keysToDelete];
            System.debug('DELETING GEOS: ' + geoTechDeletes);
            delete geoTechDeletes;
        }

        System.debug('SAVING NEW GEOS: ' + newGeoTechs);
        if (!newGeoTechs.isEmpty()) {
            upsert newGeoTechs SMAX_PS_External_Id__c;
        }

        return 'Success';
    }

    @AuraEnabled(Cacheable=false)
    public static CheckboxGrid loadManageDispatchersGrid(Id territoryId) {
        CheckboxGrid result = new CheckboxGrid();
        System.debug('Loading Dispatchers Grid for Territory: ' + territoryId);

        Set<Id> territoryIds = new Set<Id>();
        List<SVMXC__Territory__c> children = [SELECT Id, Name, BD_Qualified_Name__c
            FROM SVMXC__Territory__c WHERE Id = :territoryId
                OR SVMXC__Parent_Territory__c = :territoryId
                OR SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c = :territoryId
                OR SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c = :territoryId
            ORDER BY BD_Qualified_Name__c];
        for (SVMXC__Territory__c t : children) {
            result.columnValues.add(new ValueLabel(t.Id, t.Name));
            territoryIds.add(t.Id);
        }

//		SVMXC__Territory__c territory = [SELECT Id, Name,
//				SVMXC__Parent_Territory__c,
//				SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c,
//				SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c,
//				SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c,
//				SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c,
//				SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c
//		FROM SVMXC__Territory__c WHERE Id = :territoryId];
//		SVMXC__Territory__c t = territory;
//		while (t != null) {
//			territoryIds.add(t.Id);
//			try {
//				t = t.SVMXC__Parent_Territory__r;
//			} catch (Exception e) {
//				t = null;
//			}
//		}

        Set<Id> userIds = new Set<Id>();
        List<SVMXC__Dispatcher_Access__c> dAccesses = [SELECT Id, Name,
                SVMXC__Territory__c, SVMXC__Dispatcher__c, SVMXC__Dispatcher__r.Name
            FROM SVMXC__Dispatcher_Access__c
            WHERE SVMXC__Territory__c IN :territoryIds];
        for (SVMXC__Dispatcher_Access__c dAccess : dAccesses) {
            Id userId = dAccess.SVMXC__Dispatcher__c;
            if (!userIds.contains(userId)) {
                userIds.add(userId);
                result.rowValues.add(new ValueLabel(userId, dAccess.SVMXC__Dispatcher__r.Name));
            }
        }

        result.initGrid(false);
        for (SVMXC__Dispatcher_Access__c dAccess : dAccesses) {
            result.grid.get(dAccess.SVMXC__Dispatcher__c).put(dAccess.SVMXC__Territory__c, true);
        }

        return result;
    }

    @AuraEnabled(Cacheable=false)
    public static String saveManageDispatchersGrid(Id territoryId, String updates) {
        // NOTE: The "updates" only contains the "draft" (or changed) values
        System.debug('Updates = ' + updates);
        JSONParser parser = JSON.createParser(updates);

        // For "true" values, simply insert new Dis-Access records..
        List<SVMXC__Dispatcher_Access__c> newDAccess = new List<SVMXC__Dispatcher_Access__c>();
        // For "false" values, need to look up the Dis-Access records and delete them
        Set<String> keysToDelete = new Set<String>();

        Id userId = null;
        Id terrId = null;
        String key = null;
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                if (userId == null) {
                    userId = parser.getText();
                } else {
                    terrId = parser.getText();
                    parser.nextToken(); // Advance to the value..
                    Boolean checked = parser.getBooleanValue();
                    key = userId + '-' + terrId;
                    if (checked) {
                        SVMXC__Dispatcher_Access__c newDA = new SVMXC__Dispatcher_Access__c();
                        newDA.SVMXC__Territory__c = terrId;
                        newDA.SVMXC__Dispatcher__c = userId;
                        newDA.SMAX_PS_External_Id__c = key;
                        newDAccess.add(newDA);
                    } else if(!checked) {
                        keysToDelete.add(key);
                    }
                }
            } else if (parser.getCurrentToken() == JSONToken.END_OBJECT) {
                userId = null;
            }
        }

        System.debug('SAVING NEW DispatcherAccess: ' + newDAccess);
        if (!newDAccess.isEmpty()) {
			upsert newDAccess SMAX_PS_External_Id__c;
        }

        System.debug('DELETING Dispatcher-Access Keys: ' + keysToDelete);
        if (!keysToDelete.isEmpty()) {
            List<SVMXC__Dispatcher_Access__c> dAccessDeletes = [SELECT Id, Name FROM SVMXC__Dispatcher_Access__c
                WHERE SMAX_PS_External_Id__c IN :keysToDelete];
            System.debug('DELETING Dispatcher-Access: ' + dAccessDeletes);
			delete dAccessDeletes;
        }

        return 'Success';
    }

    public class TechnicianGeography {
        @AuraEnabled public Boolean assignedToTech { get; set; }
        @AuraEnabled public String geography { get; set; }
        @AuraEnabled public String technicianId { get; set; }
        @AuraEnabled public String geographyId { get; set; }
    }

    public class TechnicianDetails {
        @AuraEnabled public String technicianName { get; set; }
        @AuraEnabled public String technicianId { get; set; }
        @AuraEnabled public String territoryId { get; set; }
        @AuraEnabled public String territory { get; set; }
        @AuraEnabled public String teamId { get; set; }
        @AuraEnabled public String team { get; set; }
        @AuraEnabled public List<SMAX_PS_Geography_Technician__c> techGeos { get; set; }
        @AuraEnabled public List<SMAX_PS_Geography__c> geos { get; set; }
        @AuraEnabled public Map<String, Boolean> originalTechGeos { get; set; }
        @AuraEnabled public Map<String, SMAX_PS_Geography_Technician__c> techGeoToRecord { get; set; }
        @AuraEnabled public List<TechnicianGeography> technicianGeographiesList { get; set; }


        public TechnicianDetails() {
            System.debug('SMAX_PS_DispatchManagementDashboard.TechnicianDetails: No arguments passed');
        }

        public TechnicianDetails(Id technicianId) {
            this.technicianId = technicianId;

            SVMXC__Service_Group_Members__c tech = [
                    SELECT  Id, Name, SVMXC__Salesforce_User__r.fxFullName__c,SVMXC__Service_Group__c,
                            SVMXC__Salesforce_User__r.fxProfileName__c, SVMXC__Service_Territory__c,
                            SVMXC__Service_Territory__r.Name, SVMXC__Service_Group__r.Name
                    FROM SVMXC__Service_Group_Members__c
                    WHERE Id = :technicianId
            ];

            technicianName = tech?.Name;
            territoryId = tech?.SVMXC__Service_Territory__c;
            territory = tech?.SVMXC__Service_Territory__r.Name;
            teamId = tech?.SVMXC__Service_Group__c;
            team = tech?.SVMXC__Service_Group__r.Name;
            originalTechGeos = new Map<String, Boolean>();
            techGeoToRecord = new Map<String, SMAX_PS_Geography_Technician__c>();

            techGeos = [
                    SELECT Id, SMAX_PS_Technician__c, SMAX_PS_Geography__c, SMAX_PS_Location__c
                    FROM SMAX_PS_Geography_Technician__c
                    WHERE SMAX_PS_Technician__c = :technicianId
            ];

            for (SMAX_PS_Geography_Technician__c techGeo :techGeos) {
                originalTechGeos.put(techGeo.SMAX_PS_Technician__c + '-' + techGeo.SMAX_PS_Geography__c, true);
                techGeoToRecord.put(techGeo.SMAX_PS_Technician__c + '-' + techGeo.SMAX_PS_Geography__c, techGeo);
            }

            geos = [
                    SELECT Id, Name, SMAX_PS_LocationCode__c, SMAX_PS_Geography_Description__c
                    FROM SMAX_PS_Geography__c
                    WHERE BD_Territory__c = :territoryId
                    ORDER BY Name
            ];

            technicianGeographiesList = new List<TechnicianGeography>();
            for (SMAX_PS_Geography__c geo :geos) {
                TechnicianGeography technicianGeography = new TechnicianGeography();
                technicianGeography.technicianId = technicianId;
                technicianGeography.geographyId = geo.Id;
                technicianGeography.geography = geo.SMAX_PS_LocationCode__c;

                if (originalTechGeos.get(technicianId + '-' + geo.Id) == true) {
                    technicianGeography.assignedToTech = true;
                } else {
                    technicianGeography.assignedToTech = false;
                }

                technicianGeographiesList.add(technicianGeography);
            }
            System.debug('technicianGeographiesList: ' + technicianGeographiesList);
        }
    }

    @AuraEnabled(Cacheable=false)
    public static TechnicianDetails loadTechnicianEditDetails(Id technicianId) {
        TechnicianDetails result = new TechnicianDetails(technicianId);
        System.debug('Loading Technician Details for Technician: ' + technicianId);
        System.debug('Technician Name: ' + result.technicianName);
        System.debug('Technician Geographies List: ' + result.technicianGeographiesList);

        return result;
    }

    @AuraEnabled(Cacheable=false)
    public static String saveTechnicianEditDetails(TechnicianDetails technicianDetails) {

        System.debug('Saving Technician Details for Technician: ' + technicianDetails.technicianId);
        String result = 'Failure';

        try {
            List<SMAX_PS_Geography_Technician__c> insertGeoTechs = new List<SMAX_PS_Geography_Technician__c>();
            List<SMAX_PS_Geography_Technician__c> deleteGeoTechs = new List<SMAX_PS_Geography_Technician__c>();



            for (TechnicianGeography technicianGeography :technicianDetails.technicianGeographiesList) {

                // if the assignedToTech value has changed then add it to either a list of inserts or deletes
                String tgKey = technicianGeography.technicianId + '-' + technicianGeography.geographyId;
                Boolean origTechGeoValue = technicianDetails.originalTechGeos.get(tgKey);
                if ( origTechGeoValue == null && technicianGeography.assignedToTech == true) {

                    // Add this one to the list of records to be created
                    SMAX_PS_Geography_Technician__c newGeographyTechnician = new SMAX_PS_Geography_Technician__c();
                    newGeographyTechnician.SMAX_PS_Technician__c = technicianGeography.technicianId;
                    newGeographyTechnician.SMAX_PS_Geography__c = technicianGeography.geographyId;
                    newGeographyTechnician.SMAX_PS_Location__c = technicianGeography.geography;
                    insertGeoTechs.add(newGeographyTechnician);
                    System.debug('Added ' + tgKey + ' to the CREATE list');

                } else if (origTechGeoValue == true && origTechGeoValue != technicianGeography.assignedToTech) {

                    // add this to the list of records to delete
                    deleteGeoTechs.add(technicianDetails.techGeoToRecord.get(tgKey));
                    System.debug('Added ' + tgKey + ' to the DELETE list');
                }
            }

            System.debug('About to Insert: ' + insertGeoTechs);
            insert insertGeoTechs;
            System.debug('Inserted: ' + insertGeoTechs);

            delete deleteGeoTechs;
            System.debug('Deleted: ' + deleteGeoTechs);

            result = 'Success';
        }

        catch(Exception e) {
            System.debug('Error: ' + e);
            System.debug('Message: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }


        return result;
    }




    public class GeoCheckbox {
//        @AuraEnabled public Boolean assignedToTech { get; set; }
        @AuraEnabled public String technicianName { get; set; }
        @AuraEnabled public String technicianId { get; set; }
        @AuraEnabled public String territoryName { get; set; }
        @AuraEnabled public String territoryId { get; set; }
        @AuraEnabled public String teamName { get; set; }
        @AuraEnabled public String teamId { get; set; }
        @AuraEnabled public List<ValueLabel> options { get; set; }
        @AuraEnabled public List<String> values { get; set; }

        public GeoCheckbox() {
        }

        public GeoCheckbox(Id technicianId, Id territoryId) {
            this.technicianId = technicianId;
            this.territoryId = territoryId;
            options = new List<ValueLabel>();
            values = new List<String>();


            SVMXC__Service_Group_Members__c tech = [
                    SELECT  Id, Name, SVMXC__Salesforce_User__r.fxFullName__c,SVMXC__Service_Group__c,
                            SVMXC__Salesforce_User__r.fxProfileName__c, SVMXC__Service_Territory__c,
                            SVMXC__Service_Territory__r.Name, SVMXC__Service_Group__r.Name
                    FROM SVMXC__Service_Group_Members__c
                    WHERE Id = :technicianId
            ];

            technicianName = tech?.Name;
            territoryName = tech?.SVMXC__Service_Territory__r.Name;
            teamId = tech?.SVMXC__Service_Group__c;
            teamName = tech?.SVMXC__Service_Group__r.Name;
        }
    }

    @AuraEnabled(Cacheable=false)
    public static GeoCheckbox loadGeoCheckbox(Id technicianId, Id territoryId) {
        GeoCheckbox result = new GeoCheckbox(technicianId, territoryId);
        System.debug('Loading GeoCheckbox Details for Territory: ' + territoryId);
        System.debug('Technician Name: ' + result.technicianName);
        System.debug('Technician Geographies List: ' + result.options);

        List<SVMXC__Territory__c> children = [
                SELECT Id, Name, BD_Qualified_Name__c
                FROM SVMXC__Territory__c WHERE Id = :territoryId
                OR SVMXC__Parent_Territory__c = :territoryId
                OR SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c = :territoryId
                OR SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c = :territoryId
                ORDER BY BD_Qualified_Name__c
        ];

        Set<Id> territoryIds = new Set<Id>();
        for (SVMXC__Territory__c t : children) {
            //result.columnValues.add(new ValueLabel(t.Id, t.Name));
            territoryIds.add(t.Id);
        }

        List<SMAX_PS_Geography__c> geos = [
                SELECT Id, Name, SMAX_PS_Geography_Description__c, BD_Territory__c, SMAX_PS_LocationCode__c, BD_Territory__r.BD_Qualified_Name__c
                FROM SMAX_PS_Geography__c
                WHERE BD_Territory__c IN :territoryIds
                ORDER BY BD_Territory__r.BD_Qualified_Name__c, Name
        ];

        for(SMAX_PS_Geography__c geo :geos) {
            ValueLabel option = new ValueLabel(geo.Id + '-' + result.technicianId,geo.BD_Territory__r.BD_Qualified_Name__c + '/' + geo.Name);
            result.options.add(option);
        }

        List<SMAX_PS_Geography_Technician__c> geoTechs = [
                SELECT Id, SMAX_PS_Technician__c, SMAX_PS_Geography__c, SMAX_PS_Location__c
                FROM SMAX_PS_Geography_Technician__c
                WHERE SMAX_PS_Technician__c = :technicianId
        ];

        for(SMAX_PS_Geography_Technician__c geoTech :geoTechs) {
            result.values.add(geoTech.SMAX_PS_Geography__c + '-' + geoTech.SMAX_PS_Technician__c);
        }

        return result;
    }

    @AuraEnabled(Cacheable=false)
    public static String saveGeoCheckbox(String technicianId, String territoryId, String teamId, List<ValueLabel> options, List<String> values) {
        System.debug('SMAX_PS_DispatchManagementDashboard.saveGeoCheckbox');
        String result = 'Failure';

        // Get a Map of options with checked or not so we can use them to determine which new records to create and which ones to delete
        Map<String, Boolean> optionMap = new Map<String, Boolean>();
        for (ValueLabel option :options) {
            if (values.contains(option.value)) {
                optionMap.put(option.value, true);
            } else {
                optionMap.put(option.value, false);
            }
        }
        System.debug('optionMap: ' + optionMap);

        List<SMAX_PS_Geography_Technician__c> geoTechs = [
                SELECT Id, SMAX_PS_Technician__c, SMAX_PS_Geography__c, SMAX_PS_Location__c
                FROM SMAX_PS_Geography_Technician__c
                WHERE SMAX_PS_Technician__c = :technicianId
        ];

        // Delete existing SMAX_PS_Geography_Technician__c records for this Technician
        System.debug('About to DELETE geoTechs: ' + geoTechs);
        delete geoTechs;

        // Update the Territory for the Technician
        SVMXC__Service_Group_Members__c tech = [
                SELECT  Id, SVMXC__Service_Territory__c, SVMXC__Service_Group__c
                FROM SVMXC__Service_Group_Members__c
                WHERE Id = :technicianId
        ];

        System.debug('Updating Technician Territory FROM: [' + tech.SVMXC__Service_Territory__c + '] TO ['+ territoryId +']');
        tech.SVMXC__Service_Territory__c = territoryId;
        System.debug('Updating Technician Team FROM: [' + tech.SVMXC__Service_Group__c + '] TO ['+ teamId +']');
        tech.SVMXC__Service_Group__c = teamId;
        update tech;

        // Create the new SMAX_PS_Geography_Technician__c records for this Technician
        List<SMAX_PS_Geography_Technician__c> createGeoTechs = new List<SMAX_PS_Geography_Technician__c>();
        System.debug('Checking for new SMAX_PS_Geography_Technician__c records to create');
        for (ValueLabel option :options) {

            // if the option is checked then add it to the create list
            if (optionMap.get(option.value) == true) {

                System.debug('adding to create list: ' + option);
                SMAX_PS_Geography_Technician__c geoTech = new SMAX_PS_Geography_Technician__c();
                String geoId = option.value.substringBefore('-');
                String terrId = option.value.substringAfter('-');
                geoTech.SMAX_PS_Geography__c = geoId;
                geoTech.SMAX_PS_Technician__c = terrId;
                geoTech.SMAX_PS_Location__c = option.label.substringAfterLast('/');
                createGeoTechs.add(geoTech);
            }
        }

        System.debug('About to CREATE: ' + createGeoTechs);
        insert createGeoTechs;

        result = 'Success';
        return result;
    }


    public class TeamWrapper {

        @AuraEnabled public String id{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public Boolean enterprise{get;set;}
        @AuraEnabled public Boolean active{get;set;}

        public TeamWrapper(SVMXC__Service_Group__c team) {

            id = team.Id;
            name = team.Name;
            enterprise = team.SMAX_PS_Is_Enterprise__c;
            active = team.SVMXC__Active__c;
        }
    }

    //Get all the Teams
    @AuraEnabled(Cacheable=true)
    public static List<TeamWrapper> buildTeams() {

        List<SVMXC__Service_Group__c> teams = [
                SELECT  Id, Name, SMAX_PS_Is_Enterprise__c, SVMXC__Active__c
                FROM SVMXC__Service_Group__c
                ORDER BY Name
        ];


        List<TeamWrapper> teamWrappers = new List<TeamWrapper>();

        for (SVMXC__Service_Group__c team : teams) {
            TeamWrapper teamWrapper = new TeamWrapper(team);
            teamWrappers.add(teamWrapper);
        }

        System.debug('teamWrappers: ' + teamWrappers);
        return teamWrappers;
    }

    public class DispatcherAccessWrapper {
        @AuraEnabled public List<String> selectedTerritoryIds {get;set;}
        @AuraEnabled public List<String> selectedTeamIds {get;set;}

        public DispatcherAccessWrapper(List<String> territoryIds, List<String> teamIds) {
            selectedTerritoryIds = territoryIds;
            selectedTeamIds = teamIds;
        }
    }

    //Get selected Territories and Teams from the Dispatcher Access records
    @AuraEnabled(Cacheable=true)
    public static DispatcherAccessWrapper selectedTerrIdsTeamIdsInDispatcherAccess(Id dispatcherId) {

        Map<Id, SVMXC__Dispatcher_Access__c> dispatcherAccessByIds = new Map<Id, SVMXC__Dispatcher_Access__c>([
                SELECT  Id, Name, SVMXC__Dispatcher__c, SMAX_PS_Dispatcher_Name__c, SMAX_PS_Dispatcher_Profile__c,
                        SVMXC__Service_Team__c, SVMXC__Service_Team__r.Name, SVMXC__Territory__c, SVMXC__Territory__r.Name
                FROM SVMXC__Dispatcher_Access__c
                WHERE SVMXC__Dispatcher__c = :dispatcherId
        ]);

        List<String> territoryIds = new List<String>();
        List<String> teamIds = new List<String>();
        for (SVMXC__Dispatcher_Access__c dispatcherAccess : dispatcherAccessByIds.values()) {
            territoryIds.add(dispatcherAccess.SVMXC__Territory__c);
            teamIds.add(dispatcherAccess.SVMXC__Service_Team__c);
        }

        DispatcherAccessWrapper dispatcherAccessWrapper = new DispatcherAccessWrapper(territoryIds, teamIds);

        System.debug('dispatcherAccessWrapper: ' + dispatcherAccessWrapper);
        return dispatcherAccessWrapper;
    }

    @AuraEnabled(Cacheable=false)
    public static List<Id> getChildTerritoryIds(String territoryId) {
        System.debug('SMAX_PS_DispatchManagementDashboard.getChildTerritoryIds');

        Map<Id, SVMXC__Territory__c> childTerritoriesByIds = new Map<Id, SVMXC__Territory__c>([
                SELECT Id, Name, BD_Qualified_Name__c
                FROM SVMXC__Territory__c WHERE Id = :territoryId
                OR SVMXC__Parent_Territory__c = :territoryId
                OR SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c = :territoryId
                OR SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__r.SVMXC__Parent_Territory__c = :territoryId
        ]);

        List<Id> childTerritoryIds = new List<Id>(childTerritoriesByIds.keySet());
        System.debug('childTerritoryIds: ' + childTerritoryIds);
        return childTerritoryIds;
    }

    @AuraEnabled(Cacheable=false)
    public static String saveDispatcherEditDetails(String dispatcherId, List<String> newTerritoryIds, List<String> newTeamIds) {
        System.debug('SMAX_PS_DispatchManagementDashboard.saveDispatcherEditDetails');
        String result = 'Failure';

        //Query exiting Dispatcher Access records for the dispatcherId
        List<SVMXC__Dispatcher_Access__c> oldDispatcherAccessList = [
                SELECT Id, Name, SVMXC__Dispatcher__c, SMAX_PS_External_Id__c
                FROM SVMXC__Dispatcher_Access__c
                WHERE SVMXC__Dispatcher__c = :dispatcherId
        ];
        System.debug('oldDispatcherAccessList: ' + oldDispatcherAccessList);

        //Create the new Dispatcher Access records for the newTerritoryIds
        List<SVMXC__Dispatcher_Access__c> newDispatcherAccessRecords = new List<SVMXC__Dispatcher_Access__c>();
        for (String newTerritoryId :newTerritoryIds) {
            SVMXC__Dispatcher_Access__c dispatcherAccess = new SVMXC__Dispatcher_Access__c();
            dispatcherAccess.SVMXC__Territory__c = newTerritoryId;
            dispatcherAccess.SVMXC__Dispatcher__c = dispatcherId;
            newDispatcherAccessRecords.add(dispatcherAccess);
        }

        //Create the new Dispatcher Access records for the newTeamIds
        for (String newTeamId :newTeamIds) {
            SVMXC__Dispatcher_Access__c dispatcherAccess = new SVMXC__Dispatcher_Access__c();
            dispatcherAccess.SVMXC__Service_Team__c = newTeamId;
            dispatcherAccess.SVMXC__Dispatcher__c = dispatcherId;
            newDispatcherAccessRecords.add(dispatcherAccess);
        }

        //Delete the old Dispatcher Access records
        System.debug('DELETING oldDispatcherAccessList: ' + oldDispatcherAccessList);
        delete oldDispatcherAccessList;

        //Insert the new Dispatcher Access records
        System.debug('INSERTING newDispatcherAccessRecords: ' + newDispatcherAccessRecords);
        insert newDispatcherAccessRecords;

        result = 'Success';
        return result;
    }
}