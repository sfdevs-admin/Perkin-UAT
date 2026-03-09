@isTest
global class Test_SalesRepLookUp {
    global static testmethod void testSaesRepLookUp(){
        
        User newTestUser = new User();
        newTestUser.FirstName = 'test';
        newTestUser.LastName = 'test';
        newTestUser.Email = 'test1@test.com';
        newTestUser.Alias = 'te';
        newTestUser.Username = 'test1@PKITEST.com';
        newTestUser.Phone = '+(1)22121';
        newTestUser.MobilePhone = '1212121';
        newTestUser.TimeZoneSidKey = 'Africa/Cairo';
        newTestUser.LocaleSidKey = 'ar';    
        newTestUser.EmailEncodingKey = 'UTf-8';
        newTestUser.ProfileId = Userinfo.getProfileId();
        newTestUser.LanguageLocaleKey = 'en_US';
        insert newTestUser;
        //SalesRepLookupController salesrep = new SalesRepLookupController();
       
        PageReference pageRef = Page.SalesRepLookupSinglePage;
        
        Test.setCurrentPage(pageRef);
         ApexPages.currentPage().getParameters().put('CN','US');
        ApexPages.currentPage().getParameters().put('ZC','12321');
        ApexPages.currentPage().getParameters().put('PL','AA');
        ApexPages.currentPage().getParameters().put('sr','true');
       
        
        Sales_Rep_Country_List__c s = new Sales_Rep_Country_List__c();
        s.Name = 'US';
        s.Country__c = 'US';
        insert s;
        
        Sales_Rep_Country_List__c s1 = new Sales_Rep_Country_List__c();
        s1.Name = 'EMEA';
        s1.Country__c = 'EMEA';
        insert s1;
        
      
        
        Test.setMock(WebserviceMock.class, new SalesRepLookupServiceMockup());
        //Set the testing context
        Test.startTest();
        SalesRepLookupController salesrep = new SalesRepLookupController();
        salesrep.submit();
        salesrep.getSalesReps();
        salesrep.CloseResultsPage();
        Test.stopTest();
    }
    global static testmethod void testSaesRepLookUp1(){
        
        User newTestUser = new User();
        newTestUser.FirstName = 'test';
        newTestUser.LastName = 'test';
        newTestUser.Email = 'test1@test.com';
        newTestUser.Alias = 'te';
        newTestUser.Username = 'test1@PKITEST.com';
        newTestUser.Phone = '+(1)22121';
        newTestUser.MobilePhone = '1212121';
        newTestUser.TimeZoneSidKey = 'Africa/Cairo';
        newTestUser.LocaleSidKey = 'ar';    
        newTestUser.EmailEncodingKey = 'UTf-8';
        newTestUser.ProfileId = Userinfo.getProfileId();
        newTestUser.LanguageLocaleKey = 'en_US';
        insert newTestUser;
        //SalesRepLookupController salesrep = new SalesRepLookupController();
       
        PageReference pageRef = Page.SalesRepLookupSinglePage;
        Test.setCurrentPage(pageRef);
         ApexPages.currentPage().getParameters().put('CN','US');
        ApexPages.currentPage().getParameters().put('ZC','12321');
        ApexPages.currentPage().getParameters().put('PL','AA');
        ApexPages.currentPage().getParameters().put('sr','true');

        
        Sales_Rep_Country_List__c s = new Sales_Rep_Country_List__c();
        s.Name = 'US';
        s.Country__c = 'US';
        insert s;
        
        Sales_Rep_Country_List__c s1 = new Sales_Rep_Country_List__c();
        s1.Name = 'EMEA';
        s1.Country__c = 'EMEA';
        insert s1;
        
             
        Test.setMock(WebserviceMock.class, new SalesRepLookupServiceMockup());
        //Set the testing context
        Test.startTest();
        SalesRepLookupController salesrep = new SalesRepLookupController();
        salesrep.submit();
        salesrep.getSalesReps();
        salesrep.CloseResultsPage();
        Test.stopTest();
    }
    global static testmethod void testleadInternalRoutingIndia(){
        
        User newTestUser = new User();
        newTestUser.FirstName = 'test';
        newTestUser.LastName = 'test';
        newTestUser.Email = 'test1@test.com';
        newTestUser.Alias = 'te';
        newTestUser.Username = 'test1@PKITEST.com';
        newTestUser.Phone = '+(1)22121';
        newTestUser.MobilePhone = '1212121';
        newTestUser.TimeZoneSidKey = 'Africa/Cairo';
        newTestUser.LocaleSidKey = 'ar';    
        newTestUser.EmailEncodingKey = 'UTf-8';
        newTestUser.ProfileId = Userinfo.getProfileId();
        newTestUser.LanguageLocaleKey = 'en_US';
        insert newTestUser;
        //SalesRepLookupController salesrep = new SalesRepLookupController();
       
        PageReference pageRef = Page.LeadInternalRoutingPage;
        Test.setCurrentPage(pageRef);
         ApexPages.currentPage().getParameters().put('CN','IN');
         ApexPages.currentPage().getParameters().put('ZC','12321');
         ApexPages.currentPage().getParameters().put('PL','AA');
         ApexPages.currentPage().getParameters().put('sr','true');
         ApexPages.currentPage().getParameters().put('BU','INF');
         ApexPages.currentPage().getParameters().put('ST','KY');
        
        Sales_Rep_Country_List__c s = new Sales_Rep_Country_List__c();
        s.Name = 'IN';
        s.Country__c = 'IN';
        insert s;
        
        Sales_Rep_Country_List__c s1 = new Sales_Rep_Country_List__c();
        s1.Name = 'EMEA';
        s1.Country__c = 'EMEA';
        insert s1;
        
        Rep_Assignment_Table__c t = new Rep_Assignment_Table__c();
        t.BU__c = 'INF';
        t.Assigned_To__c = newTestUser.id;
        t.Country__c = 'IN';
        t.Product_Line__c = 'AA';
        t.State_Province__c = 'KY';
        t.Postal_Code__c = 12321;
        insert t;
        
        Rep_Assignment_Table__c t1 = new Rep_Assignment_Table__c();
        t1.BU__c = 'INF';
        t1.Queue__c = 'INF Marketing Queue';
        t1.Country__c = 'IN';
        t1.Product_Line__c = 'AA';
        t1.State_Province__c = 'KY';
        t1.Postal_Code__c = 12321;
        insert t1;
        
        ProductList__c p = new ProductList__c();
        p.Name = 'OSAI';
        p.Product_Name__c ='OSAI';
        insert p;
        
        ProductList__c p1 = new ProductList__c();
        p1.Name = 'AA';
        p1.Product_Name__c ='AA';
        insert p1;
        
        
        
       //Set the testing context
        Test.startTest();
        LeadInternalRoutingController salesrep = new LeadInternalRoutingController();
        salesrep.submit();
        salesrep.getSalesReps();
        salesrep.CloseResultsPage();
        Test.stopTest();
    }
     global static testmethod void testleadInternalRouting(){
        
        User newTestUser = new User();
        newTestUser.FirstName = 'test';
        newTestUser.LastName = 'test';
        newTestUser.Email = 'test1@test.com';
        newTestUser.Alias = 'te';
        newTestUser.Username = 'test1@PKITEST.com';
        newTestUser.Phone = '+(1)22121';
        newTestUser.MobilePhone = '1212121';
        newTestUser.TimeZoneSidKey = 'Africa/Cairo';
        newTestUser.LocaleSidKey = 'ar';    
        newTestUser.EmailEncodingKey = 'UTf-8';
        newTestUser.ProfileId = Userinfo.getProfileId();
        newTestUser.LanguageLocaleKey = 'en_US';
        insert newTestUser;
        //SalesRepLookupController salesrep = new SalesRepLookupController();
       
        PageReference pageRef = Page.LeadInternalRoutingPage;
        Test.setCurrentPage(pageRef);
         ApexPages.currentPage().getParameters().put('CN','US');
         ApexPages.currentPage().getParameters().put('ZC','12321');
         ApexPages.currentPage().getParameters().put('PL','AA');
         ApexPages.currentPage().getParameters().put('sr','true');
         ApexPages.currentPage().getParameters().put('BU','INF');
         ApexPages.currentPage().getParameters().put('ST','KY');
        
        Sales_Rep_Country_List__c s = new Sales_Rep_Country_List__c();
        s.Name = 'US';
        s.Country__c = 'US';
        insert s;
        
        Sales_Rep_Country_List__c s1 = new Sales_Rep_Country_List__c();
        s1.Name = 'EMEA';
        s1.Country__c = 'EMEA';
        insert s1;
        
        Rep_Assignment_Table__c t = new Rep_Assignment_Table__c();
        t.BU__c = 'INF';
        t.Assigned_To__c = newTestUser.id;
        t.Country__c = 'US';
        t.Product_Line__c = 'AA';
        t.State_Province__c = 'KY';
        insert t;
        
        Rep_Assignment_Table__c t1 = new Rep_Assignment_Table__c();
        t1.BU__c = 'INF';
        t1.Queue__c = 'INF Marketing Queue';
        t1.Country__c = 'US';
        t1.Product_Line__c = 'AA';
        t1.State_Province__c = 'KY';
        insert t1;
        
        ProductList__c p = new ProductList__c();
        p.Name = 'OSAI';
        p.Product_Name__c ='OSAI';
        insert p;
        
        ProductList__c p1 = new ProductList__c();
        p1.Name = 'AA';
        p1.Product_Name__c ='AA';
        insert p1;
        
        
        
       //Set the testing context
        Test.startTest();
        LeadInternalRoutingController salesrep = new LeadInternalRoutingController();
        salesrep.submit();
        salesrep.getSalesReps();
        salesrep.CloseResultsPage();
        Test.stopTest();
    }
}