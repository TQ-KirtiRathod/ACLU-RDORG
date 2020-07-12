/*
*Name  :  PopulateBatchLogOnTranscations_Test
*Author:  Appirio India (Gagandeep Kaur)
*Purpose : Test Call for PopulateBatchLogOnTranscations_Batch
*
*/
@isTest
private class PopulateBatchLogOnTranscations_Test {

    static testMethod void testBatch() {
        // TO DO: implement unit test
        createTestData();
        Test.startTest();
        //PopulateBatchLogOnTransactions_Schedule.execute(null);
        Database.executeBatch(new PopulateBatchLogOnTranscations_Batch());
        Test.stopTest();
    }
    static testMethod void testSchedule() {
        PopulateBatchLogOnTransactions_Schedule updateSchedule = new PopulateBatchLogOnTransactions_Schedule();
        Test.startTest();
            String str = '0 0 23 * * ?';
            String jobId = System.schedule('PopulateBatchLogOnTransactions_Schedule'+System.now(), str, updateSchedule); 
        Test.stopTest(); 
        system.assert(jobId != null);
    }
    static void createTestData() {
        Campaign c = TestUtils.createCampaign('TestCampaign', false);
        c.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        insert c;
        Account acc = TestUtils.createAccount('testAccount', true);
        Id OPPORTUNITY_RT_DONATION_Id = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
        Id OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
        list<Opportunity> parentOpp = new List<Opportunity>();
        list<Opportunity> childOpp = new List<Opportunity>();
        Batch_Log__c bl = TestUtils.createBatchLog('Test', true);
        for(Integer i=0 ; i<2 ; i++){
            Opportunity op = TestUtils.createOpportunityWithRecType(OPPORTUNITY_RT_DONATION_Id, acc.Id, 'ParentOpp'+i, null, null, 'Open', c.Id, null, system.today(), false);
            op.Batch_Log__c = bl.Id;
            parentOpp.add(op);
        }
        insert parentOpp;
        for(Integer i=0 ; i<2 ; i++){
            Opportunity op = TestUtils.createOpportunityWithRecType(OPPORTUNITY_RT_TRANSACTION_Id, acc.Id, 'ChildOpp'+i, null, null, 'Completed', c.Id, null, system.today(), false);
            op.rC_Giving__Parent__c = parentOpp[i].Id;
            childOpp.add(op);
        }
        insert childOpp;
    }
}