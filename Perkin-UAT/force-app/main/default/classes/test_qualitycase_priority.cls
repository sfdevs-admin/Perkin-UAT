@isTest
private class test_qualitycase_priority{  
static testMethod void testinsert() 
{    //create opportunity    
     case test_o = new case();    
     case test_1 = new case();    
     case test_2 = new case();    
     case test_3 = new case();       
     
   // doesn't qualify for priority assignment
   
     test_o.type = 'Out of Box Failure';
     test_o.status = 'New';
     test_o.Functional__c = 'Test';
     test_o.Completeness__c = 'Test';
     test_o.Packaging__c = 'Test';
     test_o.sub_type__c = 'Part';
     test_o.origin = 'LST';
     test_o.subject = 'Test coverage case';
     //test_o.product_score__c = 'a1YV0000000DKgAMAW';
     test_o.q_safety_concern__c = 'Minimal';
     test_o.q_revenue_impact__c = 'High';
     test_o.q_severity__c = 'Serious';
     test_o.q_occurrences__c = '5 or more';
     test_o.q_exposure__c = 'Single';
     test_o.Q_Complaint__c = 'Yes';
     test_o.exclude_in_reports__c = true;
     test_o.Q_Priority_Override__c = 'Yes';
     insert test_o;  
  
  // Priority sum over 30
  
     test_1.type = 'Out of Box Failure';
     test_1.status = 'New';
     test_1.Functional__c = 'Test';
     test_1.Completeness__c = 'Test';
     test_1.Packaging__c = 'Test';
     test_1.sub_type__c = 'Part';
     test_1.origin = 'LST';
     test_1.subject = 'Test coverage case';
     //test_1.product_score__c = 'a1YV0000000DKgAMAW';
     test_1.q_safety_concern__c = 'Minimal';
     test_1.q_revenue_impact__c = 'High';
     test_1.q_severity__c = 'Serious';
     test_1.q_occurrences__c = '5 or more';
     test_1.q_exposure__c = 'Single';
     test_1.Q_Complaint__c = 'Yes';
     test_1.exclude_in_reports__c = true;
     test_1.Q_Priority_Override__c = 'No';
     insert test_1;  
     
    // Priority sum less than 30 and greater than 15
         
     test_2.type = 'Quality Failure';
     test_2.status = 'Open';
     test_2.sub_type__c = 'Part';
     test_2.origin = 'Phone';
     test_2.subject = 'Test coverage case';
//     test_o.product_score__c = 'a1YV0000000DKgAMAW';
     test_2.q_safety_concern__c = 'Minimal';
     test_2.q_revenue_impact__c = 'Medium';
     test_2.q_severity__c = 'Minimal';
     test_2.q_occurrences__c = '5 or more';
     test_2.q_exposure__c = 'All Customers';
     test_2.Q_Complaint__c = 'No';
     test_2.exclude_in_reports__c = true;
     test_2.Q_Priority_Override__c = 'No';
     insert test_2;

    // Priority sum less than 15

     test_3.type = 'Quality Failure';
     test_3.status = 'Open';
     test_3.sub_type__c = 'Part';
     test_3.origin = 'Phone';
     test_3.subject = 'Test coverage case';
//     test_o.product_score__c = 'a1YV0000000DKgAMAW';
     test_3.q_safety_concern__c = 'Minimal';
     test_3.q_revenue_impact__c = 'Low';
     test_3.q_exposure__c = 'Single';
     test_3.Q_Complaint__c = 'No';
     test_3.exclude_in_reports__c = true;
     test_3.Q_Priority_Override__c = 'No';
     insert test_3;

     
 } 
 }