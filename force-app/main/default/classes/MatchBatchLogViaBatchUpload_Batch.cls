/*
*
*Name  :  MatchBatchLogViaBatchUpload_Batch
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  February 01, 2017
*Purpose :  Batch Class to Sync Batch Upload and Batch Log Records
            This batch queries Batch Upload records in Flagged and Committed state and are not currently associated to a batch log (other criteria exist as well).  
            The batch then proceeds to query Open Batch Logs, recounts batch upload count and giving amounts.  
            Then the Batch Upload records will either be associated to a new or existing Batch Log as long as the expected count is less than 500.  
            The batch upload that match are then updated.  
            Following that the batch log records are created, then the batch uploads that are associated to the matching new batch log record.  
            Opportunities are then updated with references to the batch log records based on the batch upload record.  
            Lastly the remaining batch logs records are updated.
*
* Modified by :: roundCorner Inc. :: 04-Mar-2019 :: Zendesk: #58115. Removed 'Flagged' status from query as it should not pick these records causing an issue
*/
global without sharing Class MatchBatchLogViaBatchUpload_Batch implements Database.Batchable<sObject>, Database.Stateful {
    
    global String queryString; 
    global Date FIRST_DATE_TEMP;
    global Decimal BATCH_LOG_LIMIT = 1;
    global Set<String> batchUploadSourceFileSet = Batch_Upload_Source_File__c.getAll().keySet();
    global Id VENDOR_RCD_TYPE_ID = Schema.Sobjecttype.Batch_Log__c.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
    global Id PLEDGE_RCD_TYPE_ID = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
    global set<Id> batchLogIdsForCalculation = new set<Id>();
    global MatchBatchLogViaBatchUpload_Batch() {
        System.debug('batchUploadSourceFileSet :: ' + batchUploadSourceFileSet);
        FIRST_DATE_TEMP = Date.newInstance(2017,08,07);
        queryString = 'Select Id, Batch_Log__c, rC_Connect__Giving_Close_Date__c, Batch_Upload_Deposit_Site__c'; 
        queryString += ', rC_Connect__Giving_Giving_Amount__c, rC_Connect__Batch_Upload_Status__c, Program_Type__c';
        queryString += ', rC_Connect__Batch_Upload_Giving_Matched__r.Id, rC_Connect__Batch_Upload_Source_File__c, rC_Connect__Giving_Paid__c';
        queryString += ' , rC_Connect__Giving_Record_Type__c From rC_Connect__Batch_Upload__c';
        queryString += ' WHERE IsDeleted = False AND Batch_Log__c = null AND rC_Connect__Batch_Upload_Source_File__c IN: batchUploadSourceFileSet';
        queryString += ' AND (rC_Connect__Giving_Record_Type__c =\'Pledge\' OR rC_Connect__Giving_Record_Type__c =\'Donation\')';
        queryString += ' AND Batch_Upload_Deposit_Site__c != null';
        queryString += ' AND isSoft_Credit__c = false';
        queryString += ' AND rC_Connect__Batch_Upload_Status__c IN (\'Committed\') ';//rC[#58115]: removed the status as was causing an issue,\'Flagged\'
        
        // Temporary
        queryString += ' AND CreatedDate >=: FIRST_DATE_TEMP';
        System.debug('Query :: ' + queryString);
    }
    
    global MatchBatchLogViaBatchUpload_Batch(Id batchUploadId) {
        queryString = 'Select Id, Batch_Log__c, rC_Connect__Giving_Close_Date__c, Batch_Upload_Deposit_Site__c'; 
        queryString += ', rC_Connect__Giving_Giving_Amount__c, rC_Connect__Batch_Upload_Status__c, Program_Type__c';
        queryString += ', rC_Connect__Batch_Upload_Giving_Matched__r.Id, rC_Connect__Batch_Upload_Source_File__c, rC_Connect__Giving_Paid__c';
        queryString += ' , rC_Connect__Giving_Record_Type__c From rC_Connect__Batch_Upload__c';
        queryString += ' WHERE Batch_Log__c = null AND rC_Connect__Batch_Upload_Source_File__c IN: batchUploadSourceFileSet';
        queryString += ' AND (rC_Connect__Giving_Record_Type__c =\'Pledge\' OR rC_Connect__Giving_Record_Type__c =\'Donation\')';
        queryString += ' AND isSoft_Credit__c = false';
        queryString += ' AND Id = \''+batchUploadId+'\'';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('Start :: QueryLocator :: ' + queryString);
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<rC_Connect__Batch_Upload__c> batchUploadLst = new List<rC_Connect__Batch_Upload__c>();
        Map<Id, Batch_Log__c> batchLogsMap = new Map<Id, Batch_Log__c>();
        Map<String, List<rC_Connect__Batch_Upload__c>> batchLogGroupSet = new Map<String, List<rC_Connect__Batch_Upload__c>>();
        List<Batch_Log__c> batchLogsToInsert = new List<Batch_Log__c>();
        Map<String, Batch_Log__c> batchLogGroup = new Map<String, Batch_Log__c>();
        //List<Opportunity> givingLst = new List<Opportunity>();
        map<Id, Opportunity> paidOpptyMap = new map<Id, Opportunity>();
        map<Id, Opportunity> givingMap = new map<Id, Opportunity>();
        map<Id, Date> batchUploadCloseDateMap = new map<Id, Date>();
        String OPPORTUNITY_RT_DONATION_Id = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
        String OPPORTUNITY_RT_PLEDGE_Id = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
        String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
        Opportunity givingObj;
        String uniqueLogKey = '';
        Integer i;
        

        for(Batch_Log__c objLog : [ SELECT  Id, Deposit_Site__c, Batch_Date__c, Expected_Count__c,
                                            Expected_Amount__c, Batch_Log_Status__c, Has_Errors__c,
                                            (SELECT Id, rC_Connect__Giving_Giving_Amount__c 
                                             FROM Batch_Uploads__r)
                                    FROM    Batch_Log__c
                                    WHERE   Batch_Log_Status__c = 'Open'
                                    AND     Deposit_Site__c != null 
                                    AND     Batch_Date__c != null  
                                    AND     Batch_Type__c = 'Standard'
                                    AND     RecordTypeId =: VENDOR_RCD_TYPE_ID]) {
            uniqueLogKey = objLog.Deposit_Site__c+'-'+objLog.Batch_Date__c;
            objLog.Expected_Amount__c = 0;
/*
objLog.Batch_Uploads__r.size() fails when result set is >200
            if(objLog.Batch_Uploads__r.size() > 0) {
                objLog.Expected_Count__c = objLog.Batch_Uploads__r.size();
                for(rC_Connect__Batch_Upload__c bu : objLog.Batch_Uploads__r) {
                    if(bu.rC_Connect__Giving_Giving_Amount__c != null) {
                        objLog.Expected_Amount__c = objLog.Expected_Amount__c + bu.rC_Connect__Giving_Giving_Amount__c;
                    }
                }
            }
*/
            for(rC_Connect__Batch_Upload__c bu : objLog.Batch_Uploads__r) {
                objLog.Expected_Count__c++;
                if(bu.rC_Connect__Giving_Giving_Amount__c != null) {
                    objLog.Expected_Amount__c = objLog.Expected_Amount__c + bu.rC_Connect__Giving_Giving_Amount__c;
                }
            }

            if(!batchLogGroup.containsKey(uniqueLogKey)) {
                batchLogGroup.put(uniqueLogKey, objLog);
            }
        }
        
        for(rC_Connect__Batch_Upload__c objBatchUpload : (List<rC_Connect__Batch_Upload__c>)scope) {
            if(objBatchUpload.Program_Type__c != null) {
                String uniqueUploadKey = objBatchUpload.Batch_Upload_Deposit_Site__c+'-'+objBatchUpload.rC_Connect__Giving_Close_Date__c;
                
                if(batchLogGroup.containsKey(uniqueUploadKey) && (batchLogGroup.get(uniqueUploadKey).Expected_Count__c < 500 || 
                    batchLogGroup.get(uniqueUploadKey).Expected_Count__c == null)) {
                    objBatchUpload.Batch_Log__c = batchLogGroup.get(uniqueUploadKey).Id;
                    givingObj = objBatchUpload.rC_Connect__Batch_Upload_Giving_Matched__r;
                    if(givingObj != null && givingObj.Id != null) {
                        givingObj.Batch_Log__c = batchLogGroup.get(uniqueUploadKey).Id;
                        givingObj.Batch_Date__c = batchLogGroup.get(uniqueUploadKey).Batch_Date__c;
                        //givingLst.add(givingObj);
                        givingMap.put(givingObj.Id, givingObj);
                        batchUploadCloseDateMap.put(givingObj.Id, objBatchUpload.rC_Connect__Giving_Close_Date__c);
                        if(objBatchUpload.rC_Connect__Giving_Paid__c && objBatchUpload.rC_Connect__Giving_Record_Type__c == 'Pledge') {
                            paidOpptyMap.put(givingObj.Id, givingObj);
                        }
                    }
                    if(objBatchUpload.rC_Connect__Batch_Upload_Status__c == 'Flagged') {
                        batchLogGroup.get(uniqueUploadKey).Has_Errors__c = true;
                    }
                    batchLogGroup.get(uniqueUploadKey).Expected_Count__c = batchLogGroup.get(uniqueUploadKey).Expected_Count__c != null ? batchLogGroup.get(uniqueUploadKey).Expected_Count__c + 1 : 1;
                    batchLogGroup.get(uniqueUploadKey).Expected_Amount__c = batchLogGroup.get(uniqueUploadKey).Expected_Amount__c != null ? batchLogGroup.get(uniqueUploadKey).Expected_Amount__c + objBatchUpload.rC_Connect__Giving_Giving_Amount__c : objBatchUpload.rC_Connect__Giving_Giving_Amount__c;
                    batchLogsMap.put(batchLogGroup.get(uniqueUploadKey).Id, batchLogGroup.get(uniqueUploadKey));
                    batchLogIdsForCalculation.add(batchLogGroup.get(uniqueUploadKey).Id);
                    batchUploadLst.add(objBatchUpload);
                } else {
                    if(batchLogGroup.containsKey(uniqueUploadKey) && batchLogGroup.get(uniqueUploadKey).Expected_Count__c != null && batchLogGroup.get(uniqueUploadKey).Expected_Count__c == 500) {
                        batchLogGroup.get(uniqueUploadKey).Batch_Log_Status__c = 'Pending';
                        batchLogsMap.put(batchLogGroup.get(uniqueUploadKey).Id, batchLogGroup.get(uniqueUploadKey));
                        batchLogIdsForCalculation.add(batchLogGroup.get(uniqueUploadKey).Id);
                    }
                    if(!batchLogGroupSet.containsKey(uniqueUploadKey)) {
                        batchLogGroupSet.put(uniqueUploadKey, new List<rC_Connect__Batch_Upload__c>());
                    }
                    batchLogGroupSet.get(uniqueUploadKey).add(objBatchUpload);
                }
            }
        }
        
        if(batchLogGroupSet != null && !batchLogGroupSet.isEmpty()) {
            for(String uniqueKey : batchLogGroupSet.keySet()) {
                Batch_Log__c objLog = new Batch_Log__c();
                //objLog.Name = 'TBD';
                objLog.Batch_Log_Type__c = 'Springboard';
                objLog.Batch_Log_Status__c = 'Open';
                objLog.Has_Errors__c = false;
                objLog.RecordTypeId = VENDOR_RCD_TYPE_ID; 
                objLog.Batch_Type__c = 'Standard';
                objLog.Batch_Log_Type__c = batchLogGroupSet.get(uniqueKey)[0].rC_Connect__Batch_Upload_Source_File__c;
                if(batchLogGroupSet.get(uniqueKey)[0].Program_Type__c != null)  objLog.Program_Type__c = (batchLogGroupSet.get(uniqueKey)[0].Program_Type__c).substring(0,1);
                objLog.Batch_Date__c = batchLogGroupSet.get(uniqueKey)[0].rC_Connect__Giving_Close_Date__c;
                objLog.Deposit_Site__c = batchLogGroupSet.get(uniqueKey)[0].Batch_Upload_Deposit_Site__c;
                batchLogGroup.put(objLog.Deposit_Site__c+'-'+objLog.Batch_Date__c, objLog);
                batchLogsToInsert.add(objLog);
            }
        }
        
        // Insert New Batch Log Records.
        if(!batchLogsToInsert.isEmpty()) {
            List<Database.SaveResult> blresults = Database.insert(batchLogsToInsert, false);
            processResults(blresults, batchLogsToInsert, 'Batch Log Insert Failed :: ');
        }
    
        
        for(String uniqueKey : batchLogGroupSet.keySet()) {
            for(rC_Connect__Batch_Upload__c objBatchUpload : batchLogGroupSet.get(uniqueKey)) {
                objBatchUpload.Batch_Log__c = batchLogGroup.get(uniqueKey).Id;
                givingObj = objBatchUpload.rC_Connect__Batch_Upload_Giving_Matched__r;
                if(givingObj != null && givingObj.Id != null) {
                    givingObj.Batch_Log__c = batchLogGroup.get(uniqueKey).Id;
                    givingObj.Batch_Date__c = batchLogGroup.get(uniqueKey).Batch_Date__c;//I-307745
                    //givingLst.add(givingObj);
                    givingMap.put(givingObj.Id, givingObj);
                    batchUploadCloseDateMap.put(givingObj.Id, objBatchUpload.rC_Connect__Giving_Close_Date__c);
                    if(objBatchUpload.rC_Connect__Giving_Paid__c && objBatchUpload.rC_Connect__Giving_Record_Type__c == 'Pledge') {
                        paidOpptyMap.put(givingObj.Id, givingObj);
                    }
                }
                if(objBatchUpload.rC_Connect__Batch_Upload_Status__c == 'Flagged') {
                    batchLogGroup.get(uniqueKey).Has_Errors__c = true;
                }
                batchLogGroup.get(uniqueKey).Expected_Count__c = batchLogGroup.get(uniqueKey).Expected_Count__c != null ? batchLogGroup.get(uniqueKey).Expected_Count__c + 1 : 1;
                batchLogGroup.get(uniqueKey).Expected_Amount__c = batchLogGroup.get(uniqueKey).Expected_Amount__c != null ? batchLogGroup.get(uniqueKey).Expected_Amount__c + objBatchUpload.rC_Connect__Giving_Giving_Amount__c : objBatchUpload.rC_Connect__Giving_Giving_Amount__c;
                batchLogsMap.put(batchLogGroup.get(uniqueKey).Id, batchLogGroup.get(uniqueKey));
                batchLogIdsForCalculation.add(batchLogGroup.get(uniqueKey).Id);
                batchUploadLst.add(objBatchUpload);
            }
        }
        
        if(!batchUploadLst.isEmpty()) {
            try{
                update batchUploadLst;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('MatchBatchLogViaBatchUpload',
                                                          'execute','Batch Upload obj updated failed  '+e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }
        if(!givingMap.isEmpty()) {
            for(Opportunity opp : [ SELECT  Id, rC_Giving__Parent__c, rC_Giving__Parent__r.Batch_Log__c, 
                                        rC_Giving__Parent__r.RecordTypeId, Sustainer_First_Payment__c,
                                        CloseDate, RecordTypeId
                                    FROM    Opportunity 
                                    WHERE   rC_Giving__Parent__c IN :givingMap.keySet() 
                                    AND     Id NOT IN :givingMap.keySet() 
                                    AND     StageName = 'Completed']) {
                if(opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id && batchUploadCloseDateMap.containsKey(opp.rC_Giving__Parent__c) 
                    && batchUploadCloseDateMap.get(opp.rC_Giving__Parent__c) == opp.CloseDate
                    && opp.Sustainer_First_Payment__c == true) {
                    opp.Batch_Log__c = givingMap.get(opp.rC_Giving__Parent__c).Batch_Log__c;
                    opp.Batch_Date__c = givingMap.get(opp.rC_Giving__Parent__c).Batch_Date__c;//I-307745
                    givingMap.put(opp.Id, opp);
                } else if(opp.RecordTypeId != OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) {
                    opp.Batch_Log__c = givingMap.get(opp.rC_Giving__Parent__c).Batch_Log__c;
                    opp.Batch_Date__c = givingMap.get(opp.rC_Giving__Parent__c).Batch_Date__c;//I-307745
                    givingMap.put(opp.Id, opp);
                }
            }
            for(Opportunity op : paidOpptyMap.values()) {
                op.Batch_Log__c = null;
                op.Batch_Date__c = null;
                givingMap.put(op.Id, op);
            }
            
            //update givingMap.values();
            List<Database.SaveResult> opResults = Database.update(givingMap.values(), false);
            processResults(opResults, givingMap.values(), 'Opportunty update :: ' );

        }
        
        //updates batch log records
        if(!batchLogsMap.isEmpty()) {
            List<Database.SaveResult> batchLogResults = Database.update(batchLogsMap.values(), false);
            processResults(batchLogResults, batchLogsMap.values(),  'Batch Log update failed :: ' );
        }

    }
    
    global void finish(Database.BatchableContext BC) {
        Database.executeBatch(new BatchCalculateExpectedCountAmount(batchLogIdsForCalculation), 50);
    }


    public void processResults(List<Database.SaveResult> results, List<sObject> lstObj, String s ){
        integer i = 0;
        
        set<String> messages; 
        apexLogHandler.apexLog log; 
        for (Database.SaveResult result : results) {
            messages = new set<String>();
            if (!result.isSuccess()){
                for (Database.Error err : result.getErrors()){
                    if(!messages.contains(err.getMessage())) {
                        log = new apexLogHandler.apexLog('MatchBatchLogViaBatchUpload','execute',
                                                         s+ lstObj[i].id + '\n' + err.getMessage());
                        messages.add(err.getMessage());
                    }
                }
            }
            i++;
        }
        if(log != null) {
            log.saveLogs();
        }
    }


}