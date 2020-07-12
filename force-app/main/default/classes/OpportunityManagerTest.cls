/**================================================================    
* Date Modified      Modified By        Description
* 3/01/2018         Rajat Agrawal(RA)   I-307191 Made changes to method createCampaign
==================================================================*/
@isTest
public class OpportunityManagerTest {

    public static List<Opportunity> oppList = new List<Opportunity>();
    public static Map<Id,Opportunity> oppMap;
    public static UserRole r = new UserRole(DeveloperName = 'TestMyCustomRole', Name = 'Test My Role');
    public static Map<id,id> campAccMap;
    public static List<Account> accList;
    public static List<Campaign> campList;
    public static List<String> affList;
    public static Set<id> oppId;
    public static Set<id> actionPlanId;
    public static Set<id> confidentialId;
    public static Map<String, ProgramType_DepositSite_Defaults__c> stringToProgTypeMap;
    public static Account a;
    public static Map<String,Schema.RecordTypeInfo> opptyRTMap;
    private static final String OPPORTUNITY_RT_TRANSACTION_Id;
    private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
    private static final String OPPORTUNITY_RT_DONATION_Id;
    private static final String OPPORTUNITY_RT_PLEDGE_Id;
    public static opportunity oppParent, parentDonation, parentPledge;
    static {
        opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
        OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
        OPPORTUNITY_RT_DONATION_Id = opptyRTMap.get('Donation').getRecordTypeId();
        OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
    } 
     @isTest(SeeAllData=false)
    public static void testOpportunityManager1(){
       
        
        //insert r;
        User u = testUtils.createUser('Lname', 'Uname@aclu.org', UserInfo.getUserRoleId(), false);
        //u.Is_Affiliate_User__c = true;
        insert u;
    //    createData();
        
            
        System.runAs(u){
            createData();
        }
        Test.StartTest();
        
        System.runAs(u){
            actionPlanId = new Set<id>();
            rC_Bios__Action_Plan__c rba = new rC_Bios__Action_Plan__c();
            rba.Name = 'test';
            rba.rC_Bios__WhatId__c=oppParent.id;
            insert rba;
            
            actionPlanId.add(rba.id);
            confidentialId = new Set<Id>();
            Confidential_Data__c cd = TestUtils.createConfidentialData(accList.get(1).id,null,oppParent.id,true);
            confidentialId.add(cd.id);
            
            oppMap = new Map<id,Opportunity>();
            oppId = new Set<id>();
            
            for(integer i=0;i<5;i++)
            {
                Opportunity opp = testUtils.createOpportunity(accList.get(0).id, 'opp'+i, false);
                //opp.rC_Giving__Payment_Method_Selected__c =  rc.id;
                opp.Deposit_Site__c = 'AK_Alaska';
                opp.Related_Transaction__c = oppParent.id;
                opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
                opp.Campaign = campList[0];
                opp.CampaignId = campList[0].id;
                opp.stageName = 'Completed';
                opp.rC_Giving__Parent__c=oppParent.id;
                if(i<3)
                opp.rC_Giving__Payment_Method__c = 'Charge Card';
                //opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
                opp.stageName = 'Open';
                
                opp.rC_Giving__Is_Sustainer__c = false;
                    
                oppList.add(opp);
                
                if(!oppMap.containsKey(opp.id))
                    oppMap.put(opp.id, opp);
            }
    
            Opportunity childOpp1 = TestUtils.createOpportunity(accList.get(1).id, 'test transaction', false);
            childOpp1.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            childOpp1.rC_Giving__Parent__r = parentDonation;
            Opportunity childOpp2 = TestUtils.createOpportunity(accList.get(1).id, 'test Pledge Payment', false);
            childOpp2.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
            childOpp2.rC_Giving__Parent__r = parentPledge;
            Opportunity oppp = testUtils.createOpportunity(accList.get(0).id, 'opp', false);
            oppp.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
            oppp.StageName='Completed';
            oppp.IsCreatedFromBatchLog__c=true;
            oppList.add(oppp);
            oppList.add(childOpp1);
            oppList.add(childOpp2);
            //update oppId;
            insert oppList;
                
           
                
            stringToProgTypeMap = new Map<String,ProgramType_DepositSite_Defaults__c>();
            for(integer i=0;i<5;i++)
            {
                ProgramType_DepositSite_Defaults__c p = new ProgramType_DepositSite_Defaults__c();
                p.Name = 'Program_Type__c'+i;
                stringToProgTypeMap.put(p.name,p);
            }
            List<rC_Bios__Preference__c> rcList = new List<rC_Bios__Preference__c>();
            rC_Bios__Preference__c rcbp = new rC_Bios__Preference__c();
            rcbp.rC_Bios__Code_Value__c = 'test value';
            rcbp.rC_Bios__Account__c =  campAccMap.get(campList[0].id);
            rcList.add(rcbp);
                
            rC_Bios__Preference__c rcbp1 = new rC_Bios__Preference__c();
            rcbp1.rC_Bios__Code_Value__c = '1test value';
            rcbp1.rC_Bios__Account__c =  campAccMap.get(campList[0].id);
            rcList.add(rcbp1);
            
            insert rcList;
            System.assertEquals(2,rcList.size());
             
            Campaign_Issue__c ci1 = new Campaign_Issue__c();
            ci1.Campaign__c = campList.get(1).id;
            insert ci1;
            rC_Bios__Preference_Code__c pc = new rC_Bios__Preference_Code__c();
            pc.rC_Bios__Code_Value__c = 'IL';
                insert pc;
            Campaign_Issue__c ci = new Campaign_Issue__c();
            ci.Campaign__c = campList.get(0).id;
               
            ci.Preference__c = pc.id;
            insert ci;
            rC_Bios__Relationship__c rcbr = testUtils.createRelationShip(accList.get(0).id, accList.get(1).id, true);            
            Task ta = new Task();
            ta.WhatId=oppList[0].id;
            ta.Subject='Attach Donation Backup Documentation';
            insert ta;
        }
        //System.assert(false, Limits.getQueries());
        // Build a simple feed item
  /*      ConnectApi.FeedElementPage testPage = new ConnectApi.FeedElementPage();
        List<ConnectApi.FeedItem> testItemList = new List<ConnectApi.FeedItem>();
        testItemList.add(new ConnectApi.FeedItem());
        testItemList.add(new ConnectApi.FeedItem());
        testPage.elements = testItemList;

        // Set the test data
        ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFeed(null,
        ConnectApi.FeedType.News, 'me', testPage);
        System.assertEquals(2, CalloutOpportunityManager.getNewsFeedCount());

        ConnectApi.FeedElement textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = 'test';
        messageBodyInput.messageSegments.add(textSegmentInput);
*/
      
    
    // Bulk post
       
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();

        input.subjectId = a.id;
        
        ConnectApi.MessageBodyInput body = new ConnectApi.MessageBodyInput();
        body.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = 'Let\'s win the ' + a.name + ' account.';

        body.messageSegments.add(textSegment);
        input.body = body;

        ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(input);
        batchInputs.add(batchInput);
    

        //ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);

        
      
        
        OpportunityManager opp = new OpportunityManager();
        OpportunityManager.updateMerchantName(oppList);
        OpportunityManager.setRevenueFiscalYear(oppList, oppMap);
        OpportunityManager.updateFieldsonChildOpps(oppList, oppMap);
        
        //OpportunityManager.sendEmailToOpportunityOwner(oppList);
        //OpportunityManager.retrieveSourceCode('2012','09');
        OpportunityManager.byPassCalculationsOnChild(oppList, oppMap);
        OpportunityManager.updateDepositSiteOnChildOpps(oppList,oppMap);
        OpportunityManager.populateSourceCodeValues(oppMap, oppList, oppMap);
        Opportunity oppsourcode1 = OpportunityManager.retrieveSourceCode(new Opportunity(Program_Type__c = '1', closeDate = Date.today(), 
                                                                                         Campaign_Type__c = 'E'));
        Opportunity oppsourcode2 = OpportunityManager.retrieveSourceCode(new Opportunity(Program_Type__c = '2', closeDate = Date.today(), 
                                                                                         Campaign_Type__c = 'E'));
        Opportunity oppsourcode3 = OpportunityManager.retrieveSourceCode(new Opportunity(Program_Type__c = '3', closeDate = Date.today(), 
                                                                                         Campaign_Type__c = 'E'));
        Opportunity oppsourcode4 = OpportunityManager.retrieveSourceCode(new Opportunity(Program_Type__c = '4', closeDate = Date.today(), 
                                                                                         Campaign_Type__c = 'E'));
        Opportunity oppsourcode5 = OpportunityManager.retrieveSourceCode(new Opportunity(Program_Type__c = '5', closeDate = Date.today(), 
                                                                                         Campaign_Type__c = 'E'));
                                                                                         
        Map<Id,Opportunity> mapopp = opportunityManager.updateRollUpGivingOnGrantAndProposal(new List<opportunity>{new Opportunity(closeDate = date.today())}, new map<Id, Opportunity>());                                                                                         
        try{
            OpportunityManager.createPreferenceOffIssues(campAccMap);
        }Catch(Exception e){
            
        }
        OpportunityManager.setExcludeFromRevenuesharingField(oppList,oppMap);
        OpportunityManager.setStageToOpenIfPendingFailed(oppList,oppMap);
        OpportunityManager.createDocumentAttachmentTask(oppMap);
        OpportunityManager.updateChildOpportunityFromBatchLog(oppList, oppMap, oppList, oppMap);
        OpportunityManager.updateFieldsOnSoftCredits(oppList, oppMap);
        OpportunityManager.resetRelationshipShareRecords(oppId,affList);
        OpportunityManager.resetActionPlanShareRecords(actionPlanId, affList);
        OpportunityManager.resetNGOCShareRecordsFutureHandler(actionPlanId, oppId, confidentialId, affList);
        OpportunityManager.resetNGOCSharingRecords(oppId, affList);
        OpportunityManager.resetConfidential(confidentialId,affList);
        OpportunityManager.populateDepositSite(oppList,stringToProgTypeMap);
        OpportunityManager.sendEmailToOpportunityOwner(oppList);//causing error
        Test.stopTest();
      
      }    
    
     
      
    public static void createData(){
            
        /*Sustainer_Source_Code_Setting__c sc = new Sustainer_Source_Code_Setting__c();
        sc.Name = 'test';
        sc.Month__c = '09';
        sc.Year__c = '2019';
        insert sc;*/
        a = testUtils.createAccount('test', true);
        accList = new List<Account>();
        affList = new List<String>();
        campList= new List<Campaign>();
        campAccMap = new Map<Id, Id>();
        
        List<String> subAffiliationString = new List<String>{'1 - National Union', '2 - Sustainers', '3 - Affiliate Union',
                                                             '4 - National Foundation', '5 - Affiliate Foundation'};
        
        for(integer i=0;i<5;i++)
        {
            Account a = testUtils.createAccount('test'+i, true);
            accList.add(a);
            Campaign c = createCampaign('test c'+i, subAffiliationString[i], true);
            campList.add(c);
            campAccMap.put(c.id, a.id);
        }
            
        //upsert campList; 
        //update accList;
        
        accList.get(0).Affiliation__c = 'AL';
        accList.get(1).Affiliation__c = 'AA';
        accList.get(2).Affiliation__c = 'AK';
        update accList;

        //adding values in affilliation list
        affList.add(accList.get(0).Affiliation__c);
        affList.add(accList.get(1).Affiliation__c);
        affList.add(accList.get(2).Affiliation__c);
        //update affList;
            
            
        rC_Giving__Payment_Method__c rc = testUtils.createPaymentMethod(accList.get(0).id, false);
        // rc.rC_Giving__Account__c = a1.Id;
        //rc.RecordTypeId = '01236000000fBmx';
        //insert rc;
        
        List<Opportunity> listOfParentOpps = new list<Opportunity>();
        oppParent = testUtils.createOpportunity(accList.get(1).id, 'Parent', false);
        oppParent.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Purchase').getRecordTypeId();
        oppParent.Campaign = campList.get(0);
        oppParent.stageName = 'Completed';
        listOfParentOpps.add(oppParent);
        
        parentDonation = TestUtils.createOpportunity(accList.get(1).id, 'testParentDonation', false);
        parentDonation.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
        parentDonation.CampaignId = campList.get(0).Id;
        listOfParentOpps.add(parentDonation);
        
        parentPledge = TestUtils.createOpportunity(accList.get(1).id, 'testParentPledge', false);
        parentPledge.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        parentPledge.CampaignId = campList.get(0).Id;
        listOfParentOpps.add(parentPledge);
        
        insert listOfParentOpps;
        //System.assert(false,Limits.getQueries());
        
        
             
        //rcList= [SELECT Id,rC_Bios__Code_Value__c,rC_Bios__Account__c FROM rC_Bios__Preference__c WHERE rC_Bios__Account__c IN: campAccMap.values()];
        //System.debug('rcList**'+rcList);
            
        
    }

    @isTest
    public static void setBypassCalculationsPerCampaignTest() {
            Campaign cBypassNo1 = createCampaign('test1 - dont bypass opp1', '3 - Affiliate Foundation', false);
            Campaign cBypassNo2 = createCampaign('test2 - dont bypass opp2','4 - National Foundation', false);
            Campaign cBypassYes1 = createCampaign('test3 - bypass opp1', '4 - National Foundation', false);
            Campaign cBypassYes2 = createCampaign('test4 - bypass opp2', '1 - National Union', false);
            cBypassNo1.rC_Giving__Campaign_Type__c = 'B - Benefit';
            cBypassNo2.rC_Giving__Campaign_Type__c = 'C - General Incentive';
            cBypassYes1.rC_Giving__Campaign_Type__c = 'B - Benefit';
            cBypassYes2.rC_Giving__Campaign_Type__c = 'B - Benefit';
            cBypassNo1.rC_Giving__Affiliation__c = 'TX - ACLU of Texas';
            cBypassNo2.rC_Giving__Affiliation__c = 'FN - Foundation National';
            cBypassYes1.rC_Giving__Affiliation__c = 'FN - Foundation National';
            cBypassYes2.rC_Giving__Affiliation__c = 'UN - Union National';
            List<Campaign> campaignsToInsert = new List<Campaign>{cBypassNo1,cBypassNo2,cBypassYes1,cBypassYes2};
            insert campaignsToInsert;

            Account a = testUtils.createAccount('test acct', true);
            Opportunity opp1 = TestUtils.createOpportunity(a.id, 'test1 - dont bypass opp1', false);
            opp1.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
            opp1.CampaignId = cBypassNo1.Id;
            Opportunity opp2 = TestUtils.createOpportunity(a.id, 'test2 - dont bypass opp2', false);
            opp1.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
            opp1.CampaignId = cBypassNo2.Id;            
            Opportunity opp3 = TestUtils.createOpportunity(a.id, 'test3 - bypass opp1', false);
            opp1.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
            opp1.CampaignId = cBypassYes1.Id;            
            Opportunity opp4 = TestUtils.createOpportunity(a.id, 'test4 - bypass opp2', false);
            opp1.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
            opp1.CampaignId = cBypassYes2.Id;            
            List<Opportunity> oppsToInsert = new List<Opportunity>{opp1,opp2,opp3,opp4};
            insert oppsToInsert;
    }
    
    public static campaign createCampaign(String Name, String subAffiliation, Boolean doInsert){
        campaign camp = new campaign(Name = Name, rC_Giving__Sub_Affiliation__c = subAffiliation, 
                                     Sustainer_Operational_Year__c = String.valueOf(date.today().year()),
                                     rC_Giving__Campaign_Type__c = 'E (Solicited Earmark)', Is_Sustainer_Operational_Campaign__c = true);
        //RA - I-307191                   
        String str = '';                             
        Integer i = date.today().month();
        if(i >= 1 && i <= 9)
            str = '0' + String.valueOf(i);
        else
            str = String.valueOf(i);
        camp.Sustainer_Operational_Month__c = str;
        
        if(doInsert)
            insert camp;
        return camp;
    }
   
    
    
}