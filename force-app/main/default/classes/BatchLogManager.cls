/*
*
*Name  :  BatchLogManager
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  November 15, 2016
*Purpose : Class creates webService methods invoked from varoius javascript buttons and supports BGE
*           Method use is inlcuded in comments below
*
*/
global class BatchLogManager {
    global static Map<String, Schema.RecordTypeInfo> batchLogRtMap;
    global static Map<String, Schema.RecordTypeInfo> opptyRTMap;
    global static List<Opportunity> softCreditsLst;
    global static Opportunity objTransaction;
    global static Set<String> sharingCodeSet;
    
    static {
        batchLogRtMap = Schema.Sobjecttype.Batch_Log__c.getRecordTypeInfosByName();
        opptyRTMap = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName();
        sharingCodeSet = new Set<String>{'A001', 'A002', 'A003', 'B003', 'D009', 'D010', 'D011', 'D012', 
                                                        'P001', 'P002', 'P003', 'E131', 'E181'};
    }

    // Method to update Batch Log status to Balanced.
    // OnClick Javascript method invoked from Batch Log Detail Page Button. (Button Name: 'Release')
    //
    webservice static void updateBatchLogStatus(Id logId) {
        List<Batch_Log__c> logLst = new List<Batch_Log__c>();

        for(Batch_Log__c objLog : [ SELECT  Id, Batch_Log_Status__c
                                    FROM    Batch_Log__c
                                    WHERE   Id =: logId ]) {
            objLog.Batch_Log_Status__c = 'Balanced';
            logLst.add(objLog);
        }

        if(!logLst.isEmpty()) {
            try{
                update logLst;
            } catch(Exception e) {
                Exceptionutils.createApexLog('BatchLogManager','updateBatchLogStatus',e);
            }
        }
    }

    // Method to update Batch Log status to Balanced.
    // OnClick Javascript method invoked from Batch Log List View Button. (Button Name: 'Release')
    //
    webservice static void updateBulkBatchLogStatus(Id[] logIds) {
        List<Batch_Log__c> logLst = new List<Batch_Log__c>();

        //logIdSet.addAll(logIdLst);
        for(Batch_Log__c objLog : [ SELECT  Id, Actual_Amount__c, Actual_Count__c, Expected_Amount__c, Expected_Count__c, Batch_Log_Status__c
                                    FROM    Batch_Log__c
                                    WHERE   Id IN: logIds
                                    AND     Actual_Amount__c != null AND Expected_Amount__c != null
                                    AND     Actual_Count__c != null AND Expected_Count__c != null ]) {
            if(objLog.Actual_Amount__c == objLog.Expected_Amount__c && objLog.Actual_Count__c == objLog.Expected_Count__c) {
                objLog.Batch_Log_Status__c = 'Balanced';
                logLst.add(objLog);
            }
        }

        if(!logLst.isEmpty()) {
            try{
                update logLst;
            } catch(Exception e) {
                Exceptionutils.createApexLog('BatchLogManager','updateBulkBatchLogStatus',e);
            }
        }
    }

     // Method to Associate a Adjustment Batch Log with Opportunity
    // OnClick Javascript method invoked from 'Create Adjustment Batch' Detail Page Button On Opportunity.
    //
    webservice static AdjustmentLogResult associateAdjustmentLog(Id opptyId, String hasSoftCredits ) {
        Batch_Log__c selectedBatchLog = new Batch_Log__c();
        Boolean adjustmentBatchFound = false;
        Integer adjustmentSeqNo =0;
        objTransaction = new Opportunity();
        softCreditsLst = new List<Opportunity>();

        // Transaction/Pledge Payment Opportunity
        for(Opportunity oppty : [ SELECT Id, Name, Batch_Date__c, Batch_Log__c, Batch_Log__r.Name, Deposit_Site__c,
                                    Program_Type__c, Account_Affiliation__c, Adjustment_Batch__c, Related_Transaction__c,
                                    Batch_Log__r.Id, Batch_Log__r.RecordTypeId, Amount, AccountId, StageName,
                                    CloseDate, Last_Adjusted_Date__c, rC_Giving__Parent__c, Adjustment_Sequence__c,
                                    RecordTypeId, rC_Giving__Payment_Method_Selected__c, Batch_Sequence__c, IsCreatedFromBatchLog__c,
                                    rC_Giving__Payment_Method__c, Bank_Date__c, rC_Giving__Giving_Amount__c, CampaignId, Adjustment__c
                                FROM Opportunity
                                WHERE Id =: opptyId OR Related_Transaction__c =: opptyId]) {
            if(oppty.Id == opptyId) {
                objTransaction = oppty;
            } else {
                softCreditsLst.add(oppty);
            }
        }

        String batchLogNameMatch = String.valueOf(objTransaction.Batch_Log__r.Name).substring(0,10)+'%';
		//Ana Ferreira - BGE-84 - Feb 21st
        for(Batch_Log__c objLog : [ SELECT   Id, Batch_Date__c, Batch_Log_Status__c, Batch_Type__c, RecordtypeId, Batch_Auto_Number__c, Name, Deposit_Site__c, 
                                   (select id from Opportunities1__r)
                                    FROM     Batch_Log__c
                                    WHERE    Name  LIKE: batchLogNameMatch
                                    //AND Batch_Date__c =: objTransaction.Batch_Date__c
                                    //AND        Deposit_Site__c =: objTransaction.Deposit_Site__c
                                    ORDER BY Batch_Auto_Number__c
                                    ASC ]) {
            selectedBatchLog = objLog;
            if(objLog.Batch_Type__c == 'Adjustment' && objLog.Batch_Log_Status__c != 'Balanced' 
                    && objLog.Deposit_Site__c == objTransaction.Deposit_Site__c && objLog.Batch_Date__c == objTransaction.Batch_Date__c) {
               if((objLog.Opportunities1__r.size() > 0 && objLog.Opportunities1__r[0].id == opptyId) || objLog.Opportunities1__r.size() == 0 ){ //BGE-24         
                adjustmentBatchFound = true; 
                break;
               }    
            }
        }

        //try {
            AdjustmentLogResult res = new AdjustmentLogResult();
            res.batchRTId = batchLogRtMap.get('Manual').getRecordTypeId();

           if(!adjustmentBatchFound && selectedBatchLog != null) {

                Batch_Log__c objLog = new Batch_Log__c();
                objLog.Batch_Type__c = 'Adjustment';
                objLog.Batch_Log_Status__c = 'Open';
                objLog.RecordTypeId = batchLogRtMap.get('Manual').getRecordTypeId();
                objLog.Batch_Log_Type__c = 'Manual';
                objLog.Batch_Date__c = objTransaction.Batch_Date__c;
                objLog.Deposit_Site__c = objTransaction.Deposit_Site__c;
                objLog.Name = String.ValueOf(selectedBatchLog.Name).substring(0,10);

                String autoNumString = selectedBatchLog.Batch_Auto_Number__c != null? String.ValueOf(Integer.ValueOf(selectedBatchLog.Batch_Auto_Number__c)+1): '1';
                Integer len = autoNumString.length();
                if(len < 4) {
                    for(Integer i=0; i < 4 - len; i++) {
                        autoNumString = '0'+autoNumString;
                    }
                }
                objLog.Name += autoNumString;
                objLog.Batch_Auto_Number__c = Integer.ValueOf(autoNumString);
                try {
                    insert objLog;
                } catch(Exception e) {
                    Exceptionutils.createApexLog('BatchLogManager','associateAdjustmentLog',e);
                }
                res.batchId = objLog.Id;
               res.adjustedTransactionId = objTransaction.Id;//createAdjustmentRecords(objLog);
            } else {
                res.batchId = selectedBatchLog.Id;
                adjustmentSeqNo = getadjustmentSeqNo(selectedBatchLog.Id);
                res.adjustedTransactionId = objTransaction.Id;//createAdjustmentRecords(selectedBatchLog);
            }
            
            try{
                update new Opportunity(Id=objTransaction.Id, Adjustment_Batch__c = res.batchId );
                
                Opportunity parentopptyUpdate = [SELECT Id,Adjustment_Sequence__c FROM Opportunity WHERE Id=: objTransaction.rC_Giving__Parent__c LIMIT 1];
                parentopptyUpdate.IsCreatedFromBatchLog__c = true;
                if(String.IsBlank(String.valueOf(parentopptyUpdate.Adjustment_Sequence__c))){
                    parentopptyUpdate.Adjustment_Sequence__c = adjustmentSeqNo+1;
                }
                if(objTransaction.Batch_Sequence__c != null && objTransaction.IsCreatedFromBatchLog__c == true
                   && objTransaction.recordTypeId==opptyRTMap.get('Pledge Payment').getRecordTypeId() && objTransaction.Related_Transaction__c == null){
                    parentopptyUpdate.Batch_Sequence__c = objTransaction.Batch_Sequence__c;
                }
                //separate DML for parent
                update parentopptyUpdate;
                
            }
            catch(Exception e) {
                Exceptionutils.createApexLog('BatchLogManager','associateAdjustmentLog-Updateparent',e);
            }

            return res;        
    }
    
    //internal helper method, called from associateAdjustmentLog method in this class
    webservice static Integer getadjustmentSeqNo(Id adjBatchId){
        Set<Id> parentOpptyIds = new Set<Id>();
        for(opportunity objOppty:[SELECT id,recordType.name,rC_Giving__Parent__c, rC_Giving__Giving_Amount__c 
                                            FROM opportunity 
                                            WHERE Adjustment_Batch__c=:adjBatchId AND rC_Giving__Parent__r.IsCreatedFromBatchLog__c= true 
                                            AND  (RecordType.Name = 'Transaction' OR RecordType.Name = 'Pledge' OR 
                                                    (RecordType.Name = 'Pledge Payment' AND Related_Transaction__c = null))]){
            if (objOppty.RecordType.Name == 'Pledge') {
              parentOpptyIds.add(objOppty.Id);
            } else {
                parentOpptyIds.add(objOppty.rC_Giving__Parent__c);
            }
        }
        return parentOpptyIds.size();
    }
    
    // Method to create Copy and Offsetting transaction records after Adjustment.  Called from BatchLogDetailPageController
    webservice static List<Opportunity> createAdjustmentRecords(Batch_Log__c objLog, Opportunity objTransaction) {
        List<Opportunity> opptyLst = new List<Opportunity>();
        List<Opportunity> newTransactions = new List<Opportunity>();
        Integer count = 0, numberOfAdjustments = 0;
        Double totalAmount = 0;
        Opportunity parentOppty;
        for(Opportunity oppty : [SELECT Id, Amount, rC_Giving__Giving_Amount__c, Adjustment_Code__c,IsCreatedFromBatchLog__c,Adjustment__c FROM Opportunity
                                 WHERE  (Adjustment_Batch__c =: objLog.Id
                                 AND (Adjustment_Code__c = 'B' OR Adjustment_Code__c = 'D')
                                 AND (RecordType.Name = 'Transaction' OR RecordType.Name = 'Pledge Payment' OR RecordType.Name = 'Adjustment'))]) {
           
            if(oppty.Id == objTransaction.rC_Giving__Parent__c && !oppty.IsCreatedFromBatchLog__c) {
                 parentOppty = oppty;
                 parentOppty.IsCreatedFromBatchLog__c = true;
            } else {
                count = count + 1;
                Decimal amt = (oppty.Amount!= null)?oppty.Amount:0.0;
                totalAmount = totalAmount + amt;
            }

        }
        numberOfAdjustments = count/2;

        // Update Transaction/Pledge Payment from where Adjustment is Initiated.
        objTransaction.Adjustment_Batch__c = objLog.Id;
        objTransaction.Adjustment_Code__c = 'A';
        objTransaction.Adjustment__c = true;
        opptyLst.add(objTransaction);

        // Copy transaction record Adjustment Code B
        Opportunity codeBTransactionRecord = objTransaction.clone(false, false, true, false);
        codeBTransactionRecord.Name = objTransaction.Name;
        codeBTransactionRecord.Amount = (objTransaction.Amount)*(-1);
        codeBTransactionRecord.Adjustment_Code__c = 'B';
        codeBTransactionRecord.CampaignId = objTransaction.CampaignId;
        codeBTransactionRecord.Batch_Log__c = objLog.Id;
        codeBTransactionRecord.rC_Giving__Transaction_Type__c = 'Adjustment';
        //codeBTransactionRecord.rC_Giving__Is_Giving_Transaction__c = objTransaction.rC_Giving__Is_Giving_Transaction__c;
        codeBTransactionRecord.Accounting_Date__c = system.today();
        codeBTransactionRecord.Adjustment_Sequence__c = numberOfAdjustments + 1;
        //
        codeBTransactionRecord.Batch_Log__c = objLog.Id;
        //
        codeBTransactionRecord.Adjustment_Batch__c = objLog.Id;
        codeBTransactionRecord.AccountId = objTransaction.AccountId;
        codeBTransactionRecord.StageName = objTransaction.StageName;
        codeBTransactionRecord.CloseDate = objTransaction.CloseDate;
        codeBTransactionRecord.rC_Giving__Parent__c = objTransaction.rC_Giving__Parent__c;
        codeBTransactionRecord.rC_Giving__Payment_Method_Selected__c = objTransaction.rC_Giving__Payment_Method_Selected__c;
        codeBTransactionRecord.RecordTypeId = opptyRTMap.get('Adjustment').getRecordtypeId();
        codeBTransactionRecord.Adjustment__c = true;
        newTransactions.add(codeBTransactionRecord);
        opptyLst.add(codeBTransactionRecord);

        // Copy transaction record Adjustment Code D
        Opportunity codeDTransactionRecord = objTransaction.clone(false, false, true, false);
        codeDTransactionRecord.Name = objTransaction.Name;
        codeDTransactionRecord.Amount = objTransaction.Amount;
        codeDTransactionRecord.CampaignId = objTransaction.CampaignId;
        codeDTransactionRecord.Adjustment_Code__c = 'D';
        codeDTransactionRecord.Batch_Log__c = objLog.Id;
        codeDTransactionRecord.rC_Giving__Transaction_Type__c = 'Payment';
        codeDTransactionRecord.Accounting_Date__c = system.today();
        codeDTransactionRecord.Adjustment_Sequence__c = numberOfAdjustments + 1;
        //
        codeDTransactionRecord.Batch_Log__c = objLog.Id;
        //
        codeDTransactionRecord.Adjustment_Batch__c = objLog.Id;
        codeDTransactionRecord.AccountId = objTransaction.AccountId;
        codeDTransactionRecord.StageName = objTransaction.StageName;
        codeDTransactionRecord.CloseDate = objTransaction.CloseDate;
        codeDTransactionRecord.rC_Giving__Parent__c = objTransaction.rC_Giving__Parent__c;
        codeDTransactionRecord.rC_Giving__Payment_Method_Selected__c = objTransaction.rC_Giving__Payment_Method_Selected__c;
        codeDTransactionRecord.RecordTypeId = objTransaction.RecordTypeId;
        codeDTransactionRecord.Adjustment__c = true;
        if(sharingCodeSet.contains(objTransaction.Sharing_Code__c)) {
            codeDTransactionRecord.rC_Giving__External_Id__c = 'Flagged for MembershipShareCode Reset';
        }
        newTransactions.add(codeDTransactionRecord);
        opptyLst.add(codeDTransactionRecord);

        objTransaction.RecordTypeId = opptyRTMap.get('Adjustment').getRecordtypeId();
          
        return opptyLst; 
    }    

    global class AdjustmentLogResult {
        webservice Id batchRTId;
        webservice Id batchId;
        webservice Id adjustedTransactionId;
    }
    
    //T-686535, Bhavesh
    public Id BatchResetMembershipMethod( Opportunity opp, Boolean resetAcc ){
        Account acc = new Account();
        //Get AccountIds of Related Accounts
        acc.id = opp.AccountId;
        Boolean clearJoinDate = false;
        if( opp.Account.Last_Membership_Gift__c != null && opp.Account.Original_Join_Date__c != null 
            && opp.Account.Last_Membership_Gift__r.CloseDate != null 
            && (opp.Account.Original_Join_Date__c == opp.Account.Last_Membership_Gift__r.CloseDate) ){
            clearJoinDate = true;
        }
        Boolean dateFieldUpdated = false;
        Boolean giftFieldUpdated = false;
        if( resetAcc ){
            //Query AccountHistory Object of related Accounts
            for(AccountHistory accHis : [SELECT NewValue, OldValue, Field 
                                            FROM AccountHistory 
                                            WHERE accountId = : acc.id
                                            AND Field IN ('Membership_Expiration_date__c','Last_Membership_Gift__c')
                                            ORDER BY createddate DESC]){
                if( accHis.field == 'Membership_Expiration_date__c' && dateFieldUpdated == False ){
                    if( accHis.oldValue == NULL ){
                        acc.Membership_Expiration_date__c = NULL;
                    } else {
                        acc.Membership_Expiration_date__c = Date.valueOf(''+accHis.oldValue);
                    }
                    dateFieldUpdated = true;
                
                }
                
                if( accHis.field == 'Last_Membership_Gift__c' && giftFieldUpdated == False ){
                    String oldValue = ''+acchis.oldValue;
                    if(oldValue.substring(0,3) == '006'){
                        acc.Last_Membership_Gift__c = ''+acchis.oldValue;
                        giftFieldUpdated = true;
                    }
                }
            
                if( giftFieldUpdated == True && dateFieldUpdated == True ){
                    break;
                }
            }
            if( giftFieldUpdated == false ){
                acc.Last_Membership_Gift__c = null;
            }
            if( clearJoinDate ){
                acc.Original_Join_Date__c = null;//I-324947,null Original_Join_Date__c for reset batchlog button and for adjustment logic.
            }
            
            update acc;
                
        }
        //Update Opportunities to stage Open
        //Update opp only if it is invoked from batch class,
        if(System.isBatch() ){
            opp.Sharing_Code__c = '';
            opp.Sharing_Entity__c = '';
            opp.rC_Giving__External_ID__c = '';
            opp.New_Membership_Set_To_Date__c = NULL;
            opp.Sharing_Entity_Affiliation__c  = NULL;
            opp.Revenue_Affiliation__c = NULL;
            opp.StageName = 'Open';
            update opp;
        }
        return acc.Id;
    }
}