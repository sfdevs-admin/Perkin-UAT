/*
     Change History
    ************************************************************************************************************************************************************************************************************************************************************
         JIRA       ModifiedBy        Date            Requested By                           Description                                                    PURPOSE
    **********************************************************************************************************************************************************************************************************************************************************
        SFDC-339    Ashwini         28/04/2017        Richard Talbot          Prompt for additional feedback for case survey when response is Yes   Changes to the survey on "YES" selection with the new picklist values,comments and thanks note after submit
        
*/


public class SurveySubmitController {
    
    public INF_Case_Survey__c survey { get; set; }
    public String selectedvalue {get;set;}
    public String comments {get;set;}
    public Id caseId;
    public String param{get;set;}
    public boolean flag {get;set;}
    public boolean showMessage {get;set;}
    
    public SurveySubmitController() {
        caseId = ApexPages.currentPage().getParameters().get('Id');
        param = ApexPages.currentPage().getParameters().get('mode');
        showMessage = false;
    }
    
    //Omit <apex:selectList value="{!selectedvalue}"  from Survey Page in NO mode
 /*   public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('No Solution','No Solution'));
        options.add(new SelectOption('Phone Issues','Phone Issues'));
        options.add(new SelectOption('Rep Communication Skills','Rep Communication Skills'));
        options.add(new SelectOption('SDK','SDK'));
        options.add(new SelectOption('Software Activation','Software Activation'));
        options.add(new SelectOption('Software Defect','Software Defect'));
        options.add(new SelectOption('Took too long','Took too long'));
        options.add(new SelectOption('Unsupported Environment','Unsupported Environment'));
        options.add(new SelectOption('Others','Others'));
        return options;
    }
    
 */
    
  //Render <apex:selectList value="{!selectedvalue}"  from Survey Page in YES mode
    public List<SelectOption> getYesItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Easy','Easy'));
        options.add(new SelectOption('Difficult','Difficult'));
        options.add(new SelectOption('Neither','Neither'));
        return options;
        
    //omitted from previous values in SatisfactionSurvey picklist on Case Survey obj  per Rich Talbot 6-30-20
    /*    options.add(new SelectOption('Rep Understanding of the Problem','Rep Understanding of the Problem'));
        options.add(new SelectOption('Frequency of Updates','Frequency of Updates'));
        options.add(new SelectOption('Excellent Service','Excellent Service'));
        options.add(new SelectOption('Excellent Product','Excellent Product'));   
     */
   
   // retrieve User input on UI in Sat Surv form     
   }
    public String getselectedvalue() {
        return selectedvalue;
    }
 
    public void setselectedvalue(String selectedvalue) {
        this.selectedvalue = selectedvalue;
    }
    
    //based on what email recipient enters in there survey
    public void initialize(){
    }
    public void processSurveyCreation() {
        if(param == 'YES') {
            processSurveyCreationForYES();
        }
        else if(param == 'NO') {
            processSurveyCreationForNO();
        }
    }
    
    //
    public PageReference processSurveyCreationForYES() {
        //Datetime for created date - if the survey is created in less than an hour, allow user to update -> else create new survey
        if(param == 'YES'){
            List<INF_Case_Survey__c> surveystoupdate = new List<INF_Case_Survey__c>();
            INF_Case_Survey__c survey;
            for(INF_Case_Survey__c surv :[select id,CreatedDate,INF_Recently_Created_Survey__c,INF_Support_sat_Comments__c,INF_Support_Sat_Yes__c from INF_Case_Survey__c where Case__c =:caseId and INF_Support_Sat_Yes__c = true ORDER BY CreatedDate DESC LIMIT 1]) {
                survey = surv;
        }
            if(survey == null){
                System.debug('Survey to insert for yes');
                try {
                    INF_Case_Survey__c surveytoinsert = new INF_Case_Survey__c(Case__c = caseid,INF_Support_Sat_Yes__c = true,INF_Recently_Created_Survey__c=true,INF_Support_sat_Comments__c = comments);
                    INSERT surveytoinsert;
                    return null;
                } catch (Exception e) {
                    ApexPages.addMessages(e);
                    return null;
                }
            }
            else{
                if(selectedvalue==null)
                    return null;
                Datetime timeNow = Datetime.now();
                Datetime allowedUpdateTime = survey.CreatedDate.addHours(1);
                if(allowedUpdateTime > timeNow) {
                        showMessage = true;
                        survey.INF_Recently_Created_Survey__c = false;
                        survey.INF_Support_Sat_Yes__c = true;
                        survey.INF_Support_sat_Comments__c = comments;
                        survey.INF_Support_Sat_Bin__c=selectedvalue;
                        surveystoupdate.add(survey);
                        update surveystoupdate;
                }  
                else {
                    try {
                    INF_Case_Survey__c surveytoinsert = new INF_Case_Survey__c(Case__c = caseid,INF_Support_Sat_Yes__c = true,INF_Recently_Created_Survey__c=true,INF_Support_sat_Comments__c = comments);
                    INSERT surveytoinsert;
                    return null;
                    } catch (Exception e) {
                        ApexPages.addMessages(e);
                        return null;
                    }
                }
            }
        }
        return null;
    }
    
    public PageReference processSurveyCreationForNO() {
        showMessage = true;
        List<INF_Case_Survey__c> surveystoupdate = new List<INF_Case_Survey__c>();
                try {
                    INF_Case_Survey__c surveytoinsert = new INF_Case_Survey__c(Case__c = caseid,INF_Support_Sat_No__c = true,INF_Support_sat_Comments__c = comments,INF_Support_Sat_Bin__c=selectedvalue,INF_Recently_Created_Survey__c=true);
                    INSERT surveytoinsert;
                    flag = true;
                    return null;
                } catch (Exception e) {
                    ApexPages.addMessages(e);
                    return null;
                }
            
            return null;
    }
    
}