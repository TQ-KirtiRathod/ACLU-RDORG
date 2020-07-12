/*
 *
 *Name  :  LimitsHistoryUtilitiesTEST
 *Author:  Appirio India 
 *Date  :  October 11,2017
 *Purpose : To Test LimitsHistoryUtilities Class functionality
 *
 */
@isTest
private class LimitsHistoryUtilitiesTEST {

    @isTest
    static void testLimitsHistoryUtilities() {

        //Verify that the following values are not null in the class LimitsHistoryUtilities
        System.assertNotEquals(null, LimitsHistoryUtilities.shouldRunDailySnapshots);
        System.assertNotEquals(null, LimitsHistoryUtilities.shouldRunHourlySnapshots);
        System.assertNotEquals(null, LimitsHistoryUtilities.shouldRotateLogs);
        System.assertNotEquals(null, LimitsHistoryUtilities.dailyLogsRetentionDays);
        System.assertNotEquals(null, LimitsHistoryUtilities.hourlyLogsRetentionDays);
        System.assertNotEquals(null, LimitsHistoryUtilities.dailyCronString);
        System.assertNotEquals(null, LimitsHistoryUtilities.hourlyCronString);

        //Test data updated for testing
        LimitsHistoryUtilities.configuration.Rotate_Logs__c = false;
        LimitsHistoryUtilities.configuration.Take_Daily_Snapshots__c = false;
        LimitsHistoryUtilities.configuration.Take_Hourly_Snapshots__c = false;
        LimitsHistoryUtilities.configuration.Retention_Daily_Snapshots__c = 1.0;
        LimitsHistoryUtilities.configuration.Retention_Hourly_Snapshots__c = 1.0;
        LimitsHistoryUtilities.configuration.Daily_Cron_String__c = 'TEST1';
        LimitsHistoryUtilities.configuration.Hourly_Cron_String__c = 'test2';

        //Verify the updated values based on test data updates
        System.assert(!LimitsHistoryUtilities.shouldRunDailySnapshots);
        System.assert(!LimitsHistoryUtilities.shouldRunHourlySnapshots);
        System.assert(!LimitsHistoryUtilities.shouldRotateLogs);
        System.assertEquals(1, LimitsHistoryUtilities.dailyLogsRetentionDays);
        System.assertEquals(1, LimitsHistoryUtilities.hourlyLogsRetentionDays);
        System.assertEquals('TEST1', LimitsHistoryUtilities.dailyCronString);
        System.assertEquals('test2', LimitsHistoryUtilities.hourlyCronString);

    }
}