/********************************************************************************
* Class Name: ResetCloneOpportunityHandler
* Created by: PwC/Amiya Das
* Date Created: Feb 24, 2021
* Comment: This class will contain logic for cloning opportunities with specific
            record types
* ********************************************************************************/
public inherited sharing class ResetCloneOpportunityHandler {
    

    public static void getCloneOpportunity(list<Opportunity> getOppList){

        // getting record type id for Opportunity record type 'PKI SPI Sales Process'
        Id PKIRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('PKI SPI Sales Process').getRecordTypeId();

        // getting record type id for Opportunity record type 'Informatics'
        Id Infor= Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();

        // get logged in user profile name
        Profile prof = [Select Id, Name from Profile where Id=: UserInfo.getProfileId() Limit 1];

        for(Opportunity opp : getOppList){
            if(opp.isClone()){
                if((opp.recordTypeId == PKIRT) || (opp.recordTypeId == Infor)){
                    // updating the new ForecastCategoryName for cloned opp records
                    opp.ForecastCategoryName = 'Pipeline';
                    // updating the new StageName for cloned opp records
                    opp.StageName = 'Stage 1 - Create/Plan';
                }

                // checking if the logged in user profile is 'LDR Demand Gen'
                if(prof.Name == 'LDR Demand Gen'){
                    // updating the new StageName for cloned opp records
                    opp.StageName = 'Zero Stage';
                    // updating the new ForecastCategoryName for cloned opp records
                    opp.ForecastCategoryName = 'Omitted';
                }
            }
        }
    }
}