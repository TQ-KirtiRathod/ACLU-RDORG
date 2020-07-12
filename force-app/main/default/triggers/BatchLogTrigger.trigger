/*
*Name  :  BatchLogTrigger
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  February 16, 2017
*
*/
trigger BatchLogTrigger on Batch_Log__c (before delete, after undelete, before insert, after insert, before update, after update) {
    
    
    BatchLogTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
    
}