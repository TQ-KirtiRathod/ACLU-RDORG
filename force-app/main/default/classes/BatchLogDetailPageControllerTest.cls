/*
*
*Name  :  BatchLogDetailPageControllerTest
*Author:  Appirio India
*Date  :  June 19, 2017
*Purpose : Test Class for BatchLogDetailPageController class
*
*/
@isTest
public class BatchLogDetailPageControllerTest {
    private static Batch_Log__c testBatchLog1;
    private static Batch_Log__c testBatchLog;
    private static Batch_Log__c testBatchLog2;
    private static User usr;
    private static BatchLogDetailPageController batchLogObj;
    private static Account acc;
    private static String OPPORTUNITY_RT_PLEDGEPAYMENT_Id;
    private static String OPPORTUNITY_RT_DONATION_Id;
    private static String OPPORTUNITY_RT_TRANSACTION_Id;
    private static Opportunity bL1donationBS1;
    private static Opportunity bLpledgeBS1;
    private static Opportunity bL1scBS0;
    private static Opportunity bLpledgeBS0;
    private static Map<Id,Opportunity> mapIdToOpp ;
    private static Map<Integer,Opportunity> mapInToOpp;
    private static campaign cmp;
    private static Product2 p2;
    private static List<opportunity> oppLst ;

    
    public static void testSetup() {
        Batch_Type_To_Oppty_Field_Set_Mapping__c cuSet = new Batch_Type_To_Oppty_Field_Set_Mapping__c(); 
        cuSet.Name='Mapping2';
        cuSet.Batch_Type__c = 'Adjustment';
        cuSet.Field_Set_Name__c = 'Oppty_Fields_For_Adjustment_Batch_Type';
        insert cuSet;
        
        Batch_Type_To_Oppty_Field_Set_Mapping__c cuSet1 = new Batch_Type_To_Oppty_Field_Set_Mapping__c();
        cuSet1.Name='Mapping1';
        cuSet1.Batch_Type__c = 'Standard';
        cuSet1.Field_Set_Name__c = 'Oppty_Fields_For_Standard_Batch_Type';
        insert cuSet1;
        
        oppLst = new List<opportunity>();
        //fetching RecordTypeIds of Batch_Log__c using Schema class
        Map<String,Schema.RecordTypeInfo> blRTMap = Schema.SObjectType.Batch_Log__c.getRecordTypeInfosByName();

        //RecordType - Manual
        String BATCH_LOG_RT_MANUAL_Id = blRTMap.get('Manual').getRecordTypeId();

        //RecordType - Vendor
        String BATCH_LOG_RT_VENDOR_Id = blRTMap.get('Vendor').getRecordTypeId();

        Map<String,Schema.RecordTypeInfo> opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        String OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
        String OPPORTUNITY_RT_PROPOSAL_Id = opptyRTMap.get('Proposal').getRecordTypeId();
        OPPORTUNITY_RT_PLEDGEPAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
        OPPORTUNITY_RT_DONATION_Id = opptyRTMap.get('Donation').getRecordTypeId();
        OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
        String OPPORTUNITY_RT_SOFTCREDIT_Id = opptyRTMap.get('Soft Credit').getRecordTypeId();
        
        //creating Batch Log record using TestUtils class
        acc = TestUtils.createAccount('Account'+1,false);
        acc.Account_Type__c = 'Matching Company';
        acc.External_ID__c = '1234';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        insert acc;

        cmp = TestUtils.createCampaign('test camp',false);
        cmp.rC_Giving__Source_Code__c = '123';
        cmp.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        insert cmp;

        Pricebook2 pb = TestUtils.createPriceBook('Standard Price Book',true);

        p2 = TestUtils.createProduct('Test',true,true);

        //Create price book entry record
        PriceBookEntry pbe = TestUtils.createPriceBookEntry(p2.Id, false);
        pbe.Pricebook2 = pb;
        insert pbe;
        
        List<Batch_Log__c> batchLogs = new List<Batch_Log__c>();
        
        testBatchLog = TestUtils.createBatchLog('testBatchName', false);
        //adding date to avoid onbeforeinsert trigger exception
        testBatchLog.Batch_Date__c = Date.today();
        testBatchLog.Batch_Type__c='Adjustment';
        testBatchLog.RecordTypeId = BATCH_LOG_RT_MANUAL_Id;
        testBatchLog.Expected_Count__c=20;
        testBatchLog.Expected_Amount__c = 100;
        testBatchLog.Default_Campaign__c = cmp.id;
        testBatchLog.Actual_Count__c = 20;
        testBatchLog.Actual_Amount__c = 100;
        testBatchLog.Default_Account_Code__c = 'ABAD - Abortion Ad';
        testBatchLog.Default_Check__c = '33333';
        testBatchLog.Default_Check_Date__c =  Date.today();
        testBatchLog.Default_Gift_Amount__c = 1.0;
        batchLogs.add(testBatchLog);
        //insert testBatchLog;

        testBatchLog1 = TestUtils.createBatchLog('testBatchName1', false);
        //adding date to avoid onbeforeinsert trigger exception
        testBatchLog1.Batch_Date__c = Date.today();
        testBatchLog1.Batch_Type__c='Standard';
        testBatchLog1.RecordTypeId = BATCH_LOG_RT_MANUAL_Id;
        testBatchLog1.Expected_Count__c=20;
        testBatchLog1.Expected_Amount__c = 100;
        batchLogs.add(testBatchLog1);
        //insert testBatchLog1; 
        
        testBatchLog2 = TestUtils.createBatchLog('testBatchName2', false);
        //adding date to avoid onbeforeinsert trigger exception
        testBatchLog2.Batch_Date__c = Date.today();
        testBatchLog2.Batch_Type__c='Standard';
        testBatchLog2.RecordTypeId = BATCH_LOG_RT_MANUAL_Id;
        testBatchLog2.Default_Campaign__c = cmp.id;
        testBatchLog2.Expected_Count__c = 5;
        testBatchLog2.Expected_Amount__c = 100;
        testBatchLog2.Actual_Count__c = 5;
        testBatchLog2.Actual_Amount__c = 50;
        batchLogs.add(testBatchLog2);
        //insert testBatchLog2;
        
        insert batchLogs;
        List<Opportunity> parentOpptys = new List<Opportunity>();
        List<Opportunity> childOpptys = new List<Opportunity>();
        
        //BL
        
        bLpledgeBS1= TestUtils.CreateOpportunity(acc.Id, 'Test 1'+acc.Name, false);
        //bLpledgeBS1.Adjustment_Batch__c=batchLogs[0].id;
        bLpledgeBS1.IsCreatedFromBatchLog__c = true;
        bLpledgeBS1.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        bLpledgeBS1.rC_Giving__Is_Bookable__c = true;
        bLpledgeBS1.CampaignId = cmp.id;
        //bLpledgeBS1.Batch_Sequence__c = '2';
        bLpledgeBS1.Ack_Recipient_Account__c = acc.id;
        bLpledgeBS1.rC_Giving__Payment_Method__c = 'Paypal';
        //bLpledgeBS1.Related_Transaction__c= opp.id;
        bLpledgeBS1.stagename='open';
        bLpledgeBS1.Adjustment_Code__c = 'D';
        bLpledgeBS1.Batch_Sequence__c = '1';
        parentOpptys.add(bLpledgeBS1);
        //insert bLpledgeBS1;

        
        bLpledgeBS0= TestUtils.CreateOpportunity(acc.Id, 'Test 5'+acc.Name, false);
        bLpledgeBS0.Adjustment_Batch__c=batchLogs[0].id;
        bLpledgeBS0.IsCreatedFromBatchLog__c = true;
        bLpledgeBS0.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        bLpledgeBS0.rC_Giving__Is_Bookable__c = true;
        bLpledgeBS0.CampaignId = cmp.id;
        bLpledgeBS0.rC_Giving__Is_Sustainer__c = false;
        bLpledgeBS0.Ack_Recipient_Account__c = acc.id;
        bLpledgeBS0.Batch_Sequence__c = '0';
        bLpledgeBS0.Ack_Recipient_Account__c = acc.Id;
        //bLpledgeBS0.Related_Transaction__c= opp1.id;
        parentOpptys.add(bLpledgeBS0);
        //insert bLpledgeBS0;
        
    
        //BL1 
        
        bL1donationBS1 = TestUtils.CreateOpportunity(acc.Id, 'Test 0'+acc.Name, false);
        bL1donationBS1.Batch_Log__c=batchLogs[1].id;
        bL1donationBS1.IsCreatedFromBatchLog__c = true;
        bL1donationBS1.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
        bL1donationBS1.closeDate = system.today()+10;
        bL1donationBS1.Batch_Sequence__c = '1';
        bL1donationBS1.Adjustment_Sequence__c=1;
        bL1donationBS1.campaignId = cmp.id;
        parentOpptys.add(bL1donationBS1);
        //insert bL1donationBS1;
        
        Opportunity bL1pledgeBS2= TestUtils.CreateOpportunity(acc.Id, 'Test 3'+acc.Name, false);
        bL1pledgeBS2.Batch_Log__c=batchLogs[1].id;
        bL1pledgeBS2.IsCreatedFromBatchLog__c = true;
        bL1pledgeBS2.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        bL1pledgeBS2.rC_Giving__Is_Bookable__c = true;
        //opp3.rC_Giving__Parent__c = opp.Id;
        bL1pledgeBS2.closeDate = system.today()+10;
        bL1pledgeBS2.Batch_Sequence__c = '2';
        bL1pledgeBS2.Adjustment_Sequence__c=2;
        parentOpptys.add(bL1pledgeBS2);
        //insert bL1pledgeBS2;
        
        //BL2
        Opportunity bL2donationBS1 = TestUtils.CreateOpportunity(acc.Id, 'Test 0'+acc.Name, false);
        bL2donationBS1.Batch_Log__c=batchLogs[2].id;
        bL2donationBS1.IsCreatedFromBatchLog__c = true;
        bL2donationBS1.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
        bL2donationBS1.closeDate = system.today()+10;
        bL2donationBS1.rC_Giving__Giving_Amount__c = 10;
        bL2donationBS1.rC_Giving__Payment_Method__c = 'Cash/Check';
        bL2donationBS1.rC_Giving__Giving_Frequency__c = 'One Payment';
        bL2donationBS1.Payment_Subtype__c = 'Cash';
        bL2donationBS1.CampaignId = cmp.id;
        bL2donationBS1.Batch_Sequence__c = '1';
        parentOpptys.add(bL2donationBS1);
        //insert bL2donationBS1;
        
        Opportunity bL2donationBS31 = TestUtils.CreateOpportunity(acc.Id, 'Test 9'+acc.Name, false);
        bL2donationBS31.Batch_Log__c=batchLogs[2].id;
        bL2donationBS31.IsCreatedFromBatchLog__c = true;
        bL2donationBS31.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
        bL2donationBS31.closeDate = system.today()+10;
        bL2donationBS31.rC_Giving__Giving_Amount__c = 10;
        bL2donationBS31.Batch_Sequence__c = '3';
        bL2donationBS31.Split_Sequence__c = 1;
        parentOpptys.add(bL2donationBS31);
        //insert bL2donationBS31;
        
        Opportunity bL2donationBS32 = TestUtils.CreateOpportunity(acc.Id, 'Test 10'+acc.Name, false);
        bL2donationBS32.Batch_Log__c=batchLogs[2].id;
        bL2donationBS32.IsCreatedFromBatchLog__c = true;
        bL2donationBS32.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
        bL2donationBS32.closeDate = system.today()+10;
        bL2donationBS32.rC_Giving__Giving_Amount__c = 10;
        bL2donationBS32.Batch_Sequence__c = '3';
        bL2donationBS32.Split_Sequence__c = 2;
        parentOpptys.add(bL2donationBS32);
        //insert bL2donationBS32;
        
        Opportunity bL2donationBS21 = TestUtils.CreateOpportunity(acc.Id, 'Test 11'+acc.Name, false);
        bL2donationBS21.Batch_Log__c=batchLogs[2].id;
        bL2donationBS21.IsCreatedFromBatchLog__c = true;
        bL2donationBS21.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
        bL2donationBS21.closeDate = system.today()+10;
        bL2donationBS21.rC_Giving__Giving_Amount__c = 10;
        bL2donationBS21.Batch_Sequence__c = '2';
        bL2donationBS21.Split_Sequence__c = 1;
        parentOpptys.add(bL2donationBS21);
        //insert bL2donationBS21;
        
        Opportunity bL2donationBS51 = TestUtils.CreateOpportunity(acc.Id, 'Test 11'+acc.Name, false);
        bL2donationBS51.Batch_Log__c=batchLogs[2].id;
        bL2donationBS51.IsCreatedFromBatchLog__c = true;
        bL2donationBS51.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
        bL2donationBS51.closeDate = system.today()+10;
        bL2donationBS51.rC_Giving__Giving_Amount__c = 10;
        bL2donationBS51.Batch_Sequence__c = '5';
        bL2donationBS51.Split_Sequence__c = 1;
        parentOpptys.add(bL2donationBS51);
        //insert bL2donationBS51;
        
        
        Opportunity bL2donationBS4 = TestUtils.CreateOpportunity(acc.Id, 'Test 12'+acc.Name, false);
        bL2donationBS4.Batch_Log__c=batchLogs[2].id;
        bL2donationBS4.IsCreatedFromBatchLog__c = true;
        bL2donationBS4.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
        bL2donationBS4.closeDate = system.today()+10;
        bL2donationBS4.rC_Giving__Giving_Amount__c = 10;
        bL2donationBS4.Batch_Sequence__c = '4';
        parentOpptys.add(bL2donationBS4);
        //insert bL2donationBS4;
        
        insert parentOpptys;
        
        //Transction Records
        List<Opportunity> transOpptys = new List<Opportunity>();
        Opportunity bL1TransBS1= TestUtils.CreateOpportunity(acc.Id, 'Test 3'+acc.Name, false);
        bL1TransBS1.Batch_Log__c=batchLogs[1].id;
        bL1TransBS1.IsCreatedFromBatchLog__c = true;
        bL1TransBS1.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        bL1TransBS1.rC_Giving__Parent__c = parentOpptys[2].Id;
        bL1TransBS1.closeDate = system.today()+10;
        bL1TransBS1.Batch_Sequence__c = '1';
        transOpptys.add(bL1TransBS1);
        //insert opp3;
        
        Opportunity bLTransBS0= TestUtils.CreateOpportunity(acc.Id, 'Test 8'+acc.Name, false);
        bLTransBS0.RecordTypeId = OPPORTUNITY_RT_PLEDGEPAYMENT_Id;
        bLTransBS0.IsCreatedFromBatchLog__c = true;
        bLTransBS0.rC_Giving__Parent__c = parentOpptys[1].Id;
        bLTransBS0.Adjustment_Batch__c=testBatchLog.id;
        bLTransBS0.Batch_Sequence__c = '0';
        bLTransBS0.stagename='open';
        bLTransBS0.Adjustment_Code__c = 'D';
        bLTransBS0.amount=20;
        transOpptys.add(bLTransBS0);
        //insert opp8;
        
        Opportunity bL2TransBS6= TestUtils.CreateOpportunity(acc.Id, 'Test 8'+acc.Name, false);
        bL2TransBS6.RecordTypeId = OPPORTUNITY_RT_PLEDGEPAYMENT_Id;
        bL2TransBS6.Batch_Log__c=batchLogs[2].id;
        bL2TransBS6.IsCreatedFromBatchLog__c = true;
        bL2TransBS6.rC_Giving__Parent__c = parentOpptys[1].Id;
        bL2TransBS6.Adjustment_Batch__c=testBatchLog.id;
        bL2TransBS6.Batch_Sequence__c = '0';
        bL2TransBS6.stagename='open';
        bL2TransBS6.Adjustment_Code__c = 'D';
        bL2TransBS6.amount=20;
        bL2TransBS6.Batch_Sequence__c = '6';
        transOpptys.add(bL2TransBS6);
        
        Opportunity bL1TransBS3= TestUtils.CreateOpportunity(acc.Id, 'Test 8'+acc.Name, false);
        bL1TransBS3.RecordTypeId = OPPORTUNITY_RT_PLEDGEPAYMENT_Id;
        bL1TransBS3.IsCreatedFromBatchLog__c = true;
        bL1TransBS3.rC_Giving__Parent__c = parentOpptys[1].Id;
        bL1TransBS3.Batch_Log__c=testBatchLog1.id;
        bL1TransBS3.Batch_Sequence__c = '3';
        bL1TransBS3.stagename='open';
        bL1TransBS3.Adjustment_Code__c = 'D';
        bL1TransBS3.amount=20;
        transOpptys.add(bL1TransBS3);
        
        insert transOpptys;
        
        //Soft credit
        
        Opportunity bLscPPBS0= TestUtils.CreateOpportunity(acc.Id, 'Test 6'+acc.Name, false);
        bLscPPBS0.Adjustment_Batch__c=batchLogs[0].id;
        bLscPPBS0.IsCreatedFromBatchLog__c = true;
        bLscPPBS0.rC_Giving__Matching_Account__c=acc.Id;
        bLscPPBS0.rC_Giving__Matching_Status__c='POTENTIAL';
        bLscPPBS0.rC_Giving__Parent__c = transOpptys[0].id;
        bLscPPBS0.Related_Transaction__c = transOpptys[0].id;
        bLscPPBS0.CampaignId = cmp.id;
        bLscPPBS0.RecordTypeId = OPPORTUNITY_RT_PLEDGEPAYMENT_Id;
        bLscPPBS0.rC_Giving__Parent__c = parentOpptys[1].Id;
        bLscPPBS0.stagename='open';
        bLscPPBS0.Adjustment_Code__c = 'D';
        bLscPPBS0.Batch_Sequence__c = '0';
        childOpptys.add(bLscPPBS0);
        //insert bLscPPBS0;
        
        //Soft credit           
        bL1scBS0= TestUtils.CreateOpportunity(acc.Id, 'Test 4'+acc.Name, false);
        bL1scBS0.Batch_Log__c=batchLogs[1].id;
        bL1scBS0.IsCreatedFromBatchLog__c = true;
        bL1scBS0.RecordTypeId = OPPORTUNITY_RT_SOFTCREDIT_Id;
        bL1scBS0.CampaignId = cmp.id;
        bL1scBS0.Amount = 100;
        bL1scBS0.rC_Giving__Parent__c = transOpptys[0].id;
        bL1scBS0.closeDate = system.today()+10;
        bL1scBS0.Batch_Sequence__c = '0';
        childOpptys.add(bL1scBS0);
        //insert bL1scBS0;
        
        insert childOpptys;

    }
    
    @isTest
    public static void testFillPicklistValues() {
        usr = TestUtils.createUser('usertest', 'usertest@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        usr.Denied_Access_to_Open_Givings__c = true;
        usr.Primary_Affiliate__c = 'NN - National Chapters';
        insert usr;
        
        testSetup();
        system.runAs(usr){
            
            
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);
            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);

            //creating standardcontroller object to pass as parameter to controller constructor

            //Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.BatchLogDetailPage;
            pageRef.getParameters().put('matchOpptyIndex', '1');
            Test.setCurrentPage(pageRef);

            List<selectoption> getRT = batchLogObj.getRecTypeValues();
            List<selectoption> getBO = batchLogObj.getProgramOptions();
            List<selectoption> getBT = batchLogObj.getBatchTypeLst();
            
            List<selectoption> getAC = batchLogObj.getAffiliateCodes();
            List<selectoption> getDS = batchLogObj.getAffiliateDepositSites();
            List<selectoption> getACP = batchLogObj.getAcknowledgementCodePicklist();
            
            //batchLogObj.redirectToReport();
            batchLogObj.populateOpportunityWrapper();
            
            batchLogObj.oppRow = 1;
            batchLogObj.clearPaymentFields();
            pagereference pg = batchLogObj.checkRecordType();
            pagereference pg1 = batchLogObj.exportBatchItems();
            String acctype = BatchLogDetailPageController.accType;
            batchLogObj.showAdj_Save_Commit_btn = true;
            batchLogObj.showAdj_CancelAdjust_btn = true;
            batchLogObj.showAdj_Save_btn = true;
            batchLogObj.showAdj_close_btn = true;
            
            Test.startTest();
            batchLogObj.matchOpportunity();
            //system.assertEquals(101,Limits.getQueries());
            pageRef.getParameters().put('row', '1');
            pageRef.getParameters().put('OpportId', bL1donationBS1.id );
            pageRef.getParameters().put( 'isPledgePayment', 'true');
            //system.assertEquals(101,Limits.getQueries());
            /*PageReference pr1 = batchLogObj.updateParent();
            pageRef.getParameters().put( 'isPledgePayment', 'false');
            PageReference pr2 = batchLogObj.updateParent();*/
            
            pageRef.getParameters().put('selAccId', acc.Id);
            pageRef.getParameters().put('selRow', '0');
            batchLogObj.populatePledgeBoolean();
    
            
                //batchLogObj.saveBatchPref();
                batchLogObj.setBookableIfPledge(batchLogObj.opportunityWrapperlst[1]);
                
                batchLogObj.updateCampaignOnSoftCredits(batchLogObj.opportunityWrapperlst[0].objOppty.Id,batchLogObj.opportunityWrapperlst[1].objOppty.campaignId);
                
                pageRef.getParameters().put('activeOpptyIndex', '0');
                batchLogObj.changeActiveOppt();
                Boolean isNew = batchLogObj.isNew;
                Boolean newOrEditing = batchLogObj.newOrEditing;
                Boolean isCompleted = batchLogObj.isCompleted;
                Boolean isAffiliateOrReleased= batchLogObj.isAffiliateOrReleased;
                Boolean isAdjustOrReleased= batchLogObj.isAdjustOrReleased;
                Boolean affiliateUser= batchLogObj.affiliateUser;
                Boolean isSplitOrCompleted= batchLogObj.isSplitOrCompleted;
                Boolean psrequired= batchLogObj.psrequired;
                String userAffiliation = batchLogObj.userAffiliation;
                Boolean hasBatchLogItems = batchLogObj.hasBatchLogItems;
                
                
                Opportunity opp = new Opportunity();
                opp.rC_Giving__Tribute_Type__c =null;
                opp.Honoree_Title__c ='Test';
                opp.Honoree_First_Name__c ='Test';
                opp.Honoree_Middle_Name__c ='Test';
                opp.Honoree_Last_Name__c ='Test';
                opp.Honoree_Suffix__c ='Test';
                opp.Non_Person__c ='Test';
                opp.Recipient_Acknowledgment_Code__c='D';
                opp.Recipient_Acknowledgement_Status__c = 'Test';
                opp.Tribute_Message_Body__c = 'Test';
                opp.Ack_Recipient_Full_Name__c = 'Test';
                opp.Ack_Recipient_Account__c = batchLogObj.opportunityWrapperlst[1].ObjOppty.accountId;
                opp.RecordTypeId = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
                opp.rC_Giving__Payment_Method__c = 'Paypal';
                Boolean isvalid = batchLogObj.opportunityIsValid (new List<opportunity>{opp});
                batchLogObj.None();
                batchLogObj.updateRecalcBooleanFlag(new Set<Id>{batchLogObj.opportunityWrapperlst[0].objOppty.Id});
                batchLogObj.updateAmountOnChild(new List<Opportunity>{batchLogObj.opportunityWrapperlst[0].objOppty});
                batchLogObj.parentOppty = batchLogObj.opportunityWrapperlst[0].objOppty;
                batchLogObj.isAdjustementsCreated =false;
                //batchLogObj.cancelAdjustment();
                //System.assert(false, Limits.getQueries());
            Test.stopTest();
            
            
            batchLogObj.recalculateAdjustSeq(0);
            pageRef.getParameters().put('rowIndex','3');
            PageReference PgRef =  batchLogObj.deleteRow();
            system.assertEquals(2, batchLogObj.opportunityWrapperlst.size());
        }
        
    } 


    @isTest
    public static void testRecords() {
        testSetup();
        usr = TestUtils.createUser('testUsr', 'testUsr@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;
        system.runAs(usr){

            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog);
            
            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            
            batchLogObj.populateOpportunityWrapper();
            
            //member Variables
            Boolean isnew = batchLogObj.isNew;
            Boolean newOrEditing = batchLogObj.newOrEditing;
            Boolean isCompleted = batchLogObj.isCompleted;
            Boolean isAffiliateOrReleased = batchLogObj.isAffiliateOrReleased;
            Boolean affiliateUser = batchLogObj.affiliateUser;
            Boolean isAdjustOrReleased = batchLogObj.isAdjustOrReleased;
            Boolean isAdjustOrSplit = batchLogObj.isAdjustOrSplit;
            Boolean isSplitOrCompleted = batchLogObj.isSplitOrCompleted;
            Boolean psrequired = batchLogObj.psrequired;
            Boolean isAdjustmentRcType = batchLogObj.isAdjustmentRcType;
            //String userAffiliation = batchLogObj.userAffiliation;
            Boolean hasBatchLogItems = batchLogObj.hasBatchLogItems;

            PageReference pageRef = Page.BatchLogDetailPage;
            Test.setCurrentPage(pageRef);
            
            batchLogObj.editBatchLog();
            
            batchLogObj.cancelBatchLog();
            
            pageRef.getParameters().put('activeOpptyIndex', '0');
            batchLogObj.changeActiveOppt();
            batchLogObj.setOpenPledgeIcon();

            pageRef.getParameters().put('recCount1', '1');
            batchLogObj.populateRecordType();
            
            pageRef.getParameters().put('campRow', '0');
            batchLogObj.populateFund();
            
            pageRef.getParameters().put('selectdOpptyForImo', '1');
            pageRef.getParameters().put('relation', 'xyz');
            //batchLogObj.setImoIhoOpportunity();
            pageRef.getParameters().put('accountId','1');
            batchLogObj.updatePaymentURL();
            
            batchLogObj.populateAckFields();
            rC_Bios__Address__c objAddr = TestUtils.createAddress('Test ',true);
            acc.rC_Bios__Preferred_Billing_Address__c=objAddr.id;
            update acc;
            
            //pageRef.getParameters().put('relation', 'parent');
            batchLogObj.populateAckFields();
            batchLogObj.deleteIHOValues();
            bLpledgeBS1.Ack_Recipient_Account__c = null;
            update bLpledgeBS1;
            //batchLogObj.saveIHOValues();
            Test.startTest();
            pageRef.getParameters().put('selectedOpptyForAdjustment', '1');
            batchLogObj.adjustGivingProperties();
            
            Opportunity opp = [SELECT Id, Name, rC_Giving__Parent__c FROM Opportunity WHERE recordType.Name='Pledge Payment' LIMIT 1];
            opp.Adjustment_Reason_Type__c = 'Other';
            opp.Adjustment_Notes__c = 'Test';
            opp.Acknowledgment_Status__c = 'N - Not Acknowledged';
            opp.Acknowledgment_Code__c = 'AK Donor Ack';
            opp.rC_Giving__Acknowledged_Date__c = system.today();
            update opp;
            //pageRef.getParameters().put('adjustedTransactionId', String.valueOf(opp.Id));
            batchLogObj.adjustedTransactionId = opp.Id;
            Opportunity parentOp1 = [SELECT Id FROM Opportunity Where Id = :opp.rC_Giving__Parent__c];
            batchLogObj.parentOppty = parentOp1;
            batchLogObj.cancelAdjustment();
            // BatchLogManager.AdjustmentLogResult res = BatchLogManager.associateAdjustmentLog(opp.Id, false);
            pageRef.getParameters().put('adjustedTransactionId', 'opp.Id');
            batchLogObj.adjustGivingProperties();
            
            batchLogObj.saveAdjustmentOppty();
            Test.stopTest();
            Opportunity parentOp = [SELECT Acknowledgment_Status__c, Acknowledgment_Code__c,
                                        rC_Giving__Acknowledged_Date__c
                                    FROM Opportunity
                                    WHERE Id = :opp.rC_Giving__Parent__c];
            system.assertEquals(opp.Acknowledgment_Status__c, parentOp.Acknowledgment_Status__c);
            //system.assertEquals(opp.Acknowledgment_Code__c, parentOp.Acknowledgment_Code__c);
            //system.assertEquals(opp.rC_Giving__Acknowledged_Date__c, parentOp.rC_Giving__Acknowledged_Date__c);
            
            update new Batch_Log__c(Id=batchLogObj.batchLogId, Batch_Type__c = 'Adjustment');
            batchLogObj.adjustGivingProperties();

            //pagereference pg = batchLogObj.checkRecordType();
        }
    }
    
    @isTest
    public static void testCreateRecords() {
        testSetup();
        mapIdToOpp = new Map<Id,Opportunity>();
        mapInToOpp = new Map<Integer,Opportunity>();
        Integer i=0;
        for(Opportunity opp : [Select id,name,AccountId,rC_Giving__Payment_Method__c,rC_Giving__Payment_Method_Selected__c from Opportunity]){
            mapIdToOpp.put(opp.Id,opp);
            mapInToOpp.put(i++,opp);
        }

        usr = TestUtils.createUser('testUsr', 'testUsr@yz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;

        Batch_Log__c testBatchLog1 = TestUtils.createBatchLog('testBatchName2', false);
        //adding date to avoid onbeforeinsert trigger exception
        testBatchLog1.Batch_Date__c = Date.today();
        testBatchLog1.Batch_Type__c='Standard';
        //testBatchLog1.RecordTypeId = BATCH_LOG_RT_MANUAL_Id;
        testBatchLog1.Expected_Count__c=20;
        testBatchLog1.Expected_Amount__c = 100;
        testBatchLog1.Deposit_Site__c = 'AZW_Arizona_web';
        insert testBatchLog1;
        system.runAs(usr){
            Test.startTest();
            PageReference pageRef = Page.BatchLogDetailPage;
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);
            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            batchLogObj.batchLogInvalid = false;
            batchLogObj.dummy();
            batchLogObj.createBatchLogRecord();
            batchLogObj.batchLog.Deposit_Site__c = 'AZW_Arizona_web';
            batchLogObj.batchLog.Expected_Count__c = 4;
            batchLogObj.batchLog.Expected_Amount__c = 4000;
            batchLogObj.batchLog.BatchLog_Has_Fees__c = false;
            batchLogObj.batchLog.Total_Fees__c = 3000;
            batchLogObj.batchLog.Total_Net_Amount__c = 3000;
            PageReference pr = batchLogObj.saveBatchLog();
            System.assertEquals(1000, batchLogObj.batchLog.Total_Fees__c);
            System.assertEquals(3000, batchLogObj.batchLog.Total_Net_Amount__c);
            batchLogObj.deleteBatchLog();
            BatchLogDetailPageController.createPaymentMethod(mapIdToOpp,testBatchLog1);
            
            //batchLogObj.removePaymentSelected();
            batchLogObj.closePopup();
            batchLogObj.paymentMType = 'Charge Card';
            batchLogObj.paymentMethodRec= new rC_Giving__Payment_Method__c(rC_Connect__Payment_Processor__c='Sage', rC_Connect__Merchant_Name__c = 'Test');
            batchLogObj.createPayment();
            batchLogObj.paymentMType = 'EFT';
            Boolean b = batchLogObj.isValid(batchLogObj.paymentMType, batchLogObj.paymentMethodRec);
            batchLogObj.createPayment();

            pageRef.getParameters().put('oppRow', '1');
            pageRef.getParameters().put('accId', acc.id);
            pageRef.getParameters().put('payType', 'EFT');
            batchLogObj.togglePaymentMethod();
            Map<Integer,Opportunity> mapResult = batchLogObj.populateSelectedPaymentMethod(mapInToOpp);
            List<String> lstResult1 = BatchLogDetailPageController.populateAccountLookup('1','1234');
            List<String> lstRes = BatchLogDetailPageController.populateCampaignLookup('1','-------------000','NA');

            Test.stopTest();

            //System.assertEquals(5,lstRes.size());
            //System.assertEquals(3,lstResult1.size());
        }
    }
    
    @isTest
    public static void testAddSaveCancelRows() {
        testSetup();
      
        usr = TestUtils.createUser('usertest', 'usertest@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        usr.Primary_Affiliate__c = 'CN - ACLU of Northern California';
        usr.Denied_Access_to_Open_Givings__c = true;
        insert usr;
        
        system.runAs(usr){
            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog2);
            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            
            
            
            //Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.BatchLogDetailPage;
            Test.setCurrentPage(pageRef);
            
            List<selectoption> getAC = batchLogObj.getAffiliateCodes();
            List<selectoption> getDS = batchLogObj.getAffiliateDepositSites();
            
            batchLogObj.populateOpportunityWrapper();
            
            pageRef.getParameters().put('splitRowIndex','1');
            batchLogObj.addSplitRow();
            
            pageRef.getParameters().put('activeOpptyIndex','1');
            batchLogObj.changeActiveOppt();
            
            pageRef.getParameters().put('cmpRow', '1');
            pageRef.getParameters().put('cmpProdIds',p2.Id+':'+p2.id);
            batchLogObj.setCampaignProductIds();
            
            
            batchLogObj.saveOneRow();
            
            batchLogObj.createOpptyProducts();
            
            batchLogObj.releaseBatchLog();
            
            batchLogObj.reopenBatchLog();
            
            batchLogObj.addRows();
            
            batchLogObj.cancelRowChange();
            
            pageRef.getParameters().put('rowIndex','1');
            PageReference PgRef =  batchLogObj.deleteRow();
            system.assertEquals(7, batchLogObj.opportunityWrapperlst.size());
            pageRef.getParameters().put('activeOpptyIndex','6');
            batchLogObj.changeActiveOppt();
            batchLogObj.activeOpportunity.objOppty.rC_Giving__Giving_Amount__c = 10;
            
            batchLogObj.saveOneRow();
            system.assertEquals(7, batchLogObj.opportunityWrapperlst.size());
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testDeleteSplit() {
        testSetup();
        usr = TestUtils.createUser('usertest', 'usertest@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        usr.Primary_Affiliate__c = 'CN - ACLU of Northern California';
        usr.Denied_Access_to_Open_Givings__c = true;
        insert usr;
        
        system.runAs(usr){
            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog2);
            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            
            
            
            //Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.BatchLogDetailPage;
            Test.setCurrentPage(pageRef);
            
            batchLogObj.populateOpportunityWrapper();
            
            pageRef.getParameters().put('splitRowIndex','1');
            batchLogObj.addSplitRow();
            
            batchLogObj.cancelRowChange();
            
            pageRef.getParameters().put('rowIndex','6');
            PageReference PgRef =  batchLogObj.deleteRow();
            
            batchLogObj.cancelRowChange();
            
            pageRef.getParameters().put('rowIndex','4');
            PgRef =  batchLogObj.deleteRow();
            system.assert(PgRef == null);
            Test.stopTest();
        }
    }
     public static testMethod void testUpdateParentFunction(){
        usr = TestUtils.createUser('usertest', 'usertest@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        usr.Denied_Access_to_Open_Givings__c = true;
        usr.Primary_Affiliate__c = 'NN - National Chapters';
        insert usr;
        

        testSetup();
        RC_Giving__Payment_Method__c meth1 = testUtils.createPaymentMethod( acc.id, false );
        meth1.rC_Giving__Payment_Type__c = 'Paypal';
        meth1.rC_Connect__Payment_Processor__c = 'Heartland';
        meth1.RecordTypeId = Schema.SObjectType.rC_Giving__Payment_Method__c.getRecordTypeInfosByName().get('Paypal').getRecordTypeId();
        
        insert meth1;
        Opportunity oprt = new Opportunity(id= bL1donationBS1.id, rC_Giving__Payment_Method_Selected__c = meth1.id);
        update oprt; 
        system.runAs(usr){
            
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);
            //creating standardcontroller object to pass as parameter to controller constructor
            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);

            //Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.BatchLogDetailPage;
            pageRef.getParameters().put('matchOpptyIndex', '1');
            Test.setCurrentPage(pageRef);
            
            //system.assertEquals(101,Limits.getQueries());
            pageRef.getParameters().put('row', '1');
            pageRef.getParameters().put('OpportId', bL1donationBS1.id );
            pageRef.getParameters().put( 'isPledgePayment', 'true');    
                   
            //ActiveOpportunity wrapper necessary due to addition of Source_Code_Overwrite__c field reference in updateParent call (GH-34)
            batchLogObj.ActiveOpportunity = batchLogObj.opportunityWrapperlst[0];
            
            //system.assertEquals(101,Limits.getQueries());
            /*PageReference pr1 = batchLogObj.updateParent();
            pageRef.getParameters().put( 'isPledgePayment', 'false');
            PageReference pr2 = batchLogObj.updateParent();*/
            
            pageRef.getParameters().put('selAccId', acc.Id);
            pageRef.getParameters().put('selRow', '0');
            batchLogObj.ViewAllCredits();
        Test.startTest();
            System.assertEquals(null, batchLogObj.updateParent());
            
        Test.stopTest();
        
        
        }
        
    }
    /*
    * dsadsa
     */

    @isTest
    public static void reparentCredit(){
        Account acc2 = TestUtils.createAccount('Account Adjust',false);
        acc2.Account_Type__c = 'Matching Company';
        acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        insert acc2;
        testSetup();
        rC_Giving__Opportunity_Credit__c credit = new rC_Giving__Opportunity_Credit__c();
        credit.rC_Giving__Opportunity__c = bL1donationBS1.id;
        credit.rC_Giving__Account__c = bL1donationBS1.AccountId;
        credit.Soft_Credit_Type__c = 'Third Part';
        credit.rC_Giving__Type__c = 'Account Only';
        credit.rC_Giving__Distribution__c = 100;
        credit.RecordTypeId = Schema.SObjectType.rC_Giving__Opportunity_Credit__c.getRecordTypeInfosByName().get('Recognition').getRecordTypeId();
        insert credit;

        PageReference pageRef = Page.BatchLogDetailPage;
        ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);
        BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);

        batchLogObj.populateOpportunityWrapper();

        batchLogObj.oppRow = 1;
        batchLogObj.clearPaymentFields();

        batchLogObj.showAdj_Save_Commit_btn = true;
        batchLogObj.showAdj_CancelAdjust_btn = true;
        batchLogObj.showAdj_Save_btn = true;
        batchLogObj.showAdj_close_btn = true;

        Test.setCurrentPage(pageRef);

        batchLogObj.editBatchLog();

        pageRef.getParameters().put('activeOpptyIndex', '0');
        batchLogObj.changeActiveOppt();
        batchLogObj.setOpenPledgeIcon();

        pageRef.getParameters().put('recCount1', '1');
        batchLogObj.populateRecordType();

        pageRef.getParameters().put('campRow', '0');
        batchLogObj.populateFund();
        Test.startTest();

        Opportunity opp = [SELECT Id, Name, rC_Giving__Parent__c, RecordType.name, Acknowledgment_Code__c, Acknowledgment_Status__c, rC_Giving__Acknowledged_Date__c
        FROM Opportunity WHERE rC_Giving__Parent__c =  :bL1donationBS1.id LIMIT 1];
        batchLogObj.originalTransaction = opp;
        System.debug('opp opp&&&&: '+ opp);
        opp.Adjustment_Reason_Type__c = 'Other';
        opp.Adjustment_Notes__c = 'Test';
        opp.Acknowledgment_Status__c = 'N - Not Acknowledged';
        opp.Acknowledgment_Code__c = 'AK Donor Ack';
        opp.rC_Giving__Acknowledged_Date__c = system.today();
        opp.Adjustment_Code__c ='D';
        opp.AccountId = acc2.Id;        
        update opp;

        batchLogObj.adjustedTransactionId = opp.Id;
        batchLogObj.adjustmentFieldSet = batchLogObj.getFields('Adjustments_Field_Set');
        System.debug('### adjustmentFieldSet ###: '+  batchLogObj.adjustmentFieldSet);

        Opportunity trans = [SELECT Id,Name, Adjustment_Code__c, rC_Giving__Parent__c, campaignIdText__c, AccountId, rC_Giving__Transaction_Type__c, RecordType.Name,Acknowledgment_Code__c,Acknowledgment_Status__c,
                CloseDate,Amount, rC_Giving__Payment_Method__c, rC_Giving__Payment_Method_Selected__c, CampaignId, Bank_Date__c, Adjustment_Reason_Type__c, Adjustment_Notes__c, rC_Giving__Acknowledged_Date__c
        FROM Opportunity Where Id = :opp.Id];


        List<Opportunity> adjustmentOpptyLst = new List<Opportunity>();
        adjustmentOpptyLst.add(opp);

        List<Opportunity> adjustmentOpptyUpdateLst = new List<Opportunity>();
        adjustmentOpptyUpdateLst.add(trans);

        batchLogObj.adjustmentOpptyUpdateLst = adjustmentOpptyUpdateLst;
        batchLogObj.adjustmentOpptyLst = adjustmentOpptyLst;
        batchLogObj.parentOppty = bL1donationBS1;

//        batchLogObj.saveAdjustmentOppty();
        Test.stopTest();
        List<rC_Giving__Opportunity_Credit__c> cDonation = [SELECT Id FROM rC_Giving__Opportunity_Credit__c where rC_Giving__Opportunity__c = :bL1donationBS1.id];
        System.assertEquals(1, cDonation.size() );

    }


    @isTest
    public static void saveAdjustmentOpptyWithAccChange() {
        //bge-84
        Account acc2 = TestUtils.createAccount('Account Adjust',false);
        acc2.Account_Type__c = 'Matching Company';
        acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        insert acc2;
        testSetup();

        usr = TestUtils.createUser('testUsr', 'testUsr@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;
        system.runAs(usr) {

            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog);

            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            batchLogObj.populateOpportunityWrapper();
            PageReference pageRef = Page.BatchLogDetailPage;

            Test.setCurrentPage(pageRef);

            Test.startTest();
            pageRef.getParameters().put('selectedOpptyForAdjustment', '1');

            Opportunity opp = [SELECT Id, Name, rC_Giving__Parent__c, amount, rC_Giving__Is_Bookable__c
                                FROM Opportunity
                                WHERE rC_Giving__Parent__c = : bL1donationBS1.Id  LIMIT 1];

            opp.Account=acc2;
            opp.amount = 20;
            opp.Adjustment_Code__c = 'D';
            opp.Adjustment_Reason_Type__c = 'Other';
            opp.Adjustment_Notes__c = 'Test';
            opp.Acknowledgment_Status__c = 'N - Not Acknowledged';
            opp.Acknowledgment_Code__c = 'AK Donor Ack';
            opp.rC_Giving__Is_Bookable__c = true;
            opp.rC_Giving__Acknowledged_Date__c = system.today();

            update opp;
            batchLogObj.adjustedTransactionId = opp.Id;
            batchLogObj.adjustTransParentId = bL1donationBS1.Id;

            batchLogObj.adjustGivingProperties();

            batchLogObj.adjustedTransactionId = opp.Id;
            Opportunity parentOp1 = [SELECT Id, rC_Giving__Is_Bookable__c FROM Opportunity Where Id = :opp.rC_Giving__Parent__c];
            parentOp1.rC_Giving__Is_Bookable__c = true;
            update parentOp1;
            batchLogObj.parentOppty = parentOp1;
            batchLogObj.cancelAdjustment();
            // BatchLogManager.AdjustmentLogResult res = BatchLogManager.associateAdjustmentLog(opp.Id, false);
            pageRef.getParameters().put('adjustedTransactionId', 'opp.Id');
            batchLogObj.adjustGivingProperties();
            parentOp1.rC_Giving__Is_Bookable__c = false;
            update parentOp1;
            batchLogObj.parentOppty = parentOp1;
            batchLogObj.saveAdjustmentOppty();

            Test.stopTest();

            List<Opportunity> oppAfter = [SELECT Id, AccountId, Name, rC_Giving__Parent__c, amount, rC_Giving__Is_Bookable__c
                        FROM Opportunity
                        WHERE rC_Giving__Parent__c = : bL1donationBS1.Id  ];
            System.assertNotEquals(oppAfter.size(), 0 );
        }
    }

    @isTest
    public static void createBatchaAsTPABypass() {
        testSetup();

        usr = TestUtils.createUser('testUsr', 'testUsr@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;

        Opportunity opp = TestUtils.CreateOpportunity(acc.Id, 'Test 3'+acc.Name, false);
        opp.Batch_Log__c=testBatchLog1.id;
        opp.IsCreatedFromBatchLog__c = true;
        opp.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        opp.rC_Giving__Is_Bookable__c = true;
        opp.closeDate = system.today();
        insert(opp);

        testBatchLog1.TPA_Bypass__c = true;

        update testBatchLog1;

        system.runAs(usr) {
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);

            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);

            batchLogObj.populateOpportunityWrapper();

            PageReference pageRef = Page.BatchLogDetailPage;

            Test.setCurrentPage(pageRef);
        }
    }

    @isTest
    public static void deleteBatchaAsTPABypass() {
        testSetup();

        usr = TestUtils.createUser('testUsr', 'testUsr@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;
        system.runAs(usr) {
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);

            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            batchLogObj.deleteBatchLog();
        }
    }

    @isTest
    public static void checkRecordType() {
        testSetup();
        Id VendorRecordType = Schema.SObjectType.Batch_Log__c.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        testBatchLog1.RecordTypeId = VendorRecordType;
        update testBatchLog1;
        usr = TestUtils.createUser('testUsr', 'testUsr@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;
        system.runAs(usr) {
            ApexPages.currentPage().getParameters().put('RecordType', testBatchLog1.RecordTypeId);
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);
            PageReference pageRef = Page.BatchLogDetailPage;
            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            PageReference pg = batchLogObj.checkRecordType();
            System.assert(pg.getUrl().contains(VendorRecordType));
        }
    }

    @isTest
    public static void checkRecordTypeManual() {
        testSetup();

        usr = TestUtils.createUser('testUsr', 'testUsr@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;
        system.runAs(usr) {
            ApexPages.currentPage().getParameters().put('RecordType', testBatchLog1.RecordTypeId);
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);
            PageReference pageRef = Page.BatchLogDetailPage;
            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            PageReference pg = batchLogObj.checkRecordType();
            System.assertEquals(pg, null);
        }
    }
    @isTest
    public static void checkBatchLogWarning() {
        testSetup();

        usr = TestUtils.createUser('testUsr', 'testUsr@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;
        system.runAs(usr) {
            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);
            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            PageReference pg = batchLogObj.checkBatchLogWarning();
            System.assertEquals(0, pageMessages.size());
        }
    }

    @isTest
    public static void checkBatchLogWarningCsh() {
        testSetup();

        usr = TestUtils.createUser('testUsr', 'testUsr@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;
        testBatchLog1.Expected_Count__c =1;
        testBatchLog1.Expected_Amount__c =10;
        testBatchLog1.Deposit_Site__c = 'AK_Alaska';
        testBatchLog1.Affiliation__c = 'NA';
        testBatchLog1.Default_Payment__c = 'Cash/Check';
        testBatchLog1.Payment_Subtype__c = 'Cash';
        update testBatchLog1;
        system.runAs(usr) {
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);

            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            Test.startTest();
            batchLogObj.batchProgramType = 'Union';
            batchLogObj.affiliateCode = 'NA';
            batchLogObj.checkBatchLogWarning();
            List<Apexpages.Message> pMessages = ApexPages.getMessages();
            Test.stopTest();
            System.assertNotEquals(0, pMessages.size());
        }
    }
    @isTest
    public static void checkBatchLogWarningChargeCard() {
        testSetup();

        usr = TestUtils.createUser('testUsr', 'testUsr@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;
        testBatchLog1.Expected_Count__c =1;
        testBatchLog1.Expected_Amount__c =10;
        testBatchLog1.Deposit_Site__c = 'AK_Alaska';
        testBatchLog1.Affiliation__c = 'NA';
        testBatchLog1.Default_Payment__c = 'Charge Card';
        update testBatchLog1;
        system.runAs(usr) {
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);

            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            Test.startTest();
            batchLogObj.batchProgramType = 'Union';
            batchLogObj.affiliateCode = 'NA';
            batchLogObj.checkBatchLogWarning();
            List<Apexpages.Message> pMessages = ApexPages.getMessages();
            Test.stopTest();
            System.assertNotEquals(0, pMessages.size());
        }
    }

    @isTest
    public static void checkBatchLogWarningEft() {
        testSetup();

        usr = TestUtils.createUser('testUsr', 'testUsr@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;
        testBatchLog1.Expected_Count__c =1;
        testBatchLog1.Expected_Amount__c =10;
        testBatchLog1.Deposit_Site__c = 'AK_Alaska';
        testBatchLog1.Affiliation__c = 'NA';
        testBatchLog1.Default_Payment__c = 'EFT';
        update testBatchLog1;
        system.runAs(usr) {
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);

            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            Test.startTest();
            batchLogObj.batchProgramType = 'Union';
            batchLogObj.affiliateCode = 'NA';
            batchLogObj.checkBatchLogWarning();
            List<Apexpages.Message> pMessages = ApexPages.getMessages();
            Test.stopTest();
            System.assertNotEquals(0, pMessages.size());
        }
    }

    @isTest
    public static void checkBatchLogWarningOther() {
        testSetup();

        usr = TestUtils.createUser('testUsr', 'testUsr@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;
        testBatchLog1.Expected_Count__c =1;
        testBatchLog1.Expected_Amount__c =10;
        testBatchLog1.Deposit_Site__c = 'AK_Alaska';
        testBatchLog1.Affiliation__c = 'NA';
        testBatchLog1.Default_Payment__c = 'Other';
        testBatchLog1.Payment_Subtype__c = 'Wire Transfer';
        update testBatchLog1;
        system.runAs(usr) {
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);

            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            Test.startTest();
            batchLogObj.batchProgramType = 'U';
            batchLogObj.affiliateCode = 'NA';
            batchLogObj.checkBatchLogWarning();
            List<Apexpages.Message> pMessages = ApexPages.getMessages();
            Test.stopTest();
            System.assertNotEquals(0, pMessages.size());
        }
    }

    @isTest
    public static void checkBatchLogBatchProgramTypeU() {
        testSetup();

        usr = TestUtils.createUser('testUsr', 'testUsr@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;
        testBatchLog1.Expected_Count__c =1;
        testBatchLog1.Expected_Amount__c =10;
        testBatchLog1.Deposit_Site__c = 'COS_NatFU_cosmetic';
        testBatchLog1.Default_Payment__c = 'Other';
        testBatchLog1.Payment_Subtype__c = 'Wire Transfer';
        update testBatchLog1;
        system.runAs(usr) {
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);

            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            Test.startTest();
            batchLogObj.batchProgramType = 'U';
            batchLogObj.checkBatchLogWarning();
            List<Apexpages.Message> pMessages = ApexPages.getMessages();
            Test.stopTest();
            System.assertNotEquals(0, pMessages.size());

        }
    }

    @isTest
    public static void checkBatchLogBatchProgramTypeF() {
        testSetup();

        usr = TestUtils.createUser('testUsr', 'testUsr@xyz.co', null, false);
        usr.Is_Affiliate_User__c = true;
        insert usr;
        testBatchLog1.Expected_Count__c =1;
        testBatchLog1.Expected_Amount__c =10;
        testBatchLog1.Deposit_Site__c = 'NAL_NatU_Paypal';
        testBatchLog1.Default_Payment__c = 'Other';
        testBatchLog1.Payment_Subtype__c = 'Wire Transfer';
        update testBatchLog1;
        system.runAs(usr) {
            ApexPages.StandardController sc = new ApexPages.StandardController(testBatchLog1);

            BatchLogDetailPageController batchLogObj = new BatchLogDetailPageController(sc);
            Test.startTest();
            batchLogObj.batchProgramType = 'F';
            batchLogObj.checkBatchLogWarning();
            List<Apexpages.Message> pMessages = ApexPages.getMessages();
            Test.stopTest();
            System.assertNotEquals(0, pMessages.size());

        }
    }
    
}