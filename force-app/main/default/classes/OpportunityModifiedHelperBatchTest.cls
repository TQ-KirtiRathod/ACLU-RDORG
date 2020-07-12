/**
* Test Class for OpportunityModifiedHelperBatch
**/
@isTest(seeAllData = false)
private class OpportunityModifiedHelperBatchTest {
    private static testMethod void testOpportunityModifiedHelperBatch2(){
        createTestData();
        Last_Run_Time_Of_Batch__c lrtb = TestUtils.createLastRunSetting('OpportunityModifiedHelperBatch', System.today() - 1, true);
        /*lrtb.Name = 'OpportunityModifiedHelperBatch';
		lrtb.Last_Run_Time__c = System.now();
		insert lrtb;*/
        
        Test.startTest();
        Database.executeBatch(new OpportunityModifiedHelperBatch());
        Test.stopTest();
        
        Opportunity updatedOpportunity = [SELECT id,RPT_Revenue_Type__c 
                                          FROM Opportunity LIMIT 1][0];
        
        System.assertEquals('Short Fall',updatedOpportunity.RPT_Revenue_Type__c);
    }
    private static testMethod void testOpportunityModifiedHelperBatch_Schedule(){
        Test.StartTest();
        OpportunityModifiedHelperBatch_Schedule sh1 = new OpportunityModifiedHelperBatch_Schedule();
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = system.schedule('Test Territory Check', CRON_EXP, sh1); 
        Test.stopTest(); 
        system.assert(jobId != null);
    }
    private static void createTestData(){
        Account testacc1 = TestUtils.createAccount('testAcc1', true);
        List<Opportunity> oppList = new List<Opportunity>();
        for(integer i=0; i<150; i++){
            Opportunity tempOpp = TestUtils.createOpportunity(testacc1.Id,'testOpp'+i,false);
            tempOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
            tempOpp.rC_Giving__Source_Code__c = 'SG11212SF12';
            tempOpp.Populate_Revenue_Type__c = true;
            oppList.add(tempOpp);
        }
        if(oppList.size()>0){
            insert oppList;
        }
    }
}