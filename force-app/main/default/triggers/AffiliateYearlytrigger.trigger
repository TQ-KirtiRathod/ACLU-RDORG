trigger AffiliateYearlytrigger on Affiliate_Yearly__c (before delete, after undelete, before insert, after insert, before update, after update) {
    
AffiliateYearlyTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
   
}