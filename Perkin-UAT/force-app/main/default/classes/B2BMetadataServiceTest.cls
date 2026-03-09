/**
 * @description       : 
 * @author            : Gaurav Setia
 * @group             : 
 * @last modified on  : 02-25-2026
 * @last modified by  : Suhail Ahmed T 
**/
@IsTest
private class B2BMetadataServiceTest {

    @IsTest
    static void getTaxConfigurationTest() {
        //Given

        //When
        Test.startTest();
        Map<String, Object> respMap = B2BMetadataService.getTaxConfiguration('B2BStripeTaxCalculatorService');
        Test.stopTest();

        //Then
        System.assert(respMap != null, 'respMap should not be null');
        System.assert(respMap.get('EndPoint') != null, 'endpoint should not be null');
    }

    @IsTest
    static void getFlatTaxRateByCountryTest() {
        //Given

        //When
        Test.startTest();
        B2B_Country_Tax_Config__mdt resp = B2BMetadataService.getFlatTaxRateByCountry('USD');
        Test.stopTest();

        //Then
        System.assert(resp != null, 'response should not be null');
    }
    
    @IsTest
    static void getFlatTaxRateByCountryCodeTest() {
        //Given

        //When
        Test.startTest();
        B2B_Country_Tax_Config__mdt resp = B2BMetadataService.getFlatTaxRateByCountryCode('USD', 'US');
        Test.stopTest();

        //Then
        System.assert(resp != null, 'response should not be null');
    }

    @IsTest
    static void getSAPCustomerNumberTest() {
        //Given
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        //When
        Test.startTest();
        String resp = B2BMetadataService.getSAPCustomerNumber(acc.Id);
        Test.stopTest();

        //Then
        System.assertNotEquals(resp, 'response should not be null');
    }

    @IsTest
    static void isAccountTaxExemptTest() {
        //Given
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        B2B_TestDataFactory.createB2BTaxExemption(acc.Id, true);
        //When
        Test.startTest();
        Boolean resp = B2BMetadataService.isAccountTaxExempt(
            new Map<String, Object>{
                'accountId' => acc.Id,
                'stateCode' => 'AL'
            }
        );
        Test.stopTest();

        //Then
        System.assert(resp != null, 'response should not be null');
    }
}