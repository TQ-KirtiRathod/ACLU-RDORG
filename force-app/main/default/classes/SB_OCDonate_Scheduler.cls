/*
*
*Name  :  SB_OCDonate_Scheduler
*Author:  Joel Rothschild
*Date  :  Feb 17, 2017
*Purpose : Schedulable class for SB_OCDonate_Batch
*
*/
global class SB_OCDonate_Scheduler implements Schedulable {
	
	global void execute(SchedulableContext sc) {
		SB_OCDonate_Batch ocdBatch = new SB_OCDonate_Batch();
		Database.executeBatch(ocdBatch, 2000);
	}
}