/**
 * Test Class for OpportunityAccountManager
 **/
@isTest
private class OpportunityAccountManagerTest {
    static list<Opportunity> oppList;
    static List<Account> accList;
    private static testMethod void testInsert(){
       	createTestData();
       	Test.startTest();
       	//Test Insert
       	insert oppList;
       	Test.stopTest();
       	Integer i = 0;
       	for(Account acc : [SELECT Id, Last_Membership_Gift__c, Joint_Membership_Flag__c,Household_Count__c,Has_Renewed_Before__c
       	                            FROM Account WHERE Id IN:accList]) {
       	    system.assertEquals(oppList[i].Id, acc.Last_Membership_Gift__c);
       	    system.assertEquals(true, acc.Joint_Membership_Flag__c);
       	    system.assertEquals(true, acc.Has_Renewed_Before__c);
       	    i++;
       	}
        
        //Test Update
        //Update flags on Accounts
        for(i =0;i<10;i++) {
            accList[i].Joint_Membership_Flag__c = false;
            accList[i].Has_Renewed_Before__c = false;
            accList[i].Last_Membership_Gift__c = null;
        }
        update accList;
        
        for(i =0;i<10;i++) {
            oppList[i].Amount = 100;
        }
        update oppList;
        i=0;
        for(Account acc : [SELECT Id, Last_Membership_Gift__c, Joint_Membership_Flag__c,Household_Count__c,Has_Renewed_Before__c
       	                            FROM Account WHERE Id IN:accList]) {
       	    
       	    system.assertEquals(oppList[i].Id, acc.Last_Membership_Gift__c);
       	    system.assertEquals(true, acc.Joint_Membership_Flag__c);
       	    system.assertEquals(true, acc.Has_Renewed_Before__c);
       	    i++;
       	}
    }
    
    static void createTestData() {
        Sharing_Codes_For_Membership_Campaign__c obj = TestUtils.createSharingCodes('P001', 'P001', true);
       	
        accList = new List<Account>();
        
        String houseHoldId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        for(integer i=0; i<10; i++){
            Account tempAcc = TestUtils.createAccount('testAcc'+i, false);
            tempAcc.Has_Renewed_Before__c = false;
            tempAcc.Joint_Membership_Flag__c = false;
            tempAcc.RecordTypeId = houseHoldId;
            //tempAcc.Household_Count__c = 2;
            accList.add(tempAcc);
        }
        if(accList.size()>0){
            insert accList;
        }
        list<Contact> conList = new list<Contact>();
        //To set Household_Count__c on Account
        for(Integer i=0; i<10; i++) {
            Contact c = TestUtils.createContact(accList[i], 'TestFirst'+i, 'TestLast'+i, false);
            c.rC_Bios__Preferred_Contact__c = true;
            Contact c1 = TestUtils.createContact(accList[i], 'TestFirstSec'+i, 'TestLastSec'+i, false);
            c1.rC_Bios__Secondary_Contact__c = true;
            conList.add(c);
            conList.add(c1);
        }
        insert conList;
        
        oppList = new list<Opportunity>();
        String PledgePaymentRecType = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
        for(integer i=0; i<10; i++){
            Opportunity opp = TestUtils.createOpportunity(accList[i].Id, 'TestOpp'+i, false);
            opp.Amount = 50;
            opp.CloseDate = Date.Today();
            opp.StageName = 'Completed';
            opp.Sharing_Code__c = 'P001';
            opp.RecordTypeId = PledgePaymentRecType;
            oppList.add(opp);
        }
    }
}