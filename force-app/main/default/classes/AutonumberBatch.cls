/*
*
*Name  :  AutonumberBatch
*Author:  ACLU (David Reed)
*Date  :  Sept 07, 2017
*Purpose : To populate value in Account.Override_Account_Number__c/ Contact.Override_Contact_Number__c/ Opportunity.Override_Giving_Number__c 
*          from Account.Auto_Account_Number__c/ Contact.Auto_Contact_Number__c/ Opportunity.Auto_Giving_Number__c
*
*/
global class AutonumberBatch implements Database.Batchable<sObject>, Database.Stateful {

    private String sobjectName, accountIdField, autoNumberField, overrideField, externalIdField;
    private DateTime lastRunTime;
    private String customSettingName;
    global Boolean hasError;
    public AutonumberBatch(String obj, String idField, String anField, String overField, String extField) {
        sobjectName = obj;
        accountIdField = idField;
        autoNumberField = anField;
        overrideField = overField;
        externalIdField = extField;
        customSettingName = 'AutonumberBatch-'+sobjectName;
        lastRunTime = Last_Run_Time_Of_Batch__c.getInstance(customSettingName) != null 
                          && Last_Run_Time_Of_Batch__c.getValues(customSettingName).Last_Run_Time__c != null
                        ? Last_Run_Time_Of_Batch__c.getValues(customSettingName).Last_Run_Time__c.addDays(-1) 
                        : Date.Today();
        system.debug('lastRunTime::   '+lastRunTime);    
        hasError = false;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime daysAgo = lastRunTime.addDays(-1);
        system.debug('lastRunTime::   '+lastRunTime);
        system.debug('daysAgo::   '+daysAgo);
        return Database.getQueryLocator('SELECT ' + accountIdField + ', ' + autoNumberField + ' ' +
                                        'FROM ' + sobjectName + ' ' +
                                        'WHERE ' + externalIdField + ' = \'\' ' +
                                        'AND ' + overrideField + ' = \'\'' +
                                        'AND CreatedDate <= '+ lastRunTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'') +
                                        'AND CreatedDate >= '+ daysAgo.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'')
                                       );
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        Set<Id> scopeAcctIds = new Set<Id>();

        for(sObject a : scope) {
            Id actId = (Id)a.get(accountIdField);
            if (actId != null)  
                scopeAcctIds.add(actId);
        }

        // gets list of accounts that are in scope and being processed by bup
        Set<Id> bupAcctIds = new Set<Id>();
        for(rC_Connect__Batch_Upload__c bu : [
            SELECT id, rC_Connect__Batch_Upload_Status__c, rC_Connect__Batch_Upload_Account_Matched__c 
            FROM rC_Connect__Batch_Upload__c 
            WHERE rC_Connect__Batch_Upload_Status__c NOT IN ('Committed', 'Flagged')
                  AND rC_Connect__Batch_Upload_Account_Matched__c IN :scopeAcctIds]){
            bupAcctIds.add(bu.rC_Connect__Batch_Upload_Account_Matched__c);
        }
        
        List<sObject> toUpdate = new List<sObject>();

        for (sObject acc : scope) {
            if(!bupAcctIds.contains(acc.ID) ){
                acc.put(overrideField, String.valueOf(acc.get(autoNumberField)));
                toUpdate.add(acc); 
            } 
        }

        if (toUpdate.size() > 0) {
            List<Database.SaveResult> acResults = Database.update(toUpdate,false);
            Integer i = 0;
        
            set<String> messages; 
            apexLogHandler.apexLog log; 
            for (Database.SaveResult result : acResults) {
                messages = new set<String>();
                if (!result.isSuccess()){
                    for (Database.Error err : result.getErrors()){
                        if(!messages.contains(err.getMessage())) {
                            log = new apexLogHandler.apexLog('AutonumberBatch','execute',
                                                             'Record update failed : '
                                                             + toUpdate[i].id + '\n' + err.getMessage());
                            messages.add(err.getMessage());
                        }
                    }
                }
                i++;
            }
            if(log != null) {
                hasError = true;
                log.saveLogs();
            }
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        if(Last_Run_Time_Of_Batch__c.getInstance(customSettingName) == null) {
           Last_Run_Time_Of_Batch__c cs = new Last_Run_Time_Of_Batch__c(Name = customSettingName,
                                                                        Last_Run_Time__c=System.now());
           insert cs;
         }
         else {
           Last_Run_Time_Of_Batch__c cs = Last_Run_Time_Of_Batch__c.getInstance(customSettingName);
           cs.Last_Run_Time__c = system.now();
           update cs;
         }
         if(!hasError) {
             apexLogHandler.apexLog log = new apexLogHandler.apexLog('AutonumberBatch','finish','AutonumberBatch ran successfully on ' + system.now());
             log.saveLogs();
         }
    }
}