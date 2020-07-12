/*
*
*Name  :  OpportunityAsyncProcessorTest
*Author:  Appirio India (Aashita Sharma)
*Date  :  Jan 30, 2018
*Purpose : T-659937, Test Class for OpportunityAsyncProcessor
*	Ticket 		Modified Date		Modified by				Purpose
*   #74075        02/26/2020		SFDO (Kirti Rathod)     set the expiration date to null
*/

@isTest
private class OpportunityAsyncProcessorTest {
    OpportunityAsyncProcessor oap;
    public static Id pledgeOppPaymentId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    private static testMethod void  testOpportunityAsyncProcessor(){
        Account testacc2 = TestUtils.createAccount('testAcc2', true);
        List<Share_Source_Revenue_Codes__c> shareCodes = new List<Share_Source_Revenue_Codes__c>();
            shareCodes.add(new Share_Source_Revenue_Codes__c(Share_Code__c = 'P001', Name = '43', Share_Code_Description__c = 'Test')); 
            shareCodes.add(new Share_Source_Revenue_Codes__c(Name = '44', Share_Code__c = 'P003', Share_Code_Description__c = 'Test'));
            insert shareCodes; 
        Opportunity proposalOpp = TestUtils.createOpportunity(testacc2.Id,'Proposal Opp',true);
        proposalOpp.RecordTypeId = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
        update proposalOpp;
        List<Opportunity> oppList1 = new List<Opportunity>();
        Opportunity parentOpp2 = TestUtils.createOpportunity(testacc2.Id,'Parent Opp 2',true);
        parentOpp2.RecordTypeId = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
        parentOpp2.rC_Giving__Parent__c = proposalOpp.Id;
        update parentOpp2;
        List<Opportunity> oppList = new List<Opportunity>();
        for(integer i=0; i<5; i++){
            Opportunity tempOpp = TestUtils.createOpportunity(testacc2.Id,'Opp'+i,true);
            tempOpp.rC_Giving__Parent__c = parentOpp2.Id;
            tempOpp.StageName = 'Completed';
            tempOpp.Deposit_Site__c = 'NAF_NatF_Operating_chk/cash';
            tempOpp.Program_Type__c = '2';
            //tempOpp.Amount = 100;
            tempOpp.RecordTypeId = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
            oppList1.add(tempOpp);
        }
        if(oppList1.size()>0){
            update oppList1;
        }
        oppList1[1].Amount = 100;
        update oppList1[1];
        test.startTest();
        List<Proposal_Detail__c> proposalDetailList1 = new List<Proposal_Detail__c>();
        for(Integer i=0; i<5; i++){ 
            proposalDetailList1.add(new Proposal_Detail__c(Opportunity__c = proposalOpp.Id, 
                                                          Affiliate_c3_Projected_Amount__c = 2000,
                                                          Affiliate_c3_Requested_Amount__c = 3000,
                                                          Affiliate_c4_Projected_Amount__c = 3000,
                                                          Affiliate_c4_Requested_Amount__c = 4000,
                                                          National_c3_Projected_Amount__c = 5000,
                                                          National_c3_Requested_Amount__c = 6000,
                                                          National_c4_Projected_Amount__c = 6000,
                                                          National_c4_Requested_Amount__c = 7000));
        }
        System.debug('>>>'+proposalDetailList1);
        if(proposalDetailList1.size() > 0){
            System.debug('if');
            insert proposalDetailList1;
        }
        for(integer i=0; i<5; i++){
            Opportunity tempOpp = TestUtils.createOpportunity(testacc2.Id,'Opp'+i,true);
            tempOpp.StageName = 'Completed';
            tempOpp.Deposit_Site__c = 'NAF_NatF_Operating_chk/cash';
            tempOpp.IsCreatedFromBatchLog__c = true;
            if(i == 2)
            tempOpp.Program_Type__c = '2';
            if(i == 1)
            tempOpp.Program_Type__c = '1';
            if(i == 5){
            tempOpp.Program_Type__c = '5';
            tempOpp.Deposit_Site__c = null;
            }
            if(i == 4)
            tempOpp.Program_Type__c = '4';
            tempOpp.Amount = 100;
            tempOpp.Proposal__c = proposalOpp.Id;
            tempOpp.RecordTypeId = Schema.SObjectType.opportunity.getRecordTypeInfosByName().get('Soft Credit').getRecordTypeId();
            oppList.add(tempOpp);
        }
        
        if(oppList.size()>0){
            update oppList;
        }
        oppList[1].rC_Giving__Closed_Amount__c = 100;
        oppList[1].Amount = 300;
        update oppList[1];
        
        List<Opportunity> lstoppty = new List<Opportunity>([Select Id,rC_Giving__Closed_Amount__c, Amount from Opportunity where id IN: oppList]);
        system.assertEquals(300, lstoppty[1].Amount);
        AsyncRequest__c asynchReq = new AsyncRequest__c();
        asynchReq.AsyncType__c = 'opp_AddToDescription';
        asynchReq.Params__c = '';
        for(integer i=0; i<5; i++){
            asynchReq.Params__c += oppList.get(i).Id + ',';
        }
        for(integer i=0; i<5; i++){
            asynchReq.Params__c += oppList1.get(i).Id + ',';
        }
        insert asynchReq;
        asynchReq = [SELECT id, Params__c
                    FROM AsyncRequest__c
                    WHERE AsyncType__c = 'opp_AddToDescription'][0];
        OpportunityAsyncProcessor oap = new OpportunityAsyncProcessor(asynchReq);
        oap.opp_rollToProposal();
        test.stopTest();
        List<Proposal_Detail__c> lstPD = [Select Id,Opportunity__c,National_Banked_c3_Closed_Amount__c,National_Banked_c4_Closed_Amount__c,Affiliate_Banked_c3_Closed_Amount__c,Affiliate_Banked_c4_Closed_Amount__c
                                          FROM Proposal_Detail__c WHERE Opportunity__c =: proposalOpp.ID];
                                          system.assertEquals(500, lstPD[0].National_Banked_c3_Closed_Amount__c);
    }
    //Created By :: Zendesk #67681
    private static testMethod void  testOpportunityAffiliationChangeAsyncProcessor(){
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        Account acc = TestUtils.createAccount('Account123',false);
        acc.Affiliation__c = 'AA';
        acc.BillingPostalCode = '00000';
        acc.BillingCountry = 'Japan';
        acc.Has_Renewed_Before__c = false;
        insert acc; 
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        Opportunity opp= CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '1', 'B', false);
        insert opp;
        opp.Account_Affiliation__c = 'CN';
        opp.Sharing_Code__c	= 'A003';//SFDO -#74075
        update opp;
        AsyncRequest__c ac = new AsyncRequest__c();
        ac.AsyncType__c ='Opportunity_AffiliationSet';
        ac.Object_API_Name__c = 'Opportunity';
        ac.Params__c = opp.id;
        insert ac;
        List<Opportunity> opList = [SELECT id,Account_Affiliation__c FROM Opportunity  LIMIT 1]; 
        System.assertEquals(opList[0].Account_Affiliation__c == opp.Account_Affiliation__c, true);
     }
     // Not using the method present in the TestUtilis as requires custom fields for long records:: Created By :: Zendesk #67681
    public static Opportunity createOpportunity(Id AccountId, String Name, date closeDate, String sharingCode, String programType, String campaignType, Boolean doInsert){
        Opportunity opp = new Opportunity(Account_Affiliation__c = 'CN', Campaign_Type__c = campaignType,Program_Type__c = programType, RecordtypeId = pledgeOppPaymentId, Sharing_Code__c = sharingCode,rC_Giving__Giving_Amount__c = 20,Amount = 4, AccountId = AccountId ,Name = Name, CloseDate = closeDate, StageName = 'Completed');
        if(doInsert)
            insert opp;
        return opp;
    }
    
   
}