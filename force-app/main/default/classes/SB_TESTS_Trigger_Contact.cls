public with sharing class SB_TESTS_Trigger_Contact extends SpringboardTriggerHandler {
	
	public static String beforeInsert;
	public static String afterInsert;
	public static String beforeUpdate;
	public static String afterUpdate;
	public static String beforeDelete;
	public static String afterDelete;
	public static Id afterUndelete;
	
    public override void onBeforeInsert() {
		SB_TESTS_Trigger_Contact.beforeInsert = this.sb.settings.Trigger_Prefixes_Active__c;
    }
    public override void onAfterInsert() {
		SB_TESTS_Trigger_Contact.afterInsert = this.sb.settings.Trigger_Prefixes_Active__c;
    }
	public override void onBeforeUpdate() {
		SB_TESTS_Trigger_Contact.beforeUpdate = this.sb.settings.Trigger_Prefixes_Active__c;
	}
	public override void onAfterUpdate() {
		SB_TESTS_Trigger_Contact.afterUpdate = this.sb.settings.Trigger_Prefixes_Active__c;
	}
	public override void onBeforeDelete() {
		SB_TESTS_Trigger_Contact.beforeDelete = this.sb.settings.Trigger_Prefixes_Active__c;
	}
	public override void onAfterDelete() {
		SB_TESTS_Trigger_Contact.afterDelete = this.sb.settings.Trigger_Prefixes_Active__c;
	}
	public override void onAfterUndelete() {
    	for (Contact c : (Contact[]) Trigger.new) {
			SB_TESTS_Trigger_Contact.afterUndelete = c.Id;
    	}
	}
}