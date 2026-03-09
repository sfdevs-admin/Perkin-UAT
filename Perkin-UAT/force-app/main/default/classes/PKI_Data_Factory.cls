/**************************************************************
 * 1. Jira Ticket(s) that relates to this class
 *    - ATEAM-1383
 *
 * 2. Description - Put detailed description here of what this class is used for procedurally
 *     This is the test data factory for all test classes.
 *
 * 3. Objects referenced
 *    -Account
 *    -Contact
 *    -Case
 *    -User
 *    -Opportunity
 *
 * 4. Callouts to additional Components (including their methods)- None
 *
 * 5. Dependant Class(es): None
 *
 * 6. Test Class Name: None
 *
 * 7. Is @Invocable (Yes or No):  No
 *
 * 8. Author Name(s):
 *    - (PwC Deepak Rajan) (2021.09.08)
 *    - First Last & Updated Date(YYYY.MM.DD)
 *
 *************************************************************/
@IsTest
public class PKI_Data_Factory {
  public class PKI_Data_FactoryException extends Exception {
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Use the FieldDefaults interface to set up values you want to default in for all objects.
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  public interface FieldDefaults {
    Map<Schema.SObjectField, Object> getFieldDefaults();
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Returns the ProfileId of the given ProfileName
   * @parameter        profileName: the name of the Profile
   * @returnValue      Id of requested Profile
   * @example          Id profileId = PKI_Data_Factory.getProfileId( 'System Administrator' );
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  public static Id getProfileId(String profileName) {
    Id profileId = [
      SELECT Id, Name, UserType
      FROM Profile
      WHERE Name = :profileName
      LIMIT 1
    ]
    .Id;
    return profileId;
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Returns the List<RecordType> of the given Sobject
   * @parameter        SobjectType: the name of the Object
   * @returnValue      List<RecordType> of requested Object
   * @example          List<RecordType> recTypeList = PKI_Data_Factory.getRecordTypes('Account');
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  public static List<RecordType> getRecordTypes(String SobjectType) {
    List<RecordType> recTypeList = new List<RecordType>(
      [
        SELECT Id, DeveloperName, Name
        FROM RecordType
        WHERE SobjectType = :SobjectType
      ]
    );
    return recTypeList;
  }

  /*
   * ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Returns the instance of the Sobject
   * @parameter        sObj: instance of Sobject
   *                   doInsert: pass true for insertion or false for instance
   * @returnValue      instance of requested Sobject
   * @example          Account acc = (Account) PKI_Data_Factory.createSObject(new Account(name = 'Test Account'),true);
   * ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  public static SObject createSObject(SObject sObj, Boolean doInsert) {
    SObject retObject = createSObject(sObj);
    if (doInsert) {
      insert retObject;
    }
    return retObject;
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Returns the instance of the Sobject
   * @parameter        sObj: instance of Sobject
   * @returnValue      instance of requested Sobject
   * @example          Account acc = (Account) PKI_Data_Factory.createSObject(new Account(name = 'Test Account'));
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  public static SObject createSObject(SObject sObj) {
    // Check what type of object we are creating and add any defaults that are needed.
    String objectName = String.valueOf(sObj.getSObjectType());
    // Construct the default values class. Salesforce doesn't allow '__' in class names
    String defaultClassName =
      objectName.replaceAll('__(c|C)$|__', '') + 'Defaults';
    // If there is a class that exists for the default values, then use them
    if (Type.forName('PKI_Data_Factory.' + defaultClassName) != null) {
      sObj = createSObject(sObj, 'PKI_Data_Factory.' + defaultClassName);
    }
    return sObj;
  }

  /*
   * ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Returns the instance of the Sobject
   * @parameter        sObj: instance of Sobject
   *                   defaultClassName: default Class Name  to use default values for that object
   * @returnValue      instance of requested Sobject
   * @example          Account acc = (Account) PKI_Data_Factory.createSObject(new Account(Phone = '9999999999'),'AccountDefaults');
   * ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  public static SObject createSObject(SObject sObj, String defaultClassName) {
    // Create an instance of the defaults class so we can get the Map of field defaults
    Type t = Type.forName(defaultClassName);
    if (t == null) {
      throw new PKI_Data_FactoryException('Invalid defaults class.');
    }
    FieldDefaults defaults = (FieldDefaults) t.newInstance();
    addFieldDefaults(sObj, defaults.getFieldDefaults());
    return sObj;
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Returns the list of instance of the Sobject
   * @parameter        sObj: instance of Sobject
   *                   numberOfObjects: number of records needs to create.
   * @returnValue      list of instance of requested Sobject
   * @example          List<Account> accList = (Account) PKI_Data_Factory.createSObjectList(new Account(Name = 'Test Account'),10);
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  public static SObject[] createSObjectList(
    Sobject sObj,
    Integer numberOfObjects
  ) {
    return createSObjectList(sObj, numberOfObjects, (String) null);
  }

  /*
   * ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Returns the list of instance of the Sobject
   * @parameter        sObj: instance of Sobject
   *                   numberOfObjects: number of records needs to create
   *                   doInsert: pass true for insertion or false for instance
   * @returnValue      list of instance of requested Sobject
   * @example          List<Account> accList = (Account) PKI_Data_Factory.createSObjectList(new Account(Name = 'Test Account'),10,true);
   * ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  public static SObject[] createSObjectList(
    SObject sObj,
    Integer numberOfObjects,
    Boolean doInsert
  ) {
    SObject[] retList = createSObjectList(sObj, numberOfObjects, (String) null);
    if (doInsert) {
      insert retList;
    }
    return retList;
  }

  /*
   * ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Returns the list of instance of the Sobject
   * @parameter        sObj: instance of Sobject
   *                   numberOfObjects: number of records needs to create
   *                   defaultClassName: default Class Name  to use default values for that object
   *                   doInsert: pass true for insertion or false for instance
   * @returnValue      list of instance of requested Sobject
   * @example          List<Account> accList = (Account) PKI_Data_Factory.createSObjectList(new Account(Phone = '9999999999'),10,'AccountDefaults',true);
   * ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  public static SObject[] createSObjectList(
    SObject sObj,
    Integer numberOfObjects,
    String defaultClassName,
    Boolean doInsert
  ) {
    SObject[] retList = createSObjectList(
      sObj,
      numberOfObjects,
      defaultClassName
    );
    if (doInsert) {
      insert retList;
    }
    return retList;
  }

  /*
   * ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Returns the list of instance of the Sobject
   * @parameter        sObj: instance of Sobject
   *                   numberOfObjects: number of records needs to create
   *                   defaultClassName: default Class Name  to use default values for that object
   * @returnValue      list of instance of requested Sobject
   * @example          List<Account> accList = (Account) PKI_Data_Factory.createSObjectList(new Account(Phone = '9999999999'),10,'AccountDefaults');
   * ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  public static SObject[] createSObjectList(
    Sobject sObj,
    Integer numberOfObjects,
    String defaultClassName
  ) {
    SObject[] sObjs = new List<SObject>{};
    SObject newObj;

    // Get one copy of the object
    if (defaultClassName == null) {
      newObj = createSObject(sObj);
    } else {
      newObj = createSObject(sObj, defaultClassName);
    }

    // Get the name field for the object
    String nameField = String.valueOf(nameFieldMap.get(sObj.getSObjectType()));
    if (nameField == null) {
      nameField = 'Name';
    }
    Boolean nameIsAutoNumber = sObj.getSobjectType()
      .getDescribe()
      .fields.getMap()
      .get(nameField)
      .getDescribe()
      .isAutoNumber();

    // Clone the object the number of times requested. Increment the name field so each record is unique
    for (Integer i = 0; i < numberOfObjects; i++) {
      SObject clonedSObj = newObj.clone(false, true);
      if (!nameIsAutoNumber) {
        clonedSObj.put(nameField, (String) clonedSObj.get(nameField) + ' ' + i);
      }
      sObjs.add(clonedSObj);
    }
    return sObjs;
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      When we create a list of SObjects, we need to have a unique field for the insert if
   *                   there isn't an autonumber field.
   *                   Usually we use the Name field, but some objects don't have a name field.
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  private static Map<Schema.SObjectType, Schema.SObjectField> nameFieldMap = new Map<Schema.SObjectType, Schema.SObjectField>{
    Contact.sObjectType => Contact.LastName,
    Case.sObjectType => Case.CaseNumber //this is the autonumber field
  };

  /*
   * ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Returns the instance of the Inserted List<Sobject>
   * @returnValue      instance of requested List<Sobject>
   * @example          Account acc = (Account) PKI_Data_Factory.createSObject(New List<Account>(),true);
   * ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  public static List<SObject> insertSObjectList(List<SObject> sObjList) {
    if (!sObjList.IsEmpty()) {
      insert sObjList;
    }
    return sObjList;
  }
  /*
   * ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Returns the instance of the updated Sobject
   * @parameter        sObj: instance of Sobject
   * @returnValue      instance of updated Sobject
   * @example          Account acc = (Account) PKI_Data_Factory.updateSObject(new Account(id='0018E00001Rt8Zv',name = 'Test Account'),true);
   * ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  public static SObject updateSObject(SObject sObj) {
    update sObj;
    return sObj;
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Use to create sObjects instance with given defaults fields.
   * @parameter        sObj= the record of the Object
   *                   defaults= the defaults fields
   * @returnValue      void
   * @example
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  private static void addFieldDefaults(
    SObject sObj,
    Map<Schema.SObjectField, Object> defaults
  ) {
    // Loop through the map of fields and if they weren't specifically assigned, fill them.
    Map<String, Object> populatedFields = sObj.getPopulatedFieldsAsMap();
    for (Schema.SObjectField field : defaults.keySet()) {
      if (!populatedFields.containsKey(String.valueOf(field))) {
        sObj.put(field, defaults.get(field));
      }
    }
  }

  /*
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   * @description      Below Classes are used to created default records for objects , here we need to add
   *                   as per requirement in respective stories
   * ──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
   */
  public class AccountDefaults implements FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object>{
        Account.Name => 'Test Account',
        Account.ShippingCity => 'São Paulo',
        Account.ShippingCountry => 'BR'
      };
    }
  }

  public class ContactDefaults implements FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object>{
        Contact.FirstName => 'First',
        Contact.LastName => 'Last'
      };
    }
  }

  public class OpportunityDefaults implements FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object>{
        Opportunity.Name => 'Test Opportunity',
        Opportunity.StageName => 'Closed Won',
        Opportunity.CloseDate => System.today()
      };
    }
  }

  public class CaseDefaults implements FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object>{
        Case.Subject => 'Test Case',
        Case.Status => 'New',
        Case.Priority => 'Medium',
        Case.Description => 'Test Description'
      };
    }
  }

  public class UserDefaults implements FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object>{
        User.EmailEncodingKey => 'UTF-8',
        User.LanguageLocaleKey => 'en_US',
        User.LocaleSidKey => 'en_GB',
        User.Country => 'United Kingdom',
        User.TimeZoneSidKey => 'Europe/London',
        User.FirstName => 'Test FirstName',
        User.LastName => 'Test LastName',
        User.isActive => true,
        User.Email => 'test' +
        Math.random().format() +
        String.valueOf(Datetime.now())
          .replace('-', '')
          .replace(':', '')
          .replace(' ', '') +
        'user1@test.org',
        User.UserName => 'test' +
        Math.random().format() +
        String.valueOf(Datetime.now())
          .replace('-', '')
          .replace(':', '')
          .replace(' ', '') +
        'user1@test.org',
        User.Alias => 'testU',
        User.CommunityNickname => ('testU' + Datetime.now().getTime()).left(40)
      };
    }
  }
}