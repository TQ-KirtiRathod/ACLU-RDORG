/*
*Name  :  ActionPlan Trigger
*Author:  Appirio India (Sai Krishna)
*Date  :  November 17, 2016
*Purpose : Trigger on ActionPlan (T-555635)
*
*/
trigger ActionPlan_Trigger on rC_Bios__Action_Plan__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    ActionPlanTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}