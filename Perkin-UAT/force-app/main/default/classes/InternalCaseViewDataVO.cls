global class InternalCaseViewDataVO implements Comparable{
    public String type {get;set;}
    public DateTime createdAt {get;set;}
    public String commentBody {get;set;}
    public Emsg emsg { get;set;}
    public Attachment attachment {get;set;}   
    public ActivityHistory webex{get;set;}
    public ActivityHistory call{get;set;}
    public Case relatedCase {get;set;}
    public boolean color {get;set;}
    
    global Integer compareTo(Object other) {
        InternalCaseViewDataVO compareToCopy = (InternalCaseViewDataVO )other;       
        if(this.createdAt > compareToCopy.createdAt) return -1;
        if(this.createdAt == compareToCopy.createdAt) return 0;
        return 1;
    }
    
    public Class Emsg {
        public EmailMessage msg {get;set;}
        public List<Attachment> eat {get; set;}
        public boolean found {get; set;}
    }
}