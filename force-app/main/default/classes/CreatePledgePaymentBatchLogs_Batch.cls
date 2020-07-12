/*
*
*Name  :  CreatePledgePaymentBatchLogs_Batch
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  January 24, 2017
*Purpose :  Batch Class to create Sustainer Pledge Payment Batch Logs Records.
            Sustainer Pledge Payment records are querried, Batch Log records are querried, new Batch Logs are created when count exceeds 1000
            Pledge Payment records a are updated with Batch Log reference, actual and expected counts are updated on batch log"
*
*/
global without sharing Class CreatePledgePaymentBatchLogs_Batch implements Database.Batchable<sObject>, Database.Stateful {
    
    global String queryString; 
    global Date PRIOR_DATE, PRIOR_DAYS;
    global static Map<String,Schema.RecordTypeInfo> opptyRTMap;
    global static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
    global static final Set<String> setOfProgrmTypes = new Set<String>{'1','2','3','4','5'};
    global static final Set<String> unProgramTypes = new Set<String>{'1','2','3'};
    global static final Set<String> fnProgramTypes = new Set<String>{'4'};
    global static DateTime lastRunTime;
    global static One_Time_Run_Batch__c oneTimeRun;
    global Boolean runBasedOnOneTimeSetting;
    global Id VENDOR_RCD_TYPE_ID = Schema.Sobjecttype.Batch_Log__c.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
    
    static {
      opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
      OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
          lastRunTime = Last_Run_Time_Of_Batch__c.getInstance('CreatePledgePaymentBatchLogs_Batch') != null 
                          && Last_Run_Time_Of_Batch__c.getValues('CreatePledgePaymentBatchLogs_Batch').Last_Run_Time__c != null
                        ? Last_Run_Time_Of_Batch__c.getValues('CreatePledgePaymentBatchLogs_Batch').Last_Run_Time__c 
                        : Date.Today();
          oneTimeRun = One_Time_Run_Batch__c.getInstance('CreatePledgePaymentBatchLogs_Batch');
    }
    
    global CreatePledgePaymentBatchLogs_Batch(Boolean runBasedOnLastExecutedDate) {
        runBasedOnOneTimeSetting = false;
        PRIOR_DATE = System.today() - 3;
        PRIOR_DAYS = System.today() - 3;
        queryString = 'Select Id, Name, Amount, rC_Giving__Affiliation__c, rC_Giving__Parent__r.rC_Giving__Is_Sustainer__c,';
        queryString += ' rC_Connect__Response_Date_Time__c, Batch_Log__c, Program_Type__c, StageName, Deposit_Site__c,'; 
        queryString += ' rC_Giving__Parent__r.Campaign.Record_Sharing_Affiliate__c ';
        queryString += ' From Opportunity';
        queryString += ' WHERE RecordTypeId =: OPPORTUNITY_RT_PLEDGE_PAYMENT_Id ';
        //I-318823
        if(oneTimeRun != null && oneTimeRun.Run_Based_On_Date_Field__c && oneTimeRun.Close_Date_Start__c != null) {
            DateTime cDate = DateTime.newInstance(oneTimeRun.Close_Date_Start__c.year(), oneTimeRun.Close_Date_Start__c.month(), oneTimeRun.Close_Date_Start__c.day());
            queryString += ' AND CloseDate >= '+cDate.format('yyyy-MM-dd');
            runBasedOnOneTimeSetting = true;
            if(oneTimeRun.Close_Date_End__c != null) {
                DateTime cDate1 = DateTime.newInstance(oneTimeRun.Close_Date_End__c.year(), oneTimeRun.Close_Date_End__c.month(), oneTimeRun.Close_Date_End__c.day());
                queryString += ' AND CloseDate <= '+cDate1.format('yyyy-MM-dd');
            }
        } else {
            queryString += ' AND (LastModifiedDate > '+lastRunTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'')+' OR LastModifiedDate >: PRIOR_DAYS)';
        }
        queryString += ' AND StageName = \'Completed\'';
        //removed I-312901
        queryString += ' AND Batch_Log__c = null';
        //queryString += ' AND Deposit_Site__c != null';
    }
    
    global CreatePledgePaymentBatchLogs_Batch(Id opptyId) {
        runBasedOnOneTimeSetting = false;
        PRIOR_DATE = System.today() - 5;
        PRIOR_DAYS = System.today() - 5;
        queryString = 'Select Id, Name, Amount, rC_Giving__Affiliation__c, rC_Giving__Parent__r.rC_Giving__Is_Sustainer__c,';
        queryString += ' rC_Connect__Response_Date_Time__c, Batch_Log__c, Program_Type__c, StageName, Deposit_Site__c,'; 
        queryString += ' rC_Giving__Parent__r.Campaign.Record_Sharing_Affiliate__c';
        queryString += ' From Opportunity';
        queryString += ' WHERE RecordTypeId =: OPPORTUNITY_RT_PLEDGE_PAYMENT_Id ';
        //I-318823
        if(oneTimeRun != null && oneTimeRun.Run_Based_On_Date_Field__c && oneTimeRun.Close_Date_Start__c != null) {
            DateTime cDate = DateTime.newInstance(oneTimeRun.Close_Date_Start__c.year(), oneTimeRun.Close_Date_Start__c.month(), oneTimeRun.Close_Date_Start__c.day());
            queryString += ' AND CloseDate >= '+cDate.format('yyyy-MM-dd');
            runBasedOnOneTimeSetting = true;
            if(oneTimeRun.Close_Date_End__c != null) {
                DateTime cDate1 = DateTime.newInstance(oneTimeRun.Close_Date_End__c.year(), oneTimeRun.Close_Date_End__c.month(), oneTimeRun.Close_Date_End__c.day());
                queryString += ' AND CloseDate <= '+cDate1.format('yyyy-MM-dd');
            }
        } else {
            queryString += ' AND (LastModifiedDate > '+lastRunTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'')+' OR LastModifiedDate >=: PRIOR_DAYS)';
        }
        queryString += ' AND Id = '+'\''+opptyId+'\'';
        queryString += ' and StageName = \'Completed\'';
        //queryString += ' AND (Id = \'0060j0000092Jiw\' OR Id = \'0060j0000092Jj1\' OR Id = \'0060j0000092Jj6\' OR Id = \'0060j0000092JjB\')';
        //removed I-312901
        queryString += ' AND Batch_Log__c = null';
        //queryString += ' AND Deposit_Site__c != null';

    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Opportunity> opptyToUpdateLst = new List<Opportunity>();
        String uniqueLogKey = '';
        String prgmType = '';   
        Map<String, Batch_Log__c> batchLogGroup = new Map<String, Batch_Log__c>();
        Map<String, List<Opportunity>> batchLogGroupSet = new Map<String, List<Opportunity>>();
        List<Batch_Log__c> batchLogsToInsert = new List<Batch_Log__c>();
        Map<Id, Batch_Log__c> batchLogsLst = new Map<Id, Batch_Log__c>();
        
        for(Batch_Log__c objLog : [ SELECT  Id, Deposit_Site__c, Batch_Date__c, Expected_Count__c,
                                            Expected_Amount__c, Batch_Log_Status__c, Program_Type__c,
                                            Actual_Count__c, Actual_Amount__c//, Response_Date__c
                                    FROM    Batch_Log__c
                                    WHERE   Batch_Log_Status__c = 'Balanced'
                                    AND     Deposit_Site__c != null 
                                    AND     Batch_Date__c != null  
                                    //AND       Response_Date__c != null
                                    AND     Batch_Type__c = 'Standard'
                                    AND     RecordTypeId =: VENDOR_RCD_TYPE_ID
                                    AND     Batch_Log_Type__c = 'Sustainer'
                                    AND     Program_Type__c IN: setOfProgrmTypes
                                    AND     Actual_Count__c < 10000]) {
            if(unProgramTypes.contains(objLog.Program_Type__c)) {
                uniqueLogKey = 'UN'+'-'+objLog.Deposit_Site__c+'-'+objLog.Batch_Date__c.year()
                                +objLog.Batch_Date__c.month() +objLog.Batch_Date__c.day();
            } else if(fnProgramTypes.contains(objLog.Program_Type__c)) {
                uniqueLogKey = 'FN'+'-'+objLog.Deposit_Site__c+'-'+objLog.Batch_Date__c.year()
                                +objLog.Batch_Date__c.month()+objLog.Batch_Date__c.day();
            } else if(objLog.Program_Type__c == '5') {
                uniqueLogKey = objLog.Deposit_Site__c.substring(0,2)+'-'+objLog.Deposit_Site__c+'-'
                                +objLog.Batch_Date__c.year()+objLog.Batch_Date__c.month()+objLog.Batch_Date__c.day();
            }     
            
            if(!batchLogGroup.containsKey(uniqueLogKey)) {
                batchLogGroup.put(uniqueLogKey, objLog);
            }
        }
        for(Opportunity objOppty : (List<Opportunity>)scope) {
          prgmType = '';
          Date responseDate = objOppty.rC_Connect__Response_Date_Time__c != null ? Date.newInstance(objOppty.rC_Connect__Response_Date_Time__c.year(),objOppty.rC_Connect__Response_Date_Time__c.month(),
                    objOppty.rC_Connect__Response_Date_Time__c.day()): null;
          if(objOppty.rC_Giving__Parent__r.rC_Giving__Is_Sustainer__c && objOppty.StageName == 'Completed'
                  && (setOfProgrmTypes.contains(objOppty.Program_Type__c))
                  && ((runBasedOnOneTimeSetting && objOppty.rC_Connect__Response_Date_Time__c != null) 
                  ||  responseDate > PRIOR_DATE)
                  //added I-312901
                  && String.isBlank(objOppty.Batch_Log__c)
                  && !String.isBlank(objOppty.Deposit_Site__c)
            ) { 
             prgmType = objOppty.Program_Type__c.substring(0,1);        
             String uniqueKey = unProgramTypes.contains(prgmType) 
                                ? 'UN'+'-'+objOppty.Deposit_Site__c+'-'+objOppty.rC_Connect__Response_Date_Time__c.year()
                                   +objOppty.rC_Connect__Response_Date_Time__c.month()
                                   +objOppty.rC_Connect__Response_Date_Time__c.day()
                                : (fnProgramTypes.contains(prgmType) 
                                ?'FN'+'-'+objOppty.Deposit_Site__c+'-'
                                   +objOppty.rC_Connect__Response_Date_Time__c.year()
                                   +objOppty.rC_Connect__Response_Date_Time__c.month()
                                   +objOppty.rC_Connect__Response_Date_Time__c.day()
                                : objOppty.Deposit_Site__c.substring(0,2)+'-'+objOppty.Deposit_Site__c+'-'
                                  +objOppty.rC_Connect__Response_Date_Time__c.year()
                                  +objOppty.rC_Connect__Response_Date_Time__c.month()
                                  +objOppty.rC_Connect__Response_Date_Time__c.day());
             if(batchLogGroup.containsKey(uniqueKey) && batchLogGroup.get(uniqueKey).Actual_Count__c < 10000) {
                objOppty.Batch_Log__c = batchLogGroup.get(uniqueKey).Id;
                opptyToUpdateLst.add(objOppty);
                batchLogGroup.get(uniqueKey).Actual_Count__c = batchLogGroup.get(uniqueKey).Actual_Count__c != null 
                                                               ? batchLogGroup.get(uniqueKey).Actual_Count__c + 1 : 1;
                batchLogGroup.get(uniqueKey).Actual_Amount__c = batchLogGroup.get(uniqueKey).Actual_Amount__c != null 
                                                               ? batchLogGroup.get(uniqueKey).Actual_Amount__c + objOppty.Amount 
                                                               : objOppty.Amount;
                batchLogGroup.get(uniqueKey).Expected_Count__c = batchLogGroup.get(uniqueKey).Actual_Count__c;
                batchLogGroup.get(uniqueKey).Expected_Amount__c = batchLogGroup.get(uniqueKey).Actual_Amount__c;
                if(batchLogGroup.get(uniqueKey).Batch_Log_Status__c != 'Balanced') {
                    batchLogGroup.get(uniqueKey).Batch_Log_Status__c = 'Balanced';
                }
                batchLogsLst.put(batchLogGroup.get(uniqueKey).Id, batchLogGroup.get(uniqueKey));
                
             } else {
                if(!batchLogGroupSet.containsKey(uniqueKey)) {
                    batchLogGroupSet.put(uniqueKey, new List<Opportunity>());
                }
                batchLogGroupSet.get(uniqueKey).add(objOppty);
             }
             //set Batch Date and Bank Date from Response Date Time - I-318823
             objOppty.Batch_Date__c = responseDate;
             objOppty.Bank_Date__c = responseDate;
          }    
        }
         
        if(batchLogGroupSet != null && !batchLogGroupSet.isEmpty()) {
            for(String key : batchLogGroupSet.keySet()) {
                Batch_Log__c objLog = new Batch_Log__c();
                objLog.Batch_Log_Type__c = 'Sustainer';
                objLog.Batch_Log_Status__c = 'Open';
                objLog.RecordTypeId = VENDOR_RCD_TYPE_ID; 
                objLog.Batch_Type__c = 'Standard';
                objLog.Program_Type__c = batchLogGroupSet.get(key)[0].Program_Type__c.substring(0,1);
                //objLog.Batch_Date__c = system.today();
                objLog.Deposit_Site__c = batchLogGroupSet.get(key)[0].Deposit_Site__c;
                objLog.Batch_Date__c = Date.newInstance(batchLogGroupSet.get(key)[0].rC_Connect__Response_Date_Time__c.year(),
                                        batchLogGroupSet.get(key)[0].rC_Connect__Response_Date_Time__c.month(),
                                        batchLogGroupSet.get(key)[0].rC_Connect__Response_Date_Time__c.day());
                //objLog.Batch_Date__c = Date.ValueOf(batchLogGroupSet.get(key)[0].rC_Connect__Response_Date_Time__c);
                batchLogGroup.put(key, objLog);
                batchLogsToInsert.add(objLog);
            }
        }
        
        // Insert New Batch Log Records.
        if(!batchLogsToInsert.isEmpty()) {
            try{
                Database.insert(batchLogsToInsert, false);
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('CreatePledgePaymentBatchLogs_Batch',
                                                                        'execute',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
        
        for(String uniqueKey : batchLogGroupSet.keySet()) {
            for(Opportunity objOppty : batchLogGroupSet.get(uniqueKey)) {
                //system.assert(false,uniqueKey+'>>> @@ '+ batchLogGroup);
                objOppty.Batch_Log__c = batchLogGroup.get(uniqueKey).Id;
          
                batchLogGroup.get(uniqueKey).Actual_Count__c = batchLogGroup.get(uniqueKey).Actual_Count__c != null 
                                                             ? batchLogGroup.get(uniqueKey).Actual_Count__c + 1 
                                                             : 1;
                batchLogGroup.get(uniqueKey).Actual_Amount__c = batchLogGroup.get(uniqueKey).Actual_Amount__c != null 
                                                              ? batchLogGroup.get(uniqueKey).Actual_Amount__c + objOppty.Amount 
                                                              : objOppty.Amount;
                batchLogGroup.get(uniqueKey).Expected_Count__c = batchLogGroup.get(uniqueKey).Actual_Count__c;
                batchLogGroup.get(uniqueKey).Expected_Amount__c = batchLogGroup.get(uniqueKey).Actual_Amount__c;
                batchLogGroup.get(uniqueKey).Batch_Log_Status__c = 'Balanced';
                batchLogsLst.put(batchLogGroup.get(uniqueKey).Id, batchLogGroup.get(uniqueKey));
                opptyToUpdateLst.add(objOppty);
            }
        }
        
        if(opptyToUpdateLst.size() > 0) {
            try{
                Database.update(opptyToUpdateLst, false);
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('CreatePledgePaymentBatchLogs_Batch',
                                                                        'execute',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
        
        if(batchLogsLst != null && !batchLogsLst.isEmpty()) {
            try{
                Database.update(batchLogsLst.values(), false);
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('CreatePledgePaymentBatchLogs_Batch',
                                                                        'execute',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        if(Last_Run_Time_Of_Batch__c.getInstance('CreatePledgePaymentBatchLogs_Batch') == null) {
           Last_Run_Time_Of_Batch__c cs = new Last_Run_Time_Of_Batch__c(Name = 'CreatePledgePaymentBatchLogs_Batch',
                                                                        Last_Run_Time__c=System.now());
           insert cs;
         }
         else {
           Last_Run_Time_Of_Batch__c cs = Last_Run_Time_Of_Batch__c.getInstance('CreatePledgePaymentBatchLogs_Batch');
           cs.Last_Run_Time__c = system.now();
           update cs;
         }
         if(One_Time_Run_Batch__c.getInstance('CreatePledgePaymentBatchLogs_Batch') != null) {
             One_Time_Run_Batch__c oneTimeRunBatch = One_Time_Run_Batch__c.getInstance('CreatePledgePaymentBatchLogs_Batch');
             oneTimeRunBatch.Close_Date_Start__c = null;
             oneTimeRunBatch.Close_Date_End__c = null;
             oneTimeRunBatch.Run_Based_On_Date_Field__c = false;
             update oneTimeRunBatch;
         }
    }
}