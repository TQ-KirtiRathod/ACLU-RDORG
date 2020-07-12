/*
*
*Name  :  GivingViewsAccountLayoutControllerTest
*Author:  Appirio India 
*Date  :  May 05,2017
*Purpose : To Test GivingViewsAccountLayoutController Class functionality
*
*/
@isTest
private class GivingViewsAccountLayoutControllerTest {
    
    //Method to test the controller functionality
    private static testMethod void testGivingViewsAccountLayoutController(){
        
        List<Opportunity> oppList = new List<Opportunity>();
        //Test data created
        For(integer i=0; i<3; i++){
            Account testacc1 = TestUtils.createAccount('testAcc'+i, true);
        	Opportunity testOpp1 = TestUtils.createOpportunity(testacc1.Id,'testOpp'+i,true);
            oppList.add(testOpp1);
        }
        
        //Controller class instance
        GivingViewsAccountLayoutController gvalc = new GivingViewsAccountLayoutController();
        
        //When fieldSetName is AccountLayout_DonationSection
        gvalc.setfieldSetName('AccountLayout_DonationSection');
        gvalc.getfieldSetName();
        gvalc.getOpptyToDisplay();
        //Verify the updated section name
        System.assertEquals('Donations & Pledge Payments',gvalc.sectionName);
        
        
        //When fieldSetName is AccountLayout_PledgeSection
        gvalc.setfieldSetName('AccountLayout_PledgeSection');
        gvalc.getfieldSetName();
        gvalc.getOpptyToDisplay();
        //Verify the updated section name
        System.assertEquals('Pledges',gvalc.sectionName);
        
        
        //When fieldSetName is AccountLayout_ProposalSection
        gvalc.setfieldSetName('AccountLayout_ProposalSection');
        gvalc.getfieldSetName();
        gvalc.getOpptyToDisplay();
        //Verify the updated section name
        System.assertEquals('Proposals & Grants',gvalc.sectionName);
        
        PageReference url = gvalc.url();
        system.assertNotEquals(null, url);
        
        gvalc.setOpptyToDisplay(new List<Opportunity> {oppList[0]});
        gvalc.getOpptyToDisplay();
        //Verify the updated section name
        system.assertEquals('Proposals & Grants', gvalc.sectionName);
    }
}