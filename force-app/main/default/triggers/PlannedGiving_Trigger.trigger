/*
*Name  :  PlannedGiving_Trigger
*Author:  Appirio India (Sai Krishna)
*Date  :  November 17, 2016
*Purpose : Trigger on PlannedGiving(T-555635)
*
*/
trigger PlannedGiving_Trigger on rC_Giving__Planned_Giving__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    PlannedGivingTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}