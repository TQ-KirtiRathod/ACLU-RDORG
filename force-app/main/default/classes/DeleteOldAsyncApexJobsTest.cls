/*
*
*Name  :  DeleteOldAsyncApexJobsTest
*Author:  Appirio India 
*Date  :  May 05,2017
*Purpose : To Test ScheduleDeleteJobs and DeleteOldAsyncApexJobs Classes functionality
*
*/
@isTest
public class DeleteOldAsyncApexJobsTest {
	
	/*
	*
	* Method confDataInsertTest 
	* Testing confidential data insert scenarios
	*/
    static testMethod void testDeleteOldAsyncApexJobs(){
        Test.startTest();
        	DeleteOldAsyncApexJobs.asyncJobCount();
        	Integer asyncJobRecs = [SELECT COUNT() FROM AsyncApexJob];
        	system.assertEquals(0, asyncJobRecs);
        Test.stopTest();
    }
    
    /*
	*
	* Method confDataInsertTest 
	* Testing confidential data insert scenarios
	*/
    public static testMethod void testschedule() 
    {
		Test.StartTest();
			ScheduleDeleteJobs sh1 = new ScheduleDeleteJobs();
			String sch = '0 0 23 * * ?'; 
	        Id scheduleId = system.schedule('test my ScheduleDeleteJobs', sch, sh1); 
	        
        	system.assert(scheduleId != null);
        Test.stopTest(); 
    }
}