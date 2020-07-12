/**
/*
*Name  :  UpdatePledgePaymentsSchedulerTest
*Author:  Kirti Rathod(Salesforce.com)
*Date  :  Nov 08, 2019
*Purpose : Test Class for UpdatePledgePaymentsSchedulerTest* 
 **/
 @isTest
public with sharing class UpdatePledgePaymentsSchedulerTest {
    @isTest public static void testPledgePayments() {
        List<Opportunity> oppList = new List<Opportunity>();
        Account a = testUtils.createAccount('test acc', true);
        String preAff = 'test';
        
        for(integer i=0;i<10;i++) {
           Opportunity opp = testUtils.createOpportunity(a.id, 'opp'+i, false);
           opp.Acknowledgment_Status__c = 'N - Not Acknowledged';
           opp.StageName = 'Pending - Retry';
           opp.rC_Connect__Charge_Attempts__c = 3;
           opp.rC_Giving__Acknowledged_Date__c = null;
           oppList.add(opp);
       }
        upsert oppList;
        UpdatePledgePaymentsScheduler updateSchedule = new UpdatePledgePaymentsScheduler();
        Test.startTest();
        String str = '0 0 23 * * ?'; 
        Id scheduleId = System.schedule('UpdatePledgePaymentsSchedulerTest', str, updateSchedule); 
        Test.stopTest(); 
        List<Opportunity> oppDuplicateList = [SELECT id FROM Opportunity Where StageName = 'Pending - Retry'];
        System.assertEquals(oppDuplicateList.size() > 0, true);
    }
}