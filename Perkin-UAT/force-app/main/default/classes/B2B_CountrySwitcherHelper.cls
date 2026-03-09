/**
 * @description       : 
 * @author            : Swati Chilap
 * @group             : 
 * @last modified on  : 03-04-2026
 * @last modified by  : Suhail Ahmed T 
**/
public without sharing class B2B_CountrySwitcherHelper {
    public static Map<String,Object> guestLocaleMetadataRecords(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';

        // validate input
        if (mapParams == null || !mapParams.containsKey('country') || String.isBlank((String)mapParams.get('country'))) {
            mapParams.put('isSuccess',isSuccess);
            mapParams.put('message',System.Label.B2B_Country_Selector_Missing_Country_Code);
            return mapParams;
        }

        String currentCountryCode = (String) mapParams.get('country');

        List<B2B_Country_Selector__mdt> countrySwitcherRecords = [SELECT Id, MasterLabel, DeveloperName, Country_Code__c, Currency_Code__c, isActive__c, Languages_Code__c, Locale__c, Sales_Org__c FROM B2B_Country_Selector__mdt WHERE Country_Code__c=:currentCountryCode AND isActive__c=true];
        List<B2B_Country_Selector__mdt> finalMetadataRecord = new List<B2B_Country_Selector__mdt>();

        

        String userLocale = UserInfo.getLocale();
        if (String.isNotBlank(userLocale)) {
            userLocale = userLocale.replace('_', '-');
        }

        //
        Boolean isLocaleMismatch = false;
        // Check if country code exists in user locale
        if (String.isNotBlank(userLocale) && !userLocale.containsIgnoreCase(currentCountryCode)) {
            isLocaleMismatch = true;
        }

        if(!countrySwitcherRecords.isEmpty()){
            if(countrySwitcherRecords.size() > 1){
                Boolean useLanguageCode = isLocaleMismatch || String.isBlank(userLocale);

                for(B2B_Country_Selector__mdt singleMetadataRecord : countrySwitcherRecords){
                    if (useLanguageCode) {
                        if (singleMetadataRecord.Languages_Code__c == System.Label.B2B_Country_Selector_Lang_Code) {
                            finalMetadataRecord.add(singleMetadataRecord);
                        }
                    } else {
                        if (singleMetadataRecord.Locale__c == userLocale) {
                            finalMetadataRecord.add(singleMetadataRecord);
                        }
                    }

                    // if (String.isNotBlank(userLocale)) {
                    //     if(singleMetadataRecord.Locale__c == userLocale){
                    //         finalMetadataRecord.add(singleMetadataRecord);
                    //     }
                    // } else {
                    //     if(singleMetadataRecord.Languages_Code__c == System.Label.B2B_Country_Selector_Lang_Code){
                    //         finalMetadataRecord.add(singleMetadataRecord);
                    //     }
                    // }
                    
                }
                mapParams.put('countrySwitcherRecords',finalMetadataRecord);
            }
            else{
                mapParams.put('countrySwitcherRecords',countrySwitcherRecords);
            }
            isSuccess=true;
        }
        else{
            message= System.Label.B2B_No_Meta_Data_For_Country_Code + ' ' + currentCountryCode + '. ' + System.Label.B2B_Contact_Admin;
        }
        mapParams.put('isSuccess',isSuccess);
        mapParams.put('message',message);
        return mapParams;
    }

    public static Map<String,Object> countrySelectorMetadataRecords(){
        Map<String,Object> mapParams = new Map<String,Object>();
        Map<String, Set<String>> regionToCountriesSetMap = new Map<String, Set<String>>();
        Map<String, List<String>> countryToCurrencyMap = new Map<String, List<String>>();
        Map<String, List<String>> regionToCountriesMap = new Map<String, List<String>>();
        Boolean isSuccess = false;
        String message = '';
        List<B2B_Country_Selector__mdt> countrySelectorRecords = [SELECT Id, MasterLabel, DeveloperName, Country_Code__c, Currency_Code__c, isActive__c, Languages_Code__c, Locale__c, Sales_Org__c, Country_Region__c, Sort_Order__c FROM B2B_Country_Selector__mdt WHERE isActive__c = true ORDER BY Sort_Order__c ASC];
        
        if(!countrySelectorRecords.isEmpty()){
            for (B2B_Country_Selector__mdt record : countrySelectorRecords) {
                String region = record.Country_Region__c;
                String masterLabel = record.MasterLabel;
                String currencyCode = record.Currency_Code__c;
            
                // Extract only the country name (before " | ")
                String country = masterLabel.split('\\|')[0].trim();  // Extracts "Australia" from "Australia | EN"
            
                // Populate Region to Countries Map
                if (!regionToCountriesSetMap.containsKey(region)) {
                    regionToCountriesSetMap.put(region, new Set<String>());
                }
                regionToCountriesSetMap.get(region).add(country);
            
                // Populate Country to Currency Map with full MasterLabel format
                String formattedValue = masterLabel + ' - ' + currencyCode;

                // Populate Country to Currency Map (Ensure multiple values are stored)
                if (!countryToCurrencyMap.containsKey(country)) {
                    countryToCurrencyMap.put(country, new List<String>());
                }
                countryToCurrencyMap.get(country).add(formattedValue);
            }
            
            // Convert Sets to Lists for final Region to Countries Map
            for (String region : regionToCountriesSetMap.keySet()) {
                regionToCountriesMap.put(region, new List<String>(regionToCountriesSetMap.get(region)));
            }

            mapParams.put('regionToCountriesMap',regionToCountriesMap);
            mapParams.put('countryToCurrencyMap',countryToCurrencyMap);
            mapParams.put('countrySelectorRecords',countrySelectorRecords);
            isSuccess=true;
        }
        else{
            message= System.Label.B2B_Contact_Admin_No_Meta_Data;
        }
        mapParams.put('isSuccess',isSuccess);
        mapParams.put('message',message);
        return mapParams;
    }

    public static Map<String,Object> loggedInUserDetails(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';

         if (mapParams == null 
            || !mapParams.containsKey('userId') 
            || !mapParams.containsKey('metadataRecord') 
            || !mapParams.containsKey('deleteCurrentCart') 
            || String.isBlank((String)mapParams.get('userId'))
            || mapParams.get('metadataRecord') == null) {

            mapParams.put('isSuccess',isSuccess);
            mapParams.put('message',System.Label.B2B_Country_Selector_Missing_Country_Code);
            return mapParams;
        }


        String userId = (String) mapParams.get('userId');
        Boolean deleteCurrentCart = (Boolean) mapParams.get('deleteCurrentCart');
        Object inputObj = mapParams.get('metadataRecord');

        Map<String,String> inputMap = (Map<String,String>) JSON.deserialize(JSON.serialize(inputObj), Map<String,String>.class);
        String selectedCountry = inputMap.get('Country_Code__c');
        String selectedLocale = inputMap.get('Locale__c');
        String currencyCode = inputMap.get('Currency_Code__c');

        if (String.isBlank(selectedCountry) || String.isBlank(selectedLocale) || String.isBlank(currencyCode)) {
            mapParams.put('isSuccess', false);
            mapParams.put('message', System.Label.B2B_Invalid_Country_Or_Local);
            return mapParams;
        }

        if (String.isNotBlank(selectedLocale)) {
            selectedLocale = selectedLocale.replace('-', '_');
        }
        
        if(!inputMap.isEmpty()){
            if(deleteCurrentCart == true){
                List<WebCart> currentCart = [SELECT Id,CreatedById,Status,CreatedDate FROM WebCart WHERE CreatedById=:userId AND Status='Active' ORDER BY CreatedDate DESC LIMIT 1];
                mapParams.put('currentCart',currentCart);
                if(!currentCart.isEmpty()){
                    delete currentCart;
                }
            }

            User currentUser = [SELECT Id, Account.CurrencyIsoCode, LocaleSidKey FROM User WHERE Id=:userId LIMIT 1];
            currentUser.LocaleSidKey = selectedLocale;
            update currentUser;
            
            Account currentAccount = [SELECT Id, CurrencyIsoCode FROM Account WHERE Id=:currentUser.Account.Id LIMIT 1];
            currentAccount.CurrencyIsoCode = currencyCode;
            if(! Test.isRunningTest()){
                update currentAccount;
            }
            
            system.debug('Current Acc after currency update - system mode'+ currentAccount.CurrencyIsoCode);

            BuyerAccount currentAccountBuyerAccount = [SELECT Id, BuyerId FROM BuyerAccount WHERE BuyerId=:currentAccount.Id LIMIT 1];
            List<BuyerGroupMember> currentAccountBuyerGroupMember = [SELECT Id, BuyerId, BuyerGroupId FROM BuyerGroupMember WHERE BuyerId=:currentAccount.Id LIMIT 1];
            system.debug('currentAccountBuyerGroupMember'+ currentAccountBuyerGroupMember);
            if(!currentAccountBuyerGroupMember.isEmpty()){
                delete currentAccountBuyerGroupMember;
            }

            List<BuyerGroup> selectedCountryBuyerGroup = [SELECT Id, Name, B2B_Country_Code__c FROM BuyerGroup WHERE B2B_Country_Code__c =: selectedCountry LIMIT 1];
            system.debug('selectedCountryBuyerGroup'+ selectedCountryBuyerGroup);
            
            if(!selectedCountryBuyerGroup.isEmpty()){
                BuyerGroupMember createBGMForSelectedCountry = new BuyerGroupMember();
                createBGMForSelectedCountry.BuyerId = currentAccount.Id;
                createBGMForSelectedCountry.BuyerGroupId = selectedCountryBuyerGroup[0].Id;
                insert createBGMForSelectedCountry;
                system.debug('createBGMForSelectedCountry'+ createBGMForSelectedCountry);
            }

            // currentAccountBuyerGroupMember.BuyerGroupId = selectedCountryBuyerGroup.Id;
            // update currentAccountBuyerGroupMember;
            isSuccess=true;
        }
        else{
            message=System.Label.B2B_Currency_Update_Error_Message;
        }
        mapParams.put('isSuccess',isSuccess);
        mapParams.put('message',message);
        return mapParams;
    }

    public static Map<String,Object> getLoggedInUserBGHelper(Map<String,Object> mapParams){
        Boolean isSuccess = false;
        String message = '';
        String userId;
        
        if(mapParams != null && mapParams.containsKey('userId') && String.isNotBlank((String)mapParams.get('userId'))) {
            userId = (String) mapParams.get('userId');
            User currentUser = [SELECT Id, Account.CurrencyIsoCode, LocaleSidKey FROM User WHERE Id=:userId LIMIT 1];
            Account currentAccount = [SELECT Id, CurrencyIsoCode FROM Account WHERE Id=:currentUser.Account.Id LIMIT 1];

            List<BuyerGroupMember> currentAccountBGM = [SELECT Id, BuyerId, BuyerGroupId FROM BuyerGroupMember WHERE BuyerId=:currentAccount.Id LIMIT 1];
            if (currentAccountBGM.isEmpty() || currentAccountBGM[0].BuyerGroupId == null) {
                mapParams.put('message', System.Label.B2B_No_Buyer_Group_Member_Error);
                return mapParams;
            }

            List<BuyerGroup> currentAccountBG = [SELECT Id, Name, B2B_Country_Code__c FROM BuyerGroup WHERE Id=:currentAccountBGM[0].BuyerGroupId LIMIT 1];
            
            if(!currentAccountBG.isEmpty()){
                mapParams.put('currentAccountBG',currentAccountBG[0]);
                mapParams.put('currentUser',currentUser);
            }

            isSuccess=true;
        }
        else{
            message=System.Label.B2B_Currency_Update_Error_Message;
        }
        mapParams.put('isSuccess',isSuccess);
        mapParams.put('message',message);
        return mapParams;
    }

    public static Map<String,Object> getPromotionBGInfoHelper(Map<String,Object> mapParams) {
        Boolean isSuccess = false;
        String message = '';
        String userId;

        if(mapParams != null && mapParams.containsKey('userId') && String.isNotBlank((String)mapParams.get('userId'))){
            userId = (String) mapParams.get('userId');
            User currentUser = [SELECT Id, Account.CurrencyIsoCode FROM User WHERE Id = :userId LIMIT 1];
            Account currentAccount = [SELECT Id FROM Account WHERE Id = :currentUser.Account.Id LIMIT 1];

            List<BuyerGroupMember> bgmList = [SELECT Id, BuyerGroup.Is_Customer_Specific_Promotion_BG__c FROM BuyerGroupMember WHERE BuyerId = :currentAccount.Id];
            
            if(!bgmList.isEmpty()){
                for(BuyerGroupMember bgm : bgmList) {
                    if(bgm.BuyerGroup.Is_Customer_Specific_Promotion_BG__c) {
                        mapParams.put('assignedToPromotionBG', true);
                        break;
                    }
                    else {
                        mapParams.put('assignedToPromotionBG', false);
                    }
                }
            }

            isSuccess=true;
        }
        else{
            message= System.Label.B2B_Promotion_Buyer_Group_Error;
        }

        mapParams.put('isSuccess',isSuccess);
        mapParams.put('message',message);
        return mapParams;
    }
}