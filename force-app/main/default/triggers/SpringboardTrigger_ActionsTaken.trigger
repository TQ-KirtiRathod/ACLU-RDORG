trigger SpringboardTrigger_ActionsTaken on sb_Actions_Taken__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    SpringboardTriggerHandler.execute('ActionsTaken');
}