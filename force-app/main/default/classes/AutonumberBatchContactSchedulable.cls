/*
*
*Name  :  AutonumberBatchContactSchedulable
*Author:  ACLU (David Reed)
*Date  :  2017
*Purpose : Scheduler class for AutonumberBatch for the object Contact.
*
*/
global class AutonumberBatchContactSchedulable implements Schedulable {
	global void execute(SchedulableContext sc) {

    Database.executeBatch(new AutonumberBatch('Contact', 'AccountId', 'Auto_Contact_Number__c', 
                                              'Override_Contact_Number__c', 'External_Id__c'), 50);

	}
}