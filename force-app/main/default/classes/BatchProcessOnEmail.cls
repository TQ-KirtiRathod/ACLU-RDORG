/*
*
*Name  :  BatchProcessOnEmail
*Author:  Appirio India (Sandeep Soni)
*Date  :  Jun 01, 2017
*Purpose : This is a batch process that will execute at a time and update the count of sb_action__c.
*          Actions_Taken_by_New_Email__c field with +1 count.  
*          Also updated are the Email Market Types on Action based on last batch run date(Last_Run_Time_Of_Batch__c.Last_Run_Time__c)
*
*/
public class BatchProcessOnEmail implements Database.Batchable<sobject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //if the custom setting is not configured, it sets the start at the current day
        DateTime lastRunTime = Last_Run_Time_Of_Batch__c.getInstance('BatchProcessOnEmail') != null 
            && Last_Run_Time_Of_Batch__c.getValues('BatchProcessOnEmail').Last_Run_Time__c != null ?
            Last_Run_Time_Of_Batch__c.getValues('BatchProcessOnEmail').Last_Run_Time__c :
        Date.Today();
        
        String query = 'SELECT Id, Acquisition_Form_ID__c, Acquisition_Initial_Market_SourceChannel__c '+
            'FROM Email__c WHERE CreatedDate > :lastRunTime';
        
        return Database.getQueryLocator(query);
    }
    
    
    public void execute(Database.BatchableContext bc, List<Email__c> scope) {
        /*Market Sources by Email*/
        //jw this will need to change when springboard id changes type
        Map<Decimal, Email__c> mapEmail = new Map<Decimal, Email__c>();
        /*For storing action taken records into map and passs it to below query as keyset*/
        for (Email__c email : scope) {
            if (email.Acquisition_Form_ID__c != null) {
                mapEmail.put(Decimal.valueOf(email.Acquisition_Form_ID__c), email);
            }
        }
        /*For fetching only those action that are exist in Action Taken*/
        List<sb_action__c> lstAction = [SELECT ID, Springboard_ID__c, Actions_Taken_by_New_Email__c, Email_Market_Source_by_Email__c,
                                        Email_Market_Source_by_Facebook__c, Email_Market_Source_by_Twitter__c,
                                        Email_Market_Source_by_Web__c, Email_Market_Source_by_Banner__c,
                                        Email_Market_Source_by_Google_Ads__c, Email_Market_Source_By_Other__c FROM sb_action__c
                                        WHERE Springboard_ID__c IN :mapEmail.keySet()];
        //jw this will be updated when springboard id changes type
        Map<Decimal, sb_action__c> mapAction = new Map<Decimal, sb_action__c>();
        for (sb_action__c act : lstAction) {
            if (act.Springboard_ID__c != null)
                mapAction.put(act.Springboard_ID__c, act);
        }
        
        Map<String, sb_action__c> mapUpdateAction = new Map<String, sb_action__c>(); //map of actions to be updated
        /*For fetching action taken records*/
        // altered 8/4 DMR for (Email__c emailObj : mapEmail.values()) {
        for (Email__c emailObj : scope) {
            /*fetch an action record based on action taken id from map*/
            sb_action__c action = null;
            if (mapAction != null && emailObj != null && emailObj.Acquisition_Form_ID__c != null) {
                //gets the action to be updated matching springoard id to acq form id
                action = mapAction.get(Decimal.valueOf(emailObj.Acquisition_Form_ID__c));
            }
            if (action != null && emailObj.Acquisition_Form_ID__c != null && action.Springboard_ID__c != null) { //validates the reocrds can tie toghether  
                if ((String.valueOf(action.Springboard_ID__c).equalsIgnoreCase(String.valueOf(emailObj.Acquisition_Form_ID__c)))) {
                    /*if Actions_Taken_by_New_Email__c is null then assign it with 0 value*/
                    if (action.Actions_Taken_by_New_Email__c == null) {
                        action.Actions_Taken_by_New_Email__c = 0;
                    }
                    /*increse the count of Actions_Taken_by_New_Email__c with +1*/
                    action.Actions_Taken_by_New_Email__c += 1;
                }
                /*if action taken's Initial_Market_Source_Channel__c column has eml value then update the count of action's
Actions_Taken_Market_Source_by_Email__c field.*/
                if (emailObj.Acquisition_Initial_Market_SourceChannel__c == 'eml') {
                    /*Assigning zero value when action's Actions_Taken_Market_Source_by_Email__c is null*/
                    if (action.Email_Market_Source_by_Email__c == null) {
                        action.Email_Market_Source_by_Email__c = 0;
                    }
                    /*update action taken market source email count with plus one*/
                    action.Email_Market_Source_by_Email__c += 1;
                }
                if (emailObj.Acquisition_Initial_Market_SourceChannel__c == 'fb') {
                    if (action.Email_Market_Source_by_Facebook__c == null) {
                        action.Email_Market_Source_by_Facebook__c = 0;
                    }
                    action.Email_Market_Source_by_Facebook__c += 1;
                }
                if (emailObj.Acquisition_Initial_Market_SourceChannel__c == 'tw') {
                    if (action.Email_Market_Source_by_Twitter__c == null) {
                        action.Email_Market_Source_by_Twitter__c = 0;
                    }
                    action.Email_Market_Source_by_Twitter__c += 1;
                }
                if (emailObj.Acquisition_Initial_Market_SourceChannel__c == 'web') {
                    if (action.Email_Market_Source_by_Web__c == null) {
                        action.Email_Market_Source_by_Web__c = 0;
                    }
                    action.Email_Market_Source_by_Web__c += 1;
                }
                if (emailObj.Acquisition_Initial_Market_SourceChannel__c == 'ban') {
                    if (action.Email_Market_Source_by_Banner__c == null) {
                        action.Email_Market_Source_by_Banner__c = 0;
                    }
                    action.Email_Market_Source_by_Banner__c += 1;
                }
                if (emailObj.Acquisition_Initial_Market_SourceChannel__c == 'gad') {
                    if (action.Email_Market_Source_by_Google_Ads__c == null) {
                        action.Email_Market_Source_by_Google_Ads__c = 0;
                    }
                    action.Email_Market_Source_by_Google_Ads__c += 1;
                }
                if (emailObj.Acquisition_Initial_Market_SourceChannel__c == 'oth') {
                    if (action.Email_Market_Source_By_Other__c == null) {
                        action.Email_Market_Source_By_Other__c = 0;
                    }
                    action.Email_Market_Source_By_Other__c += 1;
                }
                /*store all updated action into a map, here if condition for validating mapupdateAction has that action or not.*/
                if (mapUpdateAction.ContainsKey(String.valueOf(action.Springboard_ID__c))) {
                    /*if map has that action then we will fetch existing action record and update it with latest action object*/
                    sb_action__c act = mapUpdateAction.get(String.valueOf(action.Springboard_ID__c));
                    act = action;
                    mapUpdateAction.put(String.valueof(action.Springboard_ID__c), act);
                } else {
                    /*if map is empty or doesn't has that action record then add that record*/
                    mapUpdateAction.put(String.valueof(action.Springboard_ID__c), action);
                }
            }
        }
        
        try{
            update mapUpdateAction.values();
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchProcessOnEmail','execute',e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
    }
    
    
    public void finish(Database.BatchableContext bc) {
        //set the run time after batch completes
        if (Last_Run_Time_Of_Batch__c.getInstance('BatchProcessOnEmail') == null) {
            Last_Run_Time_Of_Batch__c cs = new Last_Run_Time_Of_Batch__c(Name = 'BatchProcessOnEmail', Last_Run_Time__c = System.now());
            insert cs;
        } else {
            Last_Run_Time_Of_Batch__c cs = Last_Run_Time_Of_Batch__c.getInstance('BatchProcessOnEmail');
            cs.Last_Run_Time__c = system.now();
            update cs;
        }
        
        Id batchInstanceId = Database.executeBatch(new BatchProcessOnGiving(), 200);
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchProcessOnEmail FINISHED');
        log.saveLogs();
    }
}