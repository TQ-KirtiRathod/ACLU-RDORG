/*
*
*Name  :  BatchOnActionTaken
*Author:  Appirio India (Sandeep Son)
*Date  :  Jun 05, 2017
*Purpose : This batch class will update all fields of action object based on action taken Example: 
*          if action taken(testAction) has two Initial_Market_Source_Channel__c='fb' then this batch process fetch all action taken 
*          based on last batch run date(Last_Run_Time_Of_Batch__c.Last_Run_Time__c) and update the number of count in action.
*
*/
public with sharing class BatchOnActionTaken implements Database.Batchable<sobject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime lastRunTime = Last_Run_Time_Of_Batch__c.getInstance('BatchOnActionTaken') != null && Last_Run_Time_Of_Batch__c.getValues('BatchOnActionTaken').Last_Run_Time__c != null ?
                               Last_Run_Time_Of_Batch__c.getValues('BatchOnActionTaken').Last_Run_Time__c :
                               Date.Today();
        //System.debug('lastRunTime::' + lastRunTime);

        String query = 'SELECT Id, Action__c, Initial_Market_Source_Channel__c,Market_Source__c, ' +
                       'Prior_Action_Count__c, Contact__c FROM sb_Actions_Taken__c WHERE CreatedDate > :lastRunTime';
        //System.debug('query:: ' + query);
        return Database.getQueryLocator(query);
    }


    public void execute(Database.BatchableContext bc, List<sb_Actions_Taken__c> scope) {

        /*For Report (Previous Actions Taken by Contact): Here we are updating field Prior_Action_Count__c*/
        Map<String, sb_Actions_Taken__c> mapActionTaken1 = new Map<String, sb_Actions_Taken__c>();
        for (sb_Actions_Taken__c actionTaken : scope) {
            mapActionTaken1.put(actionTaken.Contact__c, actionTaken);//collecting the contact id's for qry
        }
        List<Contact> lstContact = [SELECT ID, Lifetime_Total_Actions__c FROM Contact WHERE ID in :mapActionTaken1.keySet()];
        List<sb_Actions_Taken__c> updatePriorActionTaken = new List<sb_Actions_Taken__c>();
        for (Contact con : lstContact) {
            sb_Actions_Taken__c act = mapActionTaken1.get(con.id);
            if (act.Prior_Action_Count__c == null) {
                act.Prior_Action_Count__c = 0;
            }
            act.Prior_Action_Count__c = con.Lifetime_Total_Actions__c;
            updatePriorActionTaken.add(act);
        }
        try {
            update updatePriorActionTaken;  //updates action taken populating Prior_Action_Count__c
        } catch (Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchOnActionTaken', '', 'execute ::' + e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
        /*End Previous Actions Taken by Contact population*/

        /*start update of related Action record for sum of marketing source */
        Map<String, sb_Actions_Taken__c> mapActionTaken = new Map<String, sb_Actions_Taken__c>();
        /*For storing action taken records into map and passs it to below query as keyset*/
        for (sb_Actions_Taken__c actionTaken : scope) {
            mapActionTaken.put(actionTaken.Action__c, actionTaken);
        }

        /*For fetching only those action that are exist in Action Taken*/
        Map<Id, sb_action__c> mapAction = new Map<Id, sb_action__c>([SELECT ID, Actions_Taken_Market_Source_by_Email__c,
                Actions_Taken_Market_Source_by_Facebook__c, Actions_Taken_Market_Source_by_Twitter__c,
                Actions_Taken_Market_Source_by_Web__c, Actions_Taken_Market_Source_by_Banner__c,
                Actions_Taken_Market_Source_by_Google_Ad__c, Actions_Taken_Market_Source_by_Other__c FROM sb_action__c
                WHERE ID IN :mapActionTaken.keySet()]);
        List<sb_action__c> lstUpdateAction = new List<sb_action__c>();

        Map<Id, sb_action__c> mapUpdateAction = new Map<Id, sb_action__c>();
        /*For fetching action taken records*/
        for (sb_Actions_Taken__c sbActionTaken : scope) {

            /*fetch an action record based on action taken id from map*/
            sb_action__c action = mapAction.get(sbActionTaken.Action__c);
            /*if action taken's Initial_Market_Source_Channel__c column has eml value then update the count of action's
            Actions_Taken_Market_Source_by_Email__c field.*/
            if (sbActionTaken.Initial_Market_Source_Channel__c == 'eml') {
                /*Assigning zero value when action's Actions_Taken_Market_Source_by_Email__c is null*/
                if (action.Actions_Taken_Market_Source_by_Email__c == null) {
                    action.Actions_Taken_Market_Source_by_Email__c = 0;
                }
                /*update action taken market source email count with plus one*/
                action.Actions_Taken_Market_Source_by_Email__c += 1;
            }
            if (sbActionTaken.Initial_Market_Source_Channel__c == 'fb') {
                if (action.Actions_Taken_Market_Source_by_Facebook__c == null) {
                    action.Actions_Taken_Market_Source_by_Facebook__c = 0;
                }
                action.Actions_Taken_Market_Source_by_Facebook__c += 1;
            }
            if (sbActionTaken.Initial_Market_Source_Channel__c == 'tw') {
                if (action.Actions_Taken_Market_Source_by_Twitter__c == null) {
                    action.Actions_Taken_Market_Source_by_Twitter__c = 0;
                }
                action.Actions_Taken_Market_Source_by_Twitter__c += 1;
            }
            if (sbActionTaken.Initial_Market_Source_Channel__c == 'web') {
                if (action.Actions_Taken_Market_Source_by_Web__c == null) {
                    action.Actions_Taken_Market_Source_by_Web__c = 0;
                }
                action.Actions_Taken_Market_Source_by_Web__c += 1;
            }
            if (sbActionTaken.Initial_Market_Source_Channel__c == 'ban') {
                if (action.Actions_Taken_Market_Source_by_Banner__c == null) {
                    action.Actions_Taken_Market_Source_by_Banner__c = 0;
                }
                action.Actions_Taken_Market_Source_by_Banner__c += 1;
            }
            if (sbActionTaken.Initial_Market_Source_Channel__c == 'gad') {
                if (action.Actions_Taken_Market_Source_by_Google_Ad__c == null) {
                    action.Actions_Taken_Market_Source_by_Google_Ad__c = 0;
                }
                action.Actions_Taken_Market_Source_by_Google_Ad__c += 1;
            }
            if (sbActionTaken.Initial_Market_Source_Channel__c == 'oth') {
                if (action.Actions_Taken_Market_Source_by_Other__c == null) {
                    action.Actions_Taken_Market_Source_by_Other__c = 0;
                }
                action.Actions_Taken_Market_Source_by_Other__c += 1;
            }
            /*store all updated action into a map, here if condition for validating mapupdateAction has that action or not.*/
            if (mapUpdateAction.ContainsKey(action.id)) {
                /*if map has that action then we will fetch existing action record and update it with latest action object*/
                sb_action__c act = mapUpdateAction.get(action.id);
                act = action;
            } else {
                /*if map is empty or doesn't has that action record then add that record*/
                mapUpdateAction.put(action.id, action);
            }
        }
        /*convert map into list*/
        for (sb_action__c updateAct : mapUpdateAction.values()) {
            lstUpdateAction.add(updateAct);
        }
        /*update all action after update the count*/

        try {
            update lstUpdateAction;
        } catch (Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchOnActionTaken', '', 'execute :: ' + e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
    }


    public void finish(Database.BatchableContext bc) {
        if (Last_Run_Time_Of_Batch__c.getInstance('BatchOnActionTaken') == null) {
            Last_Run_Time_Of_Batch__c cs = new Last_Run_Time_Of_Batch__c(Name = 'BatchOnActionTaken', Last_Run_Time__c = System.now());
            insert cs;
        } else {
            Last_Run_Time_Of_Batch__c cs = Last_Run_Time_Of_Batch__c.getInstance('BatchOnActionTaken');
            cs.Last_Run_Time__c = system.now();
            update cs;
        }

        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchOnActionTaken','','BatchOnActionTaken FINISHED');
        log.saveLogs();
    }
}