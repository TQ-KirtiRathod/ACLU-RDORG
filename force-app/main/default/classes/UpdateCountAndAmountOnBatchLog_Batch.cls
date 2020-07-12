/*
*
*Name  :  UpdateCountAndAmountOnBatchLog_Batch
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  Feb 10, 2017
*Purpose : Batch Class to Update Actual Count and Acount Amount On Batch Logs
*
*/
global without sharing Class UpdateCountAndAmountOnBatchLog_Batch implements Database.Batchable<sObject>, Database.Stateful {
    global String queryString;
    global Date PRIOR_DATE;
    global Date END_DATE;
    global Boolean TO_RECALCULATE = false;
    global Set<Id> IDSET;
    global Map<Id, Batch_Log__c> batchLogMap;
    global static final String OPP_RT_DONATION_ID;
    global static final String OPP_RT_PLEDGE_PAYMENT_ID;
    global Set<String> batchUploadSourceFileSet = Batch_Upload_Source_File__c.getAll().keySet();
    static {
        OPP_RT_DONATION_ID = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
        OPP_RT_PLEDGE_PAYMENT_ID = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    }
    global UpdateCountAndAmountOnBatchLog_Batch() {
        PRIOR_DATE = System.today() - 5;
        queryString = 'SELECT Id, Actual_Count__c,Expected_Count__c,Expected_Amount__c, Actual_Amount__c, Batch_Log_Type__c';
        queryString += ' FROM Batch_Log__c';
        queryString += ' WHERE Batch_Log_Type__c IN: batchUploadSourceFileSet';
        queryString += ' AND (Batch_Log_Status__c = \'Open\' OR Batch_Log_Status__c = \'Pending\')';
        queryString += ' AND LastModifiedDate >=: PRIOR_DATE';
    }
    
    global UpdateCountAndAmountOnBatchLog_Batch(Id batchLogId) {
        queryString = 'SELECT Id, Actual_Count__c, Actual_Amount__c,Expected_Amount__c,Expected_Count__c, Batch_Log_Type__c';
        queryString += ' FROM Batch_Log__c';
        queryString += ' WHERE Batch_Log_Type__c IN: batchUploadSourceFileSet';
        queryString += ' AND (Batch_Log_Status__c = \'Open\' OR Batch_Log_Status__c = \'Pending\')';
        queryString += ' AND Id = \'' + batchLogId + '\'';
    }
    //BGE-18 Recalculate values when actual and expected is different
    global UpdateCountAndAmountOnBatchLog_Batch(Id batchLogId, Boolean toRecalculate) {
        TO_RECALCULATE = toRecalculate;
        queryString = 'SELECT Id, Actual_Count__c,Expected_Count__c,Expected_Amount__c,Actual_Amount__c, Batch_Log_Type__c';
        queryString += ' FROM Batch_Log__c';
        queryString += ' WHERE Id = \'' + batchLogId + '\'';
    }
    
    //2018-09 - DS - GH-23
    //Allow batch job to be called provided a date range
     global UpdateCountAndAmountOnBatchLog_Batch(Date startDate, Date endDate) {
        PRIOR_DATE = startDate;
        END_DATE = endDate;
        queryString = 'SELECT Id, Actual_Count__c,Expected_Count__c,Expected_Amount__c,Actual_Amount__c, Batch_Log_Type__c';
        queryString += ' FROM Batch_Log__c';
        queryString += ' WHERE Batch_Log_Type__c IN: batchUploadSourceFileSet';
        queryString += ' AND (Batch_Log_Status__c = \'Open\' OR Batch_Log_Status__c = \'Pending\')';
        queryString += ' AND LastModifiedDate >=: PRIOR_DATE';
        queryString += ' AND LastModifiedDate >=: END_DATE';
    }
    
    //2018-09 - DS - GH-23
    //Allow batch job to be called provided a list of batch log ids
     global UpdateCountAndAmountOnBatchLog_Batch(Set<Id> batchLogIdSet) {
        IDSET = batchLogIdSet;
        queryString = 'SELECT Id, Actual_Count__c,Expected_Count__c,Expected_Amount__c,Actual_Amount__c, Batch_Log_Type__c';
        queryString += ' FROM Batch_Log__c';
        queryString += ' WHERE Batch_Log_Type__c IN: batchUploadSourceFileSet';
        queryString += ' AND (Batch_Log_Status__c = \'Open\' OR Batch_Log_Status__c = \'Pending\')';
        queryString += ' AND Id in :IDSET';
    }    
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Integer count;
        Decimal amount;
        batchLogMap = new Map<Id, Batch_Log__c>();
        //Map<Id, AggregateResult> agrtMap = new Map<Id, AggregateResult>();
        List<Batch_Log__c> batchLogLst = (List<Batch_Log__c>)scope;
        Map<Id, Integer> logIdToCountMap = new Map<Id, Integer>();
        Map<Id, Double> logIdToAmountMap = new Map<Id, Double>();
        
        /*for(AggregateResult objAgrt : [SELECT Batch_Log__c, count(Id) cnt, sum(rC_Giving__Giving_Amount__c) amt
                                        FROM Opportunity 
                                        WHERE (RecordType.Name ='Pledge' OR RecordType.Name ='Donation')
                                        AND Batch_Log__c IN : batchLogLst
                                        AND (Split_Sequence__c = null OR Split_Sequence__c = 1)
                                        GROUP BY Batch_Log__c]) {
          agrtMap.put((Id)objAgrt.get('Batch_Log__c'), objAgrt);
        }*/
        Double opptyAmount = 0.0;
        for(Opportunity objOppty : [SELECT Batch_Log__c, RecordTypeId, Amount,Original_Amount__c,
                                        rC_Giving__Giving_Amount__c, Split_Sequence__c, Id
                                        FROM Opportunity 
                                        WHERE (RecordTypeId = :OPP_RT_PLEDGE_PAYMENT_ID 
                                        OR RecordTypeId = :OPP_RT_DONATION_ID)
                                        AND Batch_Log__c IN : batchLogLst
                                        ORDER BY Batch_Log__c ]) {

            objOppty.Amount = makeOperandable(objOppty.Amount);
            objOppty.rC_Giving__Giving_Amount__c = makeOperandable(objOppty.rC_Giving__Giving_Amount__c);
            
            if(!logIdToCountMap.containsKey(objOppty.Batch_Log__c)) {
            	logIdToCountMap.put(objOppty.Batch_Log__c, 0);
            }
                                        	
            if(objOppty.Split_Sequence__c == null || objOppty.Split_Sequence__c == 1) {
            	logIdToCountMap.put(objOppty.Batch_Log__c, logIdToCountMap.get(objOppty.Batch_Log__c) + 1);
            } 
            
            if(!logIdToAmountMap.containsKey(objOppty.Batch_Log__c)) {
            	logIdToAmountMap.put(objOppty.Batch_Log__c, 0.0);
            }
            //Modified by roundCorner Inc :03/Dec/18 :: Replaced Giving amount with Original amount
            opptyAmount = objOppty.RecordTypeId == OPP_RT_PLEDGE_PAYMENT_ID ? objOppty.Amount : objOppty.Original_Amount__c;//objOppty.rC_Giving__Giving_Amount__c;
            logIdToAmountMap.put(objOppty.Batch_Log__c, logIdToAmountMap.get(objOppty.Batch_Log__c) + opptyAmount);                          	
        }
        
        for(Batch_Log__c objBatchLog : batchLogLst) {
                    System.debug('batchLogMap>>> '+ batchLogMap);
            
            if(objBatchLog.Batch_Log_Type__c != 'Manual' || (objBatchLog.Batch_Log_Type__c == 'Manual' && (objBatchLog.Actual_Count__c <> objBatchLog.Expected_Count__c
                || objBatchLog.Actual_Amount__c <> objBatchLog.Expected_Amount__c)) || TO_RECALCULATE == true) {
               
                if(logIdToCountMap.containsKey(objBatchLog.Id) && logIdToAmountMap.containsKey(objBatchLog.Id)) {
                    count = logIdToCountMap.get(objBatchLog.Id);
                    amount = logIdToAmountMap.get(objBatchLog.Id);
                } else {
                    count = 0;
                    amount = 0.0;
                }
                
                if(objBatchLog.Actual_Count__c != count || objBatchLog.Actual_Amount__c != amount) {
                    objBatchLog.Actual_Count__c = count;
                    objBatchLog.Actual_Amount__c = amount.setScale(2);
                    batchLogMap.put(objBatchLog.Id, objBatchLog);
                    
                }
            }
        }
        
        if(!batchLogMap.isEmpty()) {
            try{
                update batchLogMap.values();
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('UpdateCountAndAmountOnBatchLog_Batch','execute',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
    } 
    
    global void finish(Database.BatchableContext BC) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('UpdateCountAndAmountOnBatchLog_Batch FINISHED');
        log.saveLogs();
        if(TO_RECALCULATE == true){
            Set<Id> batchIds = batchLogMap.keySet();
            if(batchIds.size() > 0 ){
                Id batchId = (new list<Id>(batchIds) [0]) ;
                Batch_Log__c batch= batchLogMap.get(batchId);
//                PageReference pg = new PageReference('/' +batchId);
//                pg.setRedirect(true);
                new ApexPages.StandardController(batch).view();
                system.debug('batch>>>'+batch);
            }

        }
    }
    
    private Decimal makeOperandable(Decimal input) { return (input == null) ? 0 : input; }
}