public with sharing class DealDeskListEmailController {
    public String requestFor{set; get;}
    public List<String> splitString;

    public List<String> getsplitString(){
            if(this.requestFor != null && this.requestFor != '' && this.splitString == null){
                splitString = new List<String>();
                splitString = this.requestFor.split(';');
               
            }
            return splitString;
    }
}