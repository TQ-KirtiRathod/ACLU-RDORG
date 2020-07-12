/*
*
*Name  :  EmailOptOutProcessorBatch
*Author:  ACLU (David Reed)
*Date  :  June 27, 2017
*Purpose : Batch Class to set Opt_In on Emails.
*
*/
global without sharing class EmailOptOutProcessorBatch implements Database.Batchable<sObject> {	
	global EmailOptOutProcessorBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext bc) {
		// We order by modification time to ensure that the most recent change to an opt-in status for a particular 
		// email address takes effect in the final case.

		// Note that there's an edge case here - unrelated modification to an email object that had opted out later in the
		// same day that that email was initially opted out and later opted back in could result in only the opt-out going through.
		// This seems very unlikely in real-world use.

		return Database.getQueryLocator(
			[SELECT Id, Email_address__c, Opt_in__c
			 FROM Email__c
			 WHERE Opt_In_Status_Changed__c = true
			 ORDER BY SystemModStamp ASC]
 		);
	}

   	global void execute(Database.BatchableContext bc, List<sObject> scope) {
        EmailOptOutProcessor.processOptOutsForEmails((List<Email__c>)scope);
	}
	
	global void finish(Database.BatchableContext bc) {
		
	}
	
}