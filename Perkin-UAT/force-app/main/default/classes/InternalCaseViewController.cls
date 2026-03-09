public class InternalCaseViewController {
    private final String caseId;
    public List<InternalCaseViewDataVO> data {get;set;}
    public List<EmailMessage> emails {get;set;}
    public Case caselist {get;set;}
    private Map<Id,InternalCaseViewDataVO> emap=new Map<Id,InternalCaseViewDataVO>();
    
    public InternalCaseViewController(ApexPages.StandardController controller) {      
        caseId = ApexPages.currentPage().getParameters().get('id');
        caselist = [select Id,Subject,CaseNumber,Description,Priority,LastModifiedDate,CreatedDate from Case where Id = :caseId];
        data = new List<InternalCaseViewDataVO>();
        buildTimeLine();
    }
    
    public void buildTimeLine() {
        emails = new List<EmailMessage>();
        List<CaseComment> comments = [select Id,CommentBody,CreatedDate from CaseComment where ParentId = :caseId];
        emails = [select Id,Subject,MessageDate,TextBody,HtmlBody,CreatedDate,Incoming from EmailMessage where ParentId = :caseId ORDER BY MessageDate];       
        List<Attachment> attachments = [SELECT Id,Name,CreatedDate from Attachment where ParentId = :caseId];      
        List<Case> webexes = [SELECT (SELECT Id,Subject,LastModifiedDate,Description,CreatedDate FROM ActivityHistories WHERE ActivityType !='Phone Call' AND (NOT Subject Like '%Email:%'))FROM Case where Id = :caseId];
        List<Case> calls = [SELECT (SELECT Id,LastModifiedDate,Subject,Description,CreatedDate FROM ActivityHistories WHERE ActivityType = 'Phone Call')FROM Case where Id = :caseId];
        List<Case> relatedcs = [SELECT Id,Subject,CreatedDate,Description,CaseNumber,RecordType.Name from Case where ParentId = :caseId];
        for(CaseComment c : comments) {
            InternalCaseViewDataVO vo = new InternalCaseViewDataVO();
            vo.type = 'CaseComment';
            vo.commentBody = c.CommentBody;
            vo.CreatedAt = c.CreatedDate;
            data.add(vo);
        }
        
        List<Case_Full_View__c> textDelimiters = [Select Delimiter__c from Case_Full_View__c where HTML_Delimiter__c=false];
        List<Case_Full_View__c> htmlDelimiters = [Select Delimiter__c from Case_Full_View__c where HTML_Delimiter__c=true];
        
        for(EmailMessage em : emails) {
            InternalCaseViewDataVO vo = new InternalCaseViewDataVO(); 
            vo.type = 'Email';          
            vo.CreatedAt = em.MessageDate;
            boolean containsTextDelimiter = false;
            String textDelimiter = '';
            boolean containsHtmlDelimiter = false;
            String HtmlDelimiter = '';
            integer textindex;
            integer htmlindex;
            if(em.TextBody!=null)
                textindex = em.TextBody.length();
            if(em.HtmlBody!=null)
                htmlindex = em.HtmlBody.length();
            if(em.TextBody!=null && !em.Incoming){
                for(Case_Full_View__c d:textDelimiters){
                    if(em.TextBody.contains(d.Delimiter__c)){
                        if(em.TextBody.indexOf(d.Delimiter__c) < textindex){
                            containsTextDelimiter = true;
                            textDelimiter = d.Delimiter__c;
                            textindex = em.TextBody.indexOf(textDelimiter);
                        }
                    }
                }
                system.debug('selected text delimiter '+textDelimiter);
                if(em.TextBody.contains(textDelimiter)) {
                    system.debug('inside second if');
                    em.TextBody=em.TextBody.replace('-','');
                    Integer i=em.TextBody.indexOf(textDelimiter);
                    
                    em.TextBody=em.TextBody.substring(0,i).trim();
                    
                    system.debug('****** reult of Msg text body'+em.textBody);
                }
            }
                vo.emsg = new InternalCaseViewDataVO.Emsg();
                vo.emsg.eat = new List<Attachment>();
                vo.emsg.msg = em;
                emap.put(em.Id, vo);
                data.add(vo); 
            } 
            
            //Fetch all e-mail attachments
            List<Attachment> att = [SELECT Id,Name,CreatedDate,ParentId from Attachment where ParentId IN:emap.keySet()]; 
            System.debug('***ATT***' + att);
            for(Attachment c: att){
                InternalCaseViewDataVO vd=emap.get(c.ParentId);
                if(vd!=null){
                    vd.emsg.eat.add(c);
                    vd.emsg.found=true;
                }
            }
            
            //Fetch all attachments on case
            for(Attachment a : attachments) {
                InternalCaseViewDataVO vo = new InternalCaseViewDataVO(); 
                vo.type = 'Attachment';          
                vo.CreatedAt = a.CreatedDate;
                vo.attachment = a;
                data.add(vo); 
            }
            
            for(Case c : webexes){
                for(ActivityHistory webexlog : c.ActivityHistories) {
                    InternalCaseViewDataVO vo = new InternalCaseViewDataVO(); 
                    vo.CreatedAt = webexlog.CreatedDate;
                    vo.type='Webex';
                    vo.webex = webexlog;                
                    data.add(vo);
                }  
            }
            
            for(Case c : calls){
                for(ActivityHistory callLog : c.ActivityHistories) {
                    System.debug('$$$$$'+c.ActivityHistories);
                    InternalCaseViewDataVO vo = new InternalCaseViewDataVO(); 
                    vo.createdAt = callLog.CreatedDate;
                    vo.type='Call';
                    vo.call = callLog;
                    data.add(vo);
                }  
            }
            data.sort();
        }             
    }