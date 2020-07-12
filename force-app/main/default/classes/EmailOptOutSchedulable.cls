/*
*
*Name  :  EmailOptOutSchedulable
*Author:  ACLU (David Reed)
*Date  :  Sept 05, 2017
*Purpose : Schedulable class for EmailOptOutProcessorBatch
*
*/
global class EmailOptOutSchedulable implements Schedulable {
	global void execute(SchedulableContext sc) {
        Database.executeBatch(new EmailOptOutProcessorBatch());    
	}
}