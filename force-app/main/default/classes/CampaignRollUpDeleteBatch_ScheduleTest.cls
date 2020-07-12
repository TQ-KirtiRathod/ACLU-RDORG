//
// (c) 2018 Appirio, Inc.
//
// Test class for Scheduler Class of CampaignRollUpDeleteBatch
//
// Aashita Sharma (Appirio) Original
//
@isTest
private class CampaignRollUpDeleteBatch_ScheduleTest {
 public static List<Opportunity_Start_End_Date_To_Process__c> listStartEndToDate;
  private static testMethod void testCampaignRollUpDeleteBatch_Schedule() {
        Test.startTest();
         listStartEndToDate= new List<Opportunity_Start_End_Date_To_Process__c>();
        Opportunity_Start_End_Date_To_Process__c oppc= TestUtils.createOpptyStartEndProcess('CloseDate', Date.today(), Date.today()+5, false);
        listStartEndToDate.add(oppc);
        
        Opportunity_Start_End_Date_To_Process__c oppc1 = TestUtils.createOpptyStartEndProcess('Tax_Date__c', Date.today(), Date.today()+6, false);
        listStartEndToDate.add(oppc1);
        
        Opportunity_Start_End_Date_To_Process__c oppc2 = TestUtils.createOpptyStartEndProcess('Run Range', Date.today(), Date.today()+7, false);
        listStartEndToDate.add(oppc2);
        
        Opportunity_Start_End_Date_To_Process__c oppc3 = TestUtils.createOpptyStartEndProcess('rC_Giving__Contract_Date__c', Date.today(), Date.today()+7, false);
        listStartEndToDate.add(oppc3);
        
        insert listStartEndToDate;
            String sch = '0 0 * * * ?';
            String jobID = system.schedule('Test', sch,  new CampaignRollUpDeleteBatch_Schedule());
            CronTrigger ct = [  SELECT ID, CronExpression
                                FROM CronTrigger 
                                WHERE id = :jobID];
            system.assertEquals(sch, ct.CronExpression);
        Test.stopTest();
  }
}