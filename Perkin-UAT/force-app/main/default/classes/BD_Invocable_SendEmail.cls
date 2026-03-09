/*********************************************************************************************************************
 * INVOCABLE CLASS: BD_Invocable_SendEmail
 * @author Bolt Data Consulting Group
 * @description Invocable method to send single emails.
 *
 * -----CHANGE LOG-----
 * 2025.09.08 - ives - Created class.
 *********************************************************************************************************************/
public without sharing class BD_Invocable_SendEmail
{
    /**----------------------------------------------------------------------------------------------------------------
     * INVOCABLE METHOD: sendEmail
     * @author Bolt Data Consulting Group
     * @param requests A List of emails to send.
     * @return A list of status results.
     * @description Send an email for each request.
     *
     * -----CHANGE LOG-----
     * 2025.09.08 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    @InvocableMethod( Category='BD Utilities' Label='Send Email with Attachments' )
    public static List<SendEmailResponse> sendEmail( List<SendEmailRequest> requests )
    {
        System.debug( LoggingLevel.INFO, 'ENTERED sendEmail() with reqs=' + requests );

        List<Messaging.SingleEmailMessage> msgs = new List<Messaging.SingleEmailMessage>();
        List<SendEmailResponse> responses = new List<SendEmailResponse>();
        for( SendEmailRequest req : requests )
        {
            SendEmailResponse rsp = new SendEmailResponse();
            responses.add( rsp );

            if( String.isBlank( req.toAddresses ) && String.isBlank( req.ccAddresses ) && String.isBlank( req.bccAddresses ) )
            {
                rsp.success = false;
                rsp.message = 'A recipient address is required (to, cc, or bcc)';
                continue;
            }

            if( String.isBlank( req.plainTextBody ) && String.isBlank( req.htmlBody ) )
            {
                rsp.success = false;
                rsp.message = 'An email body is required';
                continue;
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses( tokenizeString( req.toAddresses ) );
            email.setCcAddresses( tokenizeString( req.ccAddresses ) );
            email.setBccAddresses( tokenizeString( req.bccAddresses ) );
            email.setReplyTo( req.replyToEmail );
            email.setSubject( req.subject );
            email.setPlainTextBody( req.plainTextBody );
            email.setHtmlBody( req.htmlBody );
            email.setSaveAsActivity( req.saveAsActivity != null ? req.saveAsActivity : false );
            email.setWhatId( req.recordId );
            if( String.isNotBlank( req.orgWideEmailId ) ) email.setOrgWideEmailAddressId( req.orgWideEmailId );
            else email.setSenderDisplayName( req.senderDisplayName );
            if( req.attachmentIds != null && !req.attachmentIds.isEmpty() ) email.setEntityAttachments( req.attachmentIds );
            msgs.add( email );

            rsp.success = true;
            rsp.message = 'Email submitted.';
        }

        if( !msgs.isEmpty() )
        {
            if( !Test.isRunningTest() )
            {
                List<Messaging.SendEmailResult> results = Messaging.sendEmail( msgs );
                System.debug( 'Sent ' + msgs.size() + ' emails, results = ' + results );
            } else System.debug( '>>>>> Skipping actual sendEmail call since running in a unit test...' );

        }

        System.debug( LoggingLevel.INFO, 'EXITING sendEmail() with rsps=' + responses );
        return responses;
    }


    /**----------------------------------------------------------------------------------------------------------------
     * METHOD: tokenizeString
     * @author Bolt Data Consulting Group
     * @param str The String to tokenize
     * @return A list of tokens.
     * @description Tokenize the given string by comma and semi-colon.
     *
     * -----CHANGE LOG-----
     * 2025.09.08 - ives - Created method.
     *----------------------------------------------------------------------------------------------------------------*/
    private static List<String> tokenizeString( String str )
    {
        System.debug( 'ENTERED tokenizeString with str=' + str );
        List<String> cleanTkns = null;

        if( String.isNotBlank( str ) )
        {
            if( cleanTkns == null ) cleanTkns = new List<String>();
            String[] tkns = str.split( '[,;]' );
            for( String t : tkns ) cleanTkns.add( t.trim() );
        }

        System.debug( 'EXITING tokenizeString with cleanTkns=' + cleanTkns );
        return cleanTkns;
    }


    /*********************************************************************************************************************
     * CLASS: SendEmailRequest
     * @author Bolt Data Consulting Group
     * @description Value object for send email request.
     *
     * -----CHANGE LOG-----
     * 2025.09.08 - ives - Created class.
     *********************************************************************************************************************/
    public class SendEmailRequest
    {
        @InvocableVariable( Label = 'To Address(es)' Required = false Description = 'The To Addresses for the email. Can be a single address or a list of addresses separated by comma or semi-colon.' )
        public String toAddresses;

        @InvocableVariable( Label = 'CC Address(es)' Required = false Description = 'The CC Addresses for the email. Can be a single address or a list of addresses separated by comma or semi-colon.' )
        public String ccAddresses;

        @InvocableVariable( Label = 'BCC Address(es)' Required = false Description = 'The BCC Addresses for the email. Can be a single address or a list of addresses separated by comma or semi-colon.' )
        public String bccAddresses;

        @InvocableVariable( Label = 'Reply To' Required = true Description = 'The email Reply To address' )
        public String replyToEmail;

        @InvocableVariable( Label = 'Sender Display Name' Required = true Description = 'The Sender Display Name. Only used when Sender Org Wide Email Id is not mapped.' )
        public String senderDisplayName;

        @InvocableVariable( Label = 'Sender Org Wide Email Id' Required = false Description = 'The Org Wide Email record Id to send emails as, otherwise emails are sent as the current user.' )
        public Id orgWideEmailId;

        @InvocableVariable( Label = 'Email Subject' Required = true Description = 'The email Subject' )
        public String subject;

        @InvocableVariable( Label = 'Plain Text Body' Required = false Description = 'The email Plain Text body. Can send email as plain text or HTML.' )
        public String plainTextBody;

        @InvocableVariable( Label = 'HTML Body' Required = false Description = 'The email HTML body. Can send email as plain text or HTML.' )
        public String htmlBody;

        @InvocableVariable( Label = 'Attachments' Required = false Description = 'A List of Content Version Ids, Document Ids, or Attachment Ids to add as attachments to the email.' )
        public List<Id> attachmentIds;

        @InvocableVariable( Label = 'Save As Activity' Required = false Description = 'Set to true to save the email as an Activity (Task) on the record (requires Record Id to be mapped).' )
        public Boolean saveAsActivity;

        @InvocableVariable( Label = 'Record Id' Required = false Description = 'The record id (WhatId) to associate this email to. Required if using Save As Activity.' )
        public Id recordId;
    }

    /*********************************************************************************************************************
     * CLASS: SendEmailResponse
     * @author Bolt Data Consulting Group
     * @description Value object for the send email results.
     *
     * -----CHANGE LOG-----
     * 2025.09.08 - ives - Created class.
     *********************************************************************************************************************/
    public class SendEmailResponse
    {
        @InvocableVariable( Label = 'True if no errors sending the email' Required = false )
        public Boolean success;

        @InvocableVariable( Label = 'A message if there was an error sending the email' Required = false )
        public String message;
    }

}