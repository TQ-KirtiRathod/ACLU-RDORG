/*
*
*Name  :  ReleaseBatchLog_Batch
*Author:  Appirio India (Bhavesh Malviya)
*Date  :  March 30, 2018
*Purpose : ReleaseBatchLog_Batch is a batch class which is initiated when a manual Batch Log is release and has a large count Expected Count,
*          this process is the asyncronous process to update the opportunity status to Compledted or Pending
*
*/
global class ReleaseBatchLog_Batch implements Database.Batchable<sObject>, Database.Stateful{
    Global Id batchLogId;
    //Global Map<Id, List<Opportunity>> accIdWithOppList = new Map<Id, List<Opportunity>>();
    Global static Map<String,Schema.RecordTypeInfo> opptyRTMap;
    Global static String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
    Global static String OPPORTUNITY_RT_SOFT_CREDIT_Id;
    Global static String OPPORTUNITY_RT_TRANSACTION_Id;
    Global static String OPPORTUNITY_RT_DONATION_Id;
    Global static String OPPORTUNITY_RT_PLEDGE_Id;
    Global Boolean isFlaggedBatch = false;
    Global Map<Id, String> errorMap;
    Global String userEmailId;
    
    static{
        opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        
        OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_PLEDGE_PAYMENT).getRecordTypeId();
        OPPORTUNITY_RT_SOFT_CREDIT_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_SOFTCREDIT).getRecordTypeId();
        OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_TRANSACTION).getRecordTypeId();
        OPPORTUNITY_RT_DONATION_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_DONATION).getRecordTypeId();
        OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get(ACLU_Constants.CONST_RCDTYPE_PLEDGE).getRecordTypeId();
        
    }
    
    global ReleaseBatchLog_Batch(Id bLogId, String userEmailId) {
        this.userEmailId = userEmailId;
        this.batchLogId = bLogId;
        this.isFlaggedBatch = false;
        errorMap = new Map<id, String>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([
            SELECT Id, recordType.Name, recordTypeId, rC_Giving__Payment_Method_Selected__r.No_Charge__c, rC_Giving__Payment_Method__c, 
                rC_Giving__Parent__r.rC_Giving__Payment_Method__c, rC_Giving__Parent__r.rC_Giving__Payment_Method_Selected__r.No_Charge__c,  
                stageName, Program_Type__c, Campaign_Type__c, Deposit_Site__c, 
                rC_Giving__Parent__r.rC_Giving__Payment_Method_Selected__r.Charge_Credit_Card_EFT__c, Related_Transaction__c, 
                Related_Transaction__r.rC_Giving__Parent__c, rC_Giving__Parent__c, AccountId, Sharing_Code_Override__c, 
                Sharing_Entity_Override__c, closeDate, amount, Sharing_Entity__c, Sharing_Code__c, Sharing_Entity_Affiliation__c, 
                account.Original_Join_Date__c, rC_Giving__Parent__r.program_Type__c, rC_Giving__Parent__r.Campaign_Type__c, 
                campaignId, rC_Giving__Parent__r.campaignId, Recalculate_Revenue_Share__c, account.Membership_Expiration_date__c, 
                Exclude_from_Revenue_Sharing__c, CampaignIdText__c,Batch_Log__c, rC_Giving__External_ID__c,Account_Affiliation__c, 
                Batch_Log__r.Tax_Date__c, Batch_Log__r.Batch_Date__c 
            FROM Opportunity WHERE Batch_Log__c =: batchLogId
            AND RecordTypeId IN (:OPPORTUNITY_RT_DONATION_Id, :OPPORTUNITY_RT_PLEDGE_PAYMENT_Id)
            AND IsCreatedFromBatchLog__c = true
        ]);     
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(scope);
        //for( Opportunity opp : (List<Opportunity>)scope ){
        //    oppMap.put(opp.id, opp);
        //}
        errorMap.putAll(BatchLogTriggerHandler.updateSharingSetting( oppMap ));
    }

    global void finish(Database.BatchableContext BC) {
        String errors = '';
        Boolean isFlaggedBatch = false;
        Batch_Log__c blog = new Batch_Log__c(Id=batchLogId);
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        blog = [Select Id, Batch_Log_Status__c, Name FROM Batch_Log__c WHERE Id = : batchLogId ];
        if( errorMap.keySet().size() > 0 ){
            if(errorMap.values()[0] == 'Flagged'){
                isFlaggedBatch = true;
                blog.Has_Error_Details__c = false;
                blog.Error_Details__c = null; 
            } else {
                oppMap = new Map<Id, Opportunity>([Select Id, Batch_Sequence__c,Batch_Log__r.Name, batch_log__c, 
                                                      Sharing_Code__c, stageName 
                                                   FROM Opportunity where Id in:errorMap.keySet()]);
                for(Opportunity opp : oppMap.values() ){
                    errors+= '[Id:'+ opp.Id + ', Batch_Sequence__c:' + opp.Batch_Sequence__c + ' stageName:'+opp.stageName
                             + ' Error:'+errorMap.get(opp.Id)+']\n';
                }
                if( errors == '' ){
                    errors = errorMap.values()[0];
                }
                blog.Has_Error_Details__c = true;
                blog.Error_Details__c = errors;
                blog.Batch_Log_Status__c = 'See Error Detail';
            }
        } else {
            blog.Has_Error_Details__c = false;
            blog.Error_Details__c = null;
        }
        
        try{
            update blog;
        } Catch( Exception e ){
            saveApexLog('ReleaseBatchLog_Batch','finish Method', e);
        }
        
        //email generation
        String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm() + '/'; 
        String htmlBody = 'Batch Log record <a href='+sfdcURL+blog.Id+'>'+blog.Name+'</a> ';
        if( blog.Batch_Log_Status__c == 'Membership and Revenue Sharing Resets Needed'){
            htmlBody+= ' has not released and Membership and Sharing reset is needed.';
        } else if ( isFlaggedBatch ){
            htmlBody+= ' has processed with Batch Log Status - Membership and Revenue Sharing Resets Needed.';
        }
        else {
            htmlBody+= ' has successfully released.';
        }
        //open table..
        if( !isFlaggedBatch){
            if( errorMap.keySet().size() > 0 ){
                htmlBody += ' with following errors.</br>'
                         + '<table border="0" ><br></br><tr><th style="text-align:left">Id</th>'
                         + '<th style="text-align:left">Batch Sequence </th><th style="text-align:left">Error</th></tr>';
                for(Id str: errorMap.keySet() ){
                    htmlBody += '<tr><td><a href='+sfdcURL+str+'>' + str +' </a></td><td>'+oppMap.get(str).Batch_Sequence__c
                             +'</td><td>'+errorMap.get(str)+'</td></tr>';
                }
                htmlBody += '</table>';
                }
        }
        
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        String emailId = userEmailId;
        String[] sendingTo = new String[]{emailId}; 
        semail.setToAddresses(sendingTo); 
        
        semail.setSubject('Batch Release Complete'); 
        semail.setHtmlBody(htmlBody); 
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail});   
    }

    
    global void saveApexLog(String className, String methodName, Exception e){
        apexLogHandler.apexLog log = new apexLogHandler.apexLog(className, methodName, e.getMessage());
        log.logException(e);
        log.saveLogs();
    }

}