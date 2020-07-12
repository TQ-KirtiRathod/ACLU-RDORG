/**
 * Test Class for SoftCreditPageController
 **/
@isTest
private class SoftCreditPageController_Test {
    static Batch_Log__c manualBatchLog;
    static Opportunity donationOpp;
    static String OPPORTUNITY_RT_SOFTCREDIT_Id;
    static Opportunity pledgePaymentOpp;
    static Account acc;
    static Opportunity transactionOpp;
    public static void testSetup() {
        //rC_Bios__Address__c records
        rC_Bios__Address__c address = TestUtils.createAddress('Test', false);
        address.rC_Bios__Street_Line_1__c = 'TestStreet1';
        address.rC_Bios__Street_Line_2__c = 'TestStreet2';
        address.rC_Bios__Country__c = 'India';
        insert address;
        
        acc = TestUtils.createAccount('TestAccount',false);
        acc.External_ID__c = '1234';
        acc.rC_Bios__Preferred_Billing_Address__c = address.Id;
        insert acc;
        
        Campaign cmp = TestUtils.createCampaign('TestCampaign',false);
        insert cmp;
        
        String BATCH_LOG_RT_MANUAL_Id = Schema.SObjectType.Batch_Log__c.getRecordTypeInfosByName().get('Manual').getRecordTypeId();
        manualBatchLog = TestUtils.createBatchLog('TestBatchName1', false);
        //adding date to avoid onbeforeinsert trigger exception
        manualBatchLog.Batch_Date__c = Date.today();
        manualBatchLog.Deposit_Site__c = 'AK_Alaska';
        manualBatchLog.Batch_Type__c='Standard';
        manualBatchLog.RecordTypeId = BATCH_LOG_RT_MANUAL_Id;
        manualBatchLog.Expected_Count__c=2;
        manualBatchLog.Expected_Amount__c = 100;
        manualBatchLog.Bank_Date__c = date.today();
        manualBatchLog.Tax_Date__c = date.today();
        insert manualBatchLog;
        
        Map<String,Schema.RecordTypeInfo> opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        String OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
        //String OPPORTUNITY_RT_PROPOSAL_Id = opptyRTMap.get('Proposal').getRecordTypeId();
        String OPPORTUNITY_RT_PLEDGEPAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
        String OPPORTUNITY_RT_DONATION_Id = opptyRTMap.get('Donation').getRecordTypeId();
        String OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
        OPPORTUNITY_RT_SOFTCREDIT_Id = opptyRTMap.get('Soft Credit').getRecordTypeId();
        List<Opportunity> parentOpp = new List<Opportunity>();
        //create parent donation
        donationOpp = TestUtils.CreateOpportunity(acc.Id, 'TestDonation'+acc.Name, false);
        donationOpp.Batch_Log__c=manualBatchLog.id;        
        donationOpp.IsCreatedFromBatchLog__c = true;
        donationOpp.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
        donationOpp.CampaignId = cmp.id;
        donationOpp.closeDate = system.today()+10;
        donationOpp.Batch_Sequence__c = '1';
        donationOpp.rC_Giving__Giving_Amount__c = 100;
        
        //create Pledge Record
        Opportunity pledgeOpp= TestUtils.CreateOpportunity(acc.Id, 'TestPledge'+acc.Name, false);
        pledgeOpp.Adjustment_Batch__c=manualBatchLog.id;
        pledgeOpp.IsCreatedFromBatchLog__c = true;
        pledgeOpp.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        pledgeOpp.CampaignId = cmp.id;
        pledgeOpp.rC_Giving__Is_Sustainer__c = false;
        //pledgeOpp.Ack_Recipient_Account__c = acc.id;
        //pledgeOpp.Batch_Sequence__c = '1';
        parentOpp.add(donationOpp);
        parentOpp.add(pledgeOpp);
        insert parentOpp;
        
        
        //create Transaction Record
        transactionOpp= TestUtils.CreateOpportunity(acc.Id, 'Test 3'+acc.Name, false);
        transactionOpp.Batch_Log__c=manualBatchLog.id;
        transactionOpp.IsCreatedFromBatchLog__c = true;
        transactionOpp.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        transactionOpp.rC_Giving__Parent__c = donationOpp.Id;
        transactionOpp.closeDate = system.today()+10;
        transactionOpp.Batch_Sequence__c = '1';
        
        //Pledge Payment
        pledgePaymentOpp= TestUtils.CreateOpportunity(acc.Id, 'TestPP'+acc.Name, false);
        pledgePaymentOpp.RecordTypeId = OPPORTUNITY_RT_PLEDGEPAYMENT_Id;
        pledgePaymentOpp.IsCreatedFromBatchLog__c = true;
        pledgePaymentOpp.rC_Giving__Parent__c = pledgeOpp.Id;
        pledgePaymentOpp.batch_Log__c=manualBatchLog.id;
        pledgePaymentOpp.Batch_Sequence__c = '1';
        pledgePaymentOpp.stagename='open';
        pledgePaymentOpp.Adjustment_Code__c = 'D';
        pledgePaymentOpp.amount=20;
        pledgePaymentOpp.CloseDate = system.today();
        insert new List<Opportunity>{transactionOpp,pledgePaymentOpp};
        
        //create child Soft Credit records
        list<Opportunity> softCredits = new list<Opportunity>();
        for(Integer i=0;i<4;i++) {
            Opportunity softCreditOpp= TestUtils.CreateOpportunity(acc.Id, 'TestSoftCredit'+ i +acc.Name, false);
            softCreditOpp.Batch_Log__c=manualBatchLog.id;
            softCreditOpp.IsCreatedFromBatchLog__c = true;
            softCreditOpp.RecordTypeId = OPPORTUNITY_RT_SOFTCREDIT_Id;
            softCreditOpp.CampaignId = cmp.id;
            softCreditOpp.Amount = 100;
            softCreditOpp.rC_Giving__Parent__c = donationOpp.id;
            softCreditOpp.closeDate = system.today()+10;
            softCreditOpp.Soft_Credit_Type__c = 'GF - Gift Membership';
            //softCreditOpp.Batch_Sequence__c = String.valueOf(i);
            softCredits.add(softCreditOpp);
        }
		insert softCredits;
		
		
    }
    static testMethod void testController() {
        User usr = TestUtils.createUser('usertest1', 'usertest1@aclu.org', null, true);
        system.runAs(usr){
            testSetup();
            Test.startTest();
            
            PageReference pageRef = Page.SoftCreditPage;  
            Test.setCurrentPage(pageRef);
            
            ApexPages.currentPage().getParameters().put('parentOppId',donationOpp.id);
            ApexPages.currentPage().getParameters().put('batchLogId',manualBatchLog.id);
            ApexPages.StandardController sm = new ApexPages.StandardController(manualBatchLog);
            SoftCreditPageController softCreditObj = new SoftCreditPageController(sm);
            system.assertEquals(softCreditObj.isAdjustBatch, false);
            system.assertEquals(softCreditObj.parentAmountfield, 100);
            system.assertEquals(softCreditObj.childOppWrapperLst.size(), 4);
            
            //Deleting child rows
            ApexPages.currentPage().getParameters().put('delSoftC_Index','1');
            softCreditObj.deleteSoftCRow();
            system.assertEquals(softCreditObj.childOppWrapperLst.size(), 3);
            
            //Adding Child Rows
            softCreditObj.addChildRows();
            softCreditObj.childOppWrapperLst.get(3).objOppty.AccountId = softCreditObj.childOppWrapperLst.get(0).objOppty.AccountId;
            softCreditObj.childOppWrapperLst.get(3).objOppty.Soft_Credit_Type__c = softCreditObj.childOppWrapperLst.get(0).objOppty.Soft_Credit_Type__c;
            softCreditObj.childOppWrapperLst.get(3).objOppty.Amount = 100;
            softCreditObj.childOppWrapperLst.get(3).objOppty.CloseDate = system.today()+10;
            softCreditObj.saveChildRows(softCreditObj.childOppWrapperLst);
            system.assertEquals(4, softCreditObj.childOppWrapperLst.size());
            //Record saved by method on page
            list<Opportunity> oppList = [SELECT id, RecordType.Name,CloseDate, RecordTypeId, Restriction__c, rC_Giving__Parent__r.Restriction__c,
                                            Adjustment_Code__c, rC_Giving__Parent__r.Adjustment_Code__c,
                                            IsCreatedFromBatchLog__c, rC_Giving__Payment_Method__c, Batch_Log__c,
                                            Batch_Log__r.Batch_Date__c, Batch_Log__r.Bank_Date__c, Batch_Log__r.Tax_Date__c,
                                            Batch_Date__c, Bank_Date__c, Tax_Date__c
                                            FROM Opportunity
                                            WHERE RecordTypeId = :OPPORTUNITY_RT_SOFTCREDIT_Id
                                            AND Id = :softCreditObj.childOppWrapperLst.get(3).objOppty.Id];
            system.assertEquals(1, oppList.size()); 
            system.assertEquals('Cash/Check', oppList.get(0).rC_Giving__Payment_Method__c);
            system.assertEquals(oppList.get(0).rC_Giving__Parent__r.Restriction__c, oppList.get(0).Restriction__c); 
            system.assertEquals(true, oppList.get(0).IsCreatedFromBatchLog__c); 
            system.assertEquals(manualBatchLog.id, oppList.get(0).Batch_Log__c);
            system.assertEquals(oppList.get(0).Batch_Date__c, oppList.get(0).Batch_Log__r.Batch_Date__c);
            system.assertEquals(oppList.get(0).Bank_Date__c, oppList.get(0).Batch_Log__r.Bank_Date__c);
            system.assertEquals(oppList.get(0).Tax_Date__c, oppList.get(0).Batch_Log__r.Tax_Date__c);
            //Method updateParent
            ApexPages.currentPage().getParameters().put('row','3');
            ApexPages.currentPage().getParameters().put('OpportId',String.valueOf(donationOpp.Id));
            ApexPages.currentPage().getParameters().put('isOpenfromSft','true');
            ApexPages.currentPage().getParameters().put( 'isPledgePayment', 'false');
            softCreditObj.updateParent();
            Opportunity donationRec = [SELECT Has_Soft_Credits__c FROM Opportunity WHERE Id = :donationOpp.Id];
            system.assertEquals(true, donationRec.Has_Soft_Credits__c);
            
            //To cover export soft credits
            softCreditObj.exportSoftCredits();
            
            //To verify populateAccountLookup method
            list<String> accStrList = SoftCreditPageController.populateAccountLookup('1','1234');
            system.assertEquals('True', accStrList[0]);
            system.assertEquals(String.valueOf(acc.Id), accStrList[1]);
            system.assertEquals(acc.Name, accStrList[2]);
            
            //To Verify getAcknowledgementCodePicklist method
            //correct values assigned to the picklist as per Affiliation
            List<SelectOption> selOptionList = softCreditObj.getAcknowledgementCodePicklist();
            system.assertEquals(true, selOptionList.size() > 0);
            system.assertEquals('None', selOptionList.get(0).getlabel());
            system.assertEquals(true, selOptionList.get(1).getlabel().contains('AK'));
            
            system.assertEquals(false, softCreditObj.childOppWrapperLst.get(3).hasSharingValues);
            
            Opportunity oppty = [SELECT Id, Ack_Recipient_Account__c FROM Opportunity WHERE Id =:softCreditObj.childOppWrapperLst.get(0).objOppty.Id];
            oppty.Ack_Recipient_Account__c = acc.Id;
            update oppty;
            softCreditObj.childOppWrapperLst.get(0).objOppty = oppty;
            softCreditObj.activeOpportunity = softCreditObj.childOppWrapperLst.get(0);
            Test.stopTest();
            softCreditObj.populateAckFields();
            system.assertEquals('TestAccount',softCreditObj.activeOpportunity.objOppty.Ack_Recipient_Full_Name__c);
            system.assertEquals('TestStreet1',softCreditObj.activeOpportunity.objOppty.Ack_Recipient_Street_Line_1__c);
            system.assertEquals('India',softCreditObj.activeOpportunity.objOppty.Ack_Recipient_Country__c);
            
            softCreditObj.deleteIHOValues();
            system.assertEquals(false, softCreditObj.childOppWrapperLst.get(0).hasImoValues);
            ApexPages.currentPage().getParameters().put('selAccId',String.valueOf(acc.Id));
            ApexPages.currentPage().getParameters().put('selRow','3');
            softCreditObj.populatePledgeBoolean();
            
            ApexPages.currentPage().getParameters().put('activeOpptyIndex','2');
            softCreditObj.changeActiveOppt();
            system.assertEquals(softCreditObj.childOppWrapperLst.get(2), softCreditObj.activeOpportunity);
            
            softCreditObj.cancelRowChange();
            
            //try adding invalid opportunities
            //Adding Child Rows
            softCreditObj.addChildRows();
            Opportunity oppt = softCreditObj.childOppWrapperLst.get(4).objOppty;
            oppt.Honoree_Title__c = 'Title';
            oppt.Honoree_First_Name__c = 'First';
            oppt.Honoree_Middle_Name__c = 'Middle';
            oppt.Honoree_Last_Name__c = 'Last';
            oppt.Honoree_Suffix__c = 'Mr';
            oppt.Non_Person__c = 'Test';
            oppt.Recipient_Acknowledgment_Code__c = 'D';
            oppt.Recipient_Acknowledgement_Status__c = 'Test';
            oppt.Tribute_Message_Body__c = 'Test Message';
            oppt.Ack_Recipient_Full_Name__c = 'Test';
            softCreditObj.activeOpportunity = softCreditObj.childOppWrapperLst.get(4);
            softCreditObj.saveOneRow();
            //verify that above Soft credit is not inserted
            list<Opportunity> oppList1 = [SELECT Id FROM Opportunity
                                            WHERE RecordTypeId = :OPPORTUNITY_RT_SOFTCREDIT_Id];
            system.assertEquals(4, oppList1.size());
            
        }
        
    }
}