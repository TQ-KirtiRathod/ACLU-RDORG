/*
*
*Name  :  BatchUpdateMergeNumberOnOpportunity
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  May 16, 2017
*Purpose : batch process populates opportunity Merge Job Number. batch is called from RunDrawloopPackagesController
*
*/
global class BatchUpdateMergeNumberOnOpportunity implements Database.Batchable<sObject>, Database.Stateful {
    global String mergeJobNumber;
    global set<Id> oppIdSet;
    global Boolean excludeRecords;
    global String primaryAffiliate;
    global BatchUpdateMergeNumberOnOpportunity(String mergeJobNum, set<Id> oppIds, Boolean exRecords, String prAffiliate) {
        mergeJobNumber = mergeJobNum;
        oppIdSet = oppIds;
        excludeRecords = exRecords;
        primaryAffiliate = prAffiliate;
    }
    
    global Database.QueryLocator start(Database.BatchableContext Bc){
        return Database.getQueryLocator([SELECT Id, Merge_Job_Number__c FROM Opportunity
                                            WHERE Id IN :oppIdSet]);
    }
    
    global void execute(Database.BatchableContext Bc, List<Opportunity> opportunitiesToUpdate){
        for(Opportunity opp : opportunitiesToUpdate) {
            opp.Merge_Job_Number__c = mergeJobNumber;
        }
        if(opportunitiesToUpdate.size() > 0){
            try{
                update opportunitiesToUpdate;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchUpdateMergeNumberOnOpportunity','execute',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }
    
    global void finish(Database.BatchableContext Bc){
        if(excludeRecords) {
            BatchUpdateStatusOnOpportunity nextBatch = new BatchUpdateStatusOnOpportunity(oppIdSet, primaryAffiliate);
            Database.executeBatch(nextBatch, 200); 
        }
    }
    
    
}