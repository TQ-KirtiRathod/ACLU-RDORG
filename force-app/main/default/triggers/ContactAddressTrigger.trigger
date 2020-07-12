trigger ContactAddressTrigger on rC_Bios__Contact_Address__c (before insert, before update) {
  ContactAddressTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap,
                                         trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}