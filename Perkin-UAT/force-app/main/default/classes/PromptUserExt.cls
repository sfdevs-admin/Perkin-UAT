public with sharing class PromptUserExt {

    Case caseDX;
    public PromptUserExt(ApexPages.StandardController stdCon) {
		caseDX = (Case)stdCon.getRecord();
    }

	public PageReference SaveAndReturn()
    {
		String id = ApexPages.CurrentPage().getparameters().get('id');
        String inC = ApexPages.CurrentPage().getparameters().get('inC');
        PageReference pr;
        
        try{
            caseDX.Confirm__c = TRUE;
            caseDX.Status = 'Closed';
        	update caseDX;
            
            if(inC == '1')
            	pr = new PageReference('/console?' + caseDX.id);
            else
                pr = new PageReference('/' + caseDX.id);
        	
            pr.setRedirect(true);
        	return pr;
        }
        
        catch(DMLException e){
            ApexPages.addMessages(e);
        }
        return null;
    }
    
    public PageReference CancelAndReturn()
    {
		String id = ApexPages.CurrentPage().getparameters().get('id');
        String inC = ApexPages.CurrentPage().getparameters().get('inC');
        PageReference pr;
            
        if(inC == '1')
            pr = new PageReference('/console?' + caseDX.id);
        else
            pr = new PageReference('/' + caseDX.id);
        	
        pr.setRedirect(true);
        return pr;
    }
}