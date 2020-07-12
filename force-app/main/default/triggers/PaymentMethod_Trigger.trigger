/*
*Name  :  PaymentMethod_Trigger
*Author:  Appirio India (Sai Krishna)
*Date  :  November 17, 2016
*Purpose : Trigger on PaymentMethod(T-555635)
*
*/
trigger PaymentMethod_Trigger on rC_Giving__Payment_Method__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    PaymentMethodTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}