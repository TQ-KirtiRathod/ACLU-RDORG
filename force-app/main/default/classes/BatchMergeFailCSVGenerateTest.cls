@isTest
public with sharing class BatchMergeFailCSVGenerateTest {
    
    @TestSetup
    static void makeData(){
        Apex_Log__c al1 = new Apex_Log__c();
        al1.Message__c = '003a 003b | VALIDATION ERROR';
        al1.Exception_Type__c = 'dupcheck.dc3Exception.MergeException';
        insert al1;
    }

    @isTest
    static void testBatchRun(){
        makeData();
        Datetime startDt = Datetime.newInstance(2019,1,1);
        Datetime endDt = Datetime.now();
        Test.startTest();
        BatchMergeFailCSVGenerate myBatchObject = new BatchMergeFailCSVGenerate(startDt,endDt); 
        Id batchId = Database.executeBatch(myBatchObject);
        Test.stopTest();
    }

}