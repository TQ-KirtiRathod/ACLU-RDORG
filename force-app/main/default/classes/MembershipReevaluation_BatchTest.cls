/**
 * Test Class for MembershipReevaluation_Batch
 **/
@isTest
public class MembershipReevaluation_BatchTest {
	
    @isTest
    public static void testMembershipReevaluation_Batch()
    {
       Account a = testUtils.createAccount('test', true);
       List<Opportunity> oppList = new List<Opportunity>();
       
        for(integer i = 0;i<5;i++)
        {
             Opportunity opp = testUtils.createOpportunity(a.id, 'opp'+i, false);
             opp.New_Membership_Set_To_Date__c = system.today()-i;
             if(i<3)
        	     opp.Membership_Reevaluation_Needed__c = true;
             else
             	opp.Membership_Reevaluation_Needed__c = false;  
             oppList.add(opp);
        }
       Test.startTest();
       insert oppList;
       MembershipReevaluation_Batch obj = new MembershipReevaluation_Batch();
       //parameterised batch constructor
       MembershipReevaluation_Batch obj1 = new MembershipReevaluation_Batch(oppList.get(0).id);
       Database.executeBatch(obj1);
       DataBase.executeBatch(obj);
       Test.stopTest();
       System.assertEquals(true, oppList.get(1).Membership_Reevaluation_Needed__c);
       System.assertEquals(false, oppList.get(4).Membership_Reevaluation_Needed__c);

    }
    //test method for MembershipReevaluation_Schedule 
    public static testMethod void testschedule() 
    {
		Test.StartTest();
		MembershipReevaluation_Schedule sh1 = new MembershipReevaluation_Schedule();
		String sch = '0 0 23 * * ?'; 
        String jobId = system.schedule('test my MembershipReevaluation_Schedule', sch, sh1); 
        Test.stopTest(); 
        system.assert(jobId != null);
    }
}