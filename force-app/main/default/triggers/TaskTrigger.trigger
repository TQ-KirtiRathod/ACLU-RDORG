trigger TaskTrigger on Task (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
  TaskTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
    
}