public with sharing class OpportunityTriggerHandlerTestDataGen {
    
    private static String OPPORTUNITY_RT_SOFT_CREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
    private static String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    private static String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    private static String OPPORTUNITY_RT_PROPOSAL_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
    private static String OPPORTUNITY_RT_DONATION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
    private static String OPPORTUNITY_RT_PLEDGE_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
    
    public static void createTestData(){
        List<Share_Source_Revenue_Codes__c> shareCodes = new List<Share_Source_Revenue_Codes__c>();
        List<ProgramType_DepositSite_Defaults__c> programDepositDefaults = new List<ProgramType_DepositSite_Defaults__c>();
        List<rC_Giving__Payment_Method__c> paymentMethods = new List<rC_Giving__Payment_Method__c>();
        List<Opportunity> sCreditOppsToBeCreated = new List<Opportunity>();
        List<Opportunity> pPOppsToBeCreated = new List<Opportunity>();
        List<Opportunity> oppsToBeCreated = new List<Opportunity>();
        List<campaign> listOfCampaigns = new List<campaign>();
        List<Account> accsToBeCreated = new List<Account>();
        
        //create user with systemAdministrator
        User sysAdmin = createUser('System Administrator',1);
        
        Account acc = TestUtils.createAccount('testAcc', false);
        acc.BillingPostalCode = '82011';
        acc.BillingCountry = 'USA';
        Account acc1 = TestUtils.createAccount('tempAcc', false);
        acc1.BillingCountry = 'IND';
        acc1.Affiliation__c ='ZF';
        
        accsToBeCreated.add(acc);
        accsToBeCreated.add(acc1);
        insert accsToBeCreated;
        
        //Portfolio
        Portfolio__c portfolioRec = TestUtils.createPortfolio('Portfolio',true);
        
        //Planned Giving record
        rC_Giving__Planned_Giving__c plannedGivingRec = TestUtils.createPlannedGiving(accsToBeCreated[0].Id,null,true);
        
        //Custom Setting 
        Sharing_Codes_For_Membership_Campaign__c membershipShareCodes = TestUtils.createSharingCodes('P001', 'P001', true);
        
        //RevenueShareCodes Custom Setting Data
        shareCodes.add(new Share_Source_Revenue_Codes__c(Share_Code__c = 'P001', Name = '35', Share_Code_Description__c = 'Test')); 
        shareCodes.add(new Share_Source_Revenue_Codes__c(Name = '23', Share_Code__c = 'P003', Share_Code_Description__c = 'Test'));
        insert shareCodes; 
        
        //ProgramType_DepositSite_Defaults__c
        programDepositDefaults.add(new ProgramType_DepositSite_Defaults__c(Name='1', Deposit_Site__c = 'AK_Alaska',
                                                                            Payment_Method__c = 'Charge Card', Program_Type__c = '5'));
        programDepositDefaults.add(new ProgramType_DepositSite_Defaults__c(Name='2', Deposit_Site__c = 'AK_Alaska',
                                                                            Payment_Method__c = 'Charge Card', Program_Type__c = '1'));
        insert programDepositDefaults;                                                               
        /* custom Setting records End*/
        
        //paymentMethod
        rC_Giving__Payment_Method__c paymentMethodacc = TestUtils.createPaymentMethod(acc.Id,false);
        paymentMethodacc.Name = 'TestPaymentMethod1';
        paymentMethodacc.rC_Connect__Payment_Processor__c = 'Heartland';
        paymentMethods.add(paymentMethodacc);
        
        rC_Giving__Payment_Method__c paymentMethodacc1 = TestUtils.createPaymentMethod(acc1.Id,false);
        paymentMethodacc1.Name = 'TestPaymentMethod2';
        paymentMethodacc1.rC_Connect__Payment_Processor__c = 'Heartland';
        paymentMethods.add(paymentMethodacc1);
        
        insert paymentMethods;
        
        //Create batchLog
        Batch_Log__c batchLogRec = TestUtils.createBatchLog('Test Batch Log',false);
        batchLogRec.Batch_Log_Type__c = 'Manual';
        batchLogRec.Bank_Date__c = Date.today()-1;
        batchLogRec.Batch_Date__c = Date.today()+1;
        insert batchLogRec;
        
        //create Campaigns as a systemAdministrator
        System.runAs(sysAdmin){
            Campaign camp = TestUtils.createCampaign('testCampaign1', false);
            camp.rC_Giving__Affiliation__c = 'NGO';
            camp.rC_Giving__Source_Code__c = 'TESTSOURCECODE';
            camp.rC_Giving__Sub_Affiliation__c = '5';
            camp.rC_Giving__Campaign_Type__c = 'B - Benefit';
            camp.Account_Code__c = 'DPF - Drug Policy Fund';
            camp.Acknowledgment_Code__c  = 'AK Donor Ack';
            camp.Fund__c = 'BLDG - Building Fund';
            camp.Fundraising_Department__c  = 'Affiliate';
            camp.Restriction__c = 'BRT - Bill of Rights Trust';
            camp.ActualCost = 1; 
            camp.Exclude_Cost_Factors_in_RevShare__c = true;                
            listOfCampaigns.add(camp);
    
            Campaign camp1 = TestUtils.createCampaign('testCampaign2', false);
            camp.rC_Giving__Affiliation__c = 'NGO';
            camp1.rC_Giving__Source_Code__c = 'TESTSOURCECODE21';
            camp1.rC_Giving__Sub_Affiliation__c = '1';
            camp1.rC_Giving__Campaign_Type__c = 'A - Affiliate Membership';
            camp1.Account_Code__c = 'NAA - cash debit';
            camp1.Acknowledgment_Code__c  = 'AK New Donor Ack';
            camp1.Fund__c = 'CHST - Church-State';
            camp.Fundraising_Department__c  = 'Membership';
            camp1.Restriction__c = 'INTERNSHIP - Internship';
            camp1.Use_Campaign_Cost__c = true;
            listOfCampaigns.add(camp1);
            
            Campaign camp2 = TestUtils.createCampaign('testCampaign3', false);
            camp2.rC_Giving__Affiliation__c = 'NGO';
            camp2.rC_Giving__Source_Code__c = 'TESTSOURCECODE3';
            camp2.rC_Giving__Sub_Affiliation__c = '5';
            camp2.rC_Giving__Campaign_Type__c = 'A - Affiliate Membership';
            camp2.Account_Code__c = 'NAA - cash debit'; 
            camp2.Acknowledgment_Code__c  = 'AK New Donor Ack';
            camp2.Fund__c = 'CHST - Church-State';
            camp2.Fundraising_Department__c  = 'Membership';
            camp2.Restriction__c = 'INTERNSHIP - Internship';
            camp2.ActualCost = 1; 
            camp2.Exclude_Cost_Factors_in_RevShare__c = true;  
            listOfCampaigns.add(camp2);
            insert listOfCampaigns;     
        }
        
        //Proposal record
        Opportunity proposalRec = TestUtils.createOpportunity(acc.id, 'proposalRec', false);
        proposalRec.RecordTypeId = OPPORTUNITY_RT_PROPOSAL_ID;
        proposalRec.rC_Giving__Projected_Amount__c = 50000000;
        proposalRec.rC_Giving__Requested_Amount__c = 500;
        proposalRec.Portfolio__c = portfolioRec.Id;
        insert proposalRec;
        
        //Create Closed Donation record
        Opportunity closedDonation = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
        closedDonation.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
        closedDonation.rC_Giving__Giving_Amount__c  = 52;
        closedDonation.rC_Giving__Requested_Amount__c = 90;
        closedDonation.stageName = 'Completed';
        closedDonation.campaignId = listOfCampaigns[0].Id;
        closedDonation.Bypass_Calculations__c = true;
        closedDonation.Sharing_Code__c = 'P001';
        closedDonation.closeDate = date.Today();
        closedDonation.batch_Log__c = batchLogRec.Id;
        closedDonation.Bank_Date__c = Date.today()-1;
        closedDonation.Batch_Date__c = Date.today()+1;
        closedDonation.Tax_Date__c  = Date.today() ;
        closedDonation.Update_Payment_Method__c = paymentMethods[0].Id;
        closedDonation.rC_Giving__Payment_Method__c = 'Charge Card';
        closedDonation.rC_Giving__Planned_Giving__c = plannedGivingRec.Id;
        closedDonation.rC_Giving__Expected_Giving_Amount__c = 20;
        oppsToBeCreated.add(closedDonation);
        
        Opportunity openDonation = TestUtils.createOpportunity(acc.id, 'openDonation', false);
        openDonation.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
        openDonation.rC_Giving__Giving_Amount__c  = 52;
        openDonation.rC_Giving__Requested_Amount__c = 90;
        openDonation.stageName = 'Open';
        openDonation.campaignId = listOfCampaigns[0].Id;
        openDonation.rC_Giving__Payment_Method__c = 'Securities';
        openDonation.Bypass_Calculations__c = true;
        openDonation.Sharing_Code__c = 'P001';
        openDonation.isSoft_Credit__c = false;
        openDonation.Prior_Amount__c = 20;
        openDonation.Sharing_Entity__c = 'AA - All Affiliates';
        oppsToBeCreated.add(openDonation);
        
        
        
        Opportunity sustainerPledge = TestUtils.createOpportunity(acc.id, 'sustainerPledge', false);
        sustainerPledge.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        sustainerPledge.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge.closeDate = system.today();
        sustainerPledge.Upgrade_Amount__c = 1900;
        sustainerPledge.stageName = 'Open';
        sustainerPledge.rC_Giving__Giving_Frequency__c = 'Annually';
        sustainerPledge.campaignId = listOfCampaigns[0].Id;
        sustainerPledge.Upgrade_Source__c = listOfCampaigns[0].Id;
        oppsToBeCreated.add(sustainerPledge);
        
        Opportunity closedPledge = TestUtils.createOpportunity(acc.id, 'closedPledge', false);
        closedPledge.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        closedDonation.campaignId = listOfCampaigns[0].Id;
        closedPledge.stageName = 'Completed';
        closedPledge.Deposit_Site__c = Label.Cosmetic_Gift_Deposit_Site;
        closedPledge.rC_Giving__Parent__c= proposalRec.Id;
        closedPledge.amount = 20;
        closedPledge.closeDate = date.Today()+1;
        closedPledge.Bank_Date__c = Date.today()-1;
        closedPledge.Batch_Date__c = Date.today()+1;
        oppsToBeCreated.add(closedPledge);
        
        insert oppsToBeCreated;
        
        
        /*Opportunity donationParent = [SELECT Id FROM Opportunity WHERE Name = 'closedDonation'];
        Opportunity donationParentOpen = [SELECT Id FROM Opportunity WHERE Name = 'openDonation'];
        Opportunity sustainerParent = [SELECT Id FROM Opportunity WHERE Name = 'sustainerPledge'];
        Opportunity pledgeParent = [SELECT Id FROM Opportunity WHERE Name = 'closedPledge'];*/
        
        //Transaction
        Opportunity closedDonationTrans = TestUtils.createOpportunity(acc.id, 'closedDonationTrans', false);
        closedDonationTrans.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        closedDonationTrans.rC_Giving__Parent__c = closedDonation.Id;
        closedDonationTrans.batch_Log__c = batchLogRec.Id;
        pPOppsToBeCreated.add(closedDonationTrans);
        
        Opportunity openDonationTrans = TestUtils.createOpportunity(acc.id, 'openDonationTrans', false);
        openDonationTrans.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        openDonationTrans.rC_Giving__Parent__c = openDonation.Id; 
        pPOppsToBeCreated.add(openDonationTrans);
        
        //Pledge Payments
        Opportunity closedPledgePayment = TestUtils.createOpportunity(acc.id, 'closedPledgePayment', false);
        closedPledgePayment.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
        closedPledgePayment.rC_Giving__Parent__c = closedPledge.Id;
        closedPledgePayment.Proposal__c = proposalRec.Id;
        closedPledgePayment.amount = 20;
        pPOppsToBeCreated.add(closedPledgePayment);
        
        Opportunity sustainerPledgePayment2 = TestUtils.createOpportunity(acc.id, 'sustainerPledgePayment2', false);
        sustainerPledgePayment2.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
        sustainerPledgePayment2.rC_Giving__Parent__c = sustainerPledge.Id; 
        pPOppsToBeCreated.add(sustainerPledgePayment2);
        
        
        
        Opportunity sustainerPledgePayment3 = TestUtils.createOpportunity(acc.id, 'sustainerPledgePayment3', false);
        sustainerPledgePayment3.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
        sustainerPledgePayment3.rC_Giving__Parent__c = sustainerPledge.Id;
        pPOppsToBeCreated.add(sustainerPledgePayment3);
        insert pPOppsToBeCreated;
        
        //Needs separate Operation as this Record to be added as a second. 
        
        
        //sCreditOppsToBeCreated.add(sustainerPledgePayment3);
        //Opportunity closedTrans = [SELECT Id FROM Opportunity WHERE Name = 'closedDonationTrans'];
        //Opportunity openTrans = [SELECT Id FROM Opportunity WHERE Name = 'openDonationTrans'];
        
        //Create Soft Credit records
        Opportunity screditClosedDonation = TestUtils.createOpportunity(acc.id, 'screditClosedDonation', false);
        screditClosedDonation.RecordTypeId = OPPORTUNITY_RT_SOFT_CREDIT_Id;
        screditClosedDonation.Related_Transaction__c = closedDonationTrans.Id;
        screditClosedDonation.rC_Giving__Parent__c = closedDonation.Id; 
        screditClosedDonation.isSoft_Credit__c = true;
        screditClosedDonation.IsCreatedFromBatchLog__c = True;
        screditClosedDonation.amount = 150;
        sCreditOppsToBeCreated.add(screditClosedDonation);
        
        Opportunity screditOpenDonation = TestUtils.createOpportunity(acc.id, 'screditOpenDonation', false);
        screditOpenDonation.RecordTypeId = OPPORTUNITY_RT_SOFT_CREDIT_Id;
        screditOpenDonation.Related_Transaction__c = openDonationTrans.Id;
        screditOpenDonation.rC_Giving__Parent__c = openDonation.Id; 
        screditOpenDonation.isSoft_Credit__c = true;
        screditOpenDonation.IsCreatedFromBatchLog__c = True;
        sCreditOppsToBeCreated.add(screditOpenDonation);
        
        insert sCreditOppsToBeCreated;
        
        
    
        
    }
    
    //not Using TestUtils to avoid the ROW_LOCK error
    private static User createUser(String profileName,integer count){
        
        User testUser = new User();
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName][0];
        testUser.ProfileId = p.id;
        testUser.FirstName = 'testUser';
        testUser.LastName = profileName;
        testUser.Username = 'testUser' + count + '@email.com'+'.random1';
        testUser.Email = 'testUser' + '@aclu.org';
        testUser.Alias = 'testUser';
        testUser.CommunityNickname = 'testUser'+count;
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.TimeZoneSidKey = 'America/Los_Angeles';
        testUser.Department = 'Executive/Admin';
        return testUser;
    }
    
    
}