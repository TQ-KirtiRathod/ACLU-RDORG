/*
*
*Name  :  zSBDonationIdFixer
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  May 27, 2018
*Purpose : One Time batch to populate SB_Donation_Id__c on Pledge payments from matching Batch Upload records. 
*          If no Batch Upload is found, the field is set to null.  Used for data fix only
*
*/
global class zSBDonationIdFixer implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Id OPPORTUNITY_PLEDGE_RECORDTYPE_ID = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
        return Database.getQueryLocator([SELECT Id, SB_Donation_id__c
                                         FROM Opportunity
                                         WHERE RecordTypeId = :OPPORTUNITY_PLEDGE_RECORDTYPE_ID
                                         AND LastModifiedDate > 2018-02-02T00:00:00.00z ]);
                                         //AND SB_Donation_id__c != null]);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        if(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) {
            set<Id> pledgeIds = new set<Id>();
            set<Id> parentIdsSet = new set<Id>();
            list<Opportunity> pledgePaymentsToProcess = new list<Opportunity>();
            Date startDate = Date.newInstance(2018,2,1);
            Date endDate = Date.newInstance(2018,5,31);
            list<Opportunity> oppsToUpdate = new list<Opportunity>();
            for(Opportunity opp : (list<Opportunity>)scope) {
                if(opp.SB_Donation_id__c !=null){
                    pledgeIds.add(opp.Id);
                }
            }
            Id OPPORTUNITY_PLEDGE_PAYMENT_RECORDTYPE_ID = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
            for(Opportunity op : [SELECT Id, SB_Donation_id__c, rc_Giving__Parent__c,//,rc_Giving__Parent__r.SB_Donation_id__c, Sustainer_First_Payment__c 
                                    StageName, CloseDate
                                    FROM Opportunity 
                                    WHERE rc_Giving__Parent__c IN :pledgeIds
                                    AND RecordtypeId = :OPPORTUNITY_PLEDGE_PAYMENT_RECORDTYPE_ID]) {
                /*if(!op.Sustainer_First_Payment__c && op.SB_Donation_id__c == op.rc_Giving__Parent__r.SB_Donation_id__c) {
                    op.SB_Donation_id__c = null;
                    oppsToUpdate.add(op);
                }*/
                if(op.StageName == 'Open') {
                    op.SB_Donation_id__c = null;
                    oppsToUpdate.add(op);
                } else if((op.StageName == 'Completed' || op.StageName == 'Pending') && op.CloseDate >= startDate && op.CloseDate <= endDate) {
                    parentIdsSet.add(op.rc_Giving__Parent__c);
                    pledgePaymentsToProcess.add(op);
                } else if(op.StageName == 'Completed' && op.CloseDate < startDate && op.SB_Donation_id__c != null) {
                    op.SB_Donation_id__c = null;
                    oppsToUpdate.add(op);
                }
            }
            map<String, String> batchUploadMap = new map<String, String>();
            for(rC_Connect__Batch_Upload__c bu : [SELECT Id, SB_Donation_Id__c, rC_Connect__Giving_Close_Date__c, rC_Connect__Batch_Upload_Giving_Matched__c
                                                    FROM rC_Connect__Batch_Upload__c
                                                    WHERE rC_Connect__Batch_Upload_Giving_Matched__c IN :parentIdsSet]) {
                batchUploadMap.put(bu.rC_Connect__Giving_Close_Date__c + '~' + bu.rC_Connect__Batch_Upload_Giving_Matched__c, bu.SB_Donation_Id__c);                                                        
            }
            
            for(Opportunity opp : pledgePaymentsToProcess) {
                if(batchUploadMap.containsKey(opp.CloseDate + '~' + opp.rc_Giving__Parent__c)) {
                    opp.SB_Donation_id__c = batchUploadMap.get(opp.CloseDate + '~' + opp.rc_Giving__Parent__c);
                    oppsToUpdate.add(opp);
                } else {
                    opp.SB_Donation_id__c = null;
                    oppsToUpdate.add(opp);
                }
            }
            if(oppsToUpdate.size() > 0) {
                list<Database.SaveResult> updatedOppsResult = Database.update(oppsToUpdate);
                Utilities.processResults(updatedOppsResult, oppsToUpdate, 'zSBDonationIdFixer', '', 'Opportunities update failed :: ');
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('zSBDonationIdFixer FINISHED' );
        log.saveLogs();
    }

}