/*
*Name  :  ConfidentialDataTrigger
*Author:  Appirio India (Sai Krishna)
*Date  :  March 15, 2016
*Purpose : Trigger on ConfidentialData
*/

trigger ConfidentialData_Trigger on Confidential_Data__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    ConfDataTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}