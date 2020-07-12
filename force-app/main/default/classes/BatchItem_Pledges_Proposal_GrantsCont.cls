/*
*
*Name  :  BatchItem_Pledges_Proposal_GrantsCont
*Author:  Appirio India (Sai Krishna)
*Date  :  March 16, 2016
*Purpose : Controller for BatchItem_Pledges_Proposal_Grants page. The page is opened from Attach Giving button on Batch 
*          Log Items (in BGE) and display three sections - Proposals, Grants and Open Pledge Payments related to the account selected on Batch log Item.
*
*/
public class BatchItem_Pledges_Proposal_GrantsCont {
    //Members
    public Id accountId {get;set;}
    public List<Opportunity> proposals {get;set;}
    public List<Opportunity> pledgePayments {get;set;}
    public List<Opportunity> grants {get;set;}
    public Id mOppId {get;set;}
    public Id mrecTypeId {get;set;}
    public Boolean manageWindow {get;set;}
    public transient Map<String,Schema.RecordTypeInfo> opptyRTMap;
    public transient String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
    public transient String OPPORTUNITY_RT_PROPOSAL_ID;
    public transient String OPPORTUNITY_RT_PLEDGE_Id;
    public transient String OPPORTUNITY_RT_GRANT_Id;
    public Boolean accessToGrants_Proposals {get;set;}
    public Boolean accessToPledgePayments {get;set;}
    public String batchId {get;Set;}
    public Boolean isOpenedFromSoftCreditTable {get;set;}

    public BatchItem_Pledges_Proposal_GrantsCont(){
        accountId = ApexPages.currentPage().getParameters().get('accId');
        batchId = ApexPages.currentPage().getParameters().get('batchId');
        isOpenedFromSoftCreditTable = ApexPages.currentPage().getParameters().get('isSC') != null ?Boolean.ValueOf(ApexPages.currentPage().getParameters().get('isSC')):false;
        accessToPledgePayments = false;
        if(ApexPages.currentPage().getParameters().get('PP') != null){
            accessToPledgePayments = Boolean.ValueOf(ApexPages.currentPage().getParameters().get('PP'));
        }

        proposals = new List<Opportunity>();
        pledgePayments = new List<Opportunity>();
        grants = new List<Opportunity>();
        manageWindow = false;
        opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
        OPPORTUNITY_RT_PROPOSAL_ID = opptyRTMap.get('Proposal').getRecordTypeId();
        OPPORTUNITY_RT_PLEDGE_Id = opptyRTMap.get('Pledge').getRecordTypeId();
        OPPORTUNITY_RT_GRANT_Id = opptyRTMap.get('Grant').getRecordTypeId();
        accessToGrants_Proposals = BatchLogDetailPageController.hide_OpenProsposals();

        // Fetch Opportunites (Pledge, Open Pledge Payments, Proposals, Grants)
        for(Opportunity opp: [SELECT Id, Name, RecordTypeId, rC_Giving__Payment_Method__c, recordType.Name, Program_Type__c, rC_Giving__Requested_Amount__c, rC_Giving__Parent__r.campaign.Name, 
                                 rC_Giving__Parent__r.campaign.rC_Giving__Source_Code__c, rC_Giving__Giving_Amount__c, amount, closeDate, campaignId, campaign.Name, StageName, rC_Giving__Parent__c,
                                 campaign.rC_Giving__Source_Code__c,rC_Giving__Source_Code__c, rC_Giving__Parent__r.rC_Giving__Source_Code__c,
                                 rC_Giving__Parent__r.Campaignid, Restriction__c, Revenue_Fiscal_Year__c
                                 FROM Opportunity WHERE accountId =: accountId  AND (RecordTypeId =: OPPORTUNITY_RT_GRANT_Id OR
                                 RecordTypeId =: OPPORTUNITY_RT_PROPOSAL_ID OR (RecordTypeId =: OPPORTUNITY_RT_PLEDGE_PAYMENT_Id AND stageName = 'Open' AND (IsCreatedFromBatchLog__c = false))) 
                                 ORDER BY closeDate ASC ]){
                // Prosposal records
                if(opp.RecordTypeId == OPPORTUNITY_RT_PROPOSAL_ID ){
                    proposals.add(opp);
                }
                // Grant records
                if(opp.RecordTypeId == OPPORTUNITY_RT_GRANT_Id ){
                    grants.add(opp);
                }

                // Pledges records
                if(opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id ){
                    pledgePayments.add(opp);
                }

        }

    }

    public void manageTransactions(){
        mOppId = ApexPages.currentPage().getParameters().get('moppId');
        mrecTypeId = ApexPages.currentPage().getParameters().get('mrecTypeId');
        manageWindow = true;
    }

    public void close(){
        manageWindow = false;
    }
}