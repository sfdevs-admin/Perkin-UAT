@isTest
private class SMAX_PS_StockedSerialTriggerHandler_UT {

    @isTest
    static void test1(){
		SMAX_PS_StockedSerialTriggerHandler h = new SMAX_PS_StockedSerialTriggerHandler();
        h.beforeInsert();
	

    }
    
    @isTest
    static void test3(){
		SMAX_PS_StockedSerialTriggerHandler h = new SMAX_PS_StockedSerialTriggerHandler();

        h.beforeUpdate();


    }
    
    @isTest
    static void test4(){
		SMAX_PS_StockedSerialTriggerHandler h = new SMAX_PS_StockedSerialTriggerHandler();

        h.afterUpdate();


    }
    
    @isTest
    static void test5(){
		SMAX_PS_StockedSerialTriggerHandler h = new SMAX_PS_StockedSerialTriggerHandler();

        h.beforeDelete();


    }
    
    @isTest
    static void test6(){
		SMAX_PS_StockedSerialTriggerHandler h = new SMAX_PS_StockedSerialTriggerHandler();

        h.afterDelete();	


    }
    
    @isTest
    static void test7(){
		SMAX_PS_StockedSerialTriggerHandler h = new SMAX_PS_StockedSerialTriggerHandler();

        h.afterUndelete();	

    }
}