trigger SpringboardTrigger_Email on Email__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    SpringboardTriggerHandler.execute('Email');
}