/**
 * An apex page controller that takes the user to the right start page based on credentials or lack thereof
 */
@isTest
private class CommunitiesLandingControllerTest {

    @isTest
    static void testForwardToStartPage() {
        // Start the test
        Test.startTest();
        
        // Instantiate the CommunitiesLandingController class
        CommunitiesLandingController controller = new CommunitiesLandingController();
        
        // Call the forwardToStartPage method
        PageReference pageRef = controller.forwardToStartPage();
        
        // Stop the test
        Test.stopTest();
        
        // Assert that the PageReference is not null
        System.assertNotEquals(null, pageRef, 'The forwardToStartPage method should return a PageReference.');

        // Assert that the URL returned by Network.communitiesLanding() is correct
        // Note: Network.communitiesLanding() dynamically returns a URL based on the community setup.
        // You can assert specific properties of the PageReference if needed.
    }
}
/*
@IsTest public with sharing class CommunitiesLandingControllerTest {
    @IsTest(SeeAllData=true) public static void testCommunitiesLandingController() {
        // Instantiate a new controller with all parameters in the page
        CommunitiesLandingController controller = new CommunitiesLandingController();
      }
}*/