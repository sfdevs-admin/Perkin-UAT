/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 02-25-2026
 * @last modified by  : Suhail Ahmed T 
**/
/* Test Class: B2BMetadataServiceTest */
public with sharing class B2BMetadataService {
  public static Map<String, Object> getTaxConfiguration(String implClassName) {
    Map<String, Object> metadataValues = new Map<String, Object>();
    
    List<B2B_HTTP_Service__mdt> metadataRecords = [
        SELECT
            End_Point__c,
            HTTP_Method__c,
            Named_Credentials__c,
            Auth_Codes__c,
            Password__c,
            Username__c,
            Hmac_Algorithm__c,
            Org_Id_CA__c,
            Org_Id_US__c,
            Impl_Class__c
        FROM B2B_HTTP_Service__mdt
        WHERE Impl_Class__c = :implClassName
        LIMIT 1
    ];
    
    if (!metadataRecords.isEmpty()) {
      B2B_HTTP_Service__mdt record = metadataRecords[0];
      metadataValues.put('EndPoint', record.End_Point__c);
      metadataValues.put('HTTPMethod', record.HTTP_Method__c);
      metadataValues.put('NamedCredential', record.Named_Credentials__c);
      metadataValues.put('HmacKey', record.Auth_Codes__c);
      metadataValues.put('Username', record.Username__c);
      metadataValues.put('Password', record.Password__c);
      metadataValues.put('HmacAlgorithm', record.Hmac_Algorithm__c);
      metadataValues.put('OrgIdCA', record.Org_Id_CA__c);
      metadataValues.put('OrgIdUS', record.Org_Id_US__c);
    }
    
    return metadataValues;
  }
  
  /**
   * Fetches tax configuration for a given currency code from B2B_Country_Tax_Config__mdt.
   */
  public static B2B_Country_Tax_Config__mdt getFlatTaxRateByCountry(String currencyCode) {
    if (String.isBlank(currencyCode)) {return null;
    }
    
    try {
      return [
            SELECT Id, Country__c, Currency_Code__c, Tax_Source__c, SAP_Goods_Tax__c 
            FROM B2B_Country_Tax_Config__mdt
            WHERE Currency_Code__c = :currencyCode
            LIMIT 1
        ];
    } catch (Exception e) {System.debug('Error fetching tax config: ' + e.getMessage());return null;
    }
  }

    //Method to fetch tax rate based on country code
     public static B2B_Country_Tax_Config__mdt getFlatTaxRateByCountryCode(String currencyCode,String countryCode) {
    if (String.isBlank(currencyCode)) {return null;
    }
    
    try {
      return [
            SELECT Id, Country__c, Currency_Code__c, Tax_Source__c, SAP_Goods_Tax__c 
            FROM B2B_Country_Tax_Config__mdt
            WHERE Currency_Code__c = :currencyCode
          AND Country_Code__c =: countryCode
            LIMIT 1
        ];
    } catch (Exception e) {System.debug('Error fetching tax config: ' + e.getMessage());return null;
    }
  }

  /**
   * Fetches the SAP Customer Number for an account.
   */
  public static String getSAPCustomerNumber(Id accountId) {
    if (accountId == null) {return null;
    }

    Account acc = [
        SELECT PKI_SAP_Customer_Number__c 
        FROM Account 
        WHERE Id = :accountId 
        LIMIT 1
    ];

    return acc != null ? acc.PKI_SAP_Customer_Number__c : null;
  }

  /**
   * Fetch if account is "Is Currently Tax Exempt" for stripe tax callout
   * @param mapParams Map containing 'accountId' and 'stateCode'
   */
  public static Boolean isAccountTaxExempt(Map<String, Object> mapParams){
    try {
        if (mapParams == null) return false;
        Id accountId = (mapParams.containsKey('accountId') && mapParams.get('accountId') != null)
            ? (Id)mapParams.get('accountId')
            : null;
        String stateCode = (mapParams.containsKey('stateCode') && mapParams.get('stateCode') != null)
            ? (String)mapParams.get('stateCode')
            : null;

        if (accountId == null || String.isBlank(stateCode)) return false;

        // First check Account's B2B_Is_Currently_Tax_Exempt__c
        Account acc = [
            SELECT B2B_Is_Currently_Tax_Exempt__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
        if (acc != null && acc.B2B_Is_Currently_Tax_Exempt__c == true) {
            return true;
        }

        // Only check B2B_Tax_Exemption__c if Account is not tax exempt
        List<B2B_Tax_Exemption__c> exemptions = [
            SELECT Id, B2B_Is_Currently_Tax_Exempt__c
            FROM B2B_Tax_Exemption__c
            WHERE Account__c = :accountId
            AND B2B_State_Code__c = :stateCode
            LIMIT 1
        ];
        if (!exemptions.isEmpty()) {
            B2B_Tax_Exemption__c b2bTaxExemption = exemptions[0];
            return b2bTaxExemption != null && b2bTaxExemption.B2B_Is_Currently_Tax_Exempt__c == true;
        }
        return false;
    } catch (Exception e) {
        System.debug('Error fetching tax exemption: ' + e.getMessage());
        return false;
    }
  }
}