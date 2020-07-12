/**
 * Test class for PlannedGivingIntentionBatch
 **/
@isTest
private class PlannedGivingIntentionBatchTest {
    private static String CAMPAING_ROLL_UP_REVENUE_YEARLY_ROLL_UP = Schema.SObjectType.Campaign_Roll_Up__c.getRecordTypeInfosByName().get('Revenue Type Yearly Roll Up').getRecordTypeId();
	private static String CAMPAING_ROLL_UP_ACCOUNT_YEARLY_ROLL_UP = Schema.SObjectType.Campaign_Roll_Up__c.getRecordTypeInfosByName().get('Account Detail Yearly Roll Up').getRecordTypeId();
	private static Opportunity_Start_End_Date_To_Process__c opportunityStartEndObj;
    private static List<rC_Giving__Planned_Giving__c> listrCGivingPlannedGiving;
    Private static Account ac;
    Private static Account ac1;
    private static opportunity op;

	@isTest
    Private static void testPlannedGivingIntention(){
        createData();
        Test.startTest();
        Database.executebatch(new PlannedGivingIntentionBatch(), 200);
        Test.stopTest();
        list<Campaign_Roll_Up__c> rollUps = [SELECT Id, Revenue_Type__c FROM Campaign_Roll_Up__c];
        system.assertEquals(4, rollUps.size());
        system.assertEquals('Planned Giving Intentions', rollUps[0].Revenue_Type__c);
    }
    
    public  static void createData(){
        opportunityStartEndObj = TestUtils.createOpptyStartEndProcess('Gift_Date__c', Date.today(), null, true);
        listrCGivingPlannedGiving= new List<rC_Giving__Planned_Giving__c>();
        
        ac=testUtils.createAccount('test',True);
        ac1=testUtils.createAccount('test1',true);
        op=TestUtils.createOpportunity(ac.id,'test',False);
        op.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        op.CloseDate=Date.today();
        insert op;
        
        Opportunity_Start_End_Date_To_Process__c oppc2= TestUtils.createOpptyStartEndProcess('Run Range', Date.today(), Date.today()+7, true);
        String recTypeId = Schema.SObjectType.rC_Giving__Planned_Giving__c.getRecordTypeInfosByName().get('Charitable Gift Annuity').getRecordTypeId();
        for(Integer i=0;i<10;i++){
            rC_Giving__Planned_Giving__c obj = TestUtils.createPlannedGiving(ac.id,ac1.id,false);
            obj.RecordTypeId=recTypeId;    
            obj.rC_Giving__Stage__c='Active';
           	obj.Gift_Date__c=Date.today();    
            obj.rC_Giving__Giving_Amount__c=1000;
            obj.Proposal__c=op.id;
            obj.rC_Giving__Bequest_Type__c='test';
            listrCGivingPlannedGiving.add(obj);    
        }
        insert listrCGivingPlannedGiving;
    }
}