/*
*Name  :  BatchUpload_Trigger
*Author:  Appirio India (Kajal Jalan)
*Date  :  October 24, 2016
*Purpose : Trigger on BatchUpload to create Email and Email Preference(T-548731)
*
*/
trigger BatchUpload_Trigger on rC_Connect__Batch_Upload__c (before delete, after undelete, before insert, after insert, before update, after update) {
    
    
    BatchUploadHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
    
}