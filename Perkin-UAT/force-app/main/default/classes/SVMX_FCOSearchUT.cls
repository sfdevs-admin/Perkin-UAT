/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class SVMX_FCOSearchUT {

    static testMethod void myUnitTest() {
        Account Acc = new Account(Name='ACC001',
                                BillingStreet='ABC',
                                BillingCity='PQR ',
                                BillingState = 'CA',
                                BillingPostalCode='111',
                                BillingCountry='US',
                                Active__c=true);
        insert Acc;         
        
        
        Product2 prod = new Product2(ProductCode='UTProd001',
                                    Name='UTProd001',
                                    Family='Oncology',
                                    SVMXC__Product_Line__c='Desktop',
                                    IsActive=true);
        insert prod;
        
        Product2 prod1 = new Product2(ProductCode='UTProd002',
                                    Name='UTProd002',
                                    Family='Oncology',
                                    SVMXC__Product_Line__c='Desktop',
                                    IsActive=true);
        insert prod1;
        Product2 prod2 = new Product2(ProductCode='UTProd003',
                                    Name='UTProd003',
                                    Family='Oncology',
                                    SVMXC__Product_Line__c='Desktop',
                                    IsActive=true);
        insert prod2;
        Product2 prod3 = new Product2(ProductCode='UTProd004',
                                    Name='UTProd004',
                                    Family='Oncology',
                                    SVMXC__Product_Line__c='Desktop',
                                    IsActive=true);
        insert prod3;
        
         SVMXC__Installed_Product__c ip = new SVMXC__Installed_Product__c(
         										Revision__c = 0,
                                                SVMXC__Product__c = prod.id,
                                                Name='101',
                                                SVMXC__Serial_Lot_Number__c = '101',
                                                SVMXC__Status__c = 'Installed',
                                                SVMXC__Company__c = Acc.id,
                                                SVMXC__Parent__c=null,
                                                Major__c=0,
                                                Minor__c =0,                                                
                                                SVMXC__Top_Level__c=null);
        insert ip;  
         SVMXC__Installed_Product__c ip1 = new SVMXC__Installed_Product__c(
                                                SVMXC__Product__c = prod1.id,
                                                Name='102',
                                                SVMXC__Serial_Lot_Number__c = '102',
                                                SVMXC__Status__c = 'Installed',
                                                SVMXC__Company__c = Acc.id,
                                                SVMXC__Parent__c=ip.id,
                                                Major__c=0,
                                                Minor__c =2,
                                                SVMXC__Top_Level__c=ip.id);
        insert ip1; 
        
        SVMXC__Installed_Product__c ip2 = new SVMXC__Installed_Product__c(
                                                SVMXC__Product__c = prod.id,
                                                Name='103',
                                                SVMXC__Serial_Lot_Number__c = '103',
                                                SVMXC__Status__c = 'Installed',
                                                SVMXC__Company__c = Acc.id,
                                                SVMXC__Parent__c=ip1.id,
                                                Major__c=3,
                                                Minor__c =0,
                                                SVMXC__Top_Level__c=ip.id);
        insert ip2;
        SVMXC__Installed_Product__c ip3 = new SVMXC__Installed_Product__c(
                                                SVMXC__Product__c = prod3.id,
                                                Name='104',
                                                SVMXC__Serial_Lot_Number__c = '104',
                                                SVMXC__Status__c = 'Installed',
                                                SVMXC__Company__c = Acc.id,
                                                SVMXC__Parent__c=ip.id,
                                                Major__c=4,
                                                Minor__c =4,
                                                SVMXC__Top_Level__c=ip2.id);
        insert ip3;
        
      
        FCO__c  fco = new FCO__c(Name='FCO UT',
                                FCO_Type__c='Important Field Safety Notice',
                                PSC_Status__c='New',
                                PSC__c='CMS',
                                Description__c='Description');
        
        insert fco;
        
        FCO_Lines__c  fcoln = new FCO_Lines__c(FCO__c=fco.id,
                                Installed_Product_1__c=ip.id,
                                Status__c='Active',
                                Account__c=Acc.id);        
        insert fcoln;
        FCO_Lines__c  fcoln2 = new FCO_Lines__c(FCO__c=fco.id,
                                Installed_Product_2__c=ip2.id,
                                Status__c='Active',
                                Account__c=Acc.id);        
        insert fcoln2;
        FCO_Lines__c  fcoln3 = new FCO_Lines__c(FCO__c=fco.id,
                                Installed_Product_3__c=ip3.id,
                                Status__c='Active',
                                Account__c=Acc.id);        
        insert fcoln3;
        
        FCO_Search__c  fcosrch = new FCO_Search__c(FCO__c=fco.id,
            Target_Product__c=prod.id,
            Target_Serial_Start__c='0',
            Target_Serial_End__c='105',
            Product_1__c=prod3.id,
            Restricted_to_Same_Product__c='Yes',
            Target_Product_SW_Minor_Start__c='0',
            Target_Product_SW_Minor_End__c='0',
            Target_Product_SW_Major_Start__c='0',
            Target_Product_SW_Major_End__c='0',
            Target_Product_SW_Build_Start__c ='0',
            Target_Product_SW_Build_End__c ='0',
            Target_Product_SW_Revision_Start__c='0',
            Target_Product_SW_Revision_End__c='0',
            Serial_1_Start__c='101',
            Serial_1_End__c='105',
            Select__c =true,
            Schedule_Time__c = '12:00 PM'                                
            );        
        insert fcosrch;        
        fcosrch.Schedule_Time__c = '1:00 PM';
        update fcosrch;
        
        FCO_Search__c  fcosrch2 = new FCO_Search__c(FCO__c=fco.id,
            Target_Product__c=prod.id,
            Target_Serial_Start__c='101',
            Target_Serial_End__c='105',
            Product_1__c=prod1.id,
            Restricted_to_Same_Product__c='Yes',
            Target_Product_SW_Minor_Start__c='0',
            Target_Product_SW_Minor_End__c='0',
            Target_Product_SW_Major_Start__c='0',
            Target_Product_SW_Major_End__c='0',
            Target_Product_SW_Build_Start__c ='0',
            Target_Product_SW_Build_End__c ='0',
            Target_Product_SW_Revision_Start__c='0',
            Target_Product_SW_Revision_End__c='200',
            Serial_1_Start__c='101',
            Serial_1_End__c='0',
            Select__c =true,
            Schedule_Time__c = '12:00 PM'                                
            );        
        insert fcosrch2;
        
        FCO_Search__c  fcosrch3 = new FCO_Search__c(FCO__c=fco.id,
            Target_Product__c=prod.id,
            Target_Serial_Start__c='101',
            Target_Serial_End__c='0',
            Product_3__c=prod3.id,
            Serial_3_Start__c='0',
            Serial_3_End__c='105',
            Product_3_SW_Minor_Start__c='0',
            Product_3_SW_Minor_End__c='105',
            Product_3_SW_Major_Start__c='0',
            Product_3_SW_Major_End__c='105',
            Product_3_SW_Build_Start__c ='0',
            Product_3_SW_Build_End__c ='105',
            Product_3_SW_Revision_Start__c ='0',
            Product_3_SW_Revision_End__c ='105',
            Restricted_to_Same_Product__c='No',
            Target_Product_SW_Minor_Start__c='0',
            Target_Product_SW_Minor_End__c='0',
            Target_Product_SW_Major_Start__c='0',
            Target_Product_SW_Major_End__c='0',
            Target_Product_SW_Build_Start__c ='0',
            Target_Product_SW_Build_End__c ='0',
            Target_Product_SW_Revision_Start__c='10',
            Target_Product_SW_Revision_End__c='0',            
            Select__c =true,
            Schedule_Time__c = '12:00 PM'                               
            );        
        insert fcosrch3;
        
        FCO__c  fco2 = new FCO__c(Name='FCO UT 2',
            FCO_Type__c='test',
            PSC_Status__c='New',
            PSC__c='CMS',
            Description__c='Description');        
        insert fco2;
        FCO_Search__c  fcosrch4 = new FCO_Search__c(FCO__c=fco2.id,            
            Select__c =true,
            Schedule_Time__c = '12:00 PM'
            );        
        insert fcosrch4;
        
        fcosrch2.Schedule_Time__c = '2:00 PM';
        update fcosrch2;
         	//Test coverage for the visualforce page
            PageReference pageRef = Page.SVMX_FCOSearch;
            pageRef.getParameters().put('uid',fco.Id);        
            Test.setCurrentPageReference(pageRef);
        
            
            // create an instance of the controller
            SVMX_FCOSearch thisPageCon = new SVMX_FCOSearch();
            
            FCO__c f1=thisPageCon.getFCO();
            thisPageCon.setFCO(f1);
            thisPageCon.uid = fco.Id;
            List<FCO_Search__c> fcoSrcl=thisPageCon.getFCOSearchlist(); System.debug('test: fcoSrcl size: '+fcoSrcl.size());
            thisPageCon.setFCOSearchlist(fcoSrcl);
            
            for(FCO_Search__c f: fcoSrcl){
	            //thisPageCon.setFCOSearch(fcoSrc);
            	thisPageCon.setFCOSearch(f);
	            List<SVMXC__Installed_Product__c> IBlist=thisPageCon.getIBlist();
	            Boolean t;
	            t=thisPageCon.getSrchlistFlg();
	            t=thisPageCon.getShowSaveflg();
	            t=thisPageCon.getSrchFlg();
	            t=thisPageCon.getCreateFlg();
	            String s=thisPageCon.getSid();	            
	            PageReference pRef1 =thisPageCon.fnXSTSearch();       
	            //PageReference pRef2 =thisPageCon.fnNewSearch();
	            PageReference pRef3 =thisPageCon.fnSearch();
	            PageReference pRef4 =thisPageCon.fnCreateFCOL();            
	            PageReference pRef5 =thisPageCon.fnReset();
	            PageReference pRef6 =thisPageCon.fnSaveSearch();  	     
            }    
            
            FCO_Search__c fcoSrc=thisPageCon.getFCOSearch();     
            /*
            thisPageCon.setFCOSearch(fcosrch);
            
            List<SVMXC__Installed_Product__c> IBlist1=thisPageCon.getIBlist();           
            
            PageReference pRef8 =thisPageCon.fnXSTSearch();       
            PageReference pRef9 =thisPageCon.fnSearch();
           // PageReference pRef10 =thisPageCon.fnCreateFCOL();
            PageReference pRef11 =thisPageCon.fnUpdSearch();
        	*/
        	f1.PSC_Status__c ='Closed';
        	update f1;
    
    }
}