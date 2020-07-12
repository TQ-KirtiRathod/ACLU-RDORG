/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 * Made changes by roundCroner #61427
 */
 
 /*
*
*Name  :  CampaignHandler
*Author:  Appirio India (Sai Krishna)
*Date  :  November 30, 2016
*Purpose : Test Class for CampaignHandler
*
*/
@isTest
private class CampaignHandlerTest {
    public static List<Campaign> Campaigns;
    public static List<Opportunity> listOpp;
    /*
    *
    *Method campaignSharingTest
    *Testing if batchUpload record created then share is created based on related affiliate.
    */
    static testMethod void campaignSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Set<Id> CampaignsIds = new Set<Id> ();
        setup();
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        Test.startTest();
       
        if(!Campaigns.isEmpty())
            insert Campaigns;
            insert listOpp;
       
        for(campaign bU: Campaigns){
            CampaignsIds.add(bU.Id);    
        }
        Test.stopTest();
        
       for(Campaignshare  bUShare: [SELECT Id, CampaignAccessLevel, UserOrGroupId FROM Campaignshare  where CampaignId =:CampaignsIds AND CampaignAccessLevel = 'Edit']){
            system.assertEquals(bUShare.UserOrGroupId,mapGroupNameToId.get('NN'));
        } 
        
    }
    
        
    /*
    *
    *Method campaignSharingUpdateTest
    *Testing if batchUpload record created then share is created based on related affiliate.
    */
    static testMethod void campaignSharingUpdateTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Set<Id> CampaignsIds = new Set<Id> ();
        List<campaign> campaignUpdate = new List<campaign>(); 
        setup();
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }        
        Test.startTest();
        for(campaign bU: Campaigns){
            bU.rC_Giving__Affiliation__c = null;
            bU.Set_Document_Attached__c = false;
            bU.Trigger_Attachment_Review_Process__c = true;
        }
        if(!Campaigns.isEmpty())
            insert Campaigns;
            
        for(campaign bU: Campaigns){
            CampaignsIds.add(bU.Id);    
        }   
        for(campaign bU: [SELECT id,Name FROM campaign ]){
            bU.rC_Giving__Affiliation__c = 'TX - ACLU of Texas';
            bU.Exclude_Cost_Factors_in_RevShare__c = true;
            bU.ActualCost = 110;
            bU.Trigger_Attachment_Review_Process__c = false;
            campaignUpdate.add(bU);
        }       
        if(!campaignUpdate.isEmpty())
            update campaignUpdate;
        if(!campaigns.isEmpty())
            delete campaigns[0];
        
        Test.stopTest();
        
        for(Campaignshare  bUShare: [SELECT Id, CampaignAccessLevel, UserOrGroupId FROM Campaignshare  where CampaignId =:CampaignsIds AND CampaignAccessLevel = 'Edit']){
            system.assertEquals(bUShare.UserOrGroupId,mapGroupNameToId.get('TX'));
        }        
    }

    @isTest
    public static void testAdvocacyAutopopulation() {
        Id advocacyId = Schema.SobjectType.Campaign.getRecordTypeInfosByName().get('Advocacy').getRecordTypeId();
        Campaign c = new Campaign(Name = 'Test', rC_Giving__Affiliation__c = 'UN - Union National', 
            rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation',
            rC_Giving__Start_Date_Time__c = system.now(),
            rC_Giving__End_Date_Time__c = System.now(),
            RecordTypeId = advocacyId);

        insert c;

        c = [SELECT rC_Giving__Campaign_Type__c, rC_Giving__Channel__c, rC_Giving__Appeal_Segment__c,
                    rC_Giving__Effort__c, rC_Giving__Solicitation_Type__c, StartDate, EndDate,
                    rC_Giving__Start_Date_Time__c, rC_Giving__End_Date_Time__c, Status, Type,
                    rC_Giving__Affiliation__c, rC_Giving__Sub_Affiliation__c,iSActive
             FROM Campaign
             WHERE Id = :c.Id
             LIMIT 1];

        System.assertEquals('W - Website', c.rC_Giving__Campaign_Type__c);
        System.assertEquals('Website', c.rC_Giving__Channel__c);
        System.assertEquals('XX Not Specified', c.rC_Giving__Appeal_Segment__c);
        System.assertEquals('00', c.rC_Giving__Effort__c);
        System.assertEquals('New', c.rC_Giving__Solicitation_Type__c);
        System.assertEquals('5 - Affiliate Foundation', c.rC_Giving__Sub_Affiliation__c);
        System.assertEquals('UN - Union National', c.rC_Giving__Affiliation__c);
        System.assertNotEquals(null, c.EndDate);
        System.assertNotEquals(null, c.StartDate);
        //System.assertNotEquals(null, c.rC_Giving__Start_Date_Time__c);
        //System.assertNotEquals(true, c.isActive);
        System.assertEquals('Advocacy', c.Type);
        System.assertEquals('In Progress', c.Status);

        c = new Campaign(Name = 'Test', rC_Giving__Affiliation__c = 'UN - Union National', 
            rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation', 
            rC_Giving__Effort__c = '01');

        insert c;

        c = [SELECT rC_Giving__Campaign_Type__c, rC_Giving__Channel__c, rC_Giving__Appeal_Segment__c,
                    rC_Giving__Effort__c, rC_Giving__Solicitation_Type__c, StartDate, EndDate,
                    rC_Giving__Start_Date_Time__c, rC_Giving__End_Date_Time__c, Status, Type,
                    rC_Giving__Affiliation__c, rC_Giving__Sub_Affiliation__c
             FROM Campaign
             WHERE Id = :c.Id
             LIMIT 1];

        // Ensure autopopulate didn't run.
        System.assert(String.isBlank(c.rC_Giving__Solicitation_Type__c));
    }

    @isTest
    public static void testSourceCodeToNameInsertSingleNonAdvocacy() {
        // Double-check with a non-Advocacy campaign.
        Campaign d = new Campaign(Name = 'Test', rC_Giving__Affiliation__c = 'UN - Union National', 
                                  rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation', 
                                  rC_Giving__Effort__c = '01');

        insert d;

        d = [SELECT Name, rC_Giving__Source_Code__c
             FROM Campaign
             WHERE Id = :d.Id
             LIMIT 1];

        System.assertEquals('Test-' + d.rC_Giving__Source_Code__c, d.Name);
    }

    @isTest
    public static void testSourceCodeToNameUpdateSingle() {
        Campaign d = new Campaign(Name = 'Test', rC_Giving__Affiliation__c = 'UN - Union National', 
                                  rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation', 
                                  rC_Giving__Effort__c = '01');

        insert d;

        d.rC_Giving__Effort__c = '02';
        update d;

        d = [SELECT Name, rC_Giving__Source_Code__c
             FROM Campaign
             WHERE Id = :d.Id
             LIMIT 1];

        System.assertEquals('Test-' + d.rC_Giving__Source_Code__c, d.Name);
        System.assert(d.rC_Giving__Source_Code__c.contains('02'));
    }

    @isTest
    public static void testSourceCodeToNameUpdateBulk() {
        Id advocacyId = Schema.SobjectType.Campaign.getRecordTypeInfosByName().get('Advocacy').getRecordTypeId();
        Id eventId = Schema.SobjectType.Campaign.getRecordTypeInfosByName().get('Event').getRecordTypeId();

        List<Campaign> cs = new List<Campaign>();

        for (Integer i = 0; i < 2; i++) {
            cs.add(new Campaign(Name = 'Test', rC_Giving__Affiliation__c = 'UN - Union National', 
                                rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation', 
                                RecordTypeId = (i < 25 ? advocacyId : eventId), rC_Giving__Effort__c = '01'));
        }
        try {
          insert cs;  
        }catch(Exception ex) {
            System.debug(ex);
        }
        

        /*for (Campaign c: cs) {
            c.rC_Giving__Effort__c = '02';
        }
        update cs;*/

        cs = [SELECT Name, rC_Giving__Source_Code__c
              FROM Campaign];

        
            System.assertEquals(cs.size(), 0);
            //System.assert(!c.rC_Giving__Source_Code__c.contains('02'));
        
    }
     //ZenDesk - #61427
      @isTest
    public static void testSourceCodeToNameUpdateBulk2() {
        Test.StartTest();
        //USerRole ur = [Select id from USerRole where name = 'ACLU Staff' LIMIT 1];
        Profile p = [Select id, name from Profile where Name = 'ACLU Analytics Tools' LIMIT 1];
        User u = TestUtils.createUser('test', 'abcdedfaadfasfss@aclu.org', null, false);
        u.profileId = p.id;
        u.UserPermissionsMarketingUser  = true;
        insert u;
        String errormsg = '';
        System.runAs(u){
        Id advocacyId = Schema.SobjectType.Campaign.getRecordTypeInfosByName().get('Advocacy').getRecordTypeId();
        Id eventId = Schema.SobjectType.Campaign.getRecordTypeInfosByName().get('Event').getRecordTypeId();

        List<Campaign> cs = new List<Campaign>();

        for (Integer i = 0; i < 1; i++) {
            cs.add(new Campaign(Name = 'Test', rC_Giving__Affiliation__c = 'UN - Union National', 
                                rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation', 
                                rC_Giving__Start_Date_Time__c = System.now(),
                                rC_Giving__End_Date_Time__c = System.now(),
                                RecordTypeId = (i < 25 ? advocacyId : eventId), rC_Giving__Effort__c = '01'));
        }
        try {
          insert cs;  
        }catch(Exception ex) {
            System.debug(ex);
        }
        

        for (Campaign c: cs) {
            c.rC_Giving__Effort__c = '01';
            c.rC_Giving__Campaign_Type__c = '';
        }
        try {
            update cs; 
        }catch(Exception ex) {
            
        }
       

        cs = [SELECT Name, rC_Giving__Effort__c
              FROM Campaign];

        
            System.assertEquals(cs[0].rC_Giving__Effort__c, '01');
            //System.assert(!c.rC_Giving__Source_Code__c.contains('02'));
        } 
        test.stopTest();
        
    }
     //ZenDesk - END #61427
    @isTest
    public static void testSourceCodeToNameInsertNegative() {
        Campaign d = new Campaign(Name = 'Test', rC_Giving__Affiliation__c = 'UN - Union National', 
                                  rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation', 
                                  rC_Giving__Effort__c = '01');

        insert d;

        d = [SELECT Name, rC_Giving__Source_Code__c
             FROM Campaign
             WHERE Id = :d.Id
             LIMIT 1];

        d.Name = 'Blah Blah' + d.rC_Giving__Source_Code__c;
        update d;

        d = [SELECT Name, rC_Giving__Source_Code__c
             FROM Campaign
             WHERE Id = :d.Id
             LIMIT 1];

        System.assertEquals('Blah Blah' + d.rC_Giving__Source_Code__c, d.Name);
    }
    
     /*
    *
    *Method setup
    *Testing if Affiliation updated then accountShare is re-calculated.
    */
    public static void setup(){
        Campaigns = new List<Campaign>();
        
        // Account Records
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            c.rC_Giving__Source_Code__c = '820TY';
            c.Exclude_Cost_Factors_in_RevShare__c = false;
            c.ActualCost = 420.20;
            c.Fundraising_Department__c = 'Membership';
            c.All_Affiliate_Edit_Access__c = false;
            c.rC_Giving__Sub_Affiliation__c ='5 - Affiliate Foundation';
            Campaigns.add(c);
        }
        Account acc = TestUtils.createAccount('testAccount', true);
        
        listOpp = new List<Opportunity>();
        for(Integer i=0 ; i<2 ; i++){
            Opportunity op = TestUtils.createOpportunity(acc.Id, 'Opp'+i, false);
            op.CampaignId = Campaigns[i].Id;
            op.Exclude_Cost_Factors_in_RevShare__c = false;
            op.Use_Campaign_Cost__c = true;
             listopp.add(op);
        }
      
    }
    
    
    
    @isTest
    public static void testActiveCampaignInsert(){
        Test.StartTest();
        //USerRole ur = [Select id from USerRole where name = 'ACLU Staff' LIMIT 1];
        Profile p = [Select id, name from Profile where Name = 'Marketing User' LIMIT 1];
        User u = TestUtils.createUser('test', 'abcdedfaadfasfss@aclu.org', null, false);
        u.profileId = p.id;
        u.UserPermissionsMarketingUser  = true;
        insert u;
        String errormsg = '';
        System.runAs(u){
            campaign c= TestUtils.createCampaign('Test12', false);
            c.IsActive = true;
            c.rC_Giving__Source_Code__c = '820TY';
            c.Exclude_Cost_Factors_in_RevShare__c = false;
            c.ActualCost = 420.20;
            c.Fundraising_Department__c = 'Membership';
            c.All_Affiliate_Edit_Access__c = false;
            c.rC_Giving__Sub_Affiliation__c ='5 - Affiliate Foundation';
            
                insert c;
            
        }
        
        Test.StopTest();
        System.assertEquals(1, [Select id from campaign].size());
    }
     //ZenDesk - #61427
    @isTest
    public static void testActiveCheck() {
        //Id stdId = Schema.SobjectType.Campaign.getRecordTypeInfosByName().get('Standard').getRecordTypeId();
        //Id eventId = Schema.SobjectType.Campaign.getRecordTypeInfosByName().get('Event').getRecordTypeId();

        List<Campaign> cs = new List<Campaign>();

        for (Integer i = 0; i < 10; i++) {
            cs.add(new Campaign(Name = 'Test', rC_Giving__Affiliation__c = 'UN - Union National', 
                                rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation', 
                                rC_Giving__Start_Date_Time__c = System.now(),
                                rC_Giving__End_Date_Time__c = System.now(),
                                rC_Giving__Effort__c = '01'));
        }
        
        insert cs;
        List<Campaign> camp = [Select id,IsActive from campaign];
        System.assertEquals(true, camp[0].IsActive);
    }
     //ZenDesk END - #61427
    @isTest
    public static void testActiveCampaignUpdate(){
        Test.StartTest();
        //USerRole ur = [Select id from USerRole where name = 'ACLU Staff' LIMIT 1];
        Profile p = [Select id, name from Profile where Name = 'Marketing User' LIMIT 1];
        User u = TestUtils.createUser('test', 'abcdedfaadfasfss@aclu.org', null, false);
        u.profileId = p.id;
        u.UserPermissionsMarketingUser  = true;
        insert u;
        String errormsg = '';
        System.runAs(u){
            campaign c= TestUtils.createCampaign('Test12', false);
            c.IsActive = true;
            c.rC_Giving__Source_Code__c = '820TY';
            c.Exclude_Cost_Factors_in_RevShare__c = false;
            c.ActualCost = 420.20;
            c.Fundraising_Department__c = 'Membership';
            c.All_Affiliate_Edit_Access__c = false;
            c.rC_Giving__Sub_Affiliation__c ='5 - Affiliate Foundation';
            insert c;
            System.assertEquals(1, [Select id from campaign].size());
            try{
                c.Name = 'updatename';
                update c;
            }Catch(exception e){
                
            }
            System.assertNotEquals('updatename',[Select name from Campaign where id =: c.id].Name);
        }
        
        Test.StopTest();
        
    }
}