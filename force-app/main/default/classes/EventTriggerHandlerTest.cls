/**
 * Test Class for EventTriggerHandler
 **/
 @isTest
public class EventTriggerHandlerTest {
    static list<Event> testEventList;
    static Opportunity testOpp1;
    static Portfolio__c p;
    
    //Verify Portfolio Id populated on Event
    static testMethod void testInsert(){
        createTestData();
        Test.startTest();
        insert testEventList;
        Test.stopTest();
        List<Event> eventList = [SELECT id,whatId,Portfolio_Id__c FROM Event];
        System.assertEquals(3, eventList.size());
        for(Event e:eventList){
            if(String.valueOf((e.whatId).getSObjectType()) == 'Opportunity'){
                system.assertEquals(e.Portfolio_Id__c, p.Id);
            }
        }
    }
    
    //verify update of WhatId from AccountId to OpportunityId
    static testMethod void testUpdate() {
        createTestData();
        insert testEventList;
        List<Event> eventList = [SELECT id,whatId,Portfolio_Id__c FROM Event];
        List<Event> updateEventList = new List<Event>();
        for(Event e:eventList) {
            if(String.valueOf((e.whatId).getSObjectType()) != 'Opportunity'){
                e.WhatId = testOpp1.Id;
                updateEventList.add(e);
            }
        }
        update updateEventList;
        System.assertEquals(1, updateEventList.size());
    }
     
	public static void createTestData() {
	    Account testAcc1 = TestUtils.createAccount('testAcc1', true);
        Contact testCon1 = TestUtils.createContact(testAcc1,'con1','con1',true);
        p = TestUtils.createPortfolio('testPort', true);
        String OPPORTUNITY_RT_PROPOSAL_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        testOpp1 = TestUtils.createOpportunity(testAcc1.Id, 'opp1', false);
        testOpp1.RecordTypeId = OPPORTUNITY_RT_PROPOSAL_ID;
        testOpp1.StageName = '01. Identify';
        testOpp1.CloseDate = system.today();
        testOpp1.rC_Giving__Requested_Amount__c = 100;
        testOpp1.Portfolio__c = p.Id;
        insert testOpp1;
        testEventList = new list<Event>();
        Event testEvent;
        for(Integer i = 0; i<3; i++) {
            testEvent = new Event();
            testEvent.OwnerId = UserInfo.getUserId();
            testEvent.Subject = 'Call';
            testEvent.StartDateTime = System.now();
            testEvent.EndDateTime = System.now() +1;
            testEventList.add(testEvent);
        }
        testEventList.get(0).WhatId = testOpp1.Id;
        testEventList.get(1).WhatId = testOpp1.Id;
        testEventList.get(2).WhatId = testAcc1.Id;
	}
    
}