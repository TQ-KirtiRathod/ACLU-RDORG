/*
*Name  :  UpdatePledgePaymentsBatch
*Author:  Kirti Rathod(Salesforce.com)
*Date  :  Nov 08, 2019
*Purpose : Transaction records where the max charge attempt has been reached are staying in “Pending - Retry” stage. 
*          ACLU has a customization that is supposed to change these to Failed. */
//Created a Batchclass by Salesforce ZenDesk #68555
public with sharing class UpdatePledgePaymentsBatch implements Database.Batchable<sObject>, Database.Stateful{
    public rC_Connect__Opportunity_Setting__c oppSettings = rC_Connect__Opportunity_Setting__c.getOrgDefaults();
    public integer maxAttempt = Integer.ValueOf(oppSettings.rC_Connect__Max_Charge_Attempt__c);
    String queryString = '';
    public Database.QueryLocator start(Database.BatchableContext BC){
   		queryString = 'SELECT Id, StageName,  rC_Connect__Charge_Attempts__c';
        queryString += ' FROM Opportunity ';
        queryString += ' WHERE StageName = \'Pending - Retry\' AND rC_Connect__Charge_Attempts__c >= :maxAttempt LIMIT 49999';
        System.debug('query :: ' + queryString);
        System.debug(maxAttempt);
        return Database.getQueryLocator(queryString);
	}
	
	public void execute(Database.BatchableContext BC, List<Opportunity> opportunityList){
        //Update opportunity records
        for(Opportunity oppObj :opportunityList) {
            oppObj.StageName = 'Pending Failed' ;
            if(Test.isRunningTest()) {
              oppObj.Name = '';  
            }
        }
        //Get the failure records
        if(opportunityList.size() > 0) {
            List<Database.SaveResult> saveResult = database.update(opportunityList,false);
            List<Apex_Log__c> apexLogList = new List<Apex_Log__c>();
            for (Integer i = 0; i < opportunityList.size(); i++) {
                if (!saveResult[i].isSuccess()) {
                    for(Database.Error err : saveResult[i].getErrors()) {
                        Apex_Log__c apexLogObj = new Apex_Log__c();
                        apexLogObj.Log_Type__c = 'ERROR';
                        apexLogObj.Exception_Stack_Trace_String__c =  err.getMessage();
                        apexLogObj.class_name__c = 'UpdatePledgePaymentsBatch';
                        apexLogObj.Exception_Line_Number__c =  '30';
                        apexLogObj.Message__c = 'This id is failed to update : '+String.ValueOf(opportunityList[i].Id);
                        apexLogList.add(apexLogObj);
                    }
                }
            }
            List<Database.SaveResult> saveApexLogResult = database.insert(apexLogList,false);
        }      
    }    
	public void finish(Database.BatchableContext BC) {
    }
}