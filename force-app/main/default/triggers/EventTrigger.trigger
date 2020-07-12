trigger EventTrigger on Event (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    EventTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}