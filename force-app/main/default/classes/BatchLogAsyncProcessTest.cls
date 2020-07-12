@isTest
public class BatchLogAsyncProcessTest {
    private static Batch_Log__c testBatchLog;
    private static List<opportunity> oppLst ;
    
    public testMethod static void TestBatchLogAsyncReq(){
        
        Map<String,Schema.RecordTypeInfo> blRTMap = Schema.SObjectType.Batch_Log__c.getRecordTypeInfosByName();

        //RecordType - Manual
        String BATCH_LOG_RT_MANUAL_Id = blRTMap.get('Manual').getRecordTypeId();
        testBatchLog = TestUtils.createBatchLog('testBatchName', false);
        //adding date to avoid onbeforeinsert trigger exception
        testBatchLog.Batch_Date__c = Date.today();
        testBatchLog.Batch_Type__c='Adjustment';
        testBatchLog.RecordTypeId = BATCH_LOG_RT_MANUAL_Id;
        testBatchLog.Expected_Count__c=20;
        testBatchLog.Expected_Amount__c = 100;
        testBatchLog.Actual_Count__c = 20;
        testBatchLog.Actual_Amount__c = 100;
        insert testBatchLog;
        
        BatchLogAsyncProcess batchLogclass = new BatchLogAsyncProcess(new AsyncRequest__c(Params__c = testBatchLog.id));
        batchLogclass.updateBatchLogStatus();
        
        System.assertEquals('Membership and Revenue Sharing Resets Needed', [Select id, Batch_Log_Status__c FROM Batch_Log__c where id =: testBatchLog.id].Batch_Log_Status__c);
    }
}