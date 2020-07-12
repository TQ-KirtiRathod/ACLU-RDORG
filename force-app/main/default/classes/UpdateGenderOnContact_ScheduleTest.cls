/*
*Author:  Appirio India 
*Date  :  October 
*Purpose : Test Coverage for UpdateGenderOnContact_Schedule Class
*/
@isTest
private class UpdateGenderOnContact_ScheduleTest {
	
	/* 
    *
    * Method testUpdateGenderOnContact_Schedule
    * Testing testUpdateGenderOnContact_Schedule functionality
    */
    private static testMethod void testUpdateGenderOnContact_Schedule(){
        UpdateGenderOnContact_Schedule updateSchedule = new UpdateGenderOnContact_Schedule();
        Test.startTest();
            String str = '0 0 23 * * ?'; 
            Id scheduleId = System.schedule('UpdateGenderOnContact_BatchTest', str, updateSchedule); 
        Test.stopTest(); 
    	System.assert(scheduleId != null);
    }
}