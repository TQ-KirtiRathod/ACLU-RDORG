@isTest
private class zSBDonationIdFixer_Test {
    private static Id OPPORTUNITY_PLEDGE_PAYMENT_RECORDTYPE_ID;
    private static rC_Connect__Batch_Upload__c bu;
    /*For creating test data*/
    public static void createTestData() {
        List<Account> lstAccount = new List<Account>();
        Account acc1 = TestUtils.createAccount('test1', true);
        Campaign camp1 = TestUtils.createCampaign('test',true);
        list<Opportunity> oppList = new list<Opportunity>();
        Id OPPORTUNITY_PLEDGE_RECORDTYPE_ID = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
        OPPORTUNITY_PLEDGE_PAYMENT_RECORDTYPE_ID = Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
        Opportunity openPledge = TestUtils.createOpportunity(acc1.id, 'openPledge', false);
        openPledge.RecordTypeId = OPPORTUNITY_PLEDGE_RECORDTYPE_ID;
        openPledge.rC_Giving__Giving_Amount__c  = 100;
        openPledge.stageName = 'Open';
        openPledge.campaignId = camp1.Id;
        openPledge.rC_Giving__Payment_Method__c = 'Securities';
        openPledge.closeDate = system.today();
        openPledge.SB_Donation_id__c = '1234';
        insert openPledge;
        for(Integer i = 0; i<10; i++) {
            Opportunity pledgePayment = TestUtils.createOpportunity(acc1.id, 'PledgePayment'+i, false);
            pledgePayment.RecordTypeId = OPPORTUNITY_PLEDGE_PAYMENT_RECORDTYPE_ID;
            pledgePayment.rC_Giving__Parent__c = openPledge.Id;
            pledgePayment.amount = 20;
            pledgePayment.StageName = 'Open';
            pledgePayment.SB_Donation_id__c = '1234';
            oppList.add(pledgePayment);
        }
        oppList[0].StageName = 'Completed';
        oppList[1].StageName = 'Completed';
        oppList[0].CloseDate = Date.newInstance(2018,5,30);
        oppList[1].CloseDate = Date.newInstance(2018,5,30);
        insert oppList;
        bu = TestUtils.createBatchUpload('Test BU', null, null, null, false);
        bu.rC_Connect__Batch_Upload_Giving_Matched__c = openPledge.Id;
        bu.rC_Connect__Giving_Close_Date__c = Date.newInstance(2018,5,30);
        bu.SB_Donation_Id__c = '5678';
        insert bu;
    }
    
    /*for testing execute batch method*/
    public static testMethod void exeuteTest() {
        String[] userName = Label.Data_Migration.split(' ');
        String lName = '';
        for(Integer i = 1;i<username.size();i++) lName += username[i] + ' ';
        User dmUser = new User(ProfileId = userinfo.getProfileId(),
                        LastName = lName,
                        FirstName = userName[0],
                        Email = 'dmUser000@aclu.org',
                        Username = 'dmUser000@aclu.org',
                        CompanyName = 'TEST',
                        Title = 'title',
                        Alias = 'alias',
                        TimeZoneSidKey = 'America/Los_Angeles',
                        EmailEncodingKey = 'UTF-8',
                        LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US');
        insert dmUser;
        system.runAs(dmUser) {
            createTestData();
            Test.startTest();
            zSBDonationIdFixer zfp1 = new zSBDonationIdFixer();
            Database.executeBatch(zfp1);
            Test.stopTest();
            list<Opportunity> oppList = [SELECT Id, SB_Donation_Id__c FROM Opportunity WHERE RecordTypeId = :OPPORTUNITY_PLEDGE_PAYMENT_RECORDTYPE_ID];
            system.assertEquals(10, oppList.size());
            for(Integer i=0;i<10;i++) {
                if(i==0 || i==1) {
                    system.assertEquals(bu.SB_Donation_id__c,oppList[i].SB_Donation_id__c);
                } else {
                    system.assertEquals(null,oppList[i].SB_Donation_id__c);
                }
            }
        }
        
    }

}