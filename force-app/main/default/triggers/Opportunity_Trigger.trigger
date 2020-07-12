/*
*
*Name  :  Opportunity_Trigger
*Author:  Appirio India (Kajal Jalan)
*Date  :  November 15, 2016
*Purpose : To send Chatter note to opportunity owner once an Expected amount changes(T-554685).
*
*/
trigger Opportunity_Trigger on Opportunity (before delete, after undelete, before insert, after insert, before update, after update, after delete) {
    
    OpportunityTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);

}