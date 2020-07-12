trigger SpringboardTrigger_PersonalCampaign on P2P_Personal_Campaign__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	SpringboardTriggerHandler.execute('PersonalCampaign');
}