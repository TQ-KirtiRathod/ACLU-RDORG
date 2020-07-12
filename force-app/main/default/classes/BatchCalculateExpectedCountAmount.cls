/*
*
*Name  :  BatchCalculateExpectedCountAmount
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  Feb 03, 2018
*Purpose : Batch Class to Calculate Expected Count and Amount on Batch Log
*          Class is called from a chain from MatchBatchLogViaBatchUpload_Batch
*
*/
global without sharing class BatchCalculateExpectedCountAmount implements Database.Batchable<sObject>{
    global set<Id> batchLogIds;
    String queryString; 
    global BatchCalculateExpectedCountAmount(set<Id> batchLogIdSet) {
        this.batchLogIds = batchLogIdSet;
        queryString = 'SELECT Id, Expected_Count__c,Expected_Amount__c ';
        queryString += 'FROM Batch_Log__c WHERE Id IN :batchLogIds'; 
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        set<Id> setBatchLogId = new Set<Id>();
        map<Id, Batch_Log__c> mapOfIdToBatchLog = new Map<Id, Batch_Log__c>();
        list<rC_Connect__Batch_Upload__c> batchUploads = [SELECT Id, rC_Connect__Giving_Giving_Amount__c, 
                                                             Batch_Log__c, Batch_Log__r.Expected_Amount__c, 
                                                             Batch_Log__r.Expected_Count__c
                                                          FROM rC_Connect__Batch_Upload__c 
                                                          WHERE Batch_Log__c IN: scope];
        for(rC_Connect__Batch_Upload__c bu :  batchUploads) {
            if(!setBatchLogId.contains(bu.Batch_Log__c)) {
                setBatchLogId.add(bu.Batch_Log__c);
                bu.Batch_Log__r.Expected_Amount__c = 0;
                bu.Batch_Log__r.Expected_Count__c = 0;
            }
              system.debug('before assignment' + bu.Batch_Log__r.Expected_Count__c);
            bu.Batch_Log__r.Expected_Amount__c = bu.Batch_Log__r.Expected_Amount__c + bu.rC_Connect__Giving_Giving_Amount__c;
            bu.Batch_Log__r.Expected_Count__c = Integer.ValueOf(bu.Batch_Log__r.Expected_Count__c) + 1;
            system.debug('after assignment' + bu.Batch_Log__r.Expected_Count__c);
            mapOfIdToBatchLog.put(bu.Batch_Log__c, bu.Batch_Log__r);
        } 
        try{
            update mapOfIdToBatchLog.values();
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchCalculateExpectedCountAmount','execute',e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
    }
    
    global void finish(Database.BatchableContext BC) {
    }
}