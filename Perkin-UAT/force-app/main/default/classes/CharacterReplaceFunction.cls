/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    - ATEAM-1366
 *
 * 2. Description - Put detailed description here of what this class is used for procedurally
 *    This class is used to replace Diacritics with the plain English values and the mapping
 *    is stored in C_META_Character_Replace__mdt custom metadata.
 *    It is invoked using P.FLOW:2100 when account name, city or street is changed.
 *    It can also be invoked by M.ACTION to perform a backfill
 *
 * 3. Objects referenced
 *    -Account
 *    -C_META_Character_Replace__mdt
 *    -SFDC_LOG__c
 *
 * 4. Callouts to additional Components (including their methods)- None
 *
 * 5. Dependant Class(es): None
 *
 * 6. Test Class Name: CharacterReplaceFunction_Test
 *
 * 7. Is @Invocable (Yes or No):  Yes
 *
 * 8. Author Name(s):
 *    - (PwC Deepak Rajan) (2021.09.01)
 *    - First Last & Updated Date(YYYY.MM.DD)
 *
 *************************************************************/
public class CharacterReplaceFunction {
  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Used to replace Diacritics from mapping stored in Custom Metadata.
   * @parameter        attribute
   * @returnValue      void
   *
   * @example
   * CharacterReplaceFunction.Inputs attr = new CharacterReplaceFunction.Inputs();
   * attr.input        = 'São Paulo';
   * attr.objectName   = 'Account';
   * attr.field        = 'fxSearchName__c';
   * attr.isCapitalise = true;
   * attr.recordId     = 'XXXXXXXXXXXXX';
   * CharacterReplaceFunction.character_replace_update(new List<CharacterReplaceFunction.Inputs>{attr});
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  @InvocableMethod(label='Character Replace Update')
  public static void character_replace_update(List<Inputs> attribute) {
    //to store the updated records
    List<sObject> updateList = new List<sObject>();

    //get running userName to store into SFDC_Log__c
    String runningUserName = String.isNotBlank(attribute[0].runningUser)
      ? attribute[0].runningUser
      : UserInfo.getName();

    //used to store a map of findWhat values against replace values
    Map<String, String> diacriticsToPlainEnglishMap = new Map<String, String>();

    //quering the value from custom metadata and populating the map
    for (C_META_Character_Replace__mdt meta : [
      SELECT FindWhat__c, ReplaceWith__c
      FROM C_META_Character_Replace__mdt
      WHERE inactive__c = FALSE
    ]) {
      diacriticsToPlainEnglishMap.put(meta.FindWhat__c, meta.ReplaceWith__c);
    }

    //iterate through values from wrapper class
    for (Inputs eachInput : attribute) {
      //get values from inputs wrapper class
      String input = eachInput.input;
      String objectName = eachInput.objectName;
      String field = eachInput.field;
      Boolean isCapitalise = eachInput.isCapitalise;
      String recordId = eachInput.recordId;

      //breaking a string into characters
      String[] stringCharacters = input.split('');
      //São Paulo

      //traversing the individual characters of a string
      for (Integer i = 0; i < stringCharacters.size(); i++) {
        //checking if character is found in custom metdata map
        if (diacriticsToPlainEnglishMap.containsKey(stringCharacters[i])) {
          //get the character from original input string
          String temp = input.substring(i, i + 1);
          //replace the character
          input = input.replace(
            temp,
            diacriticsToPlainEnglishMap.get(stringCharacters[i])
          );
        }
      }
      // get RecordId's from updateList
      Set<Id> sObjectIds = (new Map<Id, SObject>(updateList)).keySet();
      //check if recordId is already present in the updateList
      if (sObjectIds.contains(recordId)) {
        Map<Id, Sobject> resultIds = (new Map<Id, SObject>(updateList));
        //get the exiting record
        SObject obj = resultIds.get(recordId);
        //check for isCapitalise and based on that put the value in field in the sObject instance
        obj.put(field, isCapitalise ? input.toUppercase() : input);
      } else {
        //dynamically create a new instance of objectName
        SObject sObj = (SObject) (Type.forName('Schema.' + objectName)
          .newInstance());
        //map the recordId field
        sObj.Id = recordId;
        //check for isCapitalise and based on that put the value in field in the sObject instance
        sObj.put(field, isCapitalise ? input.toUppercase() : input);
        updateList.add(sObj);
      }
    }

    //check if updateList is not empty and update the records
    if (!updateList.isEmpty()) {
      List<SFDC_LOG__c> logList = new List<SFDC_LOG__c>();
      //update the records
      Database.SaveResult[] result = Database.update(updateList, false);
      //iterate the updated records
      for (Database.SaveResult res : result) {
        //check if there is a faliure
        if (!res.isSuccess()) {
          //create SFDC_LOG__c and map the fields
          SFDC_LOG__c eachLog = new SFDC_LOG__c();
          eachLog.Source_Type__c = 'APEX';
          eachLog.Log_Type__c = 'Error/Exception Log';
          eachLog.Source_Step__c = 'CharacterReplace';
          eachLog.Source_Name__c = 'A.CLS CharacterReplaceFunction';
          eachLog.Running_User__c = runningUserName;
          eachLog.Message_Long__c =
            'ERROR: ' +
            res.getErrors() +
            ' | ID: ' +
            res.getId() +
            ' | Field: ' +
            attribute[0].field;
          logList.add(eachLog);
        }
      }
      //check if logList is not empty and insert the logs into the system
      if (!logList.isEmpty()) {
        insert logList;
      }
    }
  }

  //wrapper class to store the input variables
  public class Inputs {
    @InvocableVariable
    public String input;
    @InvocableVariable
    public String objectName;
    @InvocableVariable
    public String field;
    @InvocableVariable
    public Boolean isCapitalise;
    @InvocableVariable
    public String recordId;
    @InvocableVariable
    public String runningUser;
  }
}