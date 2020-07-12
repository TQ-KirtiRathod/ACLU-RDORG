/*
*
*Name  :  WarmCacheForSomeReports
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  Mar 06, 2018
*Purpose : Batch Class to Iterate over a list of opportunities to build cache. Currently not being used
*
*/
global class WarmCacheForSomeReports implements Database.Batchable<sObject> {
    global Date sinceDate;
    global WarmCacheForSomeReports(Date sinceDate) {
        this.sinceDate = sinceDate;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
        String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
        String OPPORTUNITY_RT_SOFTCREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
        set<Id> setOfValidRecordTypes = new set<Id>{OPPORTUNITY_RT_TRANSACTION_Id,OPPORTUNITY_RT_PLEDGE_PAYMENT_Id,OPPORTUNITY_RT_SOFTCREDIT_Id};
        return Database.getQueryLocator([SELECT Id, Amount, accountId, Sharing_Entity_Affiliation__c, Program_Type__c,
                                         Exclude_Cost_Factors_in_RevShare__c, Exclude_from_Revenue_Sharing__c,
                                         Sharing_Entity__c, Sharing_Code__c, Cost_Factor__c,
                                         Use_Campaign_Cost__c, CloseDate, Account_Affiliation__c, Deposit_Site__c
                                         FROM Opportunity
                                         WHERE RecordTypeId IN :setOfValidRecordTypes
                                         AND stageName = 'Completed'
                                         AND CloseDate >=: sinceDate]);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        for(Opportunity opp:(list<Opportunity>)scope){ 
            //To do nothing
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        Datetime dt = System.now();
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('WarmCacheForSomeReports DONE at: ' + dt );
        log.saveLogs();
    }
}