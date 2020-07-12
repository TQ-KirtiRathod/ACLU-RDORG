/*
*Name  :  LeadTrigger
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  May 12, 2017
*
*/
trigger LeadTrigger on Lead(before delete, after undelete, before insert, after insert, before update, after update) {
    LeadTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}