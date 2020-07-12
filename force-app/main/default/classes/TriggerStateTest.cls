@isTest(seeAllData = false)
private class TriggerStateTest {
    private static testMethod void testTriggerState(){
        TriggerSettings__c triggerSettings = new TriggerSettings__c();
        triggerSettings.name = 'Account_Trigger';
        triggerSettings.IsActive__c = true;
        triggerSettings.isTestMode__c = true;
        insert triggerSettings;
        
        boolean isActive = TriggerState.isActive('Account_Trigger');
        System.assertEquals(true,isActive);
        
        isActive = TriggerState.isActive('AddressTrigger');
        System.assertEquals(true,isActive);
    }
}