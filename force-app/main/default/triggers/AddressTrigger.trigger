Trigger AddressTrigger on rC_Bios__Address__c (before insert, before update) {
  AddressTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap,
                                         trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}