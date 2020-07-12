/**
Test Call for Recalculate_ActualAmountsCounts_BatchLog
*/
@isTest
private class Recalculate_ActAmtsCounts_BatchLogTest {
    static Batch_Log__c b;
    static testMethod void testBatchLog() {
        createTestData();
        Test.startTest();
        Recalculate_ActualAmountsCounts_BatchLog.runAmountCalc(b.Id);
        Batch_Log__c bLog = [SELECT Id, Actual_Amount__c, Actual_Count__c FROM Batch_Log__c WHERE Id = :b.Id];
        system.assertEquals(30, bLog.Actual_Amount__c);
        system.assertEquals(3, bLog.Actual_Count__c);
        Test.stopTest();
    }
    static testMethod void testNullBatchLog() {
        createTestData();
        Test.startTest();
        Recalculate_ActualAmountsCounts_BatchLog.runAmountCalc(null);
        Test.stopTest();
        system.assertEquals(1, ([SELECT Id, Actual_Amount__c, Actual_Count__c FROM Batch_Log__c]).size());
    }
    static testMethod void testSchedule() {
        Recalculate_ActualAmountsCounts_BatchLog updateSchedule = new Recalculate_ActualAmountsCounts_BatchLog();
        Test.startTest();
        String str = '0 0 23 * * ?'; 
        String jobId = System.schedule('Recalculate_ActualAmountsCounts_BatchLog', str, updateSchedule); 
        Test.stopTest();
        system.assert(jobId != null);
    }
    static void createTestData() {
        Id vendorRcdTypeId = Schema.SObjectType.batch_Log__c.getRecordTypeInfosByName().get(ACLU_Constants.CONST_RCDTYPE_VENDOR).getRecordTypeId();
        b = TestUtils.createBatchLog( 'batchTestName', false);
        b.RecordTypeId = vendorRcdTypeId;
        b.Batch_Log_Status__c = 'Open';
        insert b;
        Account acc = TestUtils.createAccount('testAccount', true);
        list<Opportunity> oppList = new list<Opportunity>();
        Opportunity opp;
        for(Integer i = 0; i < 3; i++) {
            opp = TestUtils.createOpportunity(acc.Id , 'testOpportunity' + i, false);
            opp.Batch_Log__c = b.Id;
            opp.rC_Giving__Giving_Amount__c = 10;
            oppList.add(opp);
        }
        insert oppList;
    }
}