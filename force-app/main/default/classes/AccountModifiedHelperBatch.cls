/*
*
*Name  :  AccountModifiedHelperBatch
*Author:  ACLU (David Reed)
*Date  :  June 21, 2017
*Purpose : Batch class to set GOL_Current_Amount__c and HPC36_Amount__c from Account to Contact
*
*/
global class AccountModifiedHelperBatch implements Database.Batchable<sObject> {

	String query;

	global AccountModifiedHelperBatch() {
	}

	global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime lastRunTime;
        Last_Run_Time_Of_Batch__c lrt = Last_Run_Time_Of_Batch__c.getInstance('AccountModifiedHelperBatch');

        if (lrt != null) {
        	if (lrt.Last_Run_Time__c != null) {
        		lastRunTime = lrt.Last_Run_Time__c;
        	} else {
        		lastRunTime = System.now();
        	}

        	lrt.Last_Run_Time__c = System.now();
        	update lrt;
        } else {
            lrt = new Last_Run_Time_Of_Batch__c(Name = 'AccountModifiedHelperBatch', Last_Run_Time__c = System.now());
            insert lrt;
        }

        return Database.getQueryLocator([SELECT Id, HPC36_Amount__c, GOL_Current_Amount__c,
        									(SELECT Id, HPC36_Amount__c, GOL_Current_Amount__c FROM Contacts)
                                         FROM Account
                                         WHERE LastModifiedDate > :lastRunTime]);
	}

   	global void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<Contact> toUpdate = new List<Contact>();
        for (Account a : (List<Account>)scope) {
          for (Contact c : a.Contacts) {
            if (c.GOL_Current_Amount__c != a.GOL_Current_Amount__c
                || c.HPC36_Amount__c != a.HPC36_Amount__c) {
                c.GOL_Current_Amount__c = a.GOL_Current_Amount__c;
                c.HPC36_Amount__c = a.HPC36_Amount__c;
                toUpdate.add(c);
            }
          }
        }
        try {
	        if(!toUpdate.isEmpty())
	          update toUpdate;
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('AccountModifiedHelperBatch','execute',e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
	}

	global void finish(Database.BatchableContext BC) {

	}

}