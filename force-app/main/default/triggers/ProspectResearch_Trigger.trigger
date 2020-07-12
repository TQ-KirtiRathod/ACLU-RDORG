/*
*Name  :  ConfidentialDataTrigger
*Author:  Appirio India (Sai Krishna)
*Date  :  March 16, 2016
*Purpose : Trigger on Prospect Research
*/

trigger ProspectResearch_Trigger on Prospect_Research__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
     ProsResearchTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}