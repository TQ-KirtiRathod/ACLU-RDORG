/*
*Test Call for CaseTriggerHandler
*
*/
@isTest
private class CaseTriggerHandlerTest {
    private static Case c1, c2;
    private static User us;
	private static testMethod void test() {
	    
	    us = TestUtils.createUser('Test', 'test.temp@aclu.test.com', null, true);
	    system.runAs(us) {
	        createTestData();
	        insert c1;
            insert c2;
	    }
	}
    private static void createTestData() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Account acc1 = TestUtils.createAccount('Test Acc1', false);
        acc1.Affiliation__c = 'AK';
        insert acc1;
        Account acc2 = TestUtils.createAccount('Test Acc2', false);
        acc2.Affiliation__c = 'AA';
        insert acc2;
        for(Group gp: [SELECT id, name FROM group WHERE Name IN ('AK','AA')]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        GroupMember gmem = TestUtils.createGroupmember(us.Id, mapGroupNameToId.get('AK'), true);
        c1 = TestUtils.createCase(acc1.Id, false);
        c2 = TestUtils.createCase(acc2.Id, false);
    }
}