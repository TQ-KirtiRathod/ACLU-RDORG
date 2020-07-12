/*
*Name  :  Relationship_Trigger  Trigger
*Author:  Appirio India (Sai Krishna)
*Date  :  November 17, 2016
*Purpose : Trigger on Relationship (T-555635)
*
*/
trigger Relationship_Trigger on rC_Bios__Relationship__c (before delete, after undelete, before insert, after insert, before update, after update) {
    
    
    RelationshipTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
    
    
}