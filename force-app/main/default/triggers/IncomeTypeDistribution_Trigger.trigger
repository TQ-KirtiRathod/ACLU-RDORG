/*
*Name  :  IncomeTypeDistribution_Trigger 
*Author:  Appirio India (Sai Krishna)
*Date  :  Jan 23, 2016
*Purpose : Trigger on Income Type Distribution
*
*/
trigger IncomeTypeDistribution_Trigger on Income_Type_Distribution__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    IncomeTypeDistributionTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}