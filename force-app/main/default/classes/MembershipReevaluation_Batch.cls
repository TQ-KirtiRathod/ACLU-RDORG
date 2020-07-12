/*
*
*Name  :  MembershipReevaluation_Batch
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  Feb 16, 2017
*Purpose : Batch Class To Reevaluate Membership Expiration Date
*
*/
global without sharing Class MembershipReevaluation_Batch implements Database.Batchable<sObject>, Database.Stateful {

    global String queryString;
    global Set<Id> accountsAlreadyProcessed;
    global static DateTime lastRunTime;

    static {

          lastRunTime = Last_Run_Time_Of_Batch__c.getInstance('MembershipReevaluation_Batch') != null && 
                           Last_Run_Time_Of_Batch__c.getValues('MembershipReevaluation_Batch').Last_Run_Time__c != null?
                           Last_Run_Time_Of_Batch__c.getValues('MembershipReevaluation_Batch').Last_Run_Time__c :
                           Date.Today();
    }

    global MembershipReevaluation_Batch() {
        accountsAlreadyProcessed = new Set<Id>();
        queryString = 'Select Id, New_Membership_Set_To_Date__c, AccountId, Membership_Reevaluation_Needed__c';
        queryString += ' From Opportunity';
        queryString += ' WHERE Membership_Reevaluation_Needed__c = True  AND LastModifiedDate > ';
        queryString += lastRunTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
    }

    global MembershipReevaluation_Batch(Id opptyId) {
        accountsAlreadyProcessed = new Set<Id>();
        queryString = 'Select Id, New_Membership_Set_To_Date__c, AccountId, Membership_Reevaluation_Needed__c';
        queryString += ' From Opportunity';
        queryString += ' WHERE Membership_Reevaluation_Needed__c = True';
        queryString += ' AND Id = \''+opptyId+'\' AND LastModifiedDate > ';
        queryString += lastRunTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Set<Id> accountIds = new Set<Id>();
        List<Account> accountsToUpdate = new List<Account>();
        List<Opportunity> opptyToUpdateLst = new List<Opportunity>();

        Boolean qualifiedOpptyFound = false;

        for(Opportunity objOppty : (List<Opportunity>)scope) {
            if(!accountsAlreadyProcessed.contains(objOppty.AccountId)) {
                accountIds.add(objOppty.AccountId);
            }
        }
        
        for(Account objAccount : [SELECT Id, Last_Membership_Gift__c, Membership_Expiration_date__c
                                , (SELECT Id, Membership_Reevaluation_Needed__c, New_Membership_Set_To_Date__c 
                                    FROM Opportunities
                                    WHERE New_Membership_Set_To_Date__c != null 
                                    ORDER BY New_Membership_Set_To_Date__c DESC)
                                  FROM Account WHERE Id IN: accountIds]) {
            //Opportunity prevQualifiedOppty;
            qualifiedOpptyFound = false;

            for(Opportunity objOppty : objAccount.Opportunities) {

                // excludes the Opp with Membership_Reevaluation_Needed__c set, which triggered this re-eval in 
                //first place
                if(!objOppty.Membership_Reevaluation_Needed__c) {

                    // Find that previous membership setting gift and set it on the Account (reverting)
                    if(!qualifiedOpptyFound && objOppty.New_Membership_Set_To_Date__c != null) {
                        objAccount.Last_Membership_Gift__c = objOppty.Id;
                        objAccount.Membership_Expiration_date__c = objOppty.New_Membership_Set_To_Date__c;
                        accountsToUpdate.add(objAccount);
                        qualifiedOpptyFound = true;
                    }

                // The Opp that triggered the re-eval, so reset the flag and null out its Exp Date so it is not 
                //picked up in future.
                } else {
                    objOppty.Membership_Reevaluation_Needed__c = false;
                    objOppty.New_Membership_Set_To_Date__c = null;
                    opptyToUpdateLst.add(objOppty);
                }
            }

            if(!qualifiedOpptyFound) {
                objAccount.Last_Membership_Gift__c = null;
                objAccount.Membership_Expiration_date__c = null;
                accountsToUpdate.add(objAccount);
            }
        }

        try {
            if(!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }

            if(opptyToUpdateLst.size() > 0) {
                update opptyToUpdateLst;
            }
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('MembershipReevaluation_Batch','execute',
                                                                        e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
    }

    global void finish(Database.BatchableContext BC) {
        if( Last_Run_Time_Of_Batch__c.getInstance('MembershipReevaluation_Batch') == null) {
           Last_Run_Time_Of_Batch__c cs = new Last_Run_Time_Of_Batch__c(Name = 'MembershipReevaluation_Batch',
                                                Last_Run_Time__c=System.now());
           insert cs;
         }
         else {
           Last_Run_Time_Of_Batch__c cs = Last_Run_Time_Of_Batch__c.getInstance('MembershipReevaluation_Batch');
           cs.Last_Run_Time__c = system.now();
           update cs;
         }
    }
}