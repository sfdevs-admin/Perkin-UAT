public class SVMX_NewFCO{

    public SVMX_NewFCO(ApexPages.StandardController controller) {

    }
    @testvisible FCO__c fco=new FCO__c();
    public FCO__c getFCO(){
        return fco;
    }
    public void setFCO(FCO__c fco){
        fco=fco;
    }
    public pagereference save(){
        pagereference pgref=null;
        if(fco.Product__c != null && fco.PSC_Status__c != null){
            try{
                Product2 prod=[select id,ProductCode from Product2 where id=:fco.Product__c];
                fco.Name=prod.ProductCode;
                insert fco;
                pgref= new pagereference('/'+fco.id);
                pgref.setRedirect(true);
            }catch(Exception E){
            }
        }
        return pgref;
    }
}