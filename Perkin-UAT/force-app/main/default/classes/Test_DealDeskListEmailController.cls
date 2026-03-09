@isTest 
public class Test_DealDeskListEmailController {
    public static testMethod void testMethodforCntrl(){
        DealDeskListEmailController d = new DealDeskListEmailController();
        d.requestFor = 'ABC;ABC';
        d.getsplitString();
    }
}