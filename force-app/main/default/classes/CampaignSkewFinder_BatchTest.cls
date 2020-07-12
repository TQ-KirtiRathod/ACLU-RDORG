@isTest
public class CampaignSkewFinder_BatchTest {
    @isTest //Method to Test CampaignSkewFinder_Batch
    public static void TestCampaignSkewFinder(){
        Test.startTest();
        Id jobId = Database.executebatch(new CampaignSkewFinder_Batch());
        Test.stopTest(); 
        system.assert(jobId != null);
        //System.assertEquals(1,[SELECT Id,NumberOfOpportunities FROM Campaign WHERE IsActive = true AND NumberOfOpportunities >=:10 ].size());
    }
    
    @IsTest //Method to Test CampaignSkewReducer_Batch
    public static void CampaignSkewReducerTest(){
        Test.startTest();
        Opportunity opps = [SELECT Id, CampaignId  FROM Opportunity LIMIT 1];
        CampaignSkewReducer_Batch.CampaignSkew(opps.campaignId);
        system.assertEquals(11, [SELECT Id FROM Campaign].size());
        CampaignSkewReducer_Batch.CampaignSkew(null);
        Test.stopTest(); 
    }
    
    @IsTest //Method to test scheduling of the batch class
    public static void testSchedule() 
    {
        Test.StartTest();
        CampaignSkewFinder_Schedule sh1 = new CampaignSkewFinder_Schedule();
        String sch = '0 0 23 * * ?'; 
        System.schedule('Test CampaignSkewFinder', sch, sh1); 
        Test.stopTest(); 
        System.assert([SELECT Id, CronJobDetail.Name, CronJobDetail.Id, State
                       FROM CronTrigger 
                       WHERE CronJobDetail.Name = 'Test CampaignSkewFinder'
                       AND State != 'COMPLETE'].size() > 0);
    }
    
    @testSetup//Method to create Test Data
    public static void createData(){
        List<Campaign> campaignList = new List<Campaign>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        //Create Campaign Skew Control record
        Campaign_Skew_Control__c campaignSkewControlObj = new Campaign_Skew_Control__c();
        campaignSkewControlObj.name='Default';
        campaignSkewControlObj.Threshold_for_Skew_Reduction__c =10;
        campaignSkewControlObj.CSV_of_Excluded_Channels__c = 'test';
        campaignSkewControlObj.Opps_per_Campain__c = 0;
        insert campaignSkewControlObj;
        
        //Create campaign records
        for(Integer i=0;i<10;i++){
            Campaign obj = TestUtils.createCampaign('test'+i,false);
            obj.rC_Giving__Segment__c=''+i;
            obj.IsActive=true;
            obj.Is_Overflow_Campaign__c = false;
            obj.rC_Giving__Channel__c = 'testgivingChannel';
            obj.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
            campaignList.add(obj);
        }
        insert campaignList;
        
        //Create a sample Account Record for Opportunity
        Account ac= TestUtils.createAccount('test',true);
        
        //Create Opprtunity records
        for(Integer i=0;i<10;i++){
            Opportunity op = TestUtils.createOpportunity(ac.id,'test'+i,false);
            op.CampaignId=campaignList.get(0).id;
            op.recordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
            op.StageName='Closed Won';
            opportunityList.add(op);
        }
        insert opportunityList;
        
        for (Integer i=2; i<4; i++) {
            opportunityList.get(i).rC_Giving__Parent__c = opportunityList.get(0).Id;
            opportunityList.get(i).RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
        }
        update opportunityList;
    }
}