@IsTest(SeeAllData=true)
public class ForgotPasswordControllerTest {
 static testMethod void ForgotPasswordControllerTestr () { 
        // Instantiate a new controller with all parameters in the page
ForgotPasswordController controller = new ForgotPasswordController();
controller.username = 'test@salesforce.com';        
    
System.assertEquals(controller.forgotPassword(),null); 
  }
}