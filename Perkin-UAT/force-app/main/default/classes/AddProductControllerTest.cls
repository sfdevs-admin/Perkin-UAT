@isTest
public class AddProductControllerTest{
    static testMethod void searchTaskTestMethod(){
       
    AddProductController jpc = new AddProductController();
    jpc.Name = 'test';
    INF_Application__c prod = new INF_Application__c(Name= 'test',INF_KW__c='DJ2',INF_Product_Group__c ='CBOE');
    INF_Application__c prod1 = new INF_Application__c(Name= 'test2',INF_KW__c='MK2',INF_Product_Group__c ='CBOE');
    List<INF_Application__c> lc=new List<INF_Application__c>();
    lc.add(prod);
    lc.add(prod1);
    Case c = new Case (Subject = 'InkjetxxxDJ2xxxx',Reason = 'Campaign Creation',Ownerid = Userinfo.getUserid());
    insert c ;
        
     Test.startTest();   
     Test.setCurrentPage(new PageReference('/apex/AddProduct?id='+c.Id));
     jpc.caseid = c.id;
     jpc.saveSelectedNames = 'test,test2';
     jpc.saveSelectedIds = prod.id + ',' + prod1.id;
     jpc.allprodlist();
     jpc.getProducts();
     jpc.initialize();
     jpc.nullAction();
     jpc.searchprods();
     jpc.addToList();
     jpc.SubmitQueue();
     jpc.saveSelectedIds = prod.id;
     jpc.SubmitQueue();
     jpc.listJPCCProducts = new List<AddProductController.JPCCProductWrapper>();
     jpc.listJPCCProducts.add(new AddProductController.JPCCProductWrapper(prod,true));
     jpc.listJPCCProducts.add(new AddProductController.JPCCProductWrapper(prod1,true));
     jpc.allprodlist();
     jpc.getProducts();
     jpc.initialize();
     jpc.nullAction();
     jpc.searchprods();
     jpc.addToList();
     jpc.SubmitQueue();
     Test.stopTest();
    }
}