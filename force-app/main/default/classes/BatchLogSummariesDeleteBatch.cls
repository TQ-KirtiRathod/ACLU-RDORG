/*
*
*Name  :  BatchLogSummariesDeleteBatch
*Author:  Appirio India (Sai Krishna )
*Date  :  February 17, 2017
*Purpose : Batch class deletes the BatchLogSummary records.For each report Cash Receipt run the records are deleted and recreated 
*
*/

global with sharing class BatchLogSummariesDeleteBatch implements Database.Batchable<sObject>,Database.stateful{
	
	private List<Batch_Log_Summary__c> batchLogSummaries;
	private Date startDate;
	private Date endDate;
	private String selectedReportType;
	
	
	global BatchLogSummariesDeleteBatch(Date startDate, Date endDate, String selectedReportType) {
		batchLogSummaries = new List<Batch_Log_Summary__c>();
		this.startDate = startDate;
		this.endDate = endDate;
		this.selectedReportType = selectedReportType;
	}
    global Database.QueryLocator start(Database.BatchableContext Bc ){
    	return Database.getQueryLocator([SELECT Id FROM Batch_Log_Summary__c ]);
    }
    
    global void execute(Database.BatchableContext Bc, List<Batch_Log_Summary__c> scope){
        batchLogSummaries = new List<Batch_Log_Summary__c>();
        
    	for(Batch_Log_Summary__c obj: scope){
    		batchLogSummaries.add(obj);    		
    	}
    	
    	if(!batchLogSummaries.IsEmpty()){
            try{
            Delete batchLogSummaries;
            database.emptyRecycleBin(batchLogSummaries);
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchLogSummariesDeleteBatch','Execute',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }                   
        }
    }
    
    global void finish(Database.BatchableContext Bc){
    	Database.executeBatch(new Batch_SummaryReportGenerations(startDate, endDate, selectedReportType),1);
    }
}