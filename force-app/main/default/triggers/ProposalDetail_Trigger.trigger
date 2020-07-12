trigger ProposalDetail_Trigger on Proposal_Detail__c (before delete, after delete, after undelete, before insert, after insert, before update, after update) {
    ProposalDetailTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, 
                                           trigger.isInsert, trigger.isUpdate, trigger.isDelete, 
                                           trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}