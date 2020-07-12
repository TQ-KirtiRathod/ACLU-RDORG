trigger ContentDocumentLinkTrigger on ContentDocumentLink (before insert,after insert) {

    ContentDocumentLinkTriggerHandler.mainEntry(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete, trigger.isBefore, trigger.isAfter);
}