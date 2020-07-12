trigger SpringboardTrigger_Opportunity on Opportunity (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    SpringboardTriggerHandler.execute('Opportunity');
}