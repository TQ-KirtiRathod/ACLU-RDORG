/*
*
*Name  :  BatchOnCampaignMember
*Author:  Appirio India (Sandeep Soni)
*Date  :  June 07, 2017
*Purpose : Batch class to update Account with a list of campain member that the primary contact was part of
*
*/
public with sharing class BatchOnCampaignMember implements Database.Batchable<sobject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        //Integer year = Date.today().year() - 2;
        Date last2Days = Date.today() - 2; 
        //System.debug('previous two days: ' + last2Days);
        String query = 'SELECT ID, Campaign.rC_Giving__Source_Code__c, Contact.rC_Bios__Preferred_Contact__c, '+
                       'Contact.AccountId,ContactId '+
                       'FROM CampaignMember '+
                       'WHERE Contact.rC_Bios__Preferred_Contact__c = true '+
                       'AND CreatedDate >=: last2Days';
        System.debug('query:: ' + query);
       
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<CampaignMember> scope) {
        //preps acct id for query
        Set<Id> scopeAcctIds = new Set<Id>();
        Set<Id> scopeContactIds = new Set<Id>();
        for(CampaignMember cm : scope){
            scopeAcctIds.add(cm.Contact.AccountId);
            scopeContactIds.add(cm.ContactId);
        }
        //gets last 12 months campaignMembers having Contact = Contact of last 2 days campaignMembers
        Integer year = Date.today().year() - 1;
        list<CampaignMember> listCampaignMembers = [SELECT ID, Campaign.rC_Giving__Source_Code__c, Contact.rC_Bios__Preferred_Contact__c,
                                                        Contact.AccountId,ContactId
                                                        FROM CampaignMember
                                                        WHERE ContactId IN :scopeContactIds
                                                        AND CALENDAR_YEAR(CreatedDate) >=: year];
                                                        
        //gets list of accounts that are in scope and being processed by bup
        List<rC_Connect__Batch_Upload__c> inProcessBatchUpload = new List<rC_Connect__Batch_Upload__c>();
        inProcessBatchUpload = [SELECT id, rC_Connect__Batch_Upload_Status__c, rC_Connect__Batch_Upload_Account_Matched__c 
                                   FROM rC_Connect__Batch_Upload__c 
                                   WHERE rC_Connect__Batch_Upload_Status__c NOT IN ('Committed', 'Flagged')
                                   AND rC_Connect__Batch_Upload_Account_Matched__c IN :scopeAcctIds];
        Set<Id> bupAcctIds = new Set<Id>();
        if(inProcessBatchUpload.size()>0){
          for(rC_Connect__Batch_Upload__c bu : inProcessBatchUpload){
            bupAcctIds.add(bu.rC_Connect__Batch_Upload_Account_Matched__c);
          }
        }
        Map<Id, CampaignMember> mapAccount = new Map<Id, CampaignMember>();
        List<Account> lstUpdateAccount = new List<Account>();

        for (CampaignMember cm : listCampaignMembers) {
            mapAccount.put(cm.Contact.AccountId, cm);
        }
        Account acc = new Account();
        String CampaignSent = '';
        Map<Id, Account> mapAccount1 = new Map<Id, Account>([SELECT ID, Campaigns_Sent__c FROM Account
                                            WHERE ID IN :mapAccount.keySet()]);
        for (Account account : mapAccount1.values()) {
            for (CampaignMember camp : listCampaignMembers) {//replaced scope by listCampaignMembers to include all the campaign members queried
                //System.debug('campAccount' + camp.Contact.AccountId);
                System.debug('account::' + account.id);
                if (camp.Contact.AccountId == account.id && !bupAcctIds.contains(account.id)) {
                    if ((camp.Campaign.rC_Giving__Source_Code__c != null) && (account.Campaigns_Sent__c == null || account.Campaigns_Sent__c == '')) {
                        account.Campaigns_Sent__c = camp.Campaign.rC_Giving__Source_Code__c;
                    } else {
                        if (camp.Campaign.rC_Giving__Source_Code__c != null && !account.Campaigns_Sent__c.contains(camp.Campaign.rC_Giving__Source_Code__c))
                            account.Campaigns_Sent__c = account.Campaigns_Sent__c + ':' + camp.Campaign.rC_Giving__Source_Code__c;
                    }
                    //System.debug('account record:: ' + account);
                }
            }
            lstUpdateAccount.add(account);

        }
        try {
            update lstUpdateAccount;
        } catch (Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchOnCampaignMember', 'execute', e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
    }
    public void finish(Database.BatchableContext bc) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchOnCampaignMember FINISHED');
        log.saveLogs();
    }
}