/*
*
*Name  :  AutonumberBatchOppSchedulable
*Author:  ACLU (David Reed)
*Date  :  2017
*Purpose : Scheduler class for AutonumberBatch for the object Opportunity.
*
*/
global class AutonumberBatchOppSchedulable implements Schedulable {
	global void execute(SchedulableContext sc) {

    Database.executeBatch(new AutonumberBatch('Opportunity', 'AccountId', 'Auto_Giving_Number__c', 
                                              'Override_Giving_Number__c', 'External_Id__c'), 50);
	}
}