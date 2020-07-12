/*
*
*Name  :  GivingRecordsSectionControllerTest
*Author:  Appirio India 
*Date  :  October 10,2017
*Purpose : To Test GivingRecordsSectionController Class functionality
*
*/
@isTest
private class GivingRecordsSectionControllerTest {
    
    //Method to test the functionality of the class
    private static testMethod void testGivingRecordsSectionController(){
        
        //creating the data required for testing
        Account testacc1 = TestUtils.createAccount('testAcc1', true);
        List<Opportunity> oppList = new List<Opportunity>();
        for(integer i=0; i<150; i++){
            Opportunity tempOpp = Testutils.createOpportunity(testacc1.Id,'testOpp'+i,false);
            tempOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
			tempOpp.Adjustment_Code__c = 'N';
            oppList.add(tempOpp);
        }
        if(oppList.size()>0){
            insert oppList;
        }
        
        
        Test.setCurrentPage(Page.GivingRecordListWithAdjustments);
        
        //Setting page parameters
        ApexPages.CurrentPage().getParameters().put('accId', testacc1.Id);
        ApexPages.CurrentPage().getParameters().put('fieldSet', 'AccountLayout_DonationSection');
        
        GivingRecordsSectionController grs = new GivingRecordsSectionController();
        boolean isHasNext = grs.hasNext;
        boolean isHasPrevious = grs.hasPrevious;
        
        //Verify the values got from controller
        System.assertEquals(true,isHasNext);
        System.assertEquals(false,isHasPrevious);
        grs.hideAdjustments();
        
        //Next page set
        grs.next();
        isHasNext = grs.hasNext;
        isHasPrevious = grs.hasPrevious;
        System.assertEquals(true,isHasNext);
        System.assertEquals(true,isHasPrevious);
        
        //Next page set
        grs.next();
        isHasNext = grs.hasNext;
        isHasPrevious = grs.hasPrevious;
        System.assertEquals(false,isHasNext); //Since there are 150 Opp records, and 50 per load
        System.assertEquals(true,isHasPrevious);
        
        //Previous page set
        grs.previous();
        isHasNext = grs.hasNext;
        isHasPrevious = grs.hasPrevious;
        System.assertEquals(true,isHasNext); //Since now we are on the second load of total 150 Opp records
        System.assertEquals(true,isHasPrevious);

        //Verifying the functionality with different page parameters
        ApexPages.CurrentPage().getParameters().put('fieldSet', 'AccountLayout_PledgeSection');
        grs = new GivingRecordsSectionController();
        String sectionName = grs.sectionName;
        Boolean isProposal = grs.isProposal;
        system.assertEquals(false, isProposal);
        system.assertEquals('Pledges', sectionName);
        
        //Verifying the functionality with different page parameters
        ApexPages.CurrentPage().getParameters().put('fieldSet', 'AccountLayout_ProposalSection');
        grs = new GivingRecordsSectionController();
        sectionName = grs.sectionName;
        isProposal = grs.isProposal;
        system.assertEquals(true, isProposal);
        system.assertEquals('Proposals', sectionName);
    }
}