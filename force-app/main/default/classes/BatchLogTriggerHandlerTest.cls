/*
*Name  :  BatchLogTriggerHandler
*Author:  Appirio India ()
*Date  :  February , 2017
*Purpose : Test Class for BatchLogTriggerHandler
*/
@isTest
public class BatchLogTriggerHandlerTest {
    public static Map<String,Schema.RecordTypeInfo> opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
    public static Map<String,Schema.RecordTypeInfo> batchLogRTMap =  Schema.SObjectType.batch_Log__c.getRecordTypeInfosByName();
    public static Id OPPORTUNITY_RT_DONATION_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_DONATION).getRecordTypeId();
    public static Id OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_TRANSACTION).getRecordTypeId();
    
    /*
    * Method to test Batch_Log__c insert case
    */
    public static TestMethod void testBatchLogInsert() {
        //Create Batch_Log__c records
        List<Batch_Log__c> listBatchLog = createBatchLog();
        listBatchLog[0].Batch_Date__c = Date.newInstance(2017, 1, 1);
        
        Test.startTest();
            insert listBatchLog;
            List<Batch_Log__c> logsWithNames = [SELECT id, Name FROM Batch_Log__c];
            system.assertEquals('CDUM', logsWithNames[2].Name.subString(0,4));
            system.assertEquals('ARUE', logsWithNames[1].Name.subString(0,4));
        Test.stopTest();
    }
    
    /*
    * Method to test Batch_Log__c update case
    */ 
    public static TestMethod void testBatchLogUpdate() {
        //Create Batch_Log__c records
        List<Batch_Log__c> listBatchLog = createBatchLog();
        listBatchLog.get(1).Total_Net_Amount__c = 500;
        listBatchLog.get(1).Total_Fees__c = 300;
        listBatchLog.get(1).Expected_Amount__c = 800;
        insert listBatchLog;
        
        createOpportunity(listBatchLog);
        
        Test.startTest();
            // Update Batch_Log__c records
            //listBatchLog.get(1).Batch_Log_Status__c = 'Balanced';
            listBatchLog.get(2).Batch_Log_Status__c = 'Balanced';
            update listBatchLog.get(2);
            
            List<Opportunity> opptyLst = [SELECT Id, rC_Giving__Parent__r.Program_Type__c, Program_Type__c, StageName 
                                          FROM Opportunity 
                                          WHERE Batch_Log__c =: listBatchLog.get(2).Id 
                                                AND RecordType.Name = 'Transaction'];
            system.assertEquals(1, opptyLst.size());
            system.assertEquals(opptyLst.get(0).Program_Type__c,opptyLst.get(0).rC_Giving__Parent__r.Program_Type__c);
            system.assertEquals('Completed', opptyLst.get(0).StageName);
            
            listBatchLog.get(1).Expected_Amount__c = 900;
            update listBatchLog.get(1);
            System.assertEquals(400, [select id, Total_Fees__c from Batch_Log__c where id =: listBatchLog.get(1).Id  ][0].Total_Fees__c);
        Test.stopTest();
    }
    
    /*
    * Method to test Batch_Log__c update case
    */ 
    public static TestMethod void testBatchLogUpdateGiftsFields() {
        //Create Batch_Log__c records
        List<Batch_Log__c> listBatchLog = createBatchLog();
        insert listBatchLog;
        
        createOpportunity(listBatchLog);
        Test.startTest();
            // Update Batch_Log__c records
            listBatchLog.get(2).Bank_Date__c = system.today().addDays(5);
            listBatchLog.get(2).Batch_Date__c = system.today().addDays(3);
            update listBatchLog.get(2);
            
            List<Opportunity> opptyLst = [SELECT Id, Bank_Date__c, Batch_Date__c
                                          FROM Opportunity 
                                          WHERE Batch_Log__c =: listBatchLog.get(2).Id ];
            system.assertEquals(2, opptyLst.size());
            for(Opportunity opp : opptyLst) {
                system.assertEquals(listBatchLog.get(2).Bank_Date__c, opp.Bank_Date__c);
                system.assertEquals(listBatchLog.get(2).Batch_Date__c, opp.Batch_Date__c);
            }
        Test.stopTest();
    }
    
    /*
    * Method to create Batch_Log__c records
    */
    public static List<Batch_Log__c> createBatchLog() {
        List<Batch_Log__c> listBatchLog = new List<Batch_Log__c>();
        
        //Create diffrent Batch_Log__c records
        for(Integer i = 1; i < 10 ; i ++) {
            Batch_Log__c batlog = TestUtils.batchLog('', false);
            batlog.RecordTypeId = batchLogRTMap.get(ACLU_Constants.CONST_RCDTYPE_VENDOR).getRecordTypeId();
            batLog.Affiliation__c = 'CD';
            batLog.Program_Type__c = String.valueOf(i);
            batLog.Batch_Date__c = system.today();
            batLog.Batch_Auto_Number__c = i;
            batLog.Deposit_Site__c = 'AR_Arkansas';
            batLog.Batch_Log_Status__c = 'Pending';
            batLog.Actual_Amount__c = 4;
            batLog.Expected_Amount__c = 4;
            batlog.Actual_Count__c = 2;
            batLog.Expected_Count__c = 2;
            if(i==1)
                batlog.Batch_Log_Type__c = 'SpringBoard';
            if(i==2)
                batlog.Batch_Log_Type__c = 'Vendor';
            if(i==3) {
                batlog.Batch_Log_Type__c = 'Manual';
                batlog.RecordTypeId = batchLogRTMap.get(ACLU_Constants.CONST_RCDTYPE_MANUAL).getRecordTypeId();
            }
            if(i==4) {
                batlog.Batch_Log_Type__c = 'Sustainer';
                batlog.RecordTypeId = batchLogRTMap.get(ACLU_Constants.CONST_RCDTYPE_MANUAL).getRecordTypeId(); 
            }
            if(i==5)
                batlog.Batch_Log_Type__c = 'Sustainer';
            listBatchLog.add(batLog);
        }
        
        return listBatchLog;
    }
    
    /*
    * Method to create Opportunity records
    */
    public static void createOpportunity(List<Batch_Log__c> listBatchLog){
        List<Opportunity> oppList = new List<Opportunity>();
        List<Opportunity> transactionLst = new List<Opportunity>();
        Account acc = [SELECT Id, Name FROM Account];
        Campaign cmpgn = [SELECT Id, rC_Giving__Sub_Affiliation__c FROM Campaign];
        
        //Create Donation records
        for(Integer i = 1; i < 10 ; i ++) {
            Opportunity opp = TestUtils.createOpportunity(acc.id, 'Bulk test-Opportunity'+i, false);
            opp.RecordTypeId = OPPORTUNITY_RT_DONATION_Id; 
            opp.Batch_Log__c = listBatchLog.get(i-1).Id;
            opp.IsCreatedFromBatchLog__c = true;
            opp.rC_Giving__Giving_Frequency__c = 'One Payment';
            opp.rC_Giving__Giving_Amount__c = 1000;
            opp.CampaignId = cmpgn.Id;
            opp.Program_Type__c = String.valueOf(i);
            oppList.add(opp);
        }
        insert oppList;
        
        //Create Transaction records
        for(Integer i = 1; i < 10 ; i ++) {
            Opportunity opp = TestUtils.createOpportunity(acc.id, 'Bulk test-Opportunity'+i, false);
            opp.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id; 
            opp.Batch_Log__c = listBatchLog.get(i-1).Id;
            opp.IsCreatedFromBatchLog__c = true;
            opp.Amount = 1000;
            opp.CampaignId = cmpgn.Id;
            opp.rC_Giving__Parent__c = oppList.get(i-1).Id;
            transactionLst.add(opp);
        }
        insert transactionLst;
    }
    
    @testSetup
    public static void createTestData() {
        // Create Account
        Account acc = TestUtils.createAccount('TestAccount',True);
        
        // Create Campaign
        Campaign cmpgn = TestUtils.createCampaign('TestCampaign', false);
        cmpgn.rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation';
        insert cmpgn;
        
        // Custom Setting Test Data
        Batch_Upload_Source_File__c uploadSetting = TestUtils.createBatchUploadSourceFileSetting('Springboard', 'S', false);
        insert uploadSetting;
    }
    
}