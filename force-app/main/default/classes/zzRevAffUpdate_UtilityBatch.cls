/*
*
*Name  :  zzRevAffUpdate_UtilityBatch
*Author:  Appirio India (Bhavesh Malviya)
*Date  :  May 08, 2018
*Purpose : Batch class to populate Revenue_Affiliation__c on Opportunity. Used for Data Fix
*
*/
global class zzRevAffUpdate_UtilityBatch implements Database.Batchable<sObject>,Database.stateful {

    private static final String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
  private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
  private static final String OPPORTUNITY_RT_SOFTCREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
  
  public Date startDate_CMI = Date.parse(Label.PatchUtilityStartDate);
  public Date endDate_CMI = Date.parse(Label.PatchUtilityEndDate);


    global zzRevAffUpdate_UtilityBatch() {

    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Set<String> setOfValidRecordTypes = new Set<String> { OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, OPPORTUNITY_RT_SOFTCREDIT_Id, OPPORTUNITY_RT_TRANSACTION_Id};
        return Database.getQueryLocator([SELECT Id, Revenue_Affiliation__c, CloseDate, Sharing_Entity_Affiliation__c, Account_Affiliation__c, Sharing_Entity__c, AccountId
                                     FROM Opportunity
                                     WHERE RecordTypeId IN :setOfValidRecordTypes
                                     AND stageName = 'Completed'
                                     AND CloseDate >=: startDate_CMI
                                     AND CloseDate <=: endDate_CMI
                                     AND Adjustment_Code__c IN ('N','D')
                                    ]);
    }

  global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        set<Id> acctIdInScope = new set<Id>();
        Opportunity[] oppsToUpdate = new list<Opportunity>();
        List<Database.SaveResult> srUpOpp;
        for(Opportunity theOpp : scope){

            if(acctIdInScope.contains(theOpp.AccountId)){
                continue;
            } else {
                acctIdInScope.add(theOpp.AccountId);
            }

            if(String.isNotBlank(theOpp.Revenue_Affiliation__c) && theOpp.Revenue_Affiliation__c != 'ER') continue;


            if(  theOpp.Sharing_Entity_Affiliation__c == theOpp.Account_Affiliation__c
                || theOpp.Sharing_Entity_Affiliation__c == 'NA'){

                theOpp.Revenue_Affiliation__c = theOpp.Account_Affiliation__c;
                oppsToUpdate.add(theOpp);

            } else if(  theOpp.Sharing_Entity_Affiliation__c != theOpp.Account_Affiliation__c
                       || theOpp.Sharing_Entity_Affiliation__c != 'NA'){

                theOpp.Revenue_Affiliation__c = theOpp.Sharing_Entity_Affiliation__c;
                oppsToUpdate.add(theOpp);
            }
        }

        
        if(!oppsToUpdate.isEmpty()){
            srUpOpp = Database.update( oppsToUpdate, false );
            Utilities.processResults(srUpOpp, oppsToUpdate,  'zzRevAffUpdate_UtilityBatch','', 
                               'zzRevAffUpdate_UtilityBatch error::  ' );
        }

    }

    global void finish(Database.BatchableContext BC) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('zzRevAffUpdate_UtilityBatch DONE');
        //log.logException(e);
        log.saveLogs();
    }

}