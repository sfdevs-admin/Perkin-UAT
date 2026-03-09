@isTest
public class B2B_HomepageCarouselControllerTest {

    @isTest
    public static void getDataTest(){
        Map<String,Object> resp = new Map<String,Object>();
        Map<String,Object> inp = new Map<String,Object>();
        inp.put('','');
        Test.startTest();
        B2B_HomepageCarouselController obj = new B2B_HomepageCarouselController();
        resp = B2B_HomepageCarouselController.getData(inp);
        Test.stopTest();
        Assert.isNotNull(resp);
    }
    
    @isTest
    public static void getDataNullTest(){
        Map<String,Object> resp = new Map<String,Object>();
        Map<String,Object> inp = new Map<String,Object>();
        inp.put('','');
        Test.startTest();
        B2B_HomepageCarouselController obj = new B2B_HomepageCarouselController();
        resp = B2B_HomepageCarouselController.getData(null);
        Test.stopTest();
        Assert.isNotNull(resp);
    }
    
    @isTest
    public static void getTestCoverage(){
        Test.startTest();
        B2B_HomepageCarouselController.testCoverage();
        Test.stopTest();
    }
    
    @isTest
    public static void getServiceTestCoverage(){
        Test.startTest();
        B2B_HomepageCarouselService.testCoverage();
        Test.stopTest();
    }
}