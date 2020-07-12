/**
 * Test Class for LeadTriggerHandler
 **/
@isTest
private class LeadTriggerHandlerTest {
    
    //Verify CampaignMembers created corressponding to leads
    static testMethod void testLeadCreation(){
        Test.startTest();
        //createTestData();
        List<CampaignMember> listOfCampaignMembers = [SELECT Id FROM CampaignMember];
        system.assertEquals(listOfCampaignMembers.size(),3);
        Test.stopTest();    
    }
    
    @testSetup
    public static void createTestData()
    {
        List<Campaign> listOfCampaigns = new List<Campaign>();
        Campaign camp = TestUtils.createCampaign('testCampaign1', false);
        camp.rC_Giving__Source_Code__c = 'TESTSOURCECODE';
        camp.rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation';
        camp.rC_Giving__Campaign_Type__c = 'B - Benefit';
        camp.Account_Code__c = 'DPF - Drug Policy Fund';
        camp.Fund__c = 'BLDG - Building Fund';
        camp.Restriction__c = 'BRT - Bill of Rights Trust';
        listOfCampaigns.add(camp);
         
        Campaign camp1 = TestUtils.createCampaign('testCampaign2', false);
        camp1.rC_Giving__Source_Code__c = 'TESTSOURCECODE21';
        camp1.rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation';
        camp1.rC_Giving__Campaign_Type__c = 'A - Affiliate Membership';
        camp1.Account_Code__c = 'NAA - cash debit';
        camp1.Fund__c = 'CHST - Church-State';
        camp1.Restriction__c = 'INTERNSHIP - Internship';
        listOfCampaigns.add(camp1);
        insert listOfCampaigns;
        
        List<Lead> listOfLeads = new List<Lead>();
        Lead testLead1 = TestUtils.createLead('Test Lead 1','Company 1','Open',False);
        Lead testLead2 = TestUtils.createLead('Test Lead 2','Company 2','Open',False);
        Lead testLead3 = TestUtils.createLead('Test Lead 3','Company 3','Open',False);
        testLead1.SB_Campaign_Id__c = listOfCampaigns.get(0).Id;
        testLead2.SB_Campaign_Id__c = listOfCampaigns.get(0).Id;
        testLead3.SB_Campaign_Id__c = listOfCampaigns.get(1).Id;
        listOfLeads.add(testLead1);
        listOfLeads.add(testLead2);
        listOfLeads.add(testLead3);
        insert listOfLeads;
    }
}