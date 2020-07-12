/*
*
*Name  :  BatchLogTriggerHandler
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  February 16, 2017
*Purpose :  Handler Class for BatchLogTrigger
            This class also works in conjunction with BGE where logic fit the trigger vs the controller.
            Logic includes but not limited to
            - Calculation of Name, Total Fees, 
            - On Release of BL Opp stages moved to Completed or Pending
            - Opp field population, examples Batch_Date__c, Tax_Date__c, Deposit_Site__c
            - Apex Sharing managed"
*Change Log: Traction(Mounica V)  BGE-22, 12/2/2019 : Commented some lines in updateSharingSetting method
*/
public without sharing class BatchLogTriggerHandler {
    
    private static Map<String,Schema.RecordTypeInfo> batchLogRTMap;
    private static Map<String,Schema.RecordTypeInfo> opptyRTMap;
    private static Set<String> batchUploadSourceFileSet; 
    private static Map<String,Batch_Upload_Source_File__c> batchUploadSourceFileSetting; 
    private static Set<String> naProgramTypes;
    private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
    private static final String OPPORTUNITY_RT_SOFT_CREDIT_Id;
    private static final String OPPORTUNITY_RT_TRANSACTION_Id;
    private static final String OPPORTUNITY_RT_DONATION_Id;
    private static final String OPPORTUNITY_RT_PLEDGE_Id;
    public static Boolean skipSharingCodeCalucation = false;
     
    static{
        batchLogRTMap =  Schema.SObjectType.batch_Log__c.getRecordTypeInfosByName(); 
        opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        batchUploadSourceFileSetting = Batch_Upload_Source_File__c.getAll();
        if(batchUploadSourceFileSetting != null) {
            batchUploadSourceFileSet = batchUploadSourceFileSetting.keySet();
        } else {
            batchUploadSourceFileSet = new Set<String>();
        }
        OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_PLEDGE_PAYMENT).getRecordTypeId();
        OPPORTUNITY_RT_SOFT_CREDIT_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_SOFTCREDIT).getRecordTypeId();
        OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_TRANSACTION).getRecordTypeId();
        OPPORTUNITY_RT_DONATION_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_DONATION).getRecordTypeId();
        OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_PLEDGE).getRecordTypeId();
        naProgramTypes = new Set<String>{'1','2','3','4'};
    }
    /*
    *
    *Method mainEntry
    *@description : defining all trigger events
    *
    */ 
    public static void mainEntry(List<Batch_Log__c> newList, List<Batch_Log__c> oldList, 
                                 Map<Id, Batch_Log__c> newMap, Map<Id, Batch_Log__c> oldMap, 
                                 Boolean isInsert, Boolean isUpdate, 
                                 Boolean isDelete, Boolean isUndelete, 
                                 Boolean isBefore, Boolean isAfter) {
        
        //if trigger is active
        if(TriggerState.isActive('BatchLogTrigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && 
                        !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
            
            // It is called on after insert
            if(isBefore) {
                if(isInsert) {
                   onBeforeInsert(newList);
                }
                
                if(isUpdate){
                    onBeforeUpdate(newList, oldMap);
                } 
            }
            
            // It is called on after insert
            if(isAfter) {
                if(isInsert) {
                   onAfterInsert(newList);
                } else if(isUpdate) {
                   onAfterUpdate(newList, oldMap);
                }
            }
        }
    }
    
    public static void onBeforeInsert(List<Batch_Log__c> newList) {
        List<Batch_Log__c> lstToUpdateName = new List<Batch_Log__c>();
        
        for(Batch_Log__c objBatchLog : newList) {
            if(objBatchLog.Batch_Type__c != 'Adjustment' && (batchUploadSourceFileSet.contains(objBatchLog.Batch_Log_Type__c) || objBatchLog.Batch_Log_Type__c == 'Vendor' 
                || objBatchLog.Batch_Log_Type__c == 'Manual' || objBatchLog.Batch_Log_Type__c == 'Sustainer')) {  
                lstToUpdateName.add(objBatchLog);
            }
        }
        
        if(lstToUpdateName.size() > 0) {
            setBatchLogName(lstToUpdateName); 
        }
    }
    
    public static void onBeforeUpdate(List<Batch_Log__c> newList, map<Id, Batch_Log__c> oldMap){
        //setVendorStatus(newList, oldMap);
        for(Batch_Log__c objBatchLog : newList) {
            if( (objBatchLog.Expected_Amount__c != oldMap.get(objBatchLog.id).Expected_Amount__c) && objBatchLog.Total_Net_Amount__c != null ) {  
                objBatchLog.Total_Fees__c = objBatchLog.Expected_Amount__c - objBatchLog.Total_Net_Amount__c;
            }
        }
    }
    
    public static void onAfterInsert(List<Batch_Log__c> newList) {
        updateOpportunityStage(newList, null);
    }
    
    public static void onAfterUpdate(List<Batch_Log__c> newList, map<Id, Batch_Log__c> oldMap) {
        
        updateOpportunityStage(newList, oldMap);
        map<Id, Batch_Log__c> batchLogsToProcessMap = new map<Id, Batch_Log__c>();
        for(Batch_Log__c b : newList) {
            if(b.Batch_Log_Type__c == 'Manual' && (b.Batch_Date__c != oldMap.get(b.Id).Batch_Date__c || 
                b.Bank_Date__c != oldMap.get(b.Id).Bank_Date__c || b.Tax_Date__c != oldMap.get(b.Id).Tax_Date__c || 
                b.Deposit_Site__c != oldMap.get(b.Id).Deposit_Site__c)) {
                batchLogsToProcessMap.put(b.Id, b);
            }
            if(b.recordTypeId == batchLogRTMap.get(ACLU_Constants.CONST_RCDTYPE_VENDOR).getRecordTypeId() && 
                b.Batch_Date__c != oldMap.get(b.Id).Batch_Date__c) {
                batchLogsToProcessMap.put(b.Id, b);
            }
        }
        if(!batchLogsToProcessMap.keySet().isEmpty()) {
            updateGiftsFields(batchLogsToProcessMap);
        }
    }
    
    
    // Sets the vendor record status to Pending, If
    //Actual Amout equals Expected Amount && 
    //Actula Count equals Expected Count
    /*public static void setVendorStatus(List<Batch_Log__c> newList, map<Id, Batch_Log__c> oldMap){
        List<Batch_Log__c> batchLogUpdateList = new List<Batch_Log__c>(); 
        for(Batch_Log__c objBatchLog : newList){
            if(objBatchLog.recordTypeId == batchLogRTMap.get(ACLU_Constants.CONST_RCDTYPE_VENDOR).getRecordTypeId() &&
               objBatchLog.Actual_Amount__c == objBatchLog.Expected_Amount__c && objBatchLog.Actual_Count__c == objBatchLog.Expected_Count__c){
                objBatchLog.Has_Errors__c = false;
                objBatchLog.Batch_Log_Status__c = 'Pending';
                batchLogUpdateList.add(objBatchLog);
            }
        }
    }*/
    
    
    public static void setBatchLogName(List<Batch_Log__c> batchLogLst) {
        Set<String> uniqueKeySet = new Set<String>();
        Map<String, Decimal> batchNameToAutoNumberMap = new Map<String, Decimal>();
        
        for(Batch_Log__c objBatchLog : batchLogLst) {
            if(objBatchLog.Batch_Log_Type__c == 'Manual' && !String.IsBlank(objBatchLog.Affiliation__c)) {
                objBatchLog.Name = objBatchLog.Affiliation__c.substring(0,2);
            } else if(objBatchLog.Batch_Log_Type__c == 'Sustainer') {
                objBatchLog.Name = naProgramTypes.contains(objBatchLog.Program_Type__c)? 'NA' : objBatchLog.Deposit_Site__c.substring(0,2);
            } else if(!String.IsBlank(objBatchLog.Deposit_Site__c)) {
                objBatchLog.Name =  objBatchLog.Deposit_Site__c.substring(0,2);
            } 
            
            if(objBatchLog.Program_Type__c == '1' || objBatchLog.Program_Type__c == '2' || objBatchLog.Program_Type__c == '3') {
                objBatchLog.Name += 'U';
            } else {
                objBatchLog.Name += 'F';
            }
            //
            if(batchUploadSourceFileSet.contains(objBatchLog.Batch_Log_Type__c)) {
                objBatchLog.Name += batchUploadSourceFileSetting.get(objBatchLog.Batch_Log_Type__c).Batch_Name_Type__c;
            } else if(objBatchLog.Batch_Log_Type__c == 'Vendor') {
                objBatchLog.Name += 'E';
            } else if(objBatchLog.Batch_Log_Type__c == 'Manual') {
                objBatchLog.Name += 'M';
            } else if(objBatchLog.Batch_Log_Type__c == 'Sustainer') {
                objBatchLog.Name += 'S';
            }
            
            objBatchLog.Name += String.ValueOf(objBatchLog.Batch_Date__c.year()).substring(2,4);
            
            if(String.ValueOf(objBatchLog.Batch_Date__c.month()).length() == 1) {
                objBatchLog.Name += '0'+objBatchLog.Batch_Date__c.month();
            } else {
                objBatchLog.Name += objBatchLog.Batch_Date__c.month();
            }

            if(String.ValueOf(objBatchLog.Batch_Date__c.day()).length() == 1) {
                objBatchLog.Name += '0'+objBatchLog.Batch_Date__c.day();
            } else {
                objBatchLog.Name += objBatchLog.Batch_Date__c.day();
            }
            uniqueKeySet.add(objBatchLog.Name+'%');
        }
        
        if(!uniqueKeySet.isEmpty()) {
            for(Batch_Log__c objLog : [SELECT Name, Batch_Auto_Number__c FROM Batch_Log__c WHERE Name LIKE: uniqueKeySet AND Batch_Auto_Number__c != null ORDER BY Batch_Auto_Number__c DESC]) {
                if(!batchNameToAutoNumberMap.containsKey(objLog.Name.substring(0,10))) {
                    batchNameToAutoNumberMap.put(objLog.Name.substring(0,10), objLog.Batch_Auto_Number__c); 
                }
            } 
        }
        Integer counter = 1;
        for(Batch_Log__c objBatchLog : batchLogLst) {
            
            String autoNumString = String.valueOf(batchNameToAutoNumberMap.containsKey(objBatchLog.Name) ? batchNameToAutoNumberMap.get(objBatchLog.Name)+counter : counter);
            Integer len = autoNumString.length();
            
            if(len < 3) {
                for(Integer i=0; i < 4 - len; i++) {
                    autoNumString = '0'+autoNumString;
                }
            }
            
            objBatchLog.Name += autoNumString;
            objBatchLog.Batch_Auto_Number__c = Integer.ValueOf(autoNumString);
            counter++;
        }
    }
    
    
    //OnRelease of batchLog Record, We are setting the Pledge to Open and for Pledge Payment, look for the Payment method and if it is not charged, then "Pending" else "Completed"
    // and if it is the Transaction record then look for the Parent payment method and if it is not charged, then "pending" else to "Completed"
    public static void updateOpportunityStage(List<Batch_Log__c> newList, map<Id, Batch_Log__c> oldMap) {
//        list<Batch_Log__c> batchLogsToProcess = new list<Batch_Log__c>();
        Map<Id,Opportunity> mapUpdateOpportunity = new Map<Id,Opportunity>();
        Map<Id,Account> mapUpdateAccounts = new Map<Id,Account>();
        //Map<String,Schema.RecordTypeInfo> batchLogRTMap =  Schema.SObjectType.Batch_Log__c.getRecordTypeInfosByName();
        Boolean isInsert = oldMap == null ? true : false;
        set<Id> batchLogIds = new set<Id>();
        for(Batch_Log__c objBatchLog : newList) {
            
            //condition to be checked when called from trigger
            if( !BatchLogDetailPageController.IsAsyncProcessingRequired(objBatchLog.Actual_Count__c)
                && (isInsert || objBatchLog.Batch_Log_Status__c != oldMap.get(objBatchLog.Id).Batch_Log_Status__c) 
                && objBatchLog.Batch_Log_Status__c == 'Balanced' 
                && objBatchLog.recordTypeId == batchLogRTMap.get(ACLU_Constants.CONST_RCDTYPE_MANUAL).getRecordTypeId() 
                && !objBatchLog.TPA_Bypass__c 
                && skipSharingCodeCalucation == False) {
                batchLogIds.add(objBatchLog.Id);  
                        //batchLogsToProcess.add(objBatchLog);
            }
        }
        if(batchLogIds.size() == 0) {
            return;
        }
        Map<Id,Opportunity> oppIds = new Map<Id,Opportunity>();
        for(Opportunity opp : [SELECT Id,Sharing_Code__c, Sharing_Entity__c, Sharing_Code_Override__c, 
                                   Sharing_Entity_Override__c 
                               FROM Opportunity 
                               WHERE Batch_Log__c IN :batchLogIds
                                 AND RecordTypeId IN (:OPPORTUNITY_RT_DONATION_Id, :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
                                 AND IsCreatedFromBatchLog__c = true
                               ] ) {
            oppIds.put(opp.Id,opp);                                                
        }
         
        if(oppIds.size() == 0) { 
            return;
        }
        
        updateSharingSetting( oppIds );
        
    }
    
    
    public static Map<Id,String> updateSharingSetting( Map<Id, Opportunity> oppIds ){
        
        //list<Opportunity> childOpportunities = new List<Opportunity>();
        list<Opportunity> completedOpps = new List<opportunity>();
        list<Opportunity> setExpirationOpps = new List<opportunity>();
        Map<Id,Opportunity> mapUpdateOpportunity = new Map<Id,Opportunity>();
        Map<Id,Account> mapUpdateAccounts = new Map<Id,Account>();
        //Date dateForSetExpirationMethod = Date.newInstance(4000,12, 31);
        Set<String> batchLogIdsSet = new Set<String>();
        Set<String> sharingCodeSet = new Set<String>{'A001', 'A002', 'A003', 'B003', 'D009', 'D010', 'D011', 'D012', 
                                                        'P001', 'P002', 'P003', 'E131', 'E181'};
        Map<Id,String> errorMap = new Map<Id,String>();
        
        List<Opportunity> oppListQueried = [
            SELECT Id, recordType.Name, recordTypeId, rC_Giving__Payment_Method_Selected__r.No_Charge__c, rC_Giving__Payment_Method__c, 
                rC_Giving__Parent__r.rC_Giving__Payment_Method__c, rC_Giving__Parent__r.rC_Giving__Payment_Method_Selected__r.No_Charge__c, 
                stageName, Program_Type__c, Campaign_Type__c, Deposit_Site__c, campaignId, rC_Giving__Parent__r.campaignId,
                rC_Giving__Parent__r.rC_Giving__Payment_Method_Selected__r.Charge_Credit_Card_EFT__c, Related_Transaction__c, 
                Related_Transaction__r.rC_Giving__Parent__c, rC_Giving__Parent__c, AccountId, Sharing_Code_Override__c, 
                Sharing_Entity_Override__c, closeDate, amount,Sharing_Entity__c, Sharing_Code__c, Sharing_Entity_Affiliation__c, 
                account.Original_Join_Date__c, rC_Giving__Parent__r.program_Type__c, rC_Giving__Parent__r.Campaign_Type__c, 
                Recalculate_Revenue_Share__c, account.Membership_Expiration_date__c, Exclude_from_Revenue_Sharing__c, 
                CampaignIdText__c,Batch_Log__c, rC_Giving__External_ID__c,Account_Affiliation__c, Batch_Log__r.Tax_Date__c, 
                Batch_Log__r.Batch_Date__c, Adjustment_Sequence__c, rC_Giving__Parent__r.Batch_log__c 
            FROM Opportunity
            WHERE (rC_Giving__Parent__c IN :oppIds.keySet() OR Id IN :oppIds.keySet() 
                   OR Related_Transaction__r.rC_Giving__Parent__c IN :oppIds.keySet() )
            AND RecordTypeId IN (:OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, :OPPORTUNITY_RT_TRANSACTION_Id, :OPPORTUNITY_RT_SOFT_CREDIT_Id )
        ];
                                            
        for(Opportunity opp: oppListQueried){
            
            /* Traction(Mounica V): BGE-22, 12/2/2019 : Removing the logic to flag a batch to 'Membership and Revenue Sharing Resets Needed'  
             if( sharingCodeSet.contains(opp.Sharing_Code__c) ){
                 opp.Recalculate_Revenue_Share__c = false;
                 opp.rC_Giving__External_ID__c = 'Flagged for MembershipShareCode Reset';
                 if( opp.Adjustment_Sequence__c == NULL ){
                     batchLogIdsSet.add(opp.Batch_Log__c);
                 } else {
                     batchLogIdsSet.add(opp.rC_Giving__Parent__r.Batch_Log__c);
                 }
                 
                 errorMap.put(opp.id, 'Flagged');
             } BGE-22 END */
               
             if((opp.Recalculate_Revenue_Share__c == true) && (opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id
                     || opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id || opp.RecordTypeId == OPPORTUNITY_RT_SOFT_CREDIT_Id )
                     ){
                if(opp.RecordTypeId != OPPORTUNITY_RT_PLEDGE_PAYMENT_Id) {//If condition for I-301779
                    opp.Campaign_Type__c = opp.rC_Giving__Parent__r.Campaign_Type__c;
                    opp.program_Type__c = opp.rC_Giving__Parent__r.program_Type__c;
                }
                if((opp.Exclude_from_Revenue_Sharing__c == false 
                    && opp.rC_Giving__External_ID__c != 'Flagged for MembershipShareCode Reset') )
                {
                    completedOpps.add(opp);
                }else{
                    opp.Recalculate_Revenue_Share__c = false;
                    mapUpdateOpportunity.put(opp.id,opp);
                }
                
                if(opp.account.Membership_Expiration_date__c != Date.newInstance(4000,12, 31)){
                    setExpirationOpps.add(opp);
                }
             }
             else{
                mapUpdateOpportunity.put(opp.id,opp);
             }
        }
        /* Traction(Mounica V): BGE-22, 12/2/2019 : Removing the logic to flag a batch to 'Membership and Revenue Sharing Resets Needed'                                                  
        if( !batchLogIdsSet.isEmpty() ){
             Insert new AsyncRequest__c(AsyncType__c ='updateBatchLog_Status', Object_API_Name__c = 'Batch_Log__c',
                                        Params__c = String.join(new List<String>(batchLogIdsSet),','));
         } BGE-22 END */
        
        //fireSharingCode logic
        if(!completedOpps.isEmpty()){
            completedOpps = RevenueSharingShareCodes.setShareCode(completedOpps);
        }
        for(opportunity objOppty: completedOpps){   
            mapUpdateOpportunity.put(objOppty.Id,objOppty);
        }

        if(!setExpirationOpps.isEmpty()){
            RevenueSharingShareCodes.OpportunitiesAndAccountWrapper wrapper = RevenueSharingShareCodes.setExpirationDate(setExpirationOpps, mapUpdateAccounts, mapUpdateOpportunity);
            mapUpdateAccounts = wrapper.mapaccounts;
            mapUpdateOpportunity =  wrapper.mapOpportunities;
            //childOpportunities.addall(completedOpps);
        }
        
        for(Opportunity opp : mapUpdateOpportunity.values()) {
            
            if(opp.stageName!='Completed' && opp.stageName != 'Pending Failed' 
               && ( (opp.recordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id 
                     && opp.rC_Giving__Payment_Method_Selected__r.No_Charge__c ==  false 
                     && (opp.rC_Giving__Payment_Method__c == 'Charge Card' || opp.rC_Giving__Payment_Method__c == 'EFT')
                    )
                    || opp.recordTypeId == OPPORTUNITY_RT_TRANSACTION_Id 
                     && opp.rC_Giving__Parent__r.rC_Giving__Payment_Method_Selected__r.No_Charge__c == false 
                     && (opp.rC_Giving__Parent__r.rC_Giving__Payment_Method__c == 'Charge Card' 
                         || opp.rC_Giving__Parent__r.rC_Giving__Payment_Method__c == 'EFT')
                  )
            ){
                opp.StageName = 'Pending';
                
            } else if(opp.stageName!='Completed' && opp.stageName != 'Pending Failed' 
                      && opp.recordTypeId != OPPORTUNITY_RT_DONATION_Id 
                      && opp.recordTypeId != OPPORTUNITY_RT_PLEDGE_Id){
                opp.StageName = 'Completed';
                //Added by Aashita - I-318134, if Tax date on oppty is null and batch log's tax date is not null than 
                //populate this else populate it with batch date
                if(opp.Tax_Date__c == null) {
                    if(opp.Batch_Log__r.Tax_Date__c != null) {
                        opp.Tax_Date__c = opp.Batch_Log__r.Tax_Date__c;
                    } else if(opp.Batch_Log__r.Batch_Date__c != null) {
                        opp.Tax_Date__c = opp.Batch_Log__r.Batch_Date__c;
                    }
                }
            }  
        }

        if(mapUpdateOpportunity.values().size() > 0) {
            try{
                //Update Opportunities
                List<Database.SaveResult> srUpOpp = Database.update(mapUpdateOpportunity.values(), false);
                Utilities.processResults(srUpOpp, mapUpdateOpportunity.values(),  'BatchLogTriggerHandler','', 
                               'updateOpportunityStage error::  ' );

                //Update Accounts
                if(mapUpdateAccounts.values().size() > 0){
                    update mapUpdateAccounts.values();
                }

                
                //separate DML Operation to setRecalculate_Revenue_Share back to false. 
                //as it is setting to true when Sharing Code changes via Trigger.
                list<Opportunity> opportunitiesToUpdate = new list<Opportunity>();
                for(Opportunity opp: [SELECT Id, Recalculate_Revenue_Share__c 
                                      FROM Opportunity 
                                      WHERE Id IN :mapUpdateOpportunity.keySet()
                                       AND Recalculate_Revenue_Share__c = true] 
                ){
                    opp.Recalculate_Revenue_Share__c = false;
                    opportunitiesToUpdate.add(opp);
                }
                List<Database.SaveResult> srOppsUpdate = Database.update(opportunitiesToUpdate, false);
                Utilities.processResults(srOppsUpdate, opportunitiesToUpdate,  'BatchLogTriggerHandler','', 
                               'opportunitiesToUpdate error::  ' ); 
            }
            catch(exception e){
                apexLogHandler.apexLog log = new apexLogHandler.apexLog(
                'BatchLogTriggerHandler', 'updateOpportunityStage', e.getMessage());
              log.logException(e);
              log.saveLogs();
            }
        }
        return errorMap;
    }
    
    public static void updateGiftsFields(map<Id, Batch_Log__c> batchLogsToProcessMap) {
        list<Opportunity> oppsToUpdate = new list<Opportunity>();
        for(Opportunity opp : [SELECT Id, Batch_Log__c,Batch_Date__c, Bank_Date__c, Tax_Date__c, 
                                Deposit_Site__c, Batch_Log__r.Batch_Log_Type__c
                                FROM Opportunity
                                WHERE Batch_Log__c IN :batchLogsToProcessMap.keySet()
                                AND (RecordTypeId =: OPPORTUNITY_RT_PLEDGE_PAYMENT_Id
                                OR RecordTypeId =: OPPORTUNITY_RT_TRANSACTION_Id
                                OR RecordTypeId =: OPPORTUNITY_RT_SOFT_CREDIT_Id
                                OR RecordTypeId =: OPPORTUNITY_RT_DONATION_Id
                                OR RecordTypeId =: OPPORTUNITY_RT_PLEDGE_Id)]) {
           opp.Batch_Date__c = batchLogsToProcessMap.get(opp.Batch_Log__c).Batch_Date__c;
           if(opp.Batch_Log__r.Batch_Log_Type__c == 'Manual') {
               opp.Bank_Date__c = batchLogsToProcessMap.get(opp.Batch_Log__c).Bank_Date__c;
               opp.Tax_Date__c = batchLogsToProcessMap.get(opp.Batch_Log__c).Tax_Date__c;
               opp.Deposit_Site__c = batchLogsToProcessMap.get(opp.Batch_Log__c).Deposit_Site__c;
           }
           oppsToUpdate.add(opp);
        }
        if(!oppsToUpdate.isEmpty()) {
            try{
                update oppsToUpdate;
            }catch(exception e){
                apexLogHandler.apexLog log = new apexLogHandler.apexLog(
                'BatchLogTriggerHandler', 'updateGiftsFields', e.getMessage());
              log.logException(e);
              log.saveLogs();
            }
        }
    }
}