/*
*
*Name  :  ReleaseBatchLog_BatchTest
*Author:  Appirio India (Bhavesh Malviya)
*Date  :  02/04/2018
*Purpose : Test class for ReleaseBatchLog_Batch.
*
*/
@isTest
public class ReleaseBatchLog_BatchTest {
    public static Map<String,Schema.RecordTypeInfo> opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
    public static Map<String,Schema.RecordTypeInfo> batchLogRTMap =  Schema.SObjectType.batch_Log__c.getRecordTypeInfosByName();
    public static Id OPPORTUNITY_RT_DONATION_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_DONATION).getRecordTypeId();
    public static Id OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_TRANSACTION).getRecordTypeId();
    public static Id OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    public static Id OPPORTUNITY_RT_PLEDGE_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();

    @testSetup
    public static void createTestData() {
        // Create Account
        Account acc = TestUtils.createAccount('TestAccount',True);
        
        // Create Campaign
        Campaign cmpgn = TestUtils.createCampaign('TestCampaign', false);
        cmpgn.rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation';
        insert cmpgn;
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues'); 
    }
    
    /*
    * Method to test Batch_Log__c update case
    */ 
    public static TestMethod void testBatchLogUpdate() {
        //Create Batch_Log__c records
        Batch_Log__c listBatchLog = createBatchLog();
        insert listBatchLog;
        createOpportunity(listBatchLog);
        Opportunity opp1 = [Select Id FROM Opportunity Where RecordTypeId =: OPPORTUNITY_RT_PLEDGE_PAYMENT_Id LIMIT 1];
        ReleaseBatchLog_Batch batchClass = new ReleaseBatchLog_Batch(listBatchLog.id, UserInfo.getUserId());
        Map<Id, String> error = new Map<Id, String>();
        error.put(opp1.Id, 'abdc');
        batchClass.errorMap = error;
        Test.startTest();
            Database.executeBatch(batchClass, 1);

        Test.stopTest();
        for(Opportunity opp : [SELECT Id, rC_Giving__Parent__r.Program_Type__c, Program_Type__c, StageName ,Sharing_Code__c
                                      FROM Opportunity 
                                      WHERE Batch_Log__c =: listBatchLog.Id And RecordTypeId =: OPPORTUNITY_RT_PLEDGE_PAYMENT_Id]){
            system.assertEquals(true, opp.Sharing_Code__c != NULL );
            system.assertEquals('Completed', opp.StageName);                                 
        }
        
            
            
        
    }
    
    public static TestMethod void testBatchLogUpdateFlagged() { 
        //Create Batch_Log__c records
        Batch_Log__c listBatchLog = createBatchLog();
        insert listBatchLog;
        createOpportunity(listBatchLog);
        Opportunity opp1 = [Select Id FROM Opportunity Where RecordTypeId =: OPPORTUNITY_RT_PLEDGE_PAYMENT_Id LIMIT 1];
        ReleaseBatchLog_Batch batchClass = new ReleaseBatchLog_Batch(listBatchLog.id, UserInfo.getUserId());
        Map<Id, String> error = new Map<Id, String>();
        error.put(opp1.Id, 'Flagged');
        batchClass.errorMap = error;
        Test.startTest();
            Database.executeBatch(batchClass, 1);

        Test.stopTest();
        for(Opportunity opp : [SELECT Id, rC_Giving__Parent__r.Program_Type__c, Program_Type__c, StageName ,Sharing_Code__c
                                      FROM Opportunity 
                                      WHERE Batch_Log__c =: listBatchLog.Id And RecordTypeId =: OPPORTUNITY_RT_PLEDGE_PAYMENT_Id]){
            system.assertEquals(true, opp.Sharing_Code__c != NULL );
            system.assertEquals('Completed', opp.StageName);                                 
        }
    }
    /*
    * Method to create Opportunity records
    */
    public static void createOpportunity(Batch_Log__c batchLog){
        List<Opportunity> oppList = new List<Opportunity>();
        List<Opportunity> transactionLst = new List<Opportunity>();
        Account acc = [SELECT Id, Name FROM Account];
        Campaign cmpgn = [SELECT Id, rC_Giving__Sub_Affiliation__c FROM Campaign];
        
        //Create Donation records
        for(Integer i = 1; i < 2 ; i ++) {
            Opportunity opp = TestUtils.createOpportunity(acc.id, 'Bulk test-Opportunity'+i, false);
            opp.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id; 
            opp.Batch_Log__c = batchLog.Id;
            opp.IsCreatedFromBatchLog__c = true;
            opp.rC_Giving__Giving_Frequency__c = 'One Payment';
            opp.rC_Giving__Giving_Amount__c = 1000;
            opp.CampaignId = cmpgn.Id;
            opp.Program_Type__c = String.valueOf(i);
            opp.StageName = 'Open';
            oppList.add(opp);
        }
        insert oppList;
        
        //Create Transaction records
        for(Integer i = 1; i < 2 ; i ++) {
            Opportunity opp = TestUtils.createOpportunity(acc.id, 'Bulk test-Opportunity'+i, false);
            opp.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id; 
            opp.Batch_Log__c = batchLog.Id;
            opp.IsCreatedFromBatchLog__c = true;
            opp.Amount = 1000;
            opp.CampaignId = cmpgn.Id;
            opp.rC_Giving__Parent__c = oppList.get(i-1).Id;
            opp.StageName = 'Open';
            transactionLst.add(opp);
        }
        insert transactionLst;
        
        
    }
    
    /*
    * Method to create Batch_Log__c records
    */
    public static Batch_Log__c createBatchLog() {
        
            Batch_Log__c batlog = TestUtils.batchLog('test', false);
            batlog.RecordTypeId = batchLogRTMap.get(ACLU_Constants.CONST_RCDTYPE_MANUAL).getRecordTypeId();
            batLog.Affiliation__c = 'CD';
            batLog.Program_Type__c = '3';
            batLog.Batch_Date__c = system.today();
            batLog.Batch_Auto_Number__c = 1234;
            batLog.Deposit_Site__c = 'AR_Arkansas';
            batLog.Batch_Log_Status__c = 'Pending';
            batLog.Actual_Amount__c = 4;
            batLog.Expected_Amount__c = 4;
            batlog.Actual_Count__c = 2;
            batLog.Expected_Count__c = 2;
            batlog.Batch_Log_Type__c = 'Manual';
            batlog.Batch_Log_Status__c = 'Open';
        
        return batlog;
    }
}