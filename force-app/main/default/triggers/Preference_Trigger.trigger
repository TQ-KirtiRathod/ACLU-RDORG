/*
*Name  :  Preference Trigger
*Author:  Appirio India (Sai Krishna)
*Date  :  November 17, 2016
*Purpose : Trigger on Preference (T-555635)
*
*/
trigger Preference_Trigger on rC_Bios__Preference__c (before delete, after undelete, before insert, after insert, before update, after update, after delete) {   
    
   PreferenceTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
    
}