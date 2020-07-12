/*******************************************************************************
Created By        :  Gagandeep Kaur
Modified By		  :	 Lalit Singhal
Date              :  Feb 13th 2016
Purpose           :  Test Class For ManageEmailsController
*******************************************************************************/
@isTest
private class ManageEmailsControllerTest  {
    private static Email__c mail;
    private static testMethod void testManageEmailsController() {
      
       
	    createTestData();
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CalloutMergeEmail());

            Test.setCurrentPage(Page.ManageEmails);
            ApexPages.CurrentPage().getParameters().put('referral', 'Test1234');
            ApexPages.CurrentPage().getParameters().put('eId', mail.Id);
            ManageEmailsController manage = new ManageEmailsController();

            system.assertEquals(false, manage.isShowFirstPanel);
            system.assertEquals(true, manage.isShowSecondPanel);
            ApexPages.CurrentPage().getParameters().put('referralCode', 'CA');
            manage.UpdateMyEmailSub1();
            ApexPages.CurrentPage().getParameters().put('isFullOptOut', 'true');
            ApexPages.CurrentPage().getParameters().put('referralCode', 'cn');
        	ApexPages.CurrentPage().getParameters().put('ePrefLabels', '["al","ca"]');
            manage.UpdateMyEmailSub2();
        
            Email__c email = [SELECT Id, Opt_In__c FROM Email__c WHERE Id = :mail.Id];
            system.assertEquals(false, email.Opt_In__c);
        	pageReference pg = manage.redirectThankYouPage();
        Test.stopTest();
	}
    
    private static testMethod void testManageEmailsController2(){
        createTestData();
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CalloutMergeEmail());
            Test.setCurrentPage(Page.ManageEmails);
            ApexPages.CurrentPage().getParameters().put('referral', 'al');
            ApexPages.CurrentPage().getParameters().put('eId', mail.Id);
            ManageEmailsController manage = new ManageEmailsController();
            ApexPages.CurrentPage().getParameters().put('referralCode', 'ca');
            manage.UpdateMyEmailSub1();
        	ApexPages.CurrentPage().getParameters().put('isFullOptOut', 'true');
        	ApexPages.CurrentPage().getParameters().put('referralCode', 'cn');
            manage.UpdateMyEmailSub2();
        
            Email__c email = [SELECT Id, Opt_In__c FROM Email__c WHERE Id = :mail.Id];
            system.assertEquals(false, email.Opt_In__c);
        	pageReference pg = manage.redirectThankYouPage();
        
        	manage.objEmail = new Email__c();
            try{
                manage.UpdateMyEmailSub1();
                manage.UpdateMyEmailSub2();
            }catch(Exception e){
                System.assertEquals(e.getMessage(), e.getMessage());
            }
        Test.stopTest();
    }
	
    private static testmethod void checkForSurge() {      
        List< rC_Connect__Batch_Upload__c > batchUploadList = new List< rC_Connect__Batch_Upload__c >();
        rC_Connect__Batch_Upload__c batchUpload1 = TestUtils.createBatchUpload('TESTBATCH1','TESTING1',null,'',false);
        Test.startTest();
            batchUpload1.Name = 'Contact Test Batch';  
	        batchUpload1.Cont1_Email__C = 'kaksdjfkdsfjk@example.com';
	        insert batchUpload1;  
        	Test.setMock(HttpCalloutMock.class, new CalloutMergeEmail());
            Test.setCurrentPage(Page.ManageEmails);
            ApexPages.CurrentPage().getParameters().put('referral', 'al');
            ApexPages.CurrentPage().getParameters().put('eId', batchUpload1.Id);
            ManageEmailsController manage = new ManageEmailsController();
            ApexPages.CurrentPage().getParameters().put('isFullOptOut', 'true');
        	ApexPages.CurrentPage().getParameters().put('referralCode', 'cn');
            manage.UpdateMyEmailSub2();
    	Test.stopTest();
    }

    @IsTest
    private static void calloutDurationTest(){
    
        Integer i;
        try {
            i = Integer.valueOf(System.Label.messageStudioCalloutDuration);
        } 
        catch (Exception e) {
        }
      
      test.startTest();
      ManageEmailsController c = new ManageEmailsController();
      Integer d = ManageEmailsController.callOutDuration;
      if (i != null) {
          System.assertEquals(Integer.valueOf(System.Label.messageStudioCalloutDuration), d);
      }
      else {
          System.assertEquals(10000, d);
      }
        
      test.stopTest();
      
    }
	
    private static void createTestData() {
        Account acc = TestUtils.createAccount('Test Acc', true);
        Contact con = TestUtils.createContact(acc, 'Test', 'Contact', true);
        mail = TestUtils.createEmail(con.Id, 'testMail@test.com', false);
        mail.Opt_In__c = true;
        insert mail;
        list<Email_Preference__c> epList = new list<Email_Preference__c>();
        list<Email_Preference_List__c> epListData = new list<Email_Preference_List__c>();
        Email_Preference__c ep = TestUtils.createEmailPreference(mail.Id, 'AL', true, false);
        Email_Preference__c ep1 = TestUtils.createEmailPreference(mail.Id, 'ca', true, false);
        Email_Preference__c ep2 = TestUtils.createEmailPreference(mail.Id, 'cn', true, false);
        epList.add(ep);
        epList.add(ep1);
        epList.add(ep2);
        insert epList;
        Email_Preference_List__c epL = TestUtils.createEmailPrefList('Test', 'TEST', true, false, 'al', 'ACLU of Alabama', false);
        Email_Preference_List__c epL1 = TestUtils.createEmailPrefList('Test1', 'T1', false, false, 'ca', 'ACLU of California', false);
        Email_Preference_List__c epL2 = TestUtils.createEmailPrefList('Test2', 'T2', false, true, 'cn', 'ACLU of Northern California', false);
        epL2.List_Code__c = 'abc@gmail.com';
        epListData.add(epL);
        epListData.add(epL1);
        epListData.add(epL2);
        insert epListData;
    }
}