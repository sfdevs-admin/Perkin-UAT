@isTest
public class Test_SBERestriction{
   /* public static testmethod void testApttus(){

        // Create a test user
        // Query Group - and insert user into it.
        Profile sysAdmin_Prof = [select Id from profile where Name='System Administrator'];
        User testUser = new User(alias = 'sUser',  Home_Country__c = 'US', email='standarduserPKIINF@perkinelmerAPTTUS.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = sysAdmin_Prof.Id,timezonesidkey='America/Los_Angeles', username='standarduser12343432@perkinelmerPKITESTAPTTUS.com');
        insert testUser;
        //List<Group> apttusGroup = [SELECT Id FROM Group where name like '%Apttus%'];

         //Create Test Groups
        Group testGroup1 = new Group();
        Group testGroup2 = new Group();
        Group testGroup3 = new Group();
        testGroup1.Name='TestGroup A';
        testGroup2.Name='TestGroup A';
        testGroup3.Name='TestGroup A';
        List<Group> groupList = new List<Group>();
        groupList.add(testGroup1);
        groupList.add(testGroup2);
        groupList.add(testGroup3);
        insert groupList;


        List<GroupMember> GMlist = new List<GroupMember>();
        List<GroupMember> NonApttusGMlist = new List<GroupMember>();
        GroupMember apttusGMember= new GroupMember();
        for(Group apGroup: [SELECT Id ,Name FROM Group where name like '%Apttus%']){
            if(apGroup.Name!='Apttus - Contract Shelton'){
                GroupMember GM = new GroupMember();
                GM.GroupId = apGroup.Id;
                GM.UserOrGroupId = testUser.Id;
                GMList.add(GM);      
          }
        }

        for(Group testGroup: groupList){
          
                GroupMember GM = new GroupMember();
                GM.GroupId = testGroup.Id;
                GM.UserOrGroupId = testUser.Id;
                NonApttusGMlist.add(GM);      
          
        }


        if(!GMList.isEmpty()) {
        System.debug('Group Member List is ' + GMList);
        insert GMList;
        }
         if(!NonApttusGMlist.isEmpty()) {
        System.debug('Group Member List is ' + NonApttusGMlist);
        insert NonApttusGMlist;
        }
      
        test.startTest();
          System.runAs(testUser){
        Apttus__APTS_Agreement__c apttusAgreement1 = new Apttus__APTS_Agreement__c();
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'Intellectual Property';
        insert apttusAgreement1 ;
        
          //Creating Territory Selection Record
             Territory_Selection__c selTerritory = new Territory_Selection__c();
            selTerritory.Agreement__c = apttusAgreement1.Id;
            selTerritory.Americas_Countries__c = 'ARGENTINA;BRAZIL';
            selTerritory.Asia_Countries__c = 'CHINA;FIJI;INDIA';
            selTerritory.Europe_Countries_1__c = 'BELGIUM;BOTSWANA';
            selTerritory.Europe_Countries_2__c = 'MOROCCO;NAMIBIA';
            Database.insert(selTerritory);
                
         //Creating Sales Volume Requirement Record
            Sales_Volume_Requirement__c svr = new Sales_Volume_Requirement__c();
            svr.Agreement__c = apttusAgreement1.Id;
            svr.Apts_Product_Line__c = 'ATOMIC ABSORPTION SPECTROSCOPY (AA);AUTOMATED WORKSTATIONS (AWS)';
            Database.insert(svr);
                
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'Medical Imaging';
        update apttusAgreement1;
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'Environmental';
        update apttusAgreement1;
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'EH – OneSource';
        update apttusAgreement1;
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'LST';
        update apttusAgreement1;
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'Diagnostics';
        update apttusAgreement1;
        }
        test.stopTest();
        //Create a test User


        
    }

    public static testmethod void testNonApttusIP(){

        // Create a test user
        // Query Group - and insert user into it.
        Profile sysAdmin_Prof = [select Id from profile where Name='System Administrator'];
        User testUser = new User(alias = 'testUser',  Home_Country__c = 'US', email='standarduserPKIINF@perkinelmerAPTTUS.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = sysAdmin_Prof.Id,timezonesidkey='America/Los_Angeles', username='standarduser12343432@perkinelmerPKITESTAPTTUS.com');
        insert testUser;
       
         Group testGroupA = new Group();
         testGroupA.Name='TestGroup A';
        insert testGroupA;
        GroupMember memberA= new GroupMember();
        memberA.GroupId=testGroupA.Id;
        memberA.UserOrGroupId=testUser.Id;
        insert memberA;


        test.startTest();
          System.runAs(testUser){

            try{
        Apttus__APTS_Agreement__c apttusAgreement1 = new Apttus__APTS_Agreement__c();
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'Intellectual Property';
        insert apttusAgreement1 ;
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'Medical Imaging';
        update apttusAgreement1;
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'Environmental';
        update apttusAgreement1;
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'EH – OneSource';
        update apttusAgreement1;
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'LST';
        update apttusAgreement1;
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'Diagnostics';
        update apttusAgreement1;
      }
     catch(DMLException  e){
              System.debug( 'message=' + e.getMessage());
            }
        }
        test.stopTest();
        //Create a test User


        
    }

 public static testmethod void testNonApttusMedical(){
      Profile sysAdmin_Prof = [select Id from profile where Name='System Administrator'];
        User testUser = new User(alias = 'testUser',  Home_Country__c = 'US', email='standarduserPKIINF@perkinelmerAPTTUS.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = sysAdmin_Prof.Id,timezonesidkey='America/Los_Angeles', username='standarduser12343432@perkinelmerPKITESTAPTTUS.com');
        insert testUser;
       
         Group testGroupB = new Group();
         testGroupB.Name='TestGroup A';
        insert testGroupB;
        GroupMember memberB= new GroupMember();
        memberB.GroupId=testGroupB.Id;
        memberB.UserOrGroupId=testUser.Id;
        insert memberB;


        test.startTest();
        
          System.runAs(testUser){
            try{
        Apttus__APTS_Agreement__c apttusAgreement1 = new Apttus__APTS_Agreement__c();
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'Medical Imaging';
        insert apttusAgreement1 ;
        }
        catch(DMLException  e){
              System.debug('message=' + e.getMessage());
            }
        }
        test.stopTest();
        
        
   }
   public static testmethod void testNonApttusEnvironmental(){
      Profile sysAdmin_Prof = [select Id from profile where Name='System Administrator'];
        User testUser = new User(alias = 'testUser',  Home_Country__c = 'US', email='standarduserPKIINF@perkinelmerAPTTUS.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = sysAdmin_Prof.Id,timezonesidkey='America/Los_Angeles', username='standarduser12343432@perkinelmerPKITESTAPTTUS.com');
        insert testUser;
       
         Group testGroupC = new Group();
         testGroupC.Name='TestGroup A';
        insert testGroupC;
        GroupMember memberC= new GroupMember();
        memberC.GroupId=testGroupC.Id;
        memberC.UserOrGroupId=testUser.Id;
        insert memberC;


        test.startTest();
          System.runAs(testUser){
        Apttus__APTS_Agreement__c apttusAgreement1 = new Apttus__APTS_Agreement__c();
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'Environmental';
        insert apttusAgreement1 ;
       
        }
        test.stopTest();
        
        
   }
   public static testmethod void testNonApttusEH(){
      Profile sysAdmin_Prof = [select Id from profile where Name='System Administrator'];
        User testUser = new User(alias = 'testUser',  Home_Country__c = 'US', email='standarduserPKIINF@perkinelmerAPTTUS.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = sysAdmin_Prof.Id,timezonesidkey='America/Los_Angeles', username='standarduser12343432@perkinelmerPKITESTAPTTUS.com');
        insert testUser;
       
         Group testGroupD = new Group();
         testGroupD.Name='TestGroup A';
        insert testGroupD;
        GroupMember memberD= new GroupMember();
        memberD.GroupId=testGroupD.Id;
        memberD.UserOrGroupId=testUser.Id;
        insert memberD;


        test.startTest();
          System.runAs(testUser){
        Apttus__APTS_Agreement__c apttusAgreement1 = new Apttus__APTS_Agreement__c();
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'EH – OneSource';
        insert apttusAgreement1 ;
       
        }
        test.stopTest();
        
        
   }
  public static testmethod void testNonApttusLST(){
      Profile sysAdmin_Prof = [select Id from profile where Name='System Administrator'];
        User testUser = new User(alias = 'testUser',  Home_Country__c = 'US', email='standarduserPKIINF@perkinelmerAPTTUS.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = sysAdmin_Prof.Id,timezonesidkey='America/Los_Angeles', username='standarduser12343432@perkinelmerPKITESTAPTTUS.com');
        insert testUser;
       
         Group testGroupE = new Group();
         testGroupE.Name='TestGroup A';
        insert testGroupE;
        GroupMember memberE= new GroupMember();
        memberE.GroupId=testGroupE.Id;
        memberE.UserOrGroupId=testUser.Id;
        insert memberE;


        test.startTest();
          System.runAs(testUser){
        Apttus__APTS_Agreement__c apttusAgreement1 = new Apttus__APTS_Agreement__c();
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'LST';
        insert apttusAgreement1 ;
       
        }
        test.stopTest();
        
        
   }
   public static testmethod void testNonApttusDiagnostics(){
      Profile sysAdmin_Prof = [select Id from profile where Name='System Administrator'];
        User testUser = new User(alias = 'testUser',  Home_Country__c = 'US', email='standarduserPKIINF@perkinelmerAPTTUS.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = sysAdmin_Prof.Id,timezonesidkey='America/Los_Angeles', username='standarduser12343432@perkinelmerPKITESTAPTTUS.com');
        insert testUser;
       
         Group testGroupF = new Group();
         testGroupF.Name='TestGroup A';
        insert testGroupF;
        GroupMember memberF= new GroupMember();
        memberF.GroupId=testGroupF.Id;
        memberF.UserOrGroupId=testUser.Id;
        insert memberF;


        test.startTest();
          System.runAs(testUser){
        Apttus__APTS_Agreement__c apttusAgreement1 = new Apttus__APTS_Agreement__c();
        apttusAgreement1.Strategic_Business_Element_SBE__c = 'Diagnostics';
        insert apttusAgreement1 ;
       
        }
        test.stopTest();
        
        
   }
   public static testmethod void testNonApttusUser(){
      Profile sysAdmin_Prof = [select Id from profile where Name='System Administrator'];
        User testUser = new User(alias = 'testUser',  Home_Country__c = 'US', email='standarduserPKIINF@perkinelmerAPTTUS.com',emailencodingkey='UTF-8',lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', profileid = sysAdmin_Prof.Id,timezonesidkey='America/Los_Angeles', username='standarduser12343432@perkinelmerPKITESTAPTTUS.com');
        insert testUser;

        Group testGroupA = new Group();
         testGroupA.Name='TestGroup A';
        insert testGroupA;
        GroupMember memberA= new GroupMember();
        memberA.GroupId=testGroupA.Id;
        memberA.UserOrGroupId=testUser.Id;
        insert memberA;

         test.startTest();
          System.runAs(testUser){
            try{
              Apttus__APTS_Agreement__c apttusAgreement1 = new Apttus__APTS_Agreement__c();
              apttusAgreement1.Strategic_Business_Element_SBE__c = 'Diagnostics';
              insert apttusAgreement1 ;      
            }
            catch(DMLException  e){
              System.debug('message=' + e.getMessage());
            }
        
       
        }
        test.stopTest();
   }
*/


}