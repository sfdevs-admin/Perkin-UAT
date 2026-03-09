/*********************************************************************************************************************
 * TEST CLASS: BD_Invocable_SendEmail_Test
 * @author Bolt Data Consulting Group
 * @description Test class for BD_Invocable_SendEmail
 *
 * -----CHANGE LOG-----
 * 2025.09.08 - ives - Created class. 
 *********************************************************************************************************************/
@IsTest private class BD_Invocable_SendEmail_Test
{
    @IsTest static void test_sendEmail()
    {
        /*
         * PREPARE TEST OBJECTS
         */

        BD_Invocable_SendEmail.SendEmailRequest req1 = new BD_Invocable_SendEmail.SendEmailRequest();
        req1.toAddresses = 'john.ives@bolt-data.com';
        req1.ccAddresses = 'ccTest@test.email.com, ccTest2@test.email.com';
        req1.bccAddresses = 'bccTest@test.email.com';
        req1.subject = 'Unit Test Email';
        req1.senderDisplayName = 'Unit Tester';
        req1.replyToEmail = 'replyto@test.email.com';
        req1.plainTextBody = 'This is a Unit Test.';
        req1.htmlBody = 'This is a Unit Test.';

        BD_Invocable_SendEmail.SendEmailRequest req2 = new BD_Invocable_SendEmail.SendEmailRequest();
        req2.subject = 'Unit Test Email';
        req2.senderDisplayName = 'Unit Tester';
        req2.replyToEmail = 'replyto@test.email.com';
        req2.plainTextBody = 'This is a Unit Test.';
        req2.htmlBody = 'This is a Unit Test.';

        BD_Invocable_SendEmail.SendEmailRequest req3 = new BD_Invocable_SendEmail.SendEmailRequest();
        req3.toAddresses = 'john.ives@bolt-data.com';
        req3.ccAddresses = 'ccTest@test.email.com, ccTest2@test.email.com';
        req3.bccAddresses = 'bccTest@test.email.com';
        req3.subject = 'Unit Test Email';
        req3.senderDisplayName = 'Unit Tester';
        req3.replyToEmail = 'replyto@test.email.com';

        BD_Invocable_SendEmail.SendEmailRequest[] reqs = new BD_Invocable_SendEmail.SendEmailRequest[]{ req1, req2, req3 };

        BD_Invocable_SendEmail.SendEmailResponse[] rsps = null;

        /*
         * RUN TEST
         */

        try
        {
            Test.startTest();

            rsps = BD_Invocable_SendEmail.sendEmail( reqs );

            Test.stopTest();
        } catch( Exception e )
        {
            System.debug('\n\n Error Line=' + e.getLineNumber() + ' Error Stack=' + e.getStackTraceString() + '\n\n');
            System.assert( false, 'Exception caught - ' + e );
        }


        /*
         * VALIDATE TEST RESULTS
         */

        System.assertEquals( 3, rsps.size(), 'Response message count not correct' );
        Integer failCount = 0;
        for( BD_Invocable_SendEmail.SendEmailResponse rsp : rsps ) if( !rsp.success ) failCount++;
        System.assertEquals( 2, failCount, 'Expected 2 error responses' );
    }


}