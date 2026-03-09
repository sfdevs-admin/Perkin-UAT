@isTest 
public class MetaDataDeleteViaApi_BatchTest {
    static testMethod void testMethod1(){
        Test.startTest();
/*        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute());
        String ss = String.valueOf(Datetime.now().second()+5);
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';*/
        
        Datetime workTime = System.now().addMinutes(15);
        String nextFireTime = '' + workTime.second() + ' ' + workTime.minute() + ' ' + workTime.hour() + ' ' + workTime.day() + ' ' + workTime.month() + ' ? ' + workTime.year();
//        String jobID = System.schedule('A new Job To Schedule -> ' + memberId, nextFireTime, new SchedualApexClass(memberId));

        string targetMetadata='EmailTemplate';
                list<Emailtemplate> results =new list<Emailtemplate>();
                EmailTemplate emltempl = new Emailtemplate();
                emltempl.developerName = 'test';
                emltempl.FolderId = userinfo.getOrganizationId();
                emltempl.TemplateType= 'Text';
                emltempl.Name = 'test';
                insert emltempl;
                results.add(emltempl);
        Set<Id> resultIds = (new Map<Id,SObject>(results)).keySet();
       MetadataDeleteViaApi_scheduler sc1 = new MetadataDeleteViaApi_scheduler(targetMetadata,resultIds);
       system.schedule('delete '+targetMetadata ,nextFireTime,sc1);
       Test.stopTest();
    }
    @isTest(SeeAllData=true)
    static  void testforReport(){
        Test.startTest();
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute());
        String ss = String.valueOf(Datetime.now().second()+5);
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';

        string targetMetadata='Report';
        list<Report> results =[select id from Report order by createddate Limit 1];
        Set<Id> resultIds = (new Map<Id,SObject>(results)).keySet();
       MetadataDeleteViaApi_scheduler sc1 = new MetadataDeleteViaApi_scheduler(targetMetadata,resultIds);
     system.schedule('delete '+targetMetadata ,nextFireTime,sc1);
       Test.stopTest();
    }
    @isTest(SeeAllData=true)
    static  void testforDashborad(){
        Test.startTest();
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute());
        String ss = String.valueOf(Datetime.now().second()+5);
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';

        string targetMetadata='Dashboard';
        list<Dashboard> results =[select id from Dashboard where developername != null  Limit 5];
        Set<Id> resultIds = (new Map<Id,SObject>(results)).keySet();
       MetadataDeleteViaApi_scheduler sc1 = new MetadataDeleteViaApi_scheduler(targetMetadata,resultIds);
     system.schedule('delete '+targetMetadata ,nextFireTime,sc1);
       Test.stopTest();
    }
     @isTest(SeeAllData=true)
    static  void testforFolder(){
        Test.startTest();
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute());
        String ss = String.valueOf(Datetime.now().second()+5);
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        string targetMetadata ='Folder'; 
        string typestring='Dashboard';
        string typestr;
        if(typestring.equalsIgnoreCase('dashboard'))
            typestr='\'Dashboard\'';
        else if(typestring.equalsIgnoreCase('Report'))
            typestr='\'Report\''; 
        else if(typestring.equalsIgnoreCase('EmailTemplate'))
            typestr='\'Email\'';
        string someSOQL;
        if(typestring.equalsIgnoreCase('dashboard') || typestring.equalsIgnoreCase('emailtemplate'))
            someSOQL ='select Id from '+ targetMetadata +' Where Type='+typestr+' AND Id NOT IN (select FolderId from '+typestring+' ) order by createddate limit 1';
        else if(typestring.equalsIgnoreCase('Report'))
            someSOQL ='select Id from '+ targetMetadata +' Where Type='+typestr+' AND OwnerId NOT IN (select Id from '+typestring+' ) order by createddate limit 1';    
        List<SObject> results = Database.query(someSOQL);
        
        Set<Id> resultIds = (new Map<Id,SObject>(results)).keySet();
        MetadataDeleteViaApi_scheduler sc1 = new MetadataDeleteViaApi_scheduler(targetMetadata,resultIds,typestring);
        system.schedule('delete '+targetMetadata ,nextFireTime,sc1);

       Test.stopTest();
    }
    
}