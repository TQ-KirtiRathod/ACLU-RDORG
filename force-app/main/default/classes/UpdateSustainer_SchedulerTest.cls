/*
*
*Name  :  UpdateSustainer_SchedulerTest
*Author:  SFDO (Amar Kulkarni)
*Date  :  March 24, 2020
*Purpose : To Schedule rc giving's update sustainer batch
*/
@IsTest
public class UpdateSustainer_SchedulerTest {
	@isTest
    public static void scheduleSustainerJob() {
        Test.startTest();
        	new UpdateSustainer_Scheduler().execute(null);
        Test.stopTest();
    }
}