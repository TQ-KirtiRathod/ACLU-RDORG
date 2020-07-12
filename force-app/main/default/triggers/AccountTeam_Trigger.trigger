/*
*
*Name  :  AccountTeamTrigger
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  October 31, 2017
*Purpose : T-639732
*
*/
trigger AccountTeam_Trigger on Account_Team__c (after insert, after update, after delete) {
    
    AccountTeamHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}