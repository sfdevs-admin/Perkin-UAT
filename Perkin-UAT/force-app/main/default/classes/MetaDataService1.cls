/*************************************************
* https://github.com/financialforcedev/apex-mdapi
*/
public class MetaDataService1 {
    
    public static String SOAP_M_URI = 'http://soap.sforce.com/2006/04/metadata';   
    
      public class AssignmentRule extends Metadata {
        public String type = 'AssignmentRule';
        public String fullName;
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'0','1','false'};
        public Boolean active;
        public MetadataService1.RuleEntry[] ruleEntry;
        private String[] active_type_info = new String[]{'active',SOAP_M_URI,null,'0','1','false'};
        private String[] ruleEntry_type_info = new String[]{'ruleEntry',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName', 'active','ruleEntry'};
    }
    
      public class AssignmentRules extends Metadata {
        public String type = 'AssignmentRules';
        public String fullName;
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'0','1','false'};
        public MetadataService1.AssignmentRule[] assignmentRule;
        private String[] assignmentRule_type_info = new String[]{'assignmentRule',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] field_order_type_info = new String[]{'fullName', 'assignmentRule'};
    }
       public class SessionHeader_element {
        public String sessionId;
        private String[] sessionId_type_info = new String[]{'sessionId',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'sessionId'};
    }
     public class DebuggingInfo_element {
        public String debugLog;
        private String[] debugLog_type_info = new String[]{'debugLog',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'debugLog'};
    }
    public class LogInfo {
        public String category;
        public String level;
        private String[] category_type_info = new String[]{'category',SOAP_M_URI,null,'1','1','false'};
        private String[] level_type_info = new String[]{'level',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'category','level'};
    }
    
     public class DebuggingHeader_element {
        public MetadataService1.LogInfo[] categories;
        public String debugLevel;
        private String[] categories_type_info = new String[]{'categories',SOAP_M_URI,null,'0','-1','false'};
        private String[] debugLevel_type_info = new String[]{'debugLevel',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'categories','debugLevel'};
    }
    
     public class CallOptions_element {
        public String client;
        private String[] client_type_info = new String[]{'client',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'client'};
    }
    
     public class AllOrNoneHeader_element {
        public Boolean allOrNone;
        private String[] allOrNone_type_info = new String[]{'allOrNone',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'allOrNone'};
    }
    
     public class Error {
        public MetadataService1.ExtendedErrorDetails[] extendedErrorDetails;
        public String[] fields;
        public String message;
        public String statusCode;
        private String[] extendedErrorDetails_type_info = new String[]{'extendedErrorDetails',SOAP_M_URI,null,'0','-1','false'};
        private String[] fields_type_info = new String[]{'fields',SOAP_M_URI,null,'0','-1','false'};
        private String[] message_type_info = new String[]{'message',SOAP_M_URI,null,'1','1','false'};
        private String[] statusCode_type_info = new String[]{'statusCode',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'extendedErrorDetails','fields','message','statusCode'};
    }
    
    public class ExtendedErrorDetails {
        public String extendedErrorCode;
        private String[] extendedErrorCode_type_info = new String[]{'extendedErrorCode',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'extendedErrorCode'};
    }
    
      public class DeleteResult {
        public MetadataService1.Error[] errors;
        public String fullName;
        public Boolean success;
        private String[] errors_type_info = new String[]{'errors',SOAP_M_URI,null,'0','-1','false'};
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'1','1','false'};
        private String[] success_type_info = new String[]{'success',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'errors','fullName','success'};
    }
    
    public class deleteMetadata_element {
        public String type_x;
        public String[] fullNames;
        private String[] type_x_type_info = new String[]{'type',SOAP_M_URI,null,'1','1','false'};
        private String[] fullNames_type_info = new String[]{'fullNames',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'type_x','fullNames'};
    }
    
     public class deleteMetadataResponse_element {
        public MetadataService1.DeleteResult[] result;
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }   
   
    
    public class MetadataPort {
        public String endpoint_x = URL.getOrgDomainUrl().toExternalForm() + '/services/Soap/m/42.0';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        public MetadataService1.SessionHeader_element SessionHeader;
        public MetadataService1.DebuggingInfo_element DebuggingInfo;
        public MetadataService1.DebuggingHeader_element DebuggingHeader;
        public MetadataService1.CallOptions_element CallOptions;
        public MetadataService1.AllOrNoneHeader_element AllOrNoneHeader;
        private String SessionHeader_hns = 'SessionHeader=http://soap.sforce.com/2006/04/metadata';
        private String DebuggingInfo_hns = 'DebuggingInfo=http://soap.sforce.com/2006/04/metadata';
        private String DebuggingHeader_hns = 'DebuggingHeader=http://soap.sforce.com/2006/04/metadata';
        private String CallOptions_hns = 'CallOptions=http://soap.sforce.com/2006/04/metadata';
        private String AllOrNoneHeader_hns = 'AllOrNoneHeader=http://soap.sforce.com/2006/04/metadata';
        private String[] ns_map_type_info = new String[]{SOAP_M_URI, 'MetadataService1'};
        public MetadataService1.DeleteResult[] deleteMetadata(String type_x,String[] fullNames) {
            MetadataService1.deleteMetadata_element request_x = new MetadataService1.deleteMetadata_element();
            request_x.type_x = type_x;
            request_x.fullNames = fullNames;
            MetadataService1.deleteMetadataResponse_element response_x;
            Map<String, MetadataService1.deleteMetadataResponse_element> response_map_x = new Map<String, MetadataService1.deleteMetadataResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              SOAP_M_URI,
              'deleteMetadata',
              SOAP_M_URI,
              'deleteMetadataResponse',
              'MetadataService1.deleteMetadataResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }



 public MetadataService1.IReadResult readMetadata(String type_x,String[] fullNames) {
            MetadataService1.readMetadata_element request_x = new MetadataService1.readMetadata_element();
            request_x.type_x = type_x;
            request_x.fullNames = fullNames;
            MetadataService1.IReadResponseElement response_x;
            Map<String, MetadataService1.IReadResponseElement> response_map_x = new Map<String, MetadataService1.IReadResponseElement>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              SOAP_M_URI,
              'readMetadata',
              SOAP_M_URI,
              'readMetadataResponse',
              'MetadataService1.read' + type_x + 'Response_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.getResult();
        }
        
      
    }

    public class readMetadata_element {
        public String type_x;
        public String[] fullNames;
        private String[] type_x_type_info = new String[]{'type',SOAP_M_URI,null,'1','1','false'};
        private String[] fullNames_type_info = new String[]{'fullNames',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'type_x','fullNames'};
    }

    public interface IReadResult {
        MetadataService1.Metadata[] getRecords();
    }
    public interface IReadResponseElement {
        IReadResult getResult();
    }
    
    public virtual class Metadata {
        public String fullName;
    }

      public class ReadAssignmentRulesResult implements IReadResult {
        public MetadataService1.AssignmentRules[] records;
        public MetadataService1.Metadata[] getRecords() { return records; }
        private String[] records_type_info = new String[]{'records',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'records'};
    }

    

    public class RuleEntry {
        public String assignedTo;
        public String assignedToType;
        public String booleanFilter;
        public String businessHours;
        public String businessHoursSource;
        public MetadataService1.FilterItem[] criteriaItems;
        public Boolean disableEscalationWhenModified;
        public MetadataService1.EscalationAction[] escalationAction;
        public String escalationStartTime;
        public String formula;
        public Boolean notifyCcRecipients;
        public Boolean overrideExistingTeams;
        public String replyToEmail;
        public String senderEmail;
        public String senderName;
        public String[] team;
        public String template;
        private String[] assignedTo_type_info = new String[]{'assignedTo',SOAP_M_URI,null,'0','1','false'};
        private String[] assignedToType_type_info = new String[]{'assignedToType',SOAP_M_URI,null,'0','1','false'};
        private String[] booleanFilter_type_info = new String[]{'booleanFilter',SOAP_M_URI,null,'0','1','false'};
        private String[] businessHours_type_info = new String[]{'businessHours',SOAP_M_URI,null,'0','1','false'};
        private String[] businessHoursSource_type_info = new String[]{'businessHoursSource',SOAP_M_URI,null,'0','1','false'};
        private String[] criteriaItems_type_info = new String[]{'criteriaItems',SOAP_M_URI,null,'0','-1','false'};
        private String[] disableEscalationWhenModified_type_info = new String[]{'disableEscalationWhenModified',SOAP_M_URI,null,'0','1','false'};
        private String[] escalationAction_type_info = new String[]{'escalationAction',SOAP_M_URI,null,'0','-1','false'};
        private String[] escalationStartTime_type_info = new String[]{'escalationStartTime',SOAP_M_URI,null,'0','1','false'};
        private String[] formula_type_info = new String[]{'formula',SOAP_M_URI,null,'0','1','false'};
        private String[] notifyCcRecipients_type_info = new String[]{'notifyCcRecipients',SOAP_M_URI,null,'0','1','false'};
        private String[] overrideExistingTeams_type_info = new String[]{'overrideExistingTeams',SOAP_M_URI,null,'0','1','false'};
        private String[] replyToEmail_type_info = new String[]{'replyToEmail',SOAP_M_URI,null,'0','1','false'};
        private String[] senderEmail_type_info = new String[]{'senderEmail',SOAP_M_URI,null,'0','1','false'};
        private String[] senderName_type_info = new String[]{'senderName',SOAP_M_URI,null,'0','1','false'};
        private String[] team_type_info = new String[]{'team',SOAP_M_URI,null,'0','-1','false'};
        private String[] template_type_info = new String[]{'template',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'assignedTo','assignedToType','booleanFilter','businessHours','businessHoursSource','criteriaItems','disableEscalationWhenModified','escalationAction','escalationStartTime','formula','notifyCcRecipients','overrideExistingTeams','replyToEmail','senderEmail','senderName','team','template'};
    }
    
     public class FilterItem {
        public String field;
        public String operation;
        public String value;
        public String valueField;
        private String[] field_type_info = new String[]{'field',SOAP_M_URI,null,'1','1','false'};
        private String[] operation_type_info = new String[]{'operation',SOAP_M_URI,null,'1','1','false'};
        private String[] value_type_info = new String[]{'value',SOAP_M_URI,null,'0','1','false'};
        private String[] valueField_type_info = new String[]{'valueField',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'field','operation','value','valueField'};
    }
    
      public class readAssignmentRulesResponse_element implements IReadResponseElement {
        public MetadataService1.ReadAssignmentRulesResult result;
        public IReadResult getResult() { return result; }
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }
    
    public class EscalationAction {
        public String assignedTo;
        public String assignedToTemplate;
        public String assignedToType;
        public Integer minutesToEscalation;
        public Boolean notifyCaseOwner;
        public String[] notifyEmail;
        public String notifyTo;
        public String notifyToTemplate;
        private String[] assignedTo_type_info = new String[]{'assignedTo',SOAP_M_URI,null,'0','1','false'};
        private String[] assignedToTemplate_type_info = new String[]{'assignedToTemplate',SOAP_M_URI,null,'0','1','false'};
        private String[] assignedToType_type_info = new String[]{'assignedToType',SOAP_M_URI,null,'0','1','false'};
        private String[] minutesToEscalation_type_info = new String[]{'minutesToEscalation',SOAP_M_URI,null,'0','1','false'};
        private String[] notifyCaseOwner_type_info = new String[]{'notifyCaseOwner',SOAP_M_URI,null,'0','1','false'};
        private String[] notifyEmail_type_info = new String[]{'notifyEmail',SOAP_M_URI,null,'0','-1','false'};
        private String[] notifyTo_type_info = new String[]{'notifyTo',SOAP_M_URI,null,'0','1','false'};
        private String[] notifyToTemplate_type_info = new String[]{'notifyToTemplate',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'assignedTo','assignedToTemplate','assignedToType','minutesToEscalation','notifyCaseOwner','notifyEmail','notifyTo','notifyToTemplate'};
    }
    
   


}