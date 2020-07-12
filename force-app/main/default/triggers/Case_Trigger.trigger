/*
*Name  :  Case_Trigger
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  April 23, 2018
*Purpose : Trigger on Case
*/
trigger Case_Trigger on Case (before Insert) {
     CaseTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}