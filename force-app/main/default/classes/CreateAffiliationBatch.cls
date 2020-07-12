/*
*
*Name  :  CreateAffiliationsBatch
*Author:  Appirio India (Sai Krishna)
*Date  :  December 7, 2016
*Purpose : Batch Class to create/reset the affiliations for existing accounts when Is_Shared_Group__c = true
*
*/


global class CreateAffiliationBatch implements Database.Batchable<sObject>{
   global Database.QueryLocator start(Database.BatchableContext Bc ){
       return Database.getQueryLocator([select id, Is_Shared_Group__c, Affiliation__c, Restricted_Account__c FROM Account WHERE Is_Shared_Group__c = true AND Affiliation__c != null ]);


   }
   global void execute(Database.BatchableContext Bc, List<Account> scope){
       Map<Id,String> AccountIdToOldAffiliations = new Map<Id,String>();
       List<Account> accountsToBeUpdated = new List<Account>();
       for(Account a : scope){
           AccountIdToOldAffiliations.put(a.Id,a.Affiliation__c);
           a.Is_Shared_Group__c = false;
           accountsToBeUpdated.add(a);
       }

       if(!AccountIdToOldAffiliations.KeySet().IsEmpty()){
            RecordAccessUtility.resetAccountSharing(true,AccountIdToOldAffiliations);
       }

       if(!accountsToBeUpdated.IsEmpty()){
           try{
            update accountsToBeUpdated;
           } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('CreateAffiliationsBatch','','execute :: ' + e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
       }

   }
   global void finish(Database.BatchableContext Bc){
      apexLogHandler.apexLog log = new apexLogHandler.apexLog('CreateAffiliationsBatch','','CreateAffiliationsBatch FINISHED');
      log.saveLogs();
   }
}