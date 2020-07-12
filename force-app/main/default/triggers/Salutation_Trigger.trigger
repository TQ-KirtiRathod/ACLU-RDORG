/*
*Name  :  Salutation Trigger
*Author:  Appirio India (Sai Krishna)
*Date  :  November 17, 2016
*Purpose : Trigger on Preference (T-555635)
*
*/
trigger Salutation_Trigger on rC_Bios__Salutation__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    SalutationTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}