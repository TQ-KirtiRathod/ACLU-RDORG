/*
 *
 *Name  :  CreatePledgePaymentBatchLogsTest
 *Author:  Appirio India 
 *Date  :  October 10,2017
 *Purpose : To Test CreatePledgePaymentBatchLogs_Batch Class functionality
 *
 */
@isTest
private class CreatePledgePaymentBatchLogsTest {

    private Static List < Opportunity > listOpportunity = new List < Opportunity > ();
    private static List < campaign > listCampaign = new List < campaign > ();
    private static String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
    private static Map < String, Schema.RecordTypeInfo > opptyRTMap = new Map < String, Schema.RecordTypeInfo > ();
    private static void createTestData() {
        User u = testUtils.createUser('testFirst', 'syst@testorg.com', null, true);

        system.runAs(u) {
            List < Batch_Log__c > batchList = new List < Batch_Log__c > ();

            //Creating Batch Log records
            for (Integer i = 0; i < 3; i++) {
                Batch_Log__c b = testUtils.createBatchLog('test' + i + 1, false);
                b.RecordTypeId = Schema.SObjectType.Batch_Log__c.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
                b.Batch_Log_Status__c = 'Balanced';
                b.Deposit_Site__c = 'AK_Alaska';
                b.Batch_Type__c = 'Standard';
                b.Batch_Log_Type__c = 'Sustainer';
                b.Actual_Count__c = b.Expected_Count__c = 10;
                b.Actual_Amount__c = b.Expected_Amount__c = 100;
                b.Program_Type__c = String.valueOf(2 * i + 1);
                b.Batch_Date__c = Date.today();
                batchList.add(b);
            }
            insert batchList;

            Batch_Log__c bL1 = [SELECT Id, RecordTypeId from Batch_Log__c WHERE Id =: batchList[0].Id];
            system.debug('************' + bL1.RecordTypeId);

            //creating campaign records
            for (integer i = 0; i < 3; i++) {
                Campaign cm = testUtils.createCampaign('Test' + i, false);
                listCampaign.add(cm);
            }
            listCampaign[0].rC_Giving__Affiliation__c = 'NN';
            listCampaign[0].rC_Giving__Sub_Affiliation__c = '1 - National Union';
            listCampaign[1].rC_Giving__Affiliation__c = 'CD';
            listCampaign[1].rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation';
            listCampaign[2].rC_Giving__Affiliation__c = 'FN';
            listCampaign[2].rC_Giving__Sub_Affiliation__c = '3 - Affiliate Union';
            insert listCampaign;

            opptyRTMap = Schema.SObjectType.opportunity.getRecordTypeInfosByName();
            OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();

            //Creating Account Record
            Account acc = testUtils.createAccount('testacc', true);

            //Creating Opportunities
            List < Opportunity > oppParentList = new List < Opportunity > ();
            for (integer i = 0; i < 3; i++) {
                Opportunity oppParent = testUtils.createOpportunity(acc.id, 'testOpportunity' + i, false);
                oppParent.rC_Giving__Is_Sustainer__c = true;
                oppParent.CampaignId = listCampaign.get(i).id;
                oppParentList.add(oppParent);
            }
            insert oppParentList;

            for (integer i = 0; i < 3; i++) {
                Opportunity opp1 = testUtils.createOpportunity(acc.id, 'testOpportunity' + i, false);
                opp1.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
                opp1.rC_Giving__Parent__c = oppParentList[i].id;
                opp1.StageName = 'Completed';
                opp1.Program_Type__c = string.valueOf(2 * i + 1);
                opp1.Amount = 5000;
                opp1.rC_Connect__Response_Date_Time__c = Date.today().addDays(1);
                opp1.Deposit_Site__c = 'AK_Alaska';
                listOpportunity.add(opp1);
            }

            List < Opportunity > listOpp = new List < Opportunity > ();
            for (integer i = 0; i <= 3; i++) {
                listOpp.add(new Opportunity(name = 'testopp' + i, rC_Giving__Parent__c = oppParentList[0].id, RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, AccountId = acc.id, StageName = 'Completed', Program_Type__c = '1', Amount = 5000, deposit_site__c = 'AK_Alaska', rC_Connect__Response_Date_Time__c = Date.today().addDays(1), closeDate = System.today().addDays(1)));
            }
            for (integer i = 4; i <= 6; i++) {
                listOpp.add(new Opportunity(name = 'testopp' + i, rC_Giving__Parent__c = oppParentList[1].id, RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, AccountId = acc.id, StageName = 'Completed', Program_Type__c = '5', Amount = 5000, deposit_site__c = 'AK_Alaska', rC_Connect__Response_Date_Time__c = Date.today(), closeDate = System.today()));
            }

            insert listOpp;
        }
    }

    @isTest
    private static void TestCreatePledgePayment() {
        insert new Last_Run_Time_Of_Batch__c(Name = 'CreatePledgePaymentBatchLogs_Batch');
        createTestData();
        Test.startTest();
        Database.executebatch(new CreatePledgePaymentBatchLogs_Batch(True));
        Test.stopTest();

        //Verify the updated values
        Batch_Log__c b = [SELECT Actual_Count__c, Actual_Amount__c, Expected_Count__c, Expected_Amount__c FROM Batch_Log__c][0];
        system.assertEquals(14, b.Actual_Count__c);
        system.assertEquals(14, b.Expected_Count__c);
        system.assertEquals(20100.00, b.Actual_Amount__c);
        system.assertEquals(20100.00, b.Expected_Amount__c);
    }

    @isTest
    private static void TestCreatePledgePaymentForID() {
        Last_Run_Time_Of_Batch__c cc = Last_Run_Time_Of_Batch__c.getInstance('CreatePledgePaymentBatchLogs_Batch');
        createTestData();
        if (cc != null)
            delete cc;
        listOpportunity = [SELECT ID FROM Opportunity];
        Test.startTest();
        Id jobId = Database.executebatch(new CreatePledgePaymentBatchLogs_Batch(listOpportunity.get(0).id), 200);
        Test.stopTest();
        system.assert(jobId != null);
    }

    @isTest
    private static void TestExecute() {
        createTestData();
        listOpportunity = [SELECT Id, Name, Amount, rC_Giving__Affiliation__c,
            rC_Giving__Parent__r.rC_Giving__Is_Sustainer__c, rC_Connect__Response_Date_Time__c,
            StageName, rC_Giving__Parent__r.Campaign.Record_Sharing_Affiliate__c, Program_Type__c,
            Batch_Log__c, Deposit_Site__c FROM Opportunity
        ];

        Test.startTest();
        CreatePledgePaymentBatchLogs_Batch cpp1 = new CreatePledgePaymentBatchLogs_Batch(true);
        //cpp1.UN_COUNT = 100000;
        //cpp1.FN_COUNT = 100000;
        cpp1.execute(null, listOpportunity);
        Test.stopTest();

        //Verify the values updated
        Batch_Log__c b = [SELECT Actual_Count__c, Actual_Amount__c, Expected_Count__c, Expected_Amount__c FROM Batch_Log__c][0];
        system.assertEquals(14, b.Actual_Count__c);
        system.assertEquals(14, b.Expected_Count__c);
        system.assertEquals(20100.00, b.Actual_Amount__c);
        system.assertEquals(20100.00, b.Expected_Amount__c);
    }
}