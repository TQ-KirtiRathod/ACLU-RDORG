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
 *  Ticket#  Modified Date       Modified By	   Description
 *  #77940    24-June-2020        SFDO             Changed the assert and assigned the stageName = Completed 
 */
 
 /*
*
*Name  :  OpportunityTriggerHandlerTest
*Author:  Appirio India (Sai Krishna )
*Date  :  November 24, 2016
*Purpose : Reset the shareing for the NGOC objects related to the opportunities Accounts
*Last Modified: Sandeep Soni
*
*/
@isTest
private class OpportunityTriggerHandlerTest { 
    
    private static String OPPORTUNITY_RT_SOFT_CREDIT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
    private static String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    private static String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    private static String OPPORTUNITY_RT_PROPOSAL_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
    private static String OPPORTUNITY_RT_DONATION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
    private static String OPPORTUNITY_RT_PLEDGE_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
    
    //Insert Scenarios
    private static testMethod void insertScenarios(){
        // Create Test Data
        Test.StartTest();
        OpportunityTriggerHandlerTestDataGen.createTestData();
        Test.stopTest();
        
        //Fetch Campaign to update
        Campaign parentcampaign = [SELECT Id, account_Code__c FROM Campaign WHERE rC_Giving__Sub_Affiliation__c = '5' LIMIT 1];
        
        //Fetch Opportunities
        Opportunity closedDonation = [SELECT Account_Affiliation__c, account_code__c, Acknowledgment_Code__c, Acknowledgment_Status__c, Prior_Amount__c, 
                                             Bypass_Calculations__c, Exclude_from_Revenue_Sharing__c, Original_Amount__c, rC_Giving__Acknowledged_Date__c,
                                             rC_Giving__Payment_Method_Selected__c, Stage_Last_Changed_Date__c, Use_Campaign_Cost__c, Restriction__c,
                                             Campaign_Type__c, Program_Type__c, Prior_Source_Code__c, rC_Giving__Source_Code__c, Cost_Factor__c,
                                             Exclude_Cost_Factors_in_RevShare__c, Deposit_Site__c, Fund__c, Fundraising_Department__c, RPT_Revenue_Type__c
                           
                                         FROM Opportunity WHERE Name = 'closedDonation' LIMIT 1];
                                         
        Opportunity openDonation = [SELECT Acknowledgment_Status__c, rC_Giving__Acknowledged_Date__c FROM Opportunity WHERE Name = 'openDonation' LIMIT 1];
        
        Opportunity transactioDonation = [SELECT account_code__c, Acknowledgment_Code__c, Prior_Amount__c, Exclude_from_Revenue_Sharing__c,
                                            Batch_Date__c, Bank_Date__c, Sharing_Code__c, Sharing_Code_Description__c, Sharing_Entity__c, 
                                            Sharing_Entity_Affiliation__c, Deposit_Site__c
                                            FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'closedDonation' LIMIT 1];
                                            
        Opportunity softcredit = [SELECT account.Name, Name, closeDate, account_code__c, Acknowledgment_Code__c, amount, Prior_Amount__c, Bypass_Calculations__c, Exclude_from_Revenue_Sharing__c,
                                            Original_Amount__c,recordTypeId, Restriction__c, Campaign_Type__c, Program_Type__c, StageName
                                            FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'closedDonation' AND IsCreatedFromBatchLog__c = TRUE LIMIT 1];
                                            
        Opportunity pledgeSustainer = [SELECT campaignId, Review_Status__c, Prior_Amount__c, Original_Amount__c, Sustainer_First_Payment__c, rC_Giving__Giving_Amount__c
                                             FROM Opportunity WHERE Name = 'sustainerPledge' LIMIT 1];
                                             
        Opportunity pledgeClosed = [SELECT Prior_Amount__c, Original_Amount__c, Sustainer_First_Payment__c, Exclude_from_Revenue_Sharing__c,
                                            Use_Campaign_Cost__c, Closed_Amount_Payments__c
                                             FROM Opportunity WHERE Name = 'closedPledge' LIMIT 1];    
                                             
        Opportunity sustainerPP = [SELECT name, Sustainer_First_Payment__c, rC_Giving__Giving_Amount__c FROM Opportunity WHERE Name = 'sustainerPledgePayment2' LIMIT 1];
        
        Opportunity sustainerPP3 = [SELECT Sustainer_First_Payment__c, rC_Giving__Giving_Amount__c FROM Opportunity WHERE Name = 'sustainerPledgePayment3' LIMIT 1];
        
        Opportunity proposalRec = [SELECT Probability__c, rC_Giving__Projected_Amount__c  FROM Opportunity WHERE Name = 'proposalRec' LIMIT 1];    
        
        Opportunity pledgePaymentClosed = [SELECT Id, Closed_Amount_Payments__c, Sharing_Code__c,Sharing_Entity__c,Sharing_Entity_Affiliation__c FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'closedPledge'];
        
        Account acc = [SELECT Joint_Membership_Flag__c, Original_Join_Date__c, Membership_Expiration_date__c, Last_Membership_Gift__c, Has_Renewed_Before__c,
                        rC_Giving__Lifetime_Is_Sustaining_Giver__c, Last_Membership_Gift__r.name
                        FROM Account WHERE Name = 'testAcc']; 
        Opportunity softCreditOpenDonation = [SELECT Id FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'openDonation' AND IsCreatedFromBatchLog__c = TRUE LIMIT 1];                        
        
        //paymentMethod
        rC_Giving__Payment_Method__c paymentMethod = [SELECT Id FROM rC_Giving__Payment_Method__c LIMIT 1];                       
        
        //AccountAffiliation field
        system.assertEquals('NN',closedDonation.Account_Affiliation__c);
        
        //AccountCode field
        system.assertEquals('DPF - Drug Policy Fund',closedDonation.account_code__c); //Donation record
        system.assertEquals('DPF - Drug Policy Fund',transactioDonation.account_code__c); //Transaction record
        system.assertEquals('DPF - Drug Policy Fund',softcredit.account_code__c); // soft credit record
        
        //AcknowledgementCode field
        system.assertEquals('AK Donor Ack',closedDonation.Acknowledgment_Code__c); //Donation record
        system.assertEquals('AK Donor Ack',transactioDonation.Acknowledgment_Code__c); //Transaction record
        system.assertEquals('AK Donor Ack',softcredit.Acknowledgment_Code__c); //SoftCredit record
        
        //Acknowledgement Status 'A - Acknowledged'
        system.assertEquals('A - Acknowledged', openDonation.Acknowledgment_Status__c ); //Open Donation record
        
        // rC_Giving__Acknowledged_Date__c
        system.assertEquals(date.today(), openDonation.rC_Giving__Acknowledged_Date__c); // Donation record
        
        //Prior Amount
        system.assertEquals(52,closedDonation.Prior_Amount__c  ); //Donation record
        system.assertEquals(20,softcredit.Prior_Amount__c  ); //softCredit record**
        system.assertEquals(1900,pledgeSustainer.Prior_Amount__c  ); //sustainerPledge record
        
        //rC_Giving__Giving_Amount__c 
        system.assertEquals(1900, pledgeSustainer.rC_Giving__Giving_Amount__c);
        
        //Amount
        system.assertEquals(20,softcredit.amount);
        
        //Bypass_Calculations__c TRUE
        system.assertEquals(TRUE,closedDonation.Bypass_Calculations__c  ); //Transaction record
        system.assertEquals(TRUE,softcredit.Bypass_Calculations__c  ); //softCredit record
        
        //ExcludeFromRevenueSharing
        system.assertEquals(TRUE, pledgeClosed.Exclude_from_Revenue_Sharing__c  ); //Donation record
        system.assertEquals(TRUE, transactioDonation.Exclude_from_Revenue_Sharing__c  ); //softCredit record
        
        //Original Amount
        system.assertEquals(52,closedDonation.Original_Amount__c  ); //Donation record
        system.assertEquals(20,softcredit.Original_Amount__c  ); //softCredit record
        system.assertEquals(1900,pledgeSustainer.Original_Amount__c  ); //sustainerPledge record
        
        //Probablity
        system.assertEquals(100, proposalRec.Probability__c); 
        system.assertEquals(50000000, proposalRec.rC_Giving__Projected_Amount__c);
        
        //softCredit RecordType
        system.assertEquals(OPPORTUNITY_RT_SOFT_CREDIT_Id, softcredit.recordTypeId);
        
        //Sharing Code
        system.assertEquals('SOFTCREDIT', transactioDonation.Sharing_Code__c); //TransRec record
        system.assertEquals(null, transactioDonation.Sharing_Entity__c); //TransRec
        system.assertEquals(null, transactioDonation.Sharing_Entity_Affiliation__c); //TransRec
        
        //Name
        String scName= 'testAcc: Soft Credit '+String.valueOf(date.today().year());
        system.assertEquals(scName, softcredit.Name); //softCredit record
        
        //rC_Giving__Payment_Method_Selected__c 
        system.assertEquals(paymentMethod.Id, closedDonation.rC_Giving__Payment_Method_Selected__c); //Donation record
        
        //Stage_Last_Changed_Date__c
        system.assertEquals(Date.today(), closedDonation.Stage_Last_Changed_Date__c); //Donation record
        
        //Use_Campaign_Cost__c
        system.assertEquals(false, closedDonation.Use_Campaign_Cost__c); //Donation record
        
        //Restriction__c
        system.assertEquals('BRT - Bill of Rights Trust', closedDonation.Restriction__c); //Donation record
        system.assertEquals('BRT - Bill of Rights Trust', softcredit.Restriction__c); //softCredit record
        
        //Campaign_Type__c, Program_Type__c
        system.assertEquals('B', closedDonation.Campaign_Type__c); //Donation record
        system.assertEquals('5', closedDonation.Program_Type__c); //Donation record
        system.assertEquals('5', softcredit.Program_Type__c); //softCredit record
        system.assertEquals('B', softcredit.Campaign_Type__c); //softCredit record
        
        //campaignId for SustainerPledge
        system.assertEquals(parentcampaign.Id, pledgeSustainer.campaignId); //Sustainer pledge record
        
        //Prior_Source_Code__c
        system.assertEquals(closedDonation.rC_Giving__Source_Code__c, closedDonation.Prior_Source_Code__c); //Donation record
        
        //Fund__c, Fundraising_Department__c
        system.assertEquals('BLDG - Building Fund', closedDonation.Fund__c); //Donation record
        system.assertEquals('Membership', closedDonation.Fundraising_Department__c); //Donation record
        
        //StageName
        system.assertEquals('Completed', softcredit.stageName);//softcredit record
        
        //Account Fields
        system.assertEquals(TRUE, acc.Has_Renewed_Before__c); 
        system.assertEquals(TRUE, acc.rC_Giving__Lifetime_Is_Sustaining_Giver__c);
        system.assertEquals(Date.newInstance(4000,12,31), acc.Membership_Expiration_date__c);
        
        //RPT_Revenue_Type__c
        system.assertEquals(null, closedDonation.RPT_Revenue_Type__c);
        
        //Review Status
        system.assertEquals('Pending Submission', pledgeSustainer.Review_Status__c);

    }
    
    
    //Update Scenarios
    private static testMethod void updateScenarios(){
        // Create Test Data
       
        OpportunityTriggerHandlerTestDataGen.createTestData();
        
        User u = TestUtils.createUser('last name', 'abcxuzq@aclu.org', null, false);
        u.Is_Affiliate_User__c = false;
       // u.TimeZoneSidKey    = 'GMT'; // DS - setting timezone to GMT causes date tests to fail during last hours of day in U.S. timezones
        u.TimeZoneSidKey    = 'GMT'; // DS - setting timezone to GMT needed otherwise
        insert u;
        System.runAs(u){
            Account tempAcc = [SELECT Name FROM Account WHERE Name= 'tempAcc'];
            List<Opportunity> oppsToBeUpdated = new List<Opportunity>();
            List<Opportunity> oppsTomadeNull = new List<Opportunity>();
            
            //Fetch Campaign to update
            Campaign tempcampaign = [SELECT Id, account_Code__c FROM Campaign WHERE rC_Giving__Sub_Affiliation__c = '1' LIMIT 1];
            
            //Proposal record
            Opportunity proposalRec = [SELECT Probability__c, rC_Giving__Projected_Amount__c  FROM Opportunity WHERE Name = 'proposalRec'];  
            proposalRec.rC_Giving__Projected_Amount__c = 500;
            oppsToBeUpdated.add(proposalRec);
            
            //making the update operations before changing to meet criterias.
            //Closed Pledge Payment record
            Opportunity ppCloseToOpen = [SELECT Id,accountId, rC_Giving__Parent__c FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'closedPledge' LIMIT 1]; 
            ppCloseToOpen.stageName = 'Open';
            ppCloseToOpen.CampaignId = null;
            update ppCloseToOpen;
            //paymentMethod
            rC_Giving__Payment_Method__c paymentMethod = [SELECT Id,rC_Giving__Account__c FROM rC_Giving__Payment_Method__c WHERE rC_Giving__Account__r.Name = 'tempAcc' LIMIT 1];
            
            //update Opportunity for AccountAffiliation,AccountCode
            Opportunity closedDonation = [SELECT Id,accountId FROM Opportunity WHERE Name = 'closedDonation' LIMIT 1];
            closedDonation.accountId = tempAcc.Id; // account affiliation
            closedDonation.campaignId = tempcampaign.Id; // account code
            closedDonation.Account_Code__c = ''; // account code
            closedDonation.Acknowledgment_Code__c = null; // acknowledgement code
            closedDonation.Acknowledgment_Status__c = 'Y - Do Not Acknowledge'; // acknowledgement code
            closedDonation.rC_Giving__Acknowledged_Date__c = null;// acknowledgement code
            closedDonation.Update_Payment_Method__c= paymentMethod.Id;
            closedDonation.Trigger_Attachment_Review_Process__c= TRUE;
            
            oppsToBeUpdated.add(closedDonation);
            Test.StartTest();
            Opportunity openDonation = [SELECT Id,accountId FROM Opportunity WHERE Name = 'openDonation' LIMIT 1];
            openDonation.Sharing_Code__c = 'P001';
            openDonation.Sharing_Entity_Override__c = TRUE;
            openDonation.Sharing_code_Override__c = TRUE;
            openDonation.Sharing_Entity__c = 'test';
            openDonation.Fundraising_Department__c =null;
            openDonation.campaignId =  tempcampaign.Id;
            openDonation.isSoft_Credit__c = true;
            openDonation.Prior_Amount__c = 20;
            openDonation.IsCreatedFromBatchLog__c = TRUE;
            oppsToBeUpdated.add(openDonation);
            
            //Closed Pledge Payment record
            Opportunity closedPP = [SELECT Id,accountId, rC_Giving__Parent__c FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'closedPledge' LIMIT 1]; 
            closedPP.Account_Code__c = '';
            closedPP.CampaignIdText__c = tempcampaign.id;
            closedPP.closeDate = date.today();
            closedPP.Exclude_from_Revenue_Sharing__c = false;
            closedPP.stageName = 'Completed';
            closedPP.amount = 50;
            oppsToBeUpdated.add(closedPP);
            
            //Soft Credit closed Donation
            Opportunity screditClosedDonation = [SELECT Id,accountId FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'closedDonation' AND IsCreatedFromBatchLog__c = TRUE LIMIT 1];
            screditClosedDonation.Related_Transaction__c = closedPP.Id; // account code
            screditClosedDonation.isSoft_Credit__c = false; //making isSoftCredit as false;
            screditClosedDonation.Account_Code__c = '';
            oppsToBeUpdated.add(screditClosedDonation);
            
            //SoftCredit Open
            Opportunity screditOpenDonation = [SELECT Id,accountId FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'openDonation' AND IsCreatedFromBatchLog__c = TRUE LIMIT 1];
            screditOpenDonation.Related_Transaction__c = closedPP.Id; // account code
            screditOpenDonation.isSoft_Credit__c = true;
            //making isSoftCredit as false;
            oppsToBeUpdated.add(screditOpenDonation);
            //Batch Log record
            batch_Log__c bLrec = [SELECT Id FROM Batch_Log__c LIMIT 1];
            
            //closed Pledge record
            Opportunity oppPledge = new Opportunity(Id=closedPP.rC_Giving__Parent__c, rC_Giving__Payment_Method__c = 'Securities', rC_Giving__Giving_Amount__c = 50, Bypass_Calculations__c = true,
                                                    Original_Expected_Giving_Amount__c = null, rC_Giving__Expected_Giving_Amount__c = 25, rC_Giving__Parent__c = null,
                                                    Revenue_Fiscal_Year__c = '2016', batch_Log__c = bLrec.Id, Exclude_Cost_Factors_in_RevShare__c = TRUE);
            update oppPledge; //Added separate update to avoid Self_Reference_From_Trigger_Error
            
            //Sustainer Pledge
            Opportunity sustainerPledge = [SELECT Id FROM Opportunity WHERE Name = 'sustainerPledge' LIMIT 1];
            sustainerPledge.Upgrade_Amount__c = 2000;
            sustainerPledge.Restriction__c = null;
            sustainerPledge.Upgrade_Source__c = tempcampaign.Id;
            sustainerPledge.rC_Giving__Is_Canceled__c = TRUE;
            oppsToBeUpdated.add(sustainerPledge);
            
            //sustainer PledgePayment2
            Opportunity sustainerPP2 = [SELECT Id FROM Opportunity WHERE Name = 'sustainerPledgePayment2' LIMIT 1];
            sustainerPP2.Adjustment_Code__c = 'B';
            oppsToBeUpdated.add(sustainerPP2);
            
            //update Transactions
            Opportunity closedTransaction = [SELECT Id, Acknowledgment_Code__c FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'closedDonation' LIMIT 1];
            closedTransaction.Acknowledgment_Code__c = null; // acknowledgement code
            closedTransaction.CampaignIdText__c = tempcampaign.Id;
            closedTransaction.Acknowledgment_Status__c = 'Y - Do Not Acknowledge';// acknowledgement code
            closedTransaction.rC_Giving__Acknowledged_Date__c = null;// acknowledgement code
            
            oppsToBeUpdated.add(closedTransaction);
            update oppsToBeUpdated;

            //Fetch Records
            Opportunity proposalOppty = [SELECT Probability__c, rC_Giving__Projected_Amount__c  FROM Opportunity WHERE Name = 'proposalRec' LIMIT 1];
            Opportunity parentDonation = [SELECT Account_Affiliation__c,account_code__c, Acknowledgment_Code__c, campaign.Name, rC_Giving__Payment_Method_Selected__c,
                                             Restriction__c, Campaign_Type__c, Program_Type__c, rC_Giving__Source_Code__c, Prior_Source_Code__c,
                                             Cost_Factor__c, Exclude_Cost_Factors_in_RevShare__c, Review_Status__c, Fundraising_Department__c, Fund__c
                                             FROM Opportunity WHERE Name = 'closedDonation' LIMIT 1];
                                             
            Opportunity softcreditRecordDonation = [SELECT Name, Program_Type__c, Campaign_Type__c, CampaignIdText__c, account_code__c, Prior_Amount__c FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'closedDonation' AND IsCreatedFromBatchLog__c = TRUE LIMIT 1];
            
            Opportunity transRecord = [SELECT Acknowledgment_Code__c, Tax_Date__c  FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'closedDonation' LIMIT 1];
            Opportunity transactioOpenDonation = [SELECT Sharing_Entity__c, Sharing_Entity_Override__c, Sharing_Code__c, Sharing_code_Override__c  
                                                    FROM Opportunity WHERE Name = 'openDonation' LIMIT 1];
            
            Opportunity pledgeRec = [SELECT Acknowledgment_Status__c, rC_Giving__Rollup_Giving__c, Prior_Amount__c, rC_Giving__Acknowledged_Date__c,
                                            Revenue_Fiscal_Year__c, Original_Expected_Giving_Amount__c, Bypass_Calculations__c, Batch_Log_Update_Date__c,
                                            rC_Giving__Payment_Method_Selected__c,Recalculate_Revenue_Share__c
                                       FROM Opportunity WHERE Name = 'closedPledge' LIMIT 1];
            
            Opportunity sustainerPl = [SELECT StageName, Prior_Amount__c, CampaignId, Restriction__c, Membership_Reevaluation_Needed__c FROM Opportunity WHERE Name = 'sustainerPledge' LIMIT 1];
            
            Opportunity sustainerPP = [SELECT campaignId, Sustainer_First_Payment__c, Membership_Reevaluation_Needed__c FROM Opportunity WHERE Name = 'sustainerPledgePayment2' LIMIT 1];     
            
            Opportunity pledgePaymentrec = [SELECT Id, batch_date__c, bank_Date__c, Tax_Date__c, Sharing_Code__c, Sharing_Code_Description__c, 
                                                Sharing_Entity__c, Sharing_Entity_Affiliation__c, Use_Campaign_Cost__c
                                                FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'closedPledge'];
             
            Opportunity softCreditOpen = [SELECT Amount, StageName, Prior_Amount__c, recordTypeId FROM Opportunity WHERE Name = 'openDonation' AND IsCreatedFromBatchLog__c = TRUE LIMIT 1];
            //system.assertEquals(null, closedPP);
            Test.stopTest();
            //AccountAffiliation
            system.assertEquals('ZF',parentDonation.Account_Affiliation__c);
            
            //AccountCode field
            system.assertEquals('NAA - cash debit', parentDonation.account_code__c); //Donation record
            //system.assertEquals('NAA - cash debit', softcreditRecordDonation.account_code__c); //softCredit record
            
            //AcknowledgementCode field
            system.assertEquals('AK New Donor Ack', parentDonation.Acknowledgment_Code__c); //Donation record
            system.assertEquals('AK New Donor Ack', transRecord.Acknowledgment_Code__c); //Transaction record
                    
            //Acknowledgement Status 'A - Acknowledged'
            system.assertEquals('A - Acknowledged', pledgeRec.Acknowledgment_Status__c ); //Pledge record
            
            // rC_Giving__Acknowledged_Date__c
            system.assertEquals(date.today()+1, pledgeRec.rC_Giving__Acknowledged_Date__c); // Pledge record        
            
            //Bypass_Calculations__c TRUE
            system.assertEquals(TRUE, pledgeRec.Bypass_Calculations__c  ); //Pledge record
            
            //Membership_Reevaluation_Needed__c TRUE
            system.assertEquals(TRUE, sustainerPP.Membership_Reevaluation_Needed__c); //SusatinerPP record
            
            //Original_Expected_Giving_Amount__c
            system.assertEquals(25, pledgeRec.Original_Expected_Giving_Amount__c); //Pledge record
            
            //rC_Giving__Rollup_Giving__c 
            system.assertNotEquals(null, pledgeRec.rC_Giving__Rollup_Giving__c); //Pledge record
            
            //Revenue_Fiscal_Year__c 
            system.assertEquals('2016',pledgeRec.Revenue_Fiscal_Year__c); //Pledge record
            
            //Probability
            system.assertEquals(100, proposalOppty.Probability__c); //proposalreecord
            system.assertEquals(500, proposalRec.rC_Giving__Projected_Amount__c); //proposalreecord
            
            //Batch_Log_Update_Date__c 
            system.assertEquals(Date.today(),pledgeRec.Batch_Log_Update_Date__c);//pledgeRec
            
            //Amount 
            system.assertEquals(20,softCreditOpen.Amount); //softCredit record
            
            //softCredit RecordType
            system.assertEquals(OPPORTUNITY_RT_SOFT_CREDIT_Id, softCreditOpen.recordTypeId); //softCredit record
            
            //TaxDate
            //system.assertEquals(date.today(), pledgePaymentrec.Tax_Date__c );  //pledgePayment record
            
            //Name
            String scName= 'testAcc: Soft Credit '+String.valueOf(date.today().year());
            system.assertEquals(scName, softcreditRecordDonation.Name); //softCredit record
            
            //rC_Giving__Payment_Method_Selected__c 
            system.assertEquals(paymentMethod.Id, parentDonation.rC_Giving__Payment_Method_Selected__c); //Donation record
            
            //Use_Campaign_Cost__c false as this is closed
            system.assertEquals(true, pledgePaymentrec.Use_Campaign_Cost__c); //pledgePayment record
            
            //Review_Status__c
            system.assertEquals('Pending Submission', parentDonation.Review_Status__c); //Donation record
            
            //Restriction__c
            system.assertEquals('INTERNSHIP - Internship', parentDonation.Restriction__c); //Donation record 
            
            //CampaignIdText__c
            system.assertEquals(tempcampaign.Id, softcreditRecordDonation.CampaignIdText__c); //Donation record
            
            //campaignId for SustainerPledge
            system.assertEquals(tempcampaign.Id, sustainerPl.campaignId); //Sustainer pledge record
            
            //Prior_Source_Code__c
            system.assertEquals(parentDonation.rC_Giving__Source_Code__c, parentDonation.Prior_Source_Code__c); //Donation record
            
            //Actual_Cost_Factor__c
            system.assertEquals(null, parentDonation.Cost_Factor__c); //Donation record
            
            //Recalculate_Revenue_Share__c 
            system.assertEquals(TRUE, pledgeRec.Recalculate_Revenue_Share__c ); //Pledge record
            
            //Sharing_Entity_Override__c, Sharing_code_Override__c
            system.assertEquals(true, transactioOpenDonation.Sharing_Entity_Override__c);
            system.assertEquals('test', transactioOpenDonation.Sharing_Entity__c);
            system.assertEquals(TRUE, transactioOpenDonation.Sharing_code_Override__c);
            system.assertEquals('P001', transactioOpenDonation.Sharing_Code__c);
            
            //Fund__c, Fundraising_Department__c
            system.assertEquals('CHST - Church-State', parentDonation.Fund__c); //Donation record
            system.assertEquals('Membership', parentDonation.Fundraising_Department__c); //Donation record
            
            //StageName
            //system.assertEquals('Canceled', sustainerPl.StageName);
        }
        
    }
    
    private static testMethod void deleteOperations(){
        // Create Test Data
        Test.StartTest();
            Account acc = TestUtils.createAccount('testAcc', false);
            acc.BillingPostalCode = '82011';
            acc.BillingCountry = 'USA';
            insert acc;
            
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
            insert camp;
            
            rC_Giving__Payment_Method__c paymentMethodacc = TestUtils.createPaymentMethod(acc.Id,false);
            paymentMethodacc.Name = 'TestPaymentMethod1';
            paymentMethodacc.rC_Connect__Payment_Processor__c = 'Heartland';
            insert paymentMethodacc;
            //Create batchLog
            Batch_Log__c batchLogRec = TestUtils.createBatchLog('Test Batch Log',false);
            batchLogRec.Batch_Log_Type__c = 'Manual';
            batchLogRec.Bank_Date__c = Date.today()-1;
            batchLogRec.Batch_Date__c = Date.today()+1;
            insert batchLogRec;
            
            //Planned Giving record
            rC_Giving__Planned_Giving__c plannedGivingRec = TestUtils.createPlannedGiving(acc.id,null,true);
            //Create Closed Donation record
            Opportunity closedDonation = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
            closedDonation.RecordTypeId = OPPORTUNITY_RT_DONATION_Id;
            closedDonation.rC_Giving__Giving_Amount__c  = 52;
            closedDonation.rC_Giving__Requested_Amount__c = 90;
            closedDonation.stageName = 'Completed';
            closedDonation.campaignId = camp.Id;
            closedDonation.Bypass_Calculations__c = true;
            closedDonation.Sharing_Code__c = 'P001';
            closedDonation.closeDate = date.Today();
            closedDonation.batch_Log__c = batchLogRec.Id;
            closedDonation.Bank_Date__c = Date.today()-1;
            closedDonation.Batch_Date__c = Date.today()+1;
            closedDonation.Tax_Date__c  = Date.today() ;
            closedDonation.Update_Payment_Method__c = paymentMethodacc.Id;
            closedDonation.rC_Giving__Payment_Method__c = 'Charge Card';
            closedDonation.rC_Giving__Planned_Giving__c = plannedGivingRec.Id;
            closedDonation.rC_Giving__Expected_Giving_Amount__c = 20;
            insert closedDonation;
        //OpportunityTriggerHandlerTestDataGen.createTestData();
            //Transaction
            List<Opportunity> pPOppsToBeCreated = new LIst<Opportunity>();
            Opportunity closedDonationTrans = TestUtils.createOpportunity(acc.id, 'closedDonationTrans', false);
            closedDonationTrans.RecordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            closedDonationTrans.rC_Giving__Parent__c = closedDonation.Id;
            closedDonationTrans.batch_Log__c = batchLogRec.Id;
            pPOppsToBeCreated.add(closedDonationTrans);
            Opportunity screditClosedDonation = TestUtils.createOpportunity(acc.id, 'screditClosedDonation', false);
            screditClosedDonation.RecordTypeId = OPPORTUNITY_RT_SOFT_CREDIT_Id;
            screditClosedDonation.Related_Transaction__c = closedDonationTrans.Id;
            screditClosedDonation.rC_Giving__Parent__c = closedDonation.Id; 
            screditClosedDonation.isSoft_Credit__c = true;
            screditClosedDonation.IsCreatedFromBatchLog__c = True;
            screditClosedDonation.amount = 150;
            pPOppsToBeCreated.add(screditClosedDonation);
            insert pPOppsToBeCreated;
        Test.stopTest();
                
        Delete [SELECT Id FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'closedDonation' AND IsCreatedFromBatchLog__c = TRUE LIMIT 1];
        
        system.assertEquals(null, [SELECT Id, amount FROM Opportunity WHERE rC_Giving__Parent__r.Name = 'closedDonation' LIMIT 1].amount);
    }  
    
    private static testMethod void testOperationSourceCode() {
        // Create Test Data
            Test.StartTest();
            Account acc = TestUtils.createAccount('testAcc', false);
            acc.BillingPostalCode = '82011';
            acc.BillingCountry = 'USA';
            insert acc;
            List<Share_Source_Revenue_Codes__c> shareCodes = new List<Share_Source_Revenue_Codes__c>();
            shareCodes.add(new Share_Source_Revenue_Codes__c(Share_Code__c = 'P001', Name = '35', Share_Code_Description__c = 'Test')); 
            shareCodes.add(new Share_Source_Revenue_Codes__c(Name = '23', Share_Code__c = 'P003', Share_Code_Description__c = 'Test'));
            insert shareCodes; 
            List<Campaign> listOfCampaigns = new List<Campaign>();
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
            
            Opportunity sustainerPledge = TestUtils.createOpportunity(acc.id, 'sustainerPledge', false);
            sustainerPledge.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
            sustainerPledge.rC_Giving__Is_Sustainer__c = true;
            sustainerPledge.closeDate = system.today();
            sustainerPledge.Upgrade_Amount__c = 1900;
            sustainerPledge.stageName = 'Open';
            sustainerPledge.rC_Giving__Giving_Frequency__c = 'Annually';
            sustainerPledge.campaignId = listOfCampaigns[0].Id;
            sustainerPledge.Upgrade_Source__c = listOfCampaigns[0].Id;
            insert sustainerPledge;
            Opportunity sustainerPledgePayment3 = TestUtils.createOpportunity(acc.id, 'sustainerPledgePayment3', false);
            sustainerPledgePayment3.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
            sustainerPledgePayment3.rC_Giving__Parent__c = sustainerPledge.Id;
            insert sustainerPledgePayment3;
            //OpportunityTriggerHandlerTestDataGen.createTestData();
        
            Campaign cmp = [SELECT Id, Is_Sustainer_Operational_Campaign__c,Sustainer_Operational_Year__c,rC_Giving__Affiliation__c,rC_Giving__Source_Code__c, rC_Giving__Sub_Affiliation__c,
                                Account_Code__c,Acknowledgment_Code__c,Fund__c, Restriction__c
                                FROM Campaign
                                WHERE name like '%testCampaign1%'];
            cmp.Sustainer_Operational_Year__c = String.valueOf(system.today().year());
            //cmp.Sustainer_Operational_Month__c = String.valueOf(system.today().month());
            //RA - I-307191                   
            String str = '';                             
            Integer i = date.today().month();
            if(i >= 1 && i <= 9)
                str = '0' + String.valueOf(i);
            else
                str = String.valueOf(i);
            cmp.Sustainer_Operational_Month__c = str;
            
            cmp.Is_Sustainer_Operational_Campaign__c = true;
            update cmp;
        Test.stopTest();
        map<String, Campaign> mapYearToCampaign = new map<String, Campaign>();
        for (Campaign c : [SELECT Id, rC_Giving__Sub_Affiliation__c, rC_Giving__Affiliation__c,
                            rC_Giving__Source_Code__c, Sustainer_Operational_Year__c, Sustainer_Operational_Month__c, rC_Giving__Campaign_Type__c,
                            Fund__c, Account_Code__c, Restriction__c, Acknowledgment_Code__c
                            FROM Campaign 
                            WHERE Sustainer_Operational_Year__c = :cmp.Sustainer_Operational_Year__c
                            AND rC_Giving__Affiliation__c != null
                            AND rC_Giving__Sub_Affiliation__c != null
                            AND Is_Sustainer_Operational_Campaign__c = TRUE]) {
            //system.assertEquals(c, null);
            String month = c.Sustainer_Operational_Month__c != null && c.Sustainer_Operational_Month__c.subString(0,1) == '0' ? c.Sustainer_Operational_Month__c.subString(1,2) : c.Sustainer_Operational_Month__c;
            String key = month + '~' + c.Sustainer_Operational_Year__c + '~' + c.rC_Giving__Sub_Affiliation__c.subString(0,1) + '~' + c.rC_Giving__Affiliation__c;
            if(!mapYearToCampaign.containsKey(key)) {
                mapYearToCampaign.put(key, c);
            }
        }
        OpportunityManager.mapFiscalMonthYearToCampaign = mapYearToCampaign;
        Opportunity opp = [SELECT Id, StageName, rC_Giving__Parent__r.rC_Giving__Affiliation__c, CloseDate,
                            rC_Giving__Parent__r.Program_Type__c, Program_Type__c,Account_Code__c, 
                            Acknowledgment_Code__c,
                            Fund__c, Restriction__c
                            FROM Opportunity
                            WHERE Name = 'sustainerPledgePayment3'];
        opp.StageName = 'Completed';
        opp.Source_Code_Override__c = false;
      
        update opp;
        opp = [SELECT Id, Program_Type__c, Account_Code__c, Acknowledgment_Code__c,
                    Fund__c, Restriction__c
                    FROM Opportunity
                    WHERE Id = :opp.Id];
        //operation source values updated on opportunity from testcampaign3
        system.assertEquals(opp.Account_Code__c, cmp.Account_Code__c);
        system.assertEquals(opp.Acknowledgment_Code__c, cmp.Acknowledgment_Code__c);
        system.assertEquals(opp.Fund__c, cmp.Fund__c);
        system.assertEquals(opp.Restriction__c, cmp.Restriction__c);
        
    }
    

    //created by Bhavesh
    //Task: T-647270 
    private static testMethod void testNetAmountAndFeesFieldUpdate(){
        Account acc = TestUtils.createAccount('testAcc', TRUE);
        List<Opportunity> oppList = new List<Opportunity>();
        Campaign cmp = TestUtils.createCampaign('test camp',false);
        cmp.rC_Giving__Source_Code__c = '123';
        cmp.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        cmp.rC_Giving__Affiliation__c = 'CN - ACLU of Northern California';
        insert cmp;
        Map<String,Schema.RecordTypeInfo> opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        Id OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
        Id OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
        Id OPPORTUNITY_RT_DONATION_Id = opptyRTMap.get('Donation').getRecordTypeId();
        Opportunity opp1 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
        opp1.rC_Giving__Giving_Amount__c = 1000;
        opp1.rC_Giving__Giving_Amount__c = 1000;
        opp1.IsCreatedFromBatchLog__c = true;
        opp1.Fees__c = 800;
        opp1.CampaignId = cmp.id;
        opp1.Ack_Recipient_Account__c = acc.id;
        opp1.rC_Giving__Payment_Method__c = 'Charge Card';
        opp1.stagename='open';
        opp1.Adjustment_Code__c = 'D';
        opp1.Batch_Sequence__c = '1';
        opp1.Program_Type__c = '5';
        oppList.add(opp1);
        
        Opportunity opp2 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
        opp2.recordTypeId = OPPORTUNITY_RT_DONATION_Id;//Parent
        opp2.rC_Giving__Giving_Amount__c = 1000;
        opp2.IsCreatedFromBatchLog__c = true;
        opp2.Fees__c = 800;
        opp2.CampaignId = cmp.id;
        opp2.Ack_Recipient_Account__c = acc.id;
        opp2.rC_Giving__Payment_Method__c = 'Charge Card';
        opp2.stagename='open';
        opp2.Adjustment_Code__c = 'D';
        opp2.Batch_Sequence__c = '1';
        oppList.add(opp2);
        
        Opportunity opp3 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
        opp3.recordTypeId = OPPORTUNITY_RT_PLEDGE_Id;//Parent
        opp3.rC_Giving__Giving_Amount__c = 1000;
        opp3.Net_Amount__c = 800;
        opp3.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        opp3.CampaignId = cmp.id;
        opp3.Ack_Recipient_Account__c = acc.id;
        opp3.rC_Giving__Payment_Method__c = 'Paypal';
        opp3.stagename='open';
        opp3.Adjustment_Code__c = 'D';
        opp3.Batch_Sequence__c = '1';
        oppList.add(opp3);
        
        User u = TestUtils.createUser('last name', 'abcxuzq@aclu.org', null, false);
        u.Is_Affiliate_User__c = false;
        insert u;
        System.runAs(u){
            insert oppList;
            //Inserting child records
            oppList.clear();
            Opportunity opp4 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);//Transaction
            opp4.recordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            opp4.rC_Giving__Parent__c = opp2.id;
            opp4.rC_Giving__Giving_Amount__c = 1000;
            oppList.add(opp4);
            
            Opportunity opp5 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
            opp5.recordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
            opp5.rC_Giving__Parent__c = opp3.id;
            opp5.rC_Giving__Giving_Amount__c = 1000;
            oppList.add(opp5);
            
            Opportunity opp6 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
            opp6.recordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            opp6.rC_Giving__Parent__c = opp3.id;
            opp6.rC_Giving__Giving_Amount__c = 1000;
            oppList.add(opp6);
            
            insert oppList;
            
            
            oppList.clear();
            opp2.Fees__c = 800;
            opp2.Net_Amount__c = 800;
            oppList.add(opp2);
            
            opp3.Fees__c = 800;
            opp3.Net_Amount__c = 700;
            oppList.add(opp3);
            Test.startTest();
                update oppList;
            Test.stopTest();
            //update oppList;
            
            System.assertEquals(200, [Select id, Fees__c from Opportunity where id = : opp2.id ].Fees__c);
            System.assertEquals(800,[Select id, Net_Amount__c from Opportunity where id = : opp2.id ].Net_Amount__c);
            
            System.assertEquals(300, [Select id, Fees__c from Opportunity where id = : opp3.id ].Fees__c);
            System.assertEquals(700, [Select id, Net_Amount__c from Opportunity where id = : opp3.id ].Net_Amount__c);
            
            System.assertEquals(200, [Select id, Fees__c from Opportunity where id = : opp4.id ].Fees__c);
            System.assertEquals(800, [Select id, Net_Amount__c from Opportunity where id = : opp4.id ].Net_Amount__c);
            
            System.assertEquals(300, [Select id, Fees__c from Opportunity where id = : opp5.id ].Fees__c);
            System.assertEquals(700,[Select id, Net_Amount__c from Opportunity where id = : opp5.id ].Net_Amount__c);
            
            System.assertEquals(300, [Select id, Fees__c from Opportunity where id = : opp6.id ].Fees__c);
            System.assertEquals(700,[Select id, Net_Amount__c from Opportunity where id = : opp6.id ].Net_Amount__c);
            
            
        }
        
        
    }
    //T-640797
    public static testMethod void testBatchLogUpdateFunction(){
        Account acc = TestUtils.createAccount('testAcc', TRUE);
        //Creating BatchLogs
        Batch_Log__c bl = TestUtils.createBatchLog('Test BatchLog', False);
        Batch_Log__c bl2 = TestUtils.createBatchLog('Test BatchLog2', False );
        bl2.Batch_Log_Type__c = 'Manual';
        List<Batch_Log__c> batchLogList = new List<Batch_Log__c>{bl, bl2};
        insert batchLogList;
        
        
        List<Opportunity> oppList = new List<Opportunity>();
        Campaign cmp = TestUtils.createCampaign('test camp',false);
        cmp.rC_Giving__Source_Code__c = '123';
        cmp.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        insert cmp;
        //Creating Parent Opportunity
        Opportunity opp1 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
        opp1.Batch_Log__c = bl.id;
        opp1.Deposit_Site__c = 'AK_Alaska';
        opp1.rC_Giving__Giving_Amount__c = 1000;
        opp1.recordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        opp1.rC_Giving__Giving_Amount__c = 1000;
        opp1.IsCreatedFromBatchLog__c = true;
        opp1.Fees__c = 800;
        opp1.CampaignId = cmp.id;
        opp1.Ack_Recipient_Account__c = acc.id;
        opp1.rC_Giving__Payment_Method__c = 'Paypal';
        opp1.stagename='open';
        opp1.Adjustment_Code__c = 'D';
        opp1.Batch_Sequence__c = '1';
        opp1.Payment_Subtype__c = 'Check';
        opp1.Bank_Date__c = Date.today();
        opp1.rC_Giving__Payment_Method__c = 'Cash/Check';
        opp1.Batch_Date__c = Date.today();
        
        
        
        insert opp1;
        Opportunity oppOld = opp1;
        Map<Id,Opportunity> oldMap = new Map<id, Opportunity>();
        oldMap.put(oppOld.id,oppOld);
        Map<Id, Opportunity> updateMap = new Map<Id, Opportunity>();
        
        oppList.clear();
        //creating child records:
        opp1.Batch_Log__c = bl2.id;  
        Update opp1;
        Test.StartTest();
        Opportunity opp4 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);//Transaction
        opp4.Deposit_Site__c = 'AK_Alaska';
        opp4.recordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        opp4.rC_Giving__Parent__c = opp1.id;
        opp4.rC_Giving__Giving_Amount__c = 1000;
        opp4.Net_Amount__c = 800;
        opp4.Fees__c = 400;
        opp4.Batch_Sequence__c = '1';
        opp4.Payment_Subtype__c = 'Check';
        opp4.rC_Giving__Payment_Method__c = 'Cash/Check';
        opp4.StageName = 'Completed';//#77940:Added a Completed to get map on transaction.
        insert opp4;
        Test.stopTest();
        List<opportunity> oppoList = [SELECT Id,Batch_Log__c,rC_Giving__Parent__c
                                        FROM Opportunity
                                        WHERE id = :opp4.id];
        if(oppoList != null && oppoList.size() >0) {
            System.assertEquals(oppoList[0].Batch_Log__c, opp1.Batch_Log__c);//#77940 :Maps to the Parent's batch log
        }    
        
    }
    
    
    //Task:T-649353
    public static testMethod void testInheritCampaignAttribute(){
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        Account acc = TestUtils.createAccount('testAcc', TRUE);
        List<Opportunity> oppList = new List<Opportunity>();
        List<Campaign> campList = new List<Campaign>();
        Campaign cmp;
        List<String> campSubAffiliation = new List<String>{'1 - National Union','2 - Sustainers','3 - Affiliate Union','4 - National Foundation','5 - Affiliate Foundation','6 - Misc. Giving'};
        Integer month = 1;
        for(String str: campSubAffiliation){
            cmp = TestUtils.createCampaign('test camp',false);
            cmp.rC_Giving__Source_Code__c = '123';
            cmp.rC_Giving__Sub_Affiliation__c=str;
            cmp.rC_Giving__Affiliation__c = 'CN - ACLU of Northern California';
            cmp.Sustainer_Operational_Month__c = '0'+month;
            cmp.Sustainer_Operational_Year__c =  String.valueOf(system.today().year());
            cmp.Is_Sustainer_Operational_Campaign__c = TRUE;
            cmp.rC_Giving__Campaign_Type__c = 'F - Advertising';
            cmp.Account_Code__c = 'ABAD - Abortion Ad';
            cmp.Restriction__c = '2NDAMENDC3 - Second Amendment C3 (156)';
            campList.add(cmp);
            month ++;
        }
        campList[4].Sustainer_Operational_Month__c = null;
        insert campList;
        
        Opportunity opp;
        Opportunity parentOpp = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
        parentOpp.recordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        parentOpp.rC_Giving__Is_Sustainer__c = true;
        parentOpp.rC_Giving__Affiliation__c = 'CN - ACLU of Northern California';
        parentOpp.rC_Giving__Source_Code__c = 'test';
        insert parentOpp;
        
        //insert child opp;
        
        for( Integer i = 1; i< 8; i++ ){
            opp = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
            opp.recordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
            opp.StageName = 'Open';
            opp.Program_Type__c = ''+i;
            opp.rC_Giving__Parent__c = parentOpp.id;
            opp.Sustainer_First_Payment__c = false;
            opp.Source_Code_Override__c = false;
            opp.rC_Giving__Affiliation__c = 'CN - ACLU of Northern California';
            opp.CloseDate = Date.newInstance(system.today().year(),i, 5);
            oppList.add(opp);
        }
        oppList[6].Program_Type__c = '5';
        insert oppList;
        
        for( Opportunity opp1 : oppList ){
            opp1.StageName = 'Completed';
            opp1.Adjustment_Code__c = 'D';
        }
        update oppList;
        oppList = [SELECT Id,Account_Code__c,Restriction__c FROM Opportunity WHERE Id IN :oppList];
        System.assertEquals(cmp.Account_Code__c, [Select id,Account_Code__c FROM Opportunity where Id =: oppList[0].id].Account_Code__c);
        System.assertEquals(cmp.Restriction__c, [Select id,Restriction__c FROM Opportunity where Id =: oppList[0].id].Restriction__c);
    }
    
    //T-647782
    public static testMethod void testTaxCalculation(){
        Account acc = TestUtils.createAccount('testAcc', TRUE);
        //Creating BatchLogs
        Batch_Log__c bl = TestUtils.createBatchLog('Test BatchLog', False);
        Batch_Log__c bl2 = TestUtils.createBatchLog('Test BatchLog2', False );
        bl2.Batch_Log_Type__c = 'Manual';
        List<Batch_Log__c> batchLogList = new List<Batch_Log__c>{bl, bl2};
        insert batchLogList;
        
        
        List<Opportunity> oppList = new List<Opportunity>();
        Campaign cmp = TestUtils.createCampaign('test camp',false);
        cmp.rC_Giving__Source_Code__c = '123';
        cmp.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        insert cmp;
        //Creating Parent Opportunity
        Opportunity opp1 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
        opp1.Batch_Log__c = bl.id;
        opp1.Deposit_Site__c = 'AK_Alaska';
        opp1.rC_Giving__Giving_Amount__c = 1000;
        opp1.recordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
        opp1.IsCreatedFromBatchLog__c = true;
        opp1.CampaignId = cmp.id;
        opp1.Batch_Date__c = Date.today();
        
        oppList.add(opp1);
        
        Opportunity opp2 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
        opp2.Batch_Log__c = bl.id;
        opp2.recordTypeId = OPPORTUNITY_RT_DONATION_Id;//Parent
        opp2.rC_Giving__Giving_Amount__c = 2000;
        opp2.Deposit_Site__c = 'AK_Alaska';
        opp2.IsCreatedFromBatchLog__c = true;
        opp2.Fees__c = 800;
        opp2.CampaignId = cmp.id;
        opp2.Low_Amount__c = 100;
        opp2.High_Amount__c = 100;
        opp2.rC_Giving__Number_Of_Shares__c = 3;
        oppList.add(opp2);
        insert oppList;
        
        System.assertEquals(1000, [Select Tax_Value__c FROM Opportunity WHERE id =: opp1.id].Tax_Value__c);
        System.assertEquals(300, [Select Tax_Value__c FROM Opportunity WHERE id =: opp2.id].Tax_Value__c);

        //creating child records:
        oppList.clear();
        Opportunity opp4 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);//Transaction
        opp4.Batch_Log__c = bl.id;
        opp4.Deposit_Site__c = 'AK_Alaska';
        opp4.recordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
        opp4.rC_Giving__Parent__c = opp1.id;
        opp4.rC_Giving__Giving_Amount__c = 1000;
        opp4.Batch_Sequence__c = '1';
        oppList.add(opp4);
        
        Opportunity opp5 = TestUtils.createOpportunity(acc.id, 'closedDonation', false);
        opp5.Batch_Log__c = bl.id;
        opp5.Deposit_Site__c = 'AK_Alaska';
        opp5.recordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
        opp5.rC_Giving__Parent__c = opp2.id;
        opp5.rC_Giving__Giving_Amount__c = 1000;
        oppList.add(opp5);
        insert oppList;
        
        oppList.clear();
        opp1.Tax_Value__c = NULL;
        oppList.add(opp1);
        opp2.Tax_Value__c = 200;
        oppList.add(opp2);
        update oppList;
        
        opp2 = [SELECT Tax_Value__c
                     , Low_Amount__c
                     , High_Amount__c
                     , rC_Giving__Number_Of_Shares__c
                  FROM Opportunity WHERE id =: opp2.id];
        
        System.assertEquals(200, opp2.Tax_Value__c);
        System.assertEquals(100, opp2.Low_Amount__c);
        System.assertEquals(100, opp2.High_Amount__c);
        System.assertEquals(3, opp2.rC_Giving__Number_Of_Shares__c);
        System.assertEquals(NULL, [Select Tax_Value__c FROM Opportunity WHERE id =: opp1.id].Tax_Value__c);
        System.assertEquals(NULL, [Select Tax_Value__c FROM Opportunity WHERE id =: opp4.id].Tax_Value__c);
        System.assertEquals(200, [Select Tax_Value__c FROM Opportunity WHERE id =: opp5.id].Tax_Value__c);
    }
    
    private static testMethod void testExpirationDate() {
        Account acc = TestUtils.createAccount('testAcc', TRUE);
        List<Opportunity> oppList = new List<Opportunity>();
        Campaign cmp = TestUtils.createCampaign('test camp',false);
        cmp.rC_Giving__Source_Code__c = '123';
        cmp.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        cmp.rC_Giving__Affiliation__c = 'CN - ACLU of Northern California';
        insert cmp;
        Opportunity opp1 = TestUtils.createOpportunity(acc.id, 'TestDonation', false);
        opp1.recordTypeId = OPPORTUNITY_RT_DONATION_Id;
        opp1.rC_Giving__Giving_Amount__c = 1000;
        opp1.CampaignId = cmp.id;
        opp1.rC_Giving__Payment_Method__c = 'Charge Card';
        opp1.stagename='open';
        
        User u = TestUtils.createUser('last name', 'abcxuzq@aclu.org', null, false);
        u.Is_Affiliate_User__c = false;
        insert u;
        System.runAs(u){
            acc = [SELECT Id,Membership_Expiration_date__c FROM Account WHERE Id = :acc.Id];
            system.assertEquals(null, acc.Membership_Expiration_date__c);
            insert opp1;
            //Inserting child record
            Opportunity opp2 = TestUtils.createOpportunity(acc.id, 'TestTransaction', false);//Transaction
            opp2.recordTypeId = OPPORTUNITY_RT_TRANSACTION_Id;
            opp2.rC_Giving__Parent__c = opp1.id;
            opp2.StageName = 'Completed';
            opp2.Sharing_Code__c = 'E131';
            opp2.Sharing_code_Override__c = TRUE;
            opp2.Amount = 100;
            insert opp2;
            acc = [SELECT Id,Membership_Expiration_date__c FROM Account WHERE Id = :acc.Id];
            opp2 = [SELECT Id, CloseDate FROM Opportunity WHERE Id = :opp2.Id];
            system.assertEquals(RevenueSharingShareCodes.addMonths(opp2.CloseDate,12), acc.Membership_Expiration_date__c);
        }
    }
    Private static testMethod void checkInsertCaseOfPortfolioRollUpFields(){
        Test.startTest();
            //insert case
            Account acc = TestUtils.createAccount('testAcc', TRUE);
            
            PortFolio__c pf1 = TestUtils.createPortfolio('PF1', FALSE);
            PortFolio__c pf2 = TestUtils.createPortfolio('PF2', FALSE);
            PortFolio__c pf3 = TestUtils.createPortfolio('PF3', FALSE);
            List<PortFolio__c> portfolioLIst = new List<PortFolio__c>{pf1,pf2,pf3};
            insert portfolioLIst;
            
            List<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp = TestUtils.createOpportunity(acc.id, 'TestTransaction', false);
            opp.recordTypeId = OPPORTUNITY_RT_PROPOSAL_ID;
            opp.StageName = 'Completed';
            opp.rC_Giving__Requested_Amount__c = 1000;
            opp.rC_Giving__Projected_Amount__c = 1000; 
            opp.Projected_Additional__c = 1000; 
            opp.Portfolio__c = pf1.id;
            opp.Portfolio_2__c = pf2.id;
            opp.Portfolio_3__c = pf3.id;
            opp.CloseDate = Date.newInstance(system.today().year(),3, 5);
            oppList.add(opp);
            
            Opportunity opp1 = TestUtils.createOpportunity(acc.id, 'TestTransaction', false);
            opp1.recordTypeId = OPPORTUNITY_RT_PROPOSAL_ID;
            opp1.StageName = 'Completed';
            opp1.rC_Giving__Requested_Amount__c = 2000;
            opp1.rC_Giving__Projected_Amount__c = 2000; 
            opp1.Projected_Additional__c = 2000; 
            opp1.Portfolio_2__c = pf1.id;
            opp1.Portfolio_3__c = pf3.id;
            opp1.CloseDate = Date.newInstance(system.today().year(),3, 5);
            oppList.add(opp1);
            
            Opportunity opp2 = TestUtils.createOpportunity(acc.id, 'TestTransaction', false);
            opp2.recordTypeId = OPPORTUNITY_RT_PROPOSAL_ID;
            opp2.StageName = 'Completed';
            opp2.rC_Giving__Requested_Amount__c = 3000;
            opp2.rC_Giving__Projected_Amount__c = 3000; 
            opp2.Projected_Additional__c = 3000; 
            //opp2.Portfolio__c = pf3.id;
            opp2.Portfolio_2__c = pf1.id;
            //opp2.Portfolio_3__c = pf2.id;
            opp2.CloseDate = Date.newInstance(system.today().year(),3, 5);
            oppList.add(opp2);
            Database.SaveResult[] srList = Database.insert(oppList, false);
            for(Database.SaveResult sr: srList){
                System.assertEquals(TRUE, sr.isSuccess());
            }
            
            
            Map<ID, PortFolio__c> portfolioMap = new Map<Id, PortFolio__c>([Select id, Sum_of_Requested_Amount__c, Sum_of_Projected_Amount__c,
                                                                                Sum_of_the_Projected_Additional_Amount__c 
                                                                            FROM PortFolio__c 
                                                                            WHERE Id in: portfolioLIst]);
            System.assertEquals(6000, portfolioMap.get(pf1.id).Sum_of_Requested_Amount__c);
            System.assertEquals(6000, portfolioMap.get(pf1.id).Sum_of_Projected_Amount__c);
            System.assertEquals(6000, portfolioMap.get(pf1.id).Sum_of_the_Projected_Additional_Amount__c);
            
            System.assertEquals(1000, portfolioMap.get(pf2.id).Sum_of_Requested_Amount__c);
            System.assertEquals(1000, portfolioMap.get(pf2.id).Sum_of_Projected_Amount__c);
            System.assertEquals(1000, portfolioMap.get(pf2.id).Sum_of_the_Projected_Additional_Amount__c);
            
            System.assertEquals(3000, portfolioMap.get(pf3.id).Sum_of_Requested_Amount__c);
            System.assertEquals(3000, portfolioMap.get(pf3.id).Sum_of_Projected_Amount__c);
            System.assertEquals(3000, portfolioMap.get(pf3.id).Sum_of_the_Projected_Additional_Amount__c);
        Test.stopTest();
        
        //update case
        opp.rC_Giving__Requested_Amount__c = 5000;
        opp1.rC_Giving__Requested_Amount__c = 4000; 
        update oppList; 
        System.assertEquals(5000, [Select id, Sum_of_Requested_Amount__c FROM PortFolio__c WHERE id = :PF2.id].Sum_of_Requested_Amount__c);
        System.assertEquals(12000, [Select id, Sum_of_Requested_Amount__c FROM PortFolio__c WHERE id = :PF1.id].Sum_of_Requested_Amount__c);
        System.assertEquals(9000, [Select id, Sum_of_Requested_Amount__c FROM PortFolio__c WHERE id = :pf3.id].Sum_of_Requested_Amount__c);
        
        //Delete case
        DELETE new List<Opportunity>{opp, opp1};
        System.assertEquals(3000, [Select id, Sum_of_Requested_Amount__c FROM PortFolio__c WHERE id = :PF1.id].Sum_of_Requested_Amount__c);
        System.assertEquals(0, [Select id, Sum_of_Requested_Amount__c FROM PortFolio__c WHERE id = :PF2.id].Sum_of_Requested_Amount__c);
        System.assertEquals(0, [Select id, Sum_of_Requested_Amount__c FROM PortFolio__c WHERE id = :pf3.id].Sum_of_Requested_Amount__c);
    }
    
    Private static testMethod void checkPortfolioValidation(){
        Account acc = TestUtils.createAccount('testAcc', TRUE);
        PortFolio__c pf1 = TestUtils.createPortfolio('PF1', TRUE);
        PortFolio__c pf2 = TestUtils.createPortfolio('PF2', TRUE);
        PortFolio__c pf3 = TestUtils.createPortfolio('PF3', TRUE);
        
        
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = TestUtils.createOpportunity(acc.id, 'TestTransaction', false);
        opp.recordTypeId = OPPORTUNITY_RT_PROPOSAL_ID;
        opp.StageName = 'Completed';
        opp.rC_Giving__Requested_Amount__c = 1000;
        opp.Sharing_code_Override__c = TRUE;
        opp.Portfolio__c = pf1.id;
        opp.Portfolio_2__c = pf1.id;
        opp.Portfolio_3__c = pf1.id;
        opp.CloseDate = Date.newInstance(system.today().year(),3, 5);
        oppList.add(opp);
        
        Opportunity opp1 = TestUtils.createOpportunity(acc.id, 'TestTransaction', false);
        opp1.recordTypeId = OPPORTUNITY_RT_PROPOSAL_ID;
        opp1.StageName = 'Completed';
        opp1.rC_Giving__Requested_Amount__c = 1000;
        opp1.Sharing_code_Override__c = TRUE;
        opp1.Portfolio__c = pf1.id;
        opp1.Portfolio_2__c = pf1.id;
        opp1.Portfolio_3__c = pf2.id;
        opp1.CloseDate = Date.newInstance(system.today().year(),3, 5);
        oppList.add(opp1);
        
        Opportunity opp2 = TestUtils.createOpportunity(acc.id, 'TestTransaction', false);
        opp2.recordTypeId = OPPORTUNITY_RT_PROPOSAL_ID;
        opp2.StageName = 'Completed';
        opp2.rC_Giving__Requested_Amount__c = 1000;
        opp2.Sharing_code_Override__c = TRUE;
        opp2.Portfolio__c = pf1.id;
        opp2.Portfolio_2__c = pf2.id;
        opp2.Portfolio_3__c = pf3.id;
        opp2.CloseDate = Date.newInstance(system.today().year(),3, 5);
        oppList.add(opp2);
        Database.SaveResult[] srList = Database.insert(oppList, false);
        //System.assertEquals(False, srList[0].isSuccess());
        System.assertEquals(False, srList[1].isSuccess());
        System.assertEquals(TRUE, srList[2].isSuccess());
     }
     
     private static testMethod void testPrimaryCampaignSourceUpdate(){
         Account acc = TestUtils.createAccount('TestAcc', true);
         Campaign cmp1 = TestUtils.createCampaign('test camp1',false);
         cmp1.rC_Giving__Source_Code__c = '123';
         cmp1.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
         cmp1.rC_Giving__Affiliation__c = 'CN - ACLU of Northern California';
         insert cmp1;
         Campaign cmp2 = TestUtils.createCampaign('test camp2',false);
         cmp2.rC_Giving__Source_Code__c = '12345';
         cmp2.rC_Giving__Sub_Affiliation__c='3 - Affiliate Union';
         cmp2.rC_Giving__Affiliation__c = 'CN - ACLU of Northern California';
         insert cmp2;
         Opportunity pledgeRec = TestUtils.createOpportunity(acc.id, 'pledgeRec', false);
         pledgeRec.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
         pledgeRec.rC_Giving__Giving_Amount__c  = 100;
         pledgeRec.stageName = 'Open';
         pledgeRec.campaignId = cmp1.Id;
         pledgeRec.closeDate = date.Today();
         insert pledgeRec;
         Opportunity pledgePaymentRec = TestUtils.createOpportunity(acc.id, 'pledgePaymentRec', false);
         pledgePaymentRec.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
         pledgePaymentRec.rC_Giving__Parent__c = pledgeRec.Id; 
         insert pledgePaymentRec;
         
         pledgePaymentRec.CampaignId = cmp2.Id;
         update pledgePaymentRec;
         
         Opportunity opp = [SELECT Id, CampaignIdText__c, rC_Giving__Source_Code__c,
                                Campaign.rC_Giving__Source_Code__c
                            FROM Opportunity
                            WHERE Id = :pledgePaymentRec.Id];
         system.assertEquals(true, opp.CampaignIdText__c.contains(cmp2.Id));
         system.assertEquals(opp.Campaign.rC_Giving__Source_Code__c, opp.rC_Giving__Source_Code__c);
     }
    
     /*flagMembershipShareCodeReset function should execute and update the batch log using asyncRequest*/
     private static /*testMethod*/ void testCaseI_FlagMembershipReset(){
         Test.startTest();
             Account acc = TestUtils.createAccount('TestAcc', true);
             Campaign cmp1 = TestUtils.createCampaign('test camp1',false);
             cmp1.rC_Giving__Source_Code__c = '123';
             cmp1.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
             cmp1.rC_Giving__Affiliation__c = 'CN - ACLU of Northern California';
             insert cmp1;
             
             Batch_Log__c blog = TestUtils.createBatchLog('Test BatchLog2', False );
             blog.Batch_Log_Type__c = 'Manual';
             insert blog;
             
             List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
             
             Opportunity pledgeRec = TestUtils.createOpportunity(acc.id, 'pledgeRec', false);
             pledgeRec.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
             pledgeRec.rC_Giving__Giving_Amount__c  = 100;
             pledgeRec.stageName = 'Open';
             pledgeRec.campaignId = cmp1.Id;
             pledgerec.Batch_Log__c = blog.id;
             pledgeRec.closeDate = date.Today();
             insert pledgeRec;
             Opportunity pledgePaymentRec = TestUtils.createOpportunity(acc.id, 'pledgePaymentRec', false);
             pledgePaymentRec.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
             pledgePaymentRec.rC_Giving__Parent__c = pledgeRec.Id; 
             pledgePaymentRec.Batch_Log__c = blog.id;
             pledgePaymentRec.Campaign_Type__c = 'I';
             pledgePaymentRec.Program_Type__c = '1';
             insert pledgePaymentRec;
             
             pledgePaymentRec.stageName = 'Completed';
             update pledgePaymentRec;
             /*after udpate sharing code updates to E181*/
             
             pledgePaymentRec.Deposit_Site__c = 'AK_Alaska';
             update pledgePaymentRec;
         
            
                            
            Test.stopTest();
             System.assertEquals('Membership and Revenue Sharing Resets Needed', [SELECT Id, Batch_Log_Status__c FROM Batch_Log__c 
                            WHERE Id = :blog.Id].Batch_Log_Status__c);
     }
     
     
     private static testMethod void testCaseII_FlagMembershipReset(){
         Test.startTest();
             Account acc = TestUtils.createAccount('TestAcc', true);
             Campaign cmp1 = TestUtils.createCampaign('test camp1',false);
             cmp1.rC_Giving__Source_Code__c = '123';
             cmp1.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
             cmp1.rC_Giving__Affiliation__c = 'CN - ACLU of Northern California';
             insert cmp1;
             
             Batch_Log__c blog = TestUtils.createBatchLog('Test BatchLog2', False );
             blog.Batch_Log_Type__c = 'Manual';
             insert blog;
             
             List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
             
             Opportunity pledgeRec = TestUtils.createOpportunity(acc.id, 'pledgeRec', false);
             pledgeRec.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
             pledgeRec.rC_Giving__Giving_Amount__c  = 100;
             pledgeRec.stageName = 'Open';
             pledgeRec.campaignId = cmp1.Id;
             pledgerec.Batch_Log__c = blog.id;
             pledgeRec.closeDate = date.Today();
             insert pledgeRec;
         
             Opportunity pledgePaymentRec = TestUtils.createOpportunity(acc.id, 'pledgePaymentRec', false);
             pledgePaymentRec.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
             pledgePaymentRec.rC_Giving__Parent__c = pledgeRec.Id; 
             pledgePaymentRec.Batch_Log__c = blog.id;
             pledgePaymentRec.Campaign_Type__c = 'B';
             pledgePaymentRec.Program_Type__c = '1';
             insert pledgePaymentRec;
             
             pledgePaymentRec.stageName = 'Completed';
             update pledgePaymentRec;
             /*after udpate sharing code updates to E141*/
             
             
             pledgePaymentRec.Campaign_Type__c = 'I';
             pledgePaymentRec.Amount = 100;
             update pledgePaymentRec;
            /*sould not pass the if condition of flagMembershipShareCodeReset() if condition and should enter into else condition>>
            sharing code should update to 'E181'*/
            
                            
            Test.stopTest();
            //System.assert(false, [select id, Sharing_Code__c FROM Opportunity where id=: pledgePaymentRec.id]);
             System.assertEquals('E181', [select id, Sharing_Code__c FROM Opportunity where id=: pledgePaymentRec.id].Sharing_Code__c);
     }
     
     private static testMethod void testNameUpdate() {
         Test.startTest();
             Account acc = TestUtils.createAccount('TestAcc', true);
             Campaign cmp1 = TestUtils.createCampaign('test camp1',false);
             insert cmp1;
             
             rC_Giving__Opportunity_Setting__c oppSetting = new rC_Giving__Opportunity_Setting__c(SetupOwnerId=UserInfo.getOrganizationId(), 
                                                                    rC_Giving__Disable_UpdateName__c = true);
             insert oppSetting;
             Opportunity pledgeRec = TestUtils.createOpportunity(acc.id, 'pledgeRec', false);
             pledgeRec.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
             pledgeRec.rC_Giving__Is_Giving__c = true;
             pledgeRec.rC_Giving__Is_Giving_Transaction__c = false;
             pledgeRec.rC_Giving__Giving_Amount__c  = 100;
             pledgeRec.stageName = 'Open';
             pledgeRec.campaignId = cmp1.Id;
             pledgeRec.closeDate = date.Today();
             insert pledgeRec;
                            
        Test.stopTest();
        
        system.assertEquals(acc.Name + ': Pledge ' + date.Today().year(), [SELECT Name FROM Opportunity WHERE Id = :pledgeRec.Id].Name);
     }
     
     private static testMethod void updateSBDonation() {
         Test.startTest();
             Account acc = TestUtils.createAccount('TestAcc', true);
             Campaign cmp1 = TestUtils.createCampaign('test camp1',false);
             insert cmp1;
             
             List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
             Opportunity pledgeRec = TestUtils.createOpportunity(acc.id, 'pledgeRec', false);
             pledgeRec.RecordTypeId = OPPORTUNITY_RT_PLEDGE_Id;
             pledgeRec.rC_Giving__Giving_Amount__c  = 100;
             pledgeRec.stageName = 'Completed';
             pledgeRec.campaignId = cmp1.Id;
             pledgeRec.closeDate = date.Today();
             pledgeRec.SB_Donation_Id__c = '12345';
             insert pledgeRec;
             Opportunity pledgePaymentRec = TestUtils.createOpportunity(acc.id, 'pledgePaymentRec', false);
             pledgePaymentRec.RecordTypeId = OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
             pledgePaymentRec.rC_Giving__Parent__c = pledgeRec.Id; 
             pledgePaymentRec.Campaign_Type__c = 'B';
             pledgePaymentRec.Program_Type__c = '1';
             pledgePaymentRec.stageName = 'Open';
             pledgePaymentRec.Related_Transaction__c  = null;
             insert pledgePaymentRec;
             //Logic moved to update, so SB_Donation_Id__c in child will be updated in update context
             System.assertEquals(null,[Select Id, SB_Donation_Id__c FROM Opportunity where ID =: pledgePaymentRec.Id].SB_Donation_Id__c);
             pledgePaymentRec.stageName = 'Completed';
             pledgePaymentRec.Sustainer_First_Payment__c = TRUE;
             update pledgePaymentRec;
             System.assertEquals('12345',[Select Id, SB_Donation_Id__c FROM Opportunity where ID =: pledgePaymentRec.Id].SB_Donation_Id__c);     
        Test.stopTest();
        
        
     }
}