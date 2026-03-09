/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    - ATEAM-1364
 *
 * 2. Description - Put detailed description here of what this class is used for procedurally
 *    This class is used to search account as part of Account Smart Search functioanlity based
 *    on certain condition
 *
 * 3. Objects referenced
 *    -Account
 *
 * 4. Callouts to additional Components (including their methods)- None
 *
 * 5. Dependant Class(es): None
 *
 * 6. Test Class Name: SmartSearchApexController_Test
 *
 * 7. Is @Invocable (Yes or No):  No
 *
 * 8. Author Name(s):
 *    - (PwC Deepak Rajan) (2021.08.31)
 *    - First Last & Updated Date(YYYY.MM.DD)
 *
 *************************************************************/
public with sharing class SmartSearchApexController {
  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      wrapper class to assemble request information from the client side controller
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  @testvisible
  private class Inputs {
    public String searchKeyWord;
    public String searchSAP;
    public String searchCity;
    public String searchStreet;
    public String searchCountry;
    public Integer maxResults;
  }
  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      wrapper class to assemble response information to the client side controller
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  @testvisible
  private class Result {
    public Boolean isError;
    public String message;
    public Boolean isMore;
    public List<Account> accounts;
    public result(String m, List<Account> o) {
      this.message = m;
      this.accounts = (o != null) ? o : new List<Account>();
      this.isMore = false;
      this.isError = false;
    }
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Used to fetch Account Records for searched string.
   * @parameter        payload
   * @returnValue      String
   * @example          SmartSearchApexController.retrieveSearchResults(payload);
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  @AuraEnabled
  public static String retrieveSearchResults(string payload) {
    Result res = new Result('no results', new List<Account>()); // default response

    Inputs attr = (Inputs) JSON.deserialize(payload, Inputs.class); // deserialise into attributes
    //forming the query
    String query =
      'SELECT  Id, fxSearchCity__c, fxSearchName__c, fxSearchStreet__c, Name, PKI_SAP_Customer_Number__c, PKI_SAP_Name_2__c, ' +
      'PKI_SAP_Customer_Base_Name__c, Opportunity_Info__c, ShippingCountry, ' +
      'ShippingCity, ShippingStreet, ShippingState, PKI_SAP_Name_3__c, ' +
      'PKI_SAP_Name_4__c,NameLocal,PKI_ShippingStreetLocal__c,PKI_ShippingCityLocal__c FROM ACCOUNT WHERE ';

    //the fixed filter in query
    String FixedFilter =
      '(PKI_SAP_Account_Group__c=\'0001\' OR ' +
      'PKI_SAP_Account_Group__c=\'ZBR1\' OR ' + 
      'PKI_SAP_Account_Group__c=\'OMIT\' OR ' +  
      'PKI_SAP_Account_Group__c=\'SFDC\') AND  ' +
      '(PKI_SAP_Marked_For_Deletion__c=false) AND (MDM_Status__c!=\'Rejected\')';

    //creating the filters from input search strings
    if (checkBlankString(attr.searchKeyWord)) {
      String name = removeSingleQuotes(attr.searchKeyWord.trim());
      FixedFilter += 'AND ( fxSearchName__c LIKE \'%' + name + '%\' OR NameLocal LIKE \'%' + name + '%\' ) ';
    }
    //  system.debug('FixedFilter='+FixedFilter);
    if (checkBlankString(attr.searchSAP)) {
      String sapNo = removeSingleQuotes(attr.searchSAP);
      FixedFilter += 'AND PKI_SAP_Customer_Number__c =: sapNo ';
    }
    if (checkBlankString(attr.searchStreet)) {
      String street = removeSingleQuotes(attr.searchStreet);
      FixedFilter += 'AND (fxSearchStreet__c LIKE \'%' + street + '%\' OR PKI_ShippingStreetLocal__c LIKE \'%' + street + '%\' ) ';
    }
    if (checkBlankString(attr.searchCity)) {
      String city = removeSingleQuotes(attr.searchCity.trim());
      FixedFilter += 'AND (fxSearchCity__c LIKE \'%' + city + '%\' OR PKI_ShippingCityLocal__c LIKE \'%' + city + '%\' ) ';
    }
    if (checkBlankString(attr.searchCountry)) {
      String country = removeSingleQuotes(attr.searchCountry.trim());
      FixedFilter += 'AND ShippingCountry LIKE \'%' + country + '%\' ';
    }

    // put order by clause and limit for restricitng the count of records queried
    query += FixedFilter + ' ORDER BY Opportunity_Info__c DESC LIMIT 2000';
system.debug('query'+query);
    try {
      List<Account> retrievedRecords = Database.query(query); // dynamic query records
system.debug('retrievedRecords=='+retrievedRecords);
      if (!retrievedRecords.isEmpty()) {
        res.message = '';
        res.accounts = retrievedRecords;
        res.isMore = (res.accounts.size() > attr.maxResults);
      }
    } catch (DMLexception e) {
        
      res.isError = true;
      res.message = 'DML exception:' + e.getMessage();
    } catch (QueryException e) {
        system.debug('exception'+e.getMessage()+e.getStackTraceString());
        system.debug('exception'+e.getCause());
      res.isError = true;
      res.message = 'Error occured during retrieval of records. Check query string fields.';
    }
    return JSON.serialize(res);
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Used to prevent the string from causing SOQL injection.
   * @parameter        str
   * @returnValue      String
   * @example          SmartSearchApexController.removeSingleQuotes(str);
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  private static String removeSingleQuotes(String str) {
    return String.escapeSingleQuotes(str);
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Used to check if string is blank or not.
   * @parameter        str
   * @returnValue      String
   * @example          SmartSearchApexController.checkBlankString(str);
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  private static Boolean checkBlankString(String str) {
    return String.isNotBlank(str);
  }
}