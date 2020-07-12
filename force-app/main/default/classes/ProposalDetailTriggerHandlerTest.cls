/*
*
*Name  :  ProposalDetailTriggerHandlerTest
*Author:  Appirio India (Aashita Sharma)
*Date  :  Jan 30, 2018
*Purpose : T-659937
*
*/

@isTest
private class ProposalDetailTriggerHandlerTest {
    
    @testSetup
    static void setup(){
        //Create Proposal Detail records
        /*Opportunity o1 = new Opportunity(Name = 'Opportunity1', Proposal_Detail_Lock__c = true, StageName = 'Qualification', CloseDate = System.today());
insert o1;*/
        Opportunity o2 = new Opportunity(Name = 'Opportunity2', Proposal_Detail_Lock__c = false, StageName = 'Qualification', CloseDate = System.today());
        insert o2;
        List<Proposal_Detail__c> proposalDetailList = new List<Proposal_Detail__c>();
        for(Integer i=0; i<10; i++){
            proposalDetailList.add(new Proposal_Detail__c(Opportunity__c = o2.Id,
                                                          Affiliate_c3_Projected_Amount__c = 2000,
                                                          Affiliate_c3_Requested_Amount__c = 3000,
                                                          Affiliate_c4_Projected_Amount__c = 3000,
                                                          Affiliate_c4_Requested_Amount__c = 4000,
                                                          National_c3_Projected_Amount__c = 5000,
                                                          National_c3_Requested_Amount__c = 6000,
                                                          National_c4_Projected_Amount__c = 6000,
                                                          National_c4_Requested_Amount__c = 7000));
        }
        insert proposalDetailList;
    }
    
    /*@isTest
static void testInsertWithLockedOpportunity(){
Opportunity opp = [SELECT Id,rC_Giving__Requested_Amount__c FROM Opportunity WHERE Name LIKE 'Opportunity1'];
System.assertEquals(null, opp.rC_Giving__Requested_Amount__c);
}*/
    
    @isTest
    static void testInsertWithoutLockedOpportunity(){
        Opportunity opp = [SELECT Id,rC_Giving__Requested_Amount__c,rC_Giving__Projected_Amount__c FROM Opportunity WHERE Name LIKE 'Opportunity2'];
        System.assertEquals(20000, opp.rC_Giving__Requested_Amount__c);
        System.assertEquals(16000, opp.rC_Giving__Projected_Amount__c);
    }
    
    @isTest
    static void testUpdate(){
        Opportunity o3 = new Opportunity(Name = 'Opportunity3', Proposal_Detail_Lock__c = false, StageName = 'Qualification', CloseDate = System.today());
        insert o3;
        List<Proposal_Detail__c> insertDetailList = new List<Proposal_Detail__c>();
        for(Integer i=0; i<10; i++){
            insertDetailList.add(new Proposal_Detail__c(Opportunity__c = o3.Id,
                                                        Affiliate_c3_Projected_Amount__c = 2000,
                                                        Affiliate_c3_Requested_Amount__c = 3000,
                                                        Affiliate_c4_Projected_Amount__c = 3000,
                                                        Affiliate_c4_Requested_Amount__c = 4000,
                                                        National_c3_Projected_Amount__c = 5000,
                                                        National_c3_Requested_Amount__c = 6000,
                                                        National_c4_Projected_Amount__c = 6000,
                                                        National_c4_Requested_Amount__c = 7000));
        }
        
        insert insertDetailList;
        List<Proposal_Detail__c> updateList = new List<Proposal_Detail__c>();
        for(Proposal_Detail__c insertDetail : insertDetailList){
            insertDetail.National_c3_Projected_Amount__c = 10000;
            insertDetail.National_c4_Requested_Amount__c = 10000;
            updateList.add(insertDetail);
        }
        
        update updateList;
        Opportunity opp = [SELECT Id,rC_Giving__Requested_Amount__c,rC_Giving__Projected_Amount__c,Proposal_Detail_Lock__c FROM Opportunity WHERE Name LIKE 'Opportunity3'];
        System.assertEquals(23000, opp.rC_Giving__Requested_Amount__c);
        System.assertEquals(23571.43, opp.rC_Giving__Projected_Amount__c);
        System.assertEquals(true, opp.Proposal_Detail_Lock__c);
    }
    
    @isTest
    static void testDelete(){
        Opportunity o4 = new Opportunity(Name = 'Opportunity4', Proposal_Detail_Lock__c = false, StageName = 'Qualification', CloseDate = System.today());
        insert o4;
        
        Proposal_Detail__c insertDetail = new Proposal_Detail__c(Opportunity__c = o4.Id,
                                                        Affiliate_c3_Projected_Amount__c = 2000,
                                                        Affiliate_c3_Requested_Amount__c = 3000,
                                                        Affiliate_c4_Projected_Amount__c = 3000,
                                                        Affiliate_c4_Requested_Amount__c = 4000,
                                                        National_c3_Projected_Amount__c = 5000,
                                                        National_c3_Requested_Amount__c = 6000,
                                                        National_c4_Projected_Amount__c = 6000,
                                                        National_c4_Requested_Amount__c = 7000);
        insert insertDetail;
        
         delete insertDetail;
        Opportunity opp = [SELECT Id,Proposal_Detail_Lock__c FROM Opportunity WHERE Name LIKE 'Opportunity4' LIMIT 1];
        System.assertEquals(false, opp.Proposal_Detail_Lock__c);
    }
}