@isTest
private class RedirectControllerTest {

    @isTest
    static void testRedirectControllerInit() {
        // Instantiate the RedirectController class
        RedirectController controller = new RedirectController();

        // Call the RedirectControllerInit method
        Test.startTest();
        PageReference result = controller.RedirectControllerInit();
        Test.stopTest();

        // Verify that the PageReference is not null
        System.assertNotEquals(null, result, 'Expected a valid PageReference to be returned.');

        // Verify that the URL is correct
        System.assertEquals('http://go.perkinelmer.com/l/32222/2014-04-17/gcd7', result.getUrl(), 
            'Expected URL to match the one defined in RedirectControllerInit.');

        // Verify that the redirect flag is set to true
        System.assert(result.getRedirect(), 'Expected redirect flag to be true.');
    }
}