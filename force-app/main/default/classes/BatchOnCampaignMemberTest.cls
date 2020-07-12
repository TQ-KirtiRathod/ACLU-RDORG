/*
*
*Name  :  BatchOnCampaignMemberTest
*Author:  Appirio India 
*Date  :  October 10,2017
*Purpose : To Test BatchOnCampaignMember Class functionality
*
*/
@isTest
private class BatchOnCampaignMemberTest {
    private static List < CampaignMember > campMemberList;
    private static Account a;
    private static Contact con;


    //Method to test Batch when Account has Campaigns Sent unempty
    @isTest
    private static void testBatchOnCampaign() {

        createData();

        Test.startTest();
        update campMemberList;
        DataBase.executeBatch(new BatchOnCampaignMember());
        Test.stopTest();
        System.debug(campMemberList.size());
        String accToqueryID = [SELECT id, contact.accountID from CampaignMember WHERE id =: campMemberList.get(0).id].contact.accountID;
        System.debug([SELECT id, Campaigns_Sent__c FROM Account WHERE id =: accToqueryID] + '><<<');

        //Verify the field update
        System.assertEquals('text area text:-------------001', [SELECT id, Campaigns_Sent__c FROM Account WHERE id =: accToqueryID].Campaigns_Sent__c);

    }


    //Method to test Batch when Account has Campaigns Sent empty
    @isTest
    private static void testBatchOnCampaign1() {

        createData();
        a.Campaigns_Sent__c = '';
        update a;

        Test.startTest();
        update campMemberList;
        DataBase.executeBatch(new BatchOnCampaignMember());
        Test.stopTest();

        String accToqueryID = [SELECT id, contact.accountID from CampaignMember WHERE id =: campMemberList.get(0).id].contact.accountID;
        System.debug([SELECT id, Campaigns_Sent__c FROM Account WHERE id =: accToqueryID] + '<<<');

        // Verify the field update
        System.assertEquals('-------------001', [SELECT id, Campaigns_Sent__c FROM Account WHERE id =: accToqueryID].Campaigns_Sent__c);

    }

    // This method creates the required data  
    private static void createData() {

        campMemberList = new List < CampaignMember > ();


        //Campaign record created
        Campaign c = testUtils.createCampaign('test campaign', false);
        c.rC_Giving__Source_Code__c = '-------------001';
        c.rC_Giving__Sub_Affiliation__c = '5 - Affiliate Foundation';
        insert c;

        Lead l = testUtils.createLead('lead 1', 'abc', 'new', true);

        //Account record created
        a = testUtils.createAccount('acc', false);
        a.Campaigns_Sent__c = 'text area text';
        insert a;

        //Contact record created
        con = testUtils.createContact(a, 'firstName', 'lastName', false);
        con.AccountId = a.id;
        con.rC_Bios__Preferred_Contact__c = true;
        insert con;

        //CampaignMember created
        CampaignMember cm = testUtils.createCampaignMember(c.id, l.id, false);
        cm.ContactId = con.id;
        insert cm;

        campMemberList.add(cm);

    }
}