/*
*Name  :  AccountAffiliationTrigger
*Author:  Appirio India (Kajal Jalan)
*Date  :  October 17, 2016
*Purpose : Trigger on Account for updating Affiliation and chapter
*
*/


trigger Account_Trigger on Account (before delete, after delete, after undelete, before insert, after insert, before update, after update) {
    
    
    AccountTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
    
    
}