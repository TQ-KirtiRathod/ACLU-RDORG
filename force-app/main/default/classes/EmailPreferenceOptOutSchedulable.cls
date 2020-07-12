/*
*
*Name  :  EmailPreferenceOptOutSchedulable
*Author:  ACLU (David Reed)
*Date  :  Oct 05, 2017
*Purpose : Schedulable class for EmailPreferenceOptOutProcessorBatch
*
*/global class EmailPreferenceOptOutSchedulable implements Schedulable {
	global void execute(SchedulableContext sc) {
		Database.executeBatch(new EmailPreferenceOptOutProcessorBatch());
	}
}