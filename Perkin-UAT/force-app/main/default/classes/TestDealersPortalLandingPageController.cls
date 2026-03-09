@isTest
public class TestDealersPortalLandingPageController {
    
    @isTest
    public static void unitTest(){
      
      DealersPortalLandingPageController ctrl = new DealersPortalLandingPageController();
      ctrl.selectedValue = 'Open Opportunities';
      ctrl.setOppTable();
      ctrl.selectedValue = 'Overdue Opportunities';
      ctrl.setOppTable();
    }
}