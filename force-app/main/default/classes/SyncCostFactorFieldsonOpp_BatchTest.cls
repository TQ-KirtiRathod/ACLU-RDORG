/*
*Author:  Appirio India 
*Date  :  October 
*Purpose : Test Coverage for SyncCostFactorFieldsonOpportunity_Batch Class
*/
@isTest(seeAllData = false)
private class SyncCostFactorFieldsonOpp_BatchTest {
	
	/* 
    *
    * Method testSyncCostFactorFieldsonOpp_Batch
    * Testing SyncCostFactorFieldsonOpportunity_Batch functionality
    */
    private static testMethod void testSyncCostFactorFieldsonOpp_Batch(){
    	
    	// Account Record
        Account testacc1 = TestUtils.createAccount('testAcc1', true);
        
        // Opportunity Records
        List<Opportunity> oppList = new List<Opportunity>();
        for(integer i=0; i<50; i++){
            Opportunity tempOpp = TestUtils.createOpportunity(testacc1.Id,'testOpp'+i,false);
			tempOpp.rC_Giving__Source_Code__c = 'sampleText';
            oppList.add(tempOpp);
        }
        
        if(oppList.size()>0){
            insert oppList;
        }
        
        // Verifying results before Batch Run
        List<Opportunity> oppListBeforeBatch = [SELECT id,rC_Giving__Source_Code__c,Exclude_Cost_Factors_in_RevShare__c,
                                                Use_Campaign_Cost__c 
                                                FROM Opportunity LIMIT 10];
        for(Opportunity opp : oppListBeforeBatch){
            System.assertEquals('sampleText',opp.rC_Giving__Source_Code__c);
            System.assertEquals(false,opp.Exclude_Cost_Factors_in_RevShare__c);
            System.assertEquals(false,opp.Use_Campaign_Cost__c);
        }
        
        Test.startTest();
        	SyncCostFactorFieldsonOpportunity_Batch.syncCostFactorFieldsonOpportunity('sampleText',true,false);
        Test.stopTest();
        
        // Verifying Results after test Run
        List<Opportunity> oppListAfterBatch = [SELECT id,rC_Giving__Source_Code__c,Exclude_Cost_Factors_in_RevShare__c,
                                               Use_Campaign_Cost__c 
                                               FROM Opportunity LIMIT 10];
                                               
        for(Opportunity opp : oppListAfterBatch){
            System.assertEquals('sampleText',opp.rC_Giving__Source_Code__c);
            System.assertEquals(true,opp.Exclude_Cost_Factors_in_RevShare__c);
            System.assertEquals(false,opp.Use_Campaign_Cost__c);
        }
    }
}