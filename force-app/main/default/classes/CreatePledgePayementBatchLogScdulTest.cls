/*
*
*Name  :  CreatePledgePayementBatchLogScdulTest
*Author:  Appirio India 
*Date  :  October 10,2017
*Purpose : To Test CreatePledgePaymentBatchLogs_Schedule Class functionality
*
*/
@isTest
private class CreatePledgePayementBatchLogScdulTest {
    @isTest
    public static void testschedule() {   			 
        		Test.StartTest();
       		    CreatePledgePaymentBatchLogs_Schedule sh1 = new CreatePledgePaymentBatchLogs_Schedule();
       		    
        		//Cron expression to set scheduled time
        		String sch = '0 0 23 * * ?'; 
        
        		//Class scheduled at given scheduled time time
        		String jobId = system.schedule('test my CreatePledgePaymentBatchLogs_Schedule', sch, sh1); 
        		Test.stopTest(); 
        		system.assert(jobId != null);
   			 }
}