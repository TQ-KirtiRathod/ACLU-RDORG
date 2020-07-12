/*
*
*Name  :  AccountNewHelperBatch
*Author:  Appirio India (Shikha Gupta)
*Date  :  April 26, 2017
*Purpose : Batch Class to populate Acquisition_Source__c on Accounts
*
*/
global class AccountNewHelperBatch implements Database.Batchable<sObject>{
    global AccountNewHelperBatch() {
    }


    global Database.QueryLocator start(Database.BatchableContext Bc ){
        DateTime lastRunTime = Last_Run_Time_Of_Batch__c.getInstance('AccountNewHelperBatch') != null && Last_Run_Time_Of_Batch__c.getValues('AccountNewHelperBatch').Last_Run_Time__c != null?
            Last_Run_Time_Of_Batch__c.getValues('AccountNewHelperBatch').Last_Run_Time__c :
        Date.Today();
        if( Last_Run_Time_Of_Batch__c.getInstance('AccountNewHelperBatch') == null) {
            Last_Run_Time_Of_Batch__c cs = new Last_Run_Time_Of_Batch__c(Name = 'AccountNewHelperBatch',Last_Run_Time__c=System.now());
            insert cs;
        }
        else {
            Last_Run_Time_Of_Batch__c cs = Last_Run_Time_Of_Batch__c.getInstance('AccountNewHelperBatch');
            cs.Last_Run_Time__c = system.now();
            update cs;
        }
        lastRunTime = lastRunTime -2;  //subtract 2 more days
        return Database.getQueryLocator([SELECT Id, Acquisition_Source__c,(SELECT Id FROM Contacts)
                                         FROM Account
                                         WHERE CreatedDate >: lastRunTime
                                        ]);
    }

    global void execute(Database.BatchableContext Bc, List<Account> scope){
        //for BUP
        Set<Id> scopeAcctIds = new Set<Id>();
        for(Account a : scope){
            scopeAcctIds.add(a.ID);
        }

        //gets list of accounts that are in scope and being processed by bup
        List<rC_Connect__Batch_Upload__c> inProcessBatchUpload = new List<rC_Connect__Batch_Upload__c>();
        inProcessBatchUpload = [
           SELECT id, rC_Connect__Batch_Upload_Status__c, rC_Connect__Batch_Upload_Account_Matched__c 
           FROM rC_Connect__Batch_Upload__c 
           WHERE rC_Connect__Batch_Upload_Status__c NOT IN ('Committed', 'Flagged')
           AND rC_Connect__Batch_Upload_Account_Matched__c IN :scopeAcctIds];
        Set<Id> bupAcctIds = new Set<Id>();
        if(inProcessBatchUpload.size()>0){
          for(rC_Connect__Batch_Upload__c bu : inProcessBatchUpload){
            bupAcctIds.add(bu.rC_Connect__Batch_Upload_Account_Matched__c);
          }
        }
        //End BUP

        List<Account> listOfAccountsToProcess = new List<Account>();
        for(Account acc : scope) {
            if(!bupAcctIds.contains(acc.ID) ){
                if(acc.Acquisition_Source__c == null) {
                    listOfAccountsToProcess.add(acc); 
                }
            } else {
                //system.debug('skipped account id:: '+acc.ID);
            }
        }
        List<Account> listOfUpdatedAccounts = AccountConstituentUpdater.updateAcquisitonSourceOnAccounts(listOfAccountsToProcess);
        if(!listOfUpdatedAccounts.IsEmpty()){
            try{
                update listOfUpdatedAccounts;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('AccountNewHelperBatch','execute',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
        
    }

    global void finish(Database.BatchableContext Bc){
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('AccountNewHelperBatch FINISHED');
        log.saveLogs();
    }
}