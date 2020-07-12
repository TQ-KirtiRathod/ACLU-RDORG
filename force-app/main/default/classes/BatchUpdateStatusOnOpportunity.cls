//
// (c) 2016 Appirio, Inc.
//
// Batch script
//
// 16 May 2017       Gagandeep Kaur (Appirio) Original I-273541
// Batch process updates Opportunity Acknowledgement Status to B - Manually Bypassed From Acknowledgements
//
global class BatchUpdateStatusOnOpportunity implements Database.Batchable<sObject>, Database.Stateful {
    global set<Id> oppIdSet;
    //global Boolean excludeRecords;
    global String primaryAffiliate;
    global BatchUpdateStatusOnOpportunity(set<Id> oppIds, String prAffiliate) {
        oppIdSet = oppIds;
        //excludeRecords = exRecords;
        primaryAffiliate = prAffiliate.subString(0,2) + ' %';
    }
    
    global Database.QueryLocator start(Database.BatchableContext Bc){
       
        return Database.getQueryLocator([SELECT Id, Acknowledgment_Status__c FROM Opportunity 
                                                    WHERE Acknowledgment_Code__c LIKE :primaryAffiliate
                                                    AND Acknowledgment_Status__c = 'N - Not Acknowledged'
                                                    AND rC_Giving__Acknowledged_Date__c = null
                                                    AND StageName = 'Completed'
                                                    AND id Not In :oppIdSet]);
    }
    
    global void execute(Database.BatchableContext Bc, List<Opportunity> opportunitiesToUpdate){
        for(Opportunity opp : opportunitiesToUpdate) {
            opp.Acknowledgment_Status__c = 'B - Manually Bypassed From Acknowledgements';
        } 
        try{
            update opportunitiesToUpdate;
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUpdateStatusOnOpportunity','execute',e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
    }
    
    global void finish(Database.BatchableContext Bc){
        //system.debug('end primaryAffiliate  ' + primaryAffiliate);
    }
}