@isTest
private class SoftCreditPageControllerTest {
    private static Batch_Log__c testBatchLog1;
    private static Batch_Log__c testBatchLog;
    private static User usr;
    private static User usr1;
    private static BatchLogDetailPageController batchLogObj;
    private static Account acc;
    private static Account acc1;
    private static Account acc2;
    private static SoftCreditPageController.OpportunityWrapper objWrap;
    
    private static String OPPORTUNITY_RT_PLEDGEPAYMENT_Id;
    private static Opportunity opp;
    private static Opportunity opp1;
    private static Opportunity opp4;
    private static Opportunity opp5;
    private static Map<Id,Opportunity> mapIdToOpp ;
    private static Map<Integer,Opportunity> mapInToOpp;
    private static campaign cmp;
    private static Campaign cmp2;

    private static List<opportunity> oppLst ;
    
    
    public static void testSetup() {
        
        
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
        String OPPORTUNITY_RT_DONATION_Id = opptyRTMap.get('Donation').getRecordTypeId();
        String OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
        String OPPORTUNITY_RT_SOFTCREDIT_Id = opptyRTMap.get('Soft Credit').getRecordTypeId();
        
        //creating Batch Log record using TestUtils class
        acc = TestUtils.createAccount('Account'+1,false);
        //acc.Account_Number__c='123';
        acc.Account_Type__c = 'Matching Company';
        acc.External_ID__c = '1234';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        insert acc;
       // System.assert(False,[Select id,Account_Type__c,Account_Number__c from Account where id=:acc.id ]);
        
        usr1 = TestUtils.createUser('usertest1', 'usertest1@aclu.org', null, false);
        usr1.Is_Affiliate_User__c = false;
        usr1.Denied_Access_to_Open_Givings__c = false;
        usr1.Email = 'usertest1@aclu.org';
        insert usr1;
        
        cmp = TestUtils.createCampaign('test camp',false);
        cmp.rC_Giving__Source_Code__c = '123';
        cmp.Account_Code__c = 'ABAD - Abortion Ad';
        
        cmp2 = TestUtils.createCampaign('test camp456',false);
        cmp2.rC_Giving__Source_Code__c = '12356';
        cmp2.Account_Code__c = 'ABAD - Abortion Ad';
        List<Campaign> cmpList = new List<Campaign>{cmp,cmp2};
        List<Opportunity> parentOppList = new List<Opportunity>();
        List<Opportunity> childOppList = new List<Opportunity>();
        List<Batch_Log__c> batchLogList = new List<Batch_Log__c>();
        System.runAs(usr1){
            insert cmpList;
        
        
        testBatchLog1 = TestUtils.createBatchLog('testBatchName1', false);
        //adding date to avoid onbeforeinsert trigger exception
        testBatchLog1.Batch_Date__c = Date.today();
        //testBatchLog1.Batch_Type__c='Adjustment';
        testBatchLog1.Batch_Type__c='Standard';
        testBatchLog1.RecordTypeId = BATCH_LOG_RT_MANUAL_Id;
        testBatchLog1.Expected_Count__c=20;
        testBatchLog1.Expected_Amount__c = 100;
        batchLogList.add(testBatchLog1);
        
        testBatchLog = TestUtils.createBatchLog('testBatchName', false);
        //adding date to avoid onbeforeinsert trigger exception
        testBatchLog.Batch_Date__c = Date.today();
        testBatchLog.Batch_Type__c='Standard';
        testBatchLog.RecordTypeId = BATCH_LOG_RT_MANUAL_Id;
        testBatchLog.Expected_Count__c=20;
        testBatchLog.Expected_Amount__c = 100;
        testBatchLog.Default_Campaign__c = cmp.id;
        testBatchLog.Actual_Count__c = 20;
        testBatchLog.Actual_Amount__c = 100;
        batchLogList.add(testBatchLog);
        insert batchLogList;
        
        opp = TestUtils.CreateOpportunity(acc.Id, 'Test 0'+acc.Name, false);
        opp.Batch_Log__c=testBatchLog1.id;        
        opp.IsCreatedFromBatchLog__c = true;
        opp.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
        opp.CampaignId = cmp2.id;
        opp.closeDate = system.today()+10;
        opp.Batch_Sequence__c = '1';
        parentOppList.add(opp);
        
        
        
        //Pledge Record
        Opportunity bLpledgeBS0= TestUtils.CreateOpportunity(acc.Id, 'Test 5'+acc.Name, false);
        bLpledgeBS0.Adjustment_Batch__c=testBatchLog1.id;
        bLpledgeBS0.IsCreatedFromBatchLog__c = true;
        bLpledgeBS0.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        bLpledgeBS0.CampaignId = cmp.id;
        bLpledgeBS0.rC_Giving__Is_Sustainer__c = false;
        bLpledgeBS0.Ack_Recipient_Account__c = acc.id;
        bLpledgeBS0.Batch_Sequence__c = '1';
        parentOppList.add(bLpledgeBS0);

        
        
        opp1= TestUtils.CreateOpportunity(acc.Id, 'Test 1'+acc.Name, false);
        opp1.Adjustment_Batch__c=testBatchLog.id;
        opp1.IsCreatedFromBatchLog__c = true;
        opp1.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        opp1.CampaignId = cmp.id;
        opp1.Ack_Recipient_Account__c = acc.id;
        opp1.Ack_Recipient_Street_Line_2__c = '1.ack street Line 2';
        opp1.rC_Giving__Payment_Method__c = 'Paypal';
        opp1.Honoree_Title__c = 'Ms.';
        opp1.Honoree_First_Name__c = 'Test Honoree User';
        opp1.Honoree_Middle_Name__c = 'Test Middle';
        opp1.Honoree_Last_Name__c = 'Test Last Name';
        
        parentOppList.add(opp1);
        
        
        opp5= TestUtils.CreateOpportunity(acc.Id, 'Test 5'+acc.Name, false);
        opp5.Adjustment_Batch__c=testBatchLog.id;
        opp5.IsCreatedFromBatchLog__c = true;
        opp5.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        opp5.CampaignId = cmp.id;
        opp5.rC_Giving__Is_Sustainer__c = false;
        opp5.Ack_Recipient_Account__c = acc.id;
        opp5.Ack_Recipient_Street_Line_2__c = '5ack street Line 2';
        opp5.Related_Transaction__c = opp1.Id;
        opp5.Batch_Sequence__c = '0';
        parentOppList.add(opp5);
        insert parentOppList;
        
        Opportunity oppTrans= TestUtils.CreateOpportunity(acc.Id, 'Test 3'+acc.Name, false);
        oppTrans.Batch_Log__c=testBatchLog1.id;
        oppTrans.IsCreatedFromBatchLog__c = true;
        oppTrans.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        oppTrans.rC_Giving__Parent__c = opp.Id;
        oppTrans.closeDate = system.today()+10;
        oppTrans.Batch_Sequence__c = '1';
        childOppList.add(oppTrans);
        //Pledge Payment
        Opportunity bLPledgePaymentBS0= TestUtils.CreateOpportunity(acc.Id, 'Test 8'+acc.Name, false);
        bLPledgePaymentBS0.RecordTypeId = OPPORTUNITY_RT_PLEDGEPAYMENT_Id;
        bLPledgePaymentBS0.IsCreatedFromBatchLog__c = true;
        bLPledgePaymentBS0.rC_Giving__Parent__c = bLpledgeBS0.Id;
        bLPledgePaymentBS0.batch_Log__c=testBatchLog1.id;
        bLPledgePaymentBS0.Batch_Sequence__c = '1';
        bLPledgePaymentBS0.stagename='open';
        bLPledgePaymentBS0.Adjustment_Code__c = 'D';
        bLPledgePaymentBS0.amount=20;
        childOppList.add(bLPledgePaymentBS0);
        
        // Soft Credit
        Opportunity bL1scBS0= TestUtils.CreateOpportunity(acc.Id, 'Test 4'+acc.Name, false);
        bL1scBS0.Batch_Log__c=testBatchLog1.id;
        bL1scBS0.IsCreatedFromBatchLog__c = true;
        bL1scBS0.RecordTypeId = OPPORTUNITY_RT_SOFTCREDIT_Id;
        bL1scBS0.CampaignId = cmp.id;
        bL1scBS0.Amount = 100;
        bL1scBS0.rC_Giving__Parent__c = opp.id;
        bL1scBS0.closeDate = system.today()+10;
        
        bL1scBS0.Batch_Sequence__c = '1';
		childOppList.add(bL1scBS0);
        
      /*  Opportunity  oppl = TestUtils.CreateOpportunity(acc.Id, 'Test 0'+acc.Name, false);
        oppl.Batch_Log__c=testBatchLog1.id;        
        oppl.IsCreatedFromBatchLog__c = true;
        oppl.rC_Giving__Parent__c = opp.Id;
        opp1.CampaignId = cmp.id;
        oppl.RecordTypeId = OPPORTUNITY_RT_SOFTCREDIT_Id;
        oppl.closeDate = system.today()+10; 
        oppl.Batch_Sequence__c = '2';
         
        insert oppl; */
        
        Opportunity opp3= TestUtils.CreateOpportunity(acc.Id, 'Test 3'+acc.Name, false);
        opp3.Batch_Log__c=testBatchLog1.id;
        opp3.RecordTypeId = OPPORTUNITY_RT_SOFTCREDIT_Id;
        opp3.IsCreatedFromBatchLog__c = true;
        //opp3.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        opp3.rC_Giving__Parent__c = opp.Id;
        //opp3.Related_Transaction__c=opp1.id;
        opp3.Ack_Recipient_Account__c=acc.id;
        opp3.Ack_Recipient_Street_Line_2__c = 'ack street Line 2';
        opp3.CampaignId = cmp.id;
        opp3.closeDate = system.today()+10;
        childOppList.add(opp3);
        insert childOppList;
        System.debug('>>>>Opportunity Wrapper>>>>' +  opp3.Ack_Recipient_Account__c);
        }   
         
        
    }
    
    
    
    @isTest
    private static void TestSoftCreditPageController(){
        
        testSetup();
        Test.startTest();
        
        map<String,String> mapofstring=new map<String,String>();
        mapofstring.put('1','10');
        
        acc1 = TestUtils.createAccount('Account'+1,false);
        acc1.Account_Type__c = 'Matching Company';
        acc1.External_ID__c = '023'; 
        acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        insert acc1;
        
        opp1= TestUtils.CreateOpportunity(acc.Id, 'Test 1'+ acc1.Name, false);
        opp1.Adjustment_Batch__c=testBatchLog.id;
        opp1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
        opp1.CampaignId = cmp.id;
        opp1.Ack_Recipient_Account__c = acc.id;
        opp1.Ack_Recipient_Street_Line_2__c = '1.ack street Line 2';
        opp1.rC_Giving__Payment_Method__c = 'Paypal';
        opp1.Honoree_Title__c = 'Ms.';
        opp1.Honoree_First_Name__c = 'Test Honoree User';
        opp1.Honoree_Middle_Name__c = 'Test Middle';
        opp1.Honoree_Last_Name__c = 'Test Last Name';
        
        
        usr = TestUtils.createUser('usertest', 'usertest@aclu.org', null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Primary_Affiliate__c = 'CN - ACLU of Northern California';
        usr.Email = 'usertest@aclu.org';
        insert usr;
        system.runAs(usr){
            PageReference pageRef = Page.SoftCreditPage;  
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('parentOppId',opp.id);
            ApexPages.currentPage().getParameters().put('batchLogId',testBatchLog1.id);
            ApexPages.currentPage().getParameters().put('selectdOpptyForImo','1');
            ApexPages.currentPage().getParameters().put( 'relation', 'child');  
            ApexPages.currentPage().getParameters().put( 'delSoftC_Index', '1');   
            ApexPages.currentPage().getParameters().put( 'row', '1');
            ApexPages.currentPage().getParameters().put( 'isOpenfromSft', 'true'); 
            ApexPages.currentPage().getParameters().put( 'isPledgePayment', 'true'); 
            ApexPages.currentPage().getParameters().put( 'OpportId',opp5.id); 
            ApexPages.currentPage().getParameters().put( 'selAccId',acc.id); 
            ApexPages.currentPage().getParameters().put( 'selRow','0'); 
            ApexPages.currentPage().getParameters().put( 'sftAccId',acc.id); 
            ApexPages.currentPage().getParameters().put( 'sftselRow','1');
            ApexPages.StandardController sm = new ApexPages.StandardController(testBatchLog1);
            
            
            objWrap = new SoftCreditPageController.OpportunityWrapper(opp5, 1 , true, true, true);
            objWrap.objOppty = opp5;
            System.debug('>>objWrap.objOppty> ' + objWrap.objOppty); 
            
            SoftCreditPageController SoftCreditObj = new SoftCreditPageController(sm);  
            SoftCreditObj.populateChildOpportunityWrapper();
            pagereference pg5 = SoftCreditObj.exportSoftCredits();
            //system.assertEquals(testSCOpp.rC_Giving__Parent__c, testOpp.id);
            //List<Opportunity> opps = [select id from opportunity where rC_Giving__Parent__c =:testOpp.Id AND recordType.Name ='Soft Credit'];
            //system.assertEquals(1,opps.size());
            //system.assertEquals(0,SoftCreditObj.childOppWrapperLst.size());
            system.debug('PPPCCCC'+SoftCreditObj.childOppWrapperLst);
            List<selectoption> getRT = SoftCreditObj.getAcknowledgementCodePicklist(); 
           
            
            //SoftCreditObj.currentPage();
            //SoftCreditObj.lastPage();
            //SoftCreditObj.next();
            //SoftCreditObj.pageNumber=2;
            //SoftCreditObj.setPageSize=1;
            //SoftCreditObj.previous();
            SoftCreditObj.addChildRows();
            
            pagereference pg3 = SoftCreditObj.deleteSoftCRow(); 
            
            pageRef.getParameters().put('activeOpptyIndex', '0');
            SoftCreditObj.changeActiveOppt();
            
            
            //pagereference pg = SoftCreditObj.saveChildRows();
            //pagereference pg1 = SoftCreditObj.updateParent();
            
            //SoftCreditObj.setImoIhoOpportunity(); 
            //SoftCreditObj.activeOpportunity = new SoftCreditPageController.OpportunityWrapper(opp5, 1 , true, true, true);
            SoftCreditObj.activeOpportunity.objOppty.accountId=null;
            SoftCreditObj.activeOpportunity.objOppty.amount=0;
            //populate IMO details
            SoftCreditObj.activeOpportunity.objOppty.rC_Giving__Tribute_Type__c ='Test';
            SoftCreditObj.activeOpportunity.objOppty.Honoree_Title__c ='Test';
            SoftCreditObj.activeOpportunity.objOppty.Honoree_First_Name__c ='Test';
            SoftCreditObj.activeOpportunity.objOppty.Honoree_Middle_Name__c ='Test';
            SoftCreditObj.activeOpportunity.objOppty.Honoree_Last_Name__c ='Test';
            SoftCreditObj.activeOpportunity.objOppty.Honoree_Suffix__c ='Test';
            SoftCreditObj.activeOpportunity.objOppty.Non_Person__c =null;
            SoftCreditObj.activeOpportunity.objOppty.Recipient_Acknowledgment_Code__c='D';
            SoftCreditObj.activeOpportunity.objOppty.Recipient_Acknowledgement_Status__c = 'Test';
            SoftCreditObj.activeOpportunity.objOppty.Tribute_Message_Body__c = 'Test';
            SoftCreditObj.activeOpportunity.objOppty.Ack_Recipient_Full_Name__c = 'Test';
            Boolean bl = SoftCreditObj.activeOpportunity.hasSharingValues;
            
            SoftCreditObj.activeOpportunity.objOppty.RecordTypeId = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
            SoftCreditObj.activeOpportunity.objOppty.rC_Giving__Payment_Method__c = 'Paypal';
            
            List<SoftCreditPageController.OpportunityWrapper> newList = new List<SoftCreditPageController.OpportunityWrapper>();
            newList.add(SoftCreditObj.activeOpportunity);
            SoftCreditObj.childOppWrapperLst= newList;
            SoftCreditObj.populateAckFields();
            
            SoftCreditObj.deleteIHOValues();
            SoftCreditObj.populatePledgeBoolean();
            SoftCreditPageController.populateAccountLookup('1','1234');
            SoftCreditObj.opportunityIsValid(newList); 
            SoftCreditObj.saveOneRow();
            pagereference pg1 = SoftCreditObj.updateParent();
            ApexPages.currentPage().getParameters().put( 'isPledgePayment', 'false');
            pagereference pg2 = SoftCreditObj.updateParent();
            
            
            SoftCreditObj.cancelRowChange();
             
            SoftCreditObj.OppToUpdate = opp1;
            SoftCreditPageController.accType = 'Account Type';
            SoftCreditObj.closeIHOPopup = true;
            SoftCreditObj.saveAndValidateAmount(); 
            
            SoftCreditObj.activeOpportunity = new SoftCreditPageController.OpportunityWrapper(opp5, 1 , true, true, true);
            SoftCreditObj.activeOpportunity.objOppty = opp5;
            SoftCreditObj.updateSftAmount(); 
            
            Test.stopTest();
            
           

        }
    }
    
    
     @isTest
    private static void TestOpportunityValidMethod(){
        testSetup();
        Test.startTest();
            usr = TestUtils.createUser('usertest', 'usertest@aclu.org', null, false);
            usr.Is_Affiliate_User__c = false;
            usr.Denied_Access_to_Open_Givings__c = false;
            usr.Primary_Affiliate__c = 'CN - ACLU of Northern California';
            usr.Email = 'usertest@aclu.org';
            insert usr;
            system.runAs(usr){
                ApexPages.currentPage().getParameters().put('parentOppId',opp.id);
                ApexPages.currentPage().getParameters().put('batchLogId',testBatchLog1.id);
                ApexPages.currentPage().getParameters().put('selectdOpptyForImo','1');
                ApexPages.currentPage().getParameters().put( 'relation', 'child');  
                ApexPages.currentPage().getParameters().put( 'delSoftC_Index', '1');   
                ApexPages.currentPage().getParameters().put( 'row', '1');
                ApexPages.currentPage().getParameters().put( 'isOpenfromSft', 'true'); 
                ApexPages.currentPage().getParameters().put( 'isPledgePayment', 'true'); 
                ApexPages.currentPage().getParameters().put( 'OpportId',opp5.id); 
                ApexPages.currentPage().getParameters().put( 'selAccId',acc.id); 
                ApexPages.currentPage().getParameters().put( 'selRow','0'); 
                ApexPages.currentPage().getParameters().put( 'sftAccId',acc.id); 
                ApexPages.currentPage().getParameters().put( 'sftselRow','1');
                ApexPages.StandardController sm = new ApexPages.StandardController(testBatchLog1);
                SoftCreditPageController SoftCreditObj = new SoftCreditPageController(sm);
                SoftCreditObj.activeOpportunity = new SoftCreditPageController.OpportunityWrapper(opp5, 1 , true, true, true);
                
                SoftCreditObj.activeOpportunity.objOppty.rC_Giving__Tribute_Type__c =null;
                SoftCreditObj.activeOpportunity.objOppty.Honoree_Title__c ='Test';
                SoftCreditObj.activeOpportunity.objOppty.Honoree_First_Name__c ='Test';
                SoftCreditObj.activeOpportunity.objOppty.Honoree_Middle_Name__c ='Test';
                SoftCreditObj.activeOpportunity.objOppty.Honoree_Last_Name__c ='Test';
                SoftCreditObj.activeOpportunity.objOppty.Honoree_Suffix__c ='Test';
                SoftCreditObj.activeOpportunity.objOppty.Non_Person__c ='Test';
                SoftCreditObj.activeOpportunity.objOppty.Recipient_Acknowledgment_Code__c='D';
                SoftCreditObj.activeOpportunity.objOppty.Recipient_Acknowledgement_Status__c = 'Test';
                SoftCreditObj.activeOpportunity.objOppty.Tribute_Message_Body__c = 'Test';
                SoftCreditObj.activeOpportunity.objOppty.Ack_Recipient_Full_Name__c = 'Test';
                Boolean b2 = SoftCreditObj.activeOpportunity.hasImoValues;
                Boolean pg= SoftCreditObj.opportunityIsValid(new list<SoftCreditPageController.OpportunityWrapper>{SoftCreditObj.activeOpportunity}); 
            }
        Test.StopTest();
    }
    
    
    
    
}