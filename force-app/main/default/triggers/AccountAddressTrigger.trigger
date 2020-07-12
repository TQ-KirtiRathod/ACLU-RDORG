trigger AccountAddressTrigger on rC_Bios__Account_Address__c (before insert, after insert, before update, after update) {
system.debug('AccountaddressTrigger');
  AccountAddressTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap,
                                         trigger.isInsert, trigger.isUpdate, trigger.isDelete, 
                                         trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}