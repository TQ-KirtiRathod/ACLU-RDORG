/*
*Name  :  Campaign_Trigger
*Author:  Appirio India (Sai Krishna)
*Date  :  November 30, 2016
*Purpose : Trigger on Campaign 
*
*/
trigger Campaign_Trigger on Campaign(before delete, after undelete, before insert, after insert, before update, after update) {
    
    
    CampaignHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
    
    
}