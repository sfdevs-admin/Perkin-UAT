/**************************************************************
  * 1. Jira Ticket(s) that relates to Apex class "MetadataDeleteViaApi"
  *    - ATEAM-264 APEX to modify Metadata via API to for cleanup of unused items
  *
  * 2. Description - This Apex Batch class is used to delete unused Listview,Report,Dashboard,Email template, Dashboardcomponent and their Empty folder.
  *				     From mass action we are calling scheduler apex batch class "MetadataDeleteViaApi_scheduler" and based on pass paramter it is processing 
  *                  and deleting Sobject.
  * 3. Objects referenced
  *    -ListView
  *    -Report
  *    -DashBoard
  *    -DashBoardomponent
  *    -EmailTemplate
  *    -Folder 
  *
  * 4. Callouts to additional Components (including their methods) or None:
  *    - FetchLARMetadataAPI.deleteListView(typestring, Fldxml); Where typestring=Sobjecttype and Fldxml is list of string(xml of Sobject)
  *
  * 5. Dependant Class(es):
  *    - FetchLARMetadataAPI
  *    - LeadAssignmentRule_Calculations
  *    - MetadataDeleteViaApi_scheduler
  *    
  *
  * 6. Test Class Name: MetaDataDeleteViaApi_BatchTest
  *
  * 7. Author Name(s): 
  *    - Vishwas Kumar Gupta (PWC) & Created Date(4/21/2021)
  *    - Vishwas Kumar Gupta (PWC) & Updated Date(5/17/2021)
  *
*************************************************************/ 
global class MetadataDeleteViaApi implements Database.Batchable<sObject>, Database.AllowsCallouts{
	public final String sobjname;
	public final String typestring;
	public final set<Id> ids;
    // Constructor for passing two parameters objectname and set of ids to delete
	public MetadataDeleteViaApi(string sobjnam, set<Id> lstid){
		ids = lstid;
		sobjname = sobjnam;
	}
    // Constructor for folder delete passing three parameters objectname and set of ids and type of folder to delete
	public MetadataDeleteViaApi(string sobjnam, set<Id> lstid, string typestr){
		typestring = typestr;
		sobjname = sobjnam;
		ids = lstid;
	}
// Start method to return database.Querylocator (Sobject) for different sobjname depend upon what sobject paramter provided
	public Database.QueryLocator start(Database.BatchableContext BC){
		string Query;
		if (sobjname.equalsIgnoreCase('Listview'))
			Query = 'select Id,SobjectType,DeveloperName from ' + sobjname + ' where id IN: ids';
		else if (sobjname.equalsIgnoreCase('Report'))
			Query = 'select Id,foldername,DeveloperName,OwnerId from ' + sobjname + ' where id IN: ids';
		else if (sobjname.equalsIgnoreCase('DashBoard'))
			Query = 'select Id,folder.developername,DeveloperName from ' + sobjname + ' where id IN: ids';
        else if (sobjname.equalsIgnoreCase('EmailTemplate'))
			Query = 'select Id,foldername,DeveloperName from ' + sobjname + ' where id IN: ids';
		else if (sobjname.equalsIgnoreCase('Folder'))
			Query = 'select Id,Name,DeveloperName from ' + sobjname + ' where id IN: ids';
		else if (sobjname.equalsIgnoreCase('DashboardComponent'))
			Query = 'select Id,folder.developername,DeveloperName from dashboard where Id IN (Select dashboardId from dashboardcomponent where id IN: ids)';
		
		return Database.getQueryLocator(Query);
	}
// Execute Method -- perfoem all operation on each batch of records...
	public void execute(Database.BatchableContext BC, List<Sobject> Scope){
		list<ID> reportIds = new list<Id>();
		list<string> reportxml = new list<string>(); //list of  xml string to delete report
		List<string> lstobjxml = new List<string>(); //list of  xml string to delete Listview
		List<string> Dashbrdxml = new List<string>(); //list of  xml string to delete dashboard
		List<string> Fldxml = new List<string>(); //list of  xml string to delete Folder
//system.debug('Scope size=='+Scope.size());
		for (sobject rpt : Scope){
            // creating xml list for report 
			if (sobjname.equalsIgnoreCase('Report')){
				reportIds.add(rpt.Id);
				if (rpt.get('OwnerId') == UserInfo.getOrganizationId()){ // this is condition for public reports
					reportxml.add('unfiled$public/' + rpt.get('DeveloperName'));
				} else{
					reportxml.add(string.valueof(rpt.get('FolderName'))+'/' + rpt.get('DeveloperName'));
				}
			}
            // creating xml list for listview -----
			if (sobjname.equalsIgnoreCase('Listview')){
				lstobjxml.add(string.valueof(rpt.get('SobjectType'))+'.' + string.valueof(rpt.get('DeveloperName')));
			}
            // creating xml list for Dashboard -----
			if (sobjname.equalsIgnoreCase('Dashboard')){
				Dashbrdxml.add(string.valueof(rpt.getSobject('Folder').get('DeveloperName'))+'/' + string.valueof(rpt.get('DeveloperName')));
			}
			// creating xml list for DashboardComponent -----
			if (sobjname.equalsIgnoreCase('DashboardComponent')){
                Dashbrdxml.add(string.valueof(rpt.getSobject('Folder').get('DeveloperName'))+'/' + string.valueof(rpt.get('DeveloperName')));
			//system.debug('Dashbrdxml==='+Dashbrdxml);
            }
            // creating xml list for Folder------
            if (sobjname.equalsIgnoreCase('Folder')){
             //   system.debug('rpt=='+rpt);
	        Fldxml.add(string.valueof(rpt.get('DeveloperName')));
           }
		}
            // Preparing to delete EmailTemplate
            if (sobjname.equalsIgnoreCase('EmailTemplate')){
                if(!Scope.isEmpty()){ 
                Database.DeleteResult[] drList = Database.delete(Scope,false);
                for(Database.DeleteResult dr : drList) {
                    if (dr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                       // System.debug('Successfully deleted account with ID: ' + dr.getId());
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : dr.getErrors()) {
                        }
                    }
                }
			}

		}
      
        // going to delete report but first check all dependent dashboard component if exit then delete those first.
		if (!reportIds.isEmpty() && sobjname.equalsIgnoreCase('Report')){
                List<Dashboard> dashbrd = new List<Dashboard>();
                List<string> Dashboardxml = new List<string>();
                List<dashboardcomponent> dbrdcmp=new List<dashboardcomponent>();
                set<id> dbrdcpmid = new set<id>();
                dbrdcmp= [select DashboardId from dashboardcomponent Where CustomReportId IN :reportIds];
                if(!dbrdcmp.isEmpty()){
                    for(dashboardcomponent dbcmp:dbrdcmp){
                        dbrdcpmid.add(dbcmp.DashboardId);
                    }
                }
                if(!dbrdcpmid.isEmpty()){
                   dashbrd = [Select id, developername, folder.developername
                           from Dashboard
                           Where id IN :dbrdcpmid]; 
                }
                
                if (!dashbrd.isEmpty()){
                  //  system.debug('dashbrd=='+dashbrd);
                    for (Dashboard db : dashbrd){
                        Dashboardxml.add(db.Folder.DeveloperName + '/' + db.DeveloperName);
                    }
                }
                boolean b = false;
                if (!Dashboardxml.isEmpty()){
                 //   system.debug('Dashboardxml=='+Dashboardxml);
                    if(!Test.isRunningTest ())
                   b= FetchLARMetadataAPI.deleteListView('Dashboard', Dashboardxml);
                 }
                if (Dashboardxml.isEmpty() && !reportxml.isEmpty()){
                    system.debug('reportxml=='+reportxml);
                    if(!Test.isRunningTest ())
                    FetchLARMetadataAPI.deleteListView('Report', reportxml);
                }
           }
        // deleting listview after final xml list.....
         if (!lstobjxml.isEmpty()){
            if(!Test.isRunningTest ())
			FetchLARMetadataAPI.deleteListView('ListView', lstobjxml);
		}
        // deleting dashboard after final xml list.....
		if (!Dashbrdxml.isEmpty()){
            if(!Test.isRunningTest ())
			FetchLARMetadataAPI.deleteListView('Dashboard', Dashbrdxml);
		}
        // deleting Empty Folder after final xml list.....
		if(!Fldxml.isEmpty() && typestring != null){
            if(!Test.isRunningTest ())
			FetchLARMetadataAPI.deleteListView(typestring, Fldxml);
		}
	}
// Finish method just to delete next schedule job using CronTrigger object.......
	public void finish(Database.BatchableContext BC){
		string cronname = 'delete ' + sobjname;
		CronTrigger con = [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType, NextFireTime
		                   FROM CronTrigger
		                   WHERE CronJobDetail.Name = :cronname
		                   ORDER BY CreatedDate desc
		                   LIMIT 1];
		//then use the active job id and abort it
		System.abortJob(con.id);
	}
}