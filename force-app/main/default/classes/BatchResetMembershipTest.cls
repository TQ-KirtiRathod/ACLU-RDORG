/*
*
*Name  :  BatchResetMembershipTest
*Author:  Appirio India (Bhavesh Malviya)
*Date  :  03/04/2018
*Purpose : Test class for BatchResetMembership.
*
*/

@isTest(SeeAllData=false)
private class BatchResetMembershipTest {
    public static Map<String,Schema.RecordTypeInfo> batchLogRTMap =  Schema.SObjectType.batch_Log__c.getRecordTypeInfosByName();
    public static Id OPPORTUNITY_RT_PLEDGE_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
    public static Id OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();

    

     @testSetup
    public static void createTestData() {
        // Create Account
        Account acc = TestUtils.createAccount('TestAccount',True);
        
        // Create Campaign
        Campaign cmpgn = TestUtils.createCampaign('TestCampaign', false);
        cmpgn.rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation';
        insert cmpgn;
        
       /* List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues'); */
    }
    @isTest
	private static void test1() {
	    Batch_Log__c BatchLog = createBatchLog();
        insert batchLog;
        createOpportunity(batchLog);
        batchLog.Batch_Log_Status__c = 'Balanced';
        update batchLog;
        
        for( Opportunity opp : [Select rC_Giving__External_ID__c From Opportunity where recordtypeId =: OPPORTUNITY_RT_PLEDGE_PAYMENT_Id ]){
            System.assertEquals(true, opp.rC_Giving__External_ID__c != null );
        }
        Test.startTest();
            Database.executeBatch(new BatchResetMembership(batchLog.id), 200);
        Test.stopTest();
        for( Opportunity opp : [Select rC_Giving__External_ID__c, stageName, sharing_code__c, recordtypeId From Opportunity where Batch_Log__c =: batchLog.id ]){
            if( opp.recordtypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id){
                System.assertEquals(true, opp.rC_Giving__External_ID__c == null );
            }
        }

	}
	
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
            opp.Sharing_Code__c = 'A002';
            opp.rC_Giving__External_ID__c = 'Flagged for MembershipShareCode Reset';
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