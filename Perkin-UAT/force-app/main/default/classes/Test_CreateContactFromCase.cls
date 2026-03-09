/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Title           : Test_CreateContactFromCase 
Description     : Test Class
Controller      : cls_createContactFromCase
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
@isTest
public class Test_CreateContactFromCase {
    static testMethod void testCreateContact(){
        Case casetoupdate = new Case(Status='New');
        try{
            insert casetoupdate; 
        }catch(Exception e){
            system.debug(e);
        }
       EmailMessage emmess= new EmailMessage(FromAddress='test@ex.com',parentid=casetoupdate.id);
        insert emmess;
        
        Contact newcontact = new Contact(email='test@example.com',lastname='test');
        insert newcontact;
        PageReference pageRefr = Page.SearchCaseContactPage;
		Test.setCurrentPage(pageRefr);
        ApexPages.StandardController controller = new ApexPages.StandardController(casetoupdate);
        cls_createContactFromCase createcont = new cls_createContactFromCase(controller);
        createcont.pageName='SearchCaseContactPage';
        cls_createContactFromCase.WrapperClass wrpa= new cls_createContactFromCase.WrapperClass(newcontact,true) ;
        //createcont.newContact = newContact;
        createcont.newContact = new Contact(email='test1@example.com',lastname='test');
        //insert newcontact1;
        pageReference pageref = createcont.createContact();
        if(pageref!=null){
            Test.setCurrentPage(pageref);
            pageref.getParameters().put('Id',casetoupdate.Id);
        }
               
        createcont.selectedCon.add(newcontact);
        createcont.searchcontact();
        createcont.Conname='' ;
        createcont.searchcontact();
         createcont.Conname='test' ;
        createcont.ConEmail='' ;
        createcont.searchcontact();
        createcont.selectedRecords();
        system.debug('***'+createcont.selectedCon+'!!'+createcont.pageName);
        
        
        //action for cancel 
        pageReference cancelref = createcont.actionforcancel();
        if(cancelref!=null){
            Test.setCurrentPage(cancelref);
            cancelref.getParameters().put('Id',casetoupdate.Id);
        }
    }
}