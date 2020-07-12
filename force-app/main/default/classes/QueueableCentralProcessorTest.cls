@isTest(seeAllData = false)
private class QueueableCentralProcessorTest {
    
    //Testing accountAffiliationChange Method
    private static testMethod void testQueueableCentralProcessor1(){
        createData('Account', 'account_AffiliationChange');
        Test.startTest();
            QueueableCentralProcessor qcp = new QueueableCentralProcessor();
            // startTest/stopTest block to force async processes to run
            System.enqueueJob(qcp);
            //ID jobID = System.enqueueJob(updater);
        Test.stopTest();
        //verify Email Preferences are created.
        System.assertEquals(2, [SELECT count() FROM Email_Preference__c]);
    }
    
    //Testing the EmailPrimarySet method
    private static testMethod void testQueueableCentralProcessor2(){
        //Create Test Data
        createData('Email__c', 'email_primarySet');
        Test.startTest();
            QueueableCentralProcessor qcp = new QueueableCentralProcessor();
            // startTest/stopTest block to force async processes to run
            System.enqueueJob(qcp);
            //ID jobID = System.enqueueJob(updater);
        Test.stopTest();
        Boolean isEnabled = QueueableControlSetting.diagnosticsEnabled;
        //Verify only one record is primary Email for a contact. 
        system.AssertEquals(1, [SELECT Id FROM Email__c WHERE Primary__c = TRUE].size());
    }
    
    //Testing the accountSharing 
    private static testMethod void testQueueableCentralProcessor3(){
        //Create Test Data
        createData('Account', 'Create_Sharing');
        Test.StartTest();
            QueueableCentralProcessor qcp = new QueueableCentralProcessor();
            // startTest/stopTest block to force async processes to run
            System.enqueueJob(qcp);
            //ID jobID = System.enqueueJob(updater);
        Test.StopTest();
        system.assert([select id,AsyncType__c from AsyncRequest__c WHERE AsyncType__c = 'Create_Sharing'].size() == 1);
    }
    
     
    
     private static testMethod void testQueueableCentralProcessorAccountAddress(){
        //Create Test Data
        createData('rC_Bios__Account_Address__c', 'accAddr_updateCountryCode');
        Test.StartTest();
            QueueableCentralProcessor qcp = new QueueableCentralProcessor();
            // startTest/stopTest block to force async processes to run
            System.enqueueJob(qcp);
            //ID jobID = System.enqueueJob(updater);
        Test.StopTest();
        system.assert([select id,AsyncType__c from AsyncRequest__c WHERE AsyncType__c = 'accAddr_updateCountryCode'].size() == 2);
     }
     private static testMethod void testQueueableCentralProcessor5(){
        //Create Test Data
        createData('Account_Team__c', 'grantUserAccess');
        Test.StartTest();
            QueueableCentralProcessor qcp = new QueueableCentralProcessor();
            // startTest/stopTest block to force async processes to run
            System.enqueueJob(qcp);
            //ID jobID = System.enqueueJob(updater);
        Test.StopTest();
        system.assert([select id,AsyncType__c from AsyncRequest__c WHERE AsyncType__c = 'grantUserAccess'].size() == 1);
     }
     private static testMethod void testQueueableCentralProcessor6(){
        //Create Test Data
        createData('Account_Team__c', 'removeUserAccess');
        Test.StartTest();
            QueueableCentralProcessor qcp = new QueueableCentralProcessor();
            // startTest/stopTest block to force async processes to run
            System.enqueueJob(qcp);
            //ID jobID = System.enqueueJob(updater);
        Test.StopTest();
        system.assert([select id,AsyncType__c from AsyncRequest__c WHERE AsyncType__c = 'removeUserAccess'].size() == 1);
     }


    private static testMethod void testQueueableCentralProcessor7(){
        //Create Test Data
        createData('Confidential_Data__c', 'share_WithAccountTeam');
        Test.StartTest();
            QueueableCentralProcessor qcp = new QueueableCentralProcessor();
            // startTest/stopTest block to force async processes to run
            System.enqueueJob(qcp);
            //ID jobID = System.enqueueJob(updater);
        Test.StopTest();
        system.assert([select id,AsyncType__c from AsyncRequest__c WHERE AsyncType__c = 'share_WithAccountTeam'].size() == 2);
     }
     private static testMethod void testQueueableCentralProcessor4(){
        //Create Test Data
        createData('rC_Giving__Payment_Method__c', 'share_WithAccountTeam');
        Test.StartTest();
            QueueableCentralProcessor qcp = new QueueableCentralProcessor();
            // startTest/stopTest block to force async processes to run
            System.enqueueJob(qcp);
            //ID jobID = System.enqueueJob(updater);
        Test.StopTest();
        system.assert([select id,AsyncType__c from AsyncRequest__c WHERE AsyncType__c = 'share_WithAccountTeam'].size() == 1);
     } 
     
    
     private static testMethod void testQueueableCentralProcessorOpportunity(){
        //Create Test Data
        createData('Opportunity', 'opp_rollToProposal');
        Test.StartTest();
            QueueableCentralProcessor qcp = new QueueableCentralProcessor();
            // startTest/stopTest block to force async processes to run
            System.enqueueJob(qcp);
            //ID jobID = System.enqueueJob(updater);
        Test.StopTest();
     }
     private static testMethod void testbatchLogupdate(){
        //Create Test Data
        createData('Batch_Log__c', 'updateBatchLog_Status');
        Test.StartTest();
            QueueableCentralProcessor qcp = new QueueableCentralProcessor();
            // startTest/stopTest block to force async processes to run
            System.enqueueJob(qcp);
            //ID jobID = System.enqueueJob(updater);
        Test.StopTest();
     }
    private static testMethod void testQueueableCentralProcessor9(){
        AsyncRequest__c testAsyncReq = new AsyncRequest__c();
        testAsyncReq.Error__c = false;
        testAsyncReq.Object_API_Name__c = 'Phone__c';
        testAsyncReq.AsyncType__c ='phone_primarySet';
        User u = [SELECT id FROM User WHERE id=:UserInfo.getUserId() LIMIT 1][0];
        System.runAs(u){
            insert testAsyncReq;
        }
        Test.startTest();
            QueueableCentralProcessor qcp = new QueueableCentralProcessor();
            // startTest/stopTest block to force async processes to run
            System.enqueueJob(qcp);
            //ID jobID = System.enqueueJob(updater);
        Test.stopTest();
    }
    
    private static void createData(String customString, String asyncType){
        Account testAcc1 = TestUtils.createAccount('testAcc1', true);
        Contact testCon1 = TestUtils.createContact(testAcc1, 'testCon1', 'testCon1', true);
        Email__c testEmail1 = TestUtils.createEmail(testCon1.Id,'a@a.com',true);
        Email__c testEmail2 = TestUtils.createEmail(testCon1.Id,'b@b.com',true);
        User u1 = TestUtils.createUser('test1','test1@aclu.org', null, true);
        Account_Team__c accteam = AccountTeamRecordAccessUtility.createAccountTeam(testAcc1.id, testCon1.id, u1.id, 'Major Gifts Affiliate', true);
        update new Account(Affiliation__c = 'TX', Id = testAcc1.Id);
        rC_Bios__Address__c address = TestUtils.createAddress('Test Address', true);
        rC_Bios__Account_Address__c accAddress = TestUtils.createAccountAddress(address.Id, testAcc1.Id, false);
        accAddress.Country_Name__c = 'India';
        insert accAddress;
        Opportunity opp = TestUtils.createOpportunity(testAcc1.id, 'test', True);
        Confidential_Data__c cd = TestUtils.createConfidentialData(testAcc1.id, testCon1.id, opp.id, TRUE );
        Map<Id, String> map1 = new Map<Id, String>();
        Map<Id, String> map2 = new Map<Id, String>();
                
        if(customString == 'Email__c' && asyncType == 'email_primarySet'){
            map1.put(testEmail1.Id, 'TX');
            map2.put(testEmail2.Id, 'TX');
            List<Map<Id, String>> emailMapList = new List<Map<Id, String>>{ map1,map2 };
            TestUtils.createAsyncRequest(customString, asyncType, JSON.serialize(emailMapList), true);
        } else
        
        if(customString == 'Account' && asyncType == 'account_AffiliationChange'){
            map1.put(testAcc1.Id, 'TX');
            map2.put(testAcc1.Id, 'AA');
            delete [select id,AsyncType__c, Object_API_Name__c,Error__c from AsyncRequest__c];
            List<Map<Id, String>> emailMapList = new List<Map<Id, String>>{ map1,map2 };
            TestUtils.createAsyncRequest(customString, asyncType, testAcc1.id, true);
        }else
        
        if(customString == 'Account' && asyncType == 'Create_Sharing'){
            rC_Bios__Preference__c  pref = TestUtils.createPreferences(testAcc1.Id,true);
            Map<Id,String> mapAccountIdToOldAffiliations = new Map<Id,String>{testAcc1.id=>'TX'};
            delete [select id,AsyncType__c, Object_API_Name__c,Error__c from AsyncRequest__c];
            TestUtils.createAsyncRequest(customString, asyncType, testAcc1.id, true);
        }
        else
        
        if(customString == 'Account_Team__c' && asyncType == 'grantUserAccess'){
            
            map1.put(accteam.Id, 'TX');
            map2.put(accteam.Id, 'TX');
            delete [select id,AsyncType__c, Object_API_Name__c,Error__c from AsyncRequest__c];
            List<Map<Id, String>> emailMapList = new List<Map<Id, String>>{ map1 };
            TestUtils.createAsyncRequest(customString, asyncType,JSON.serialize(map1) , true);
        }
        else
        
        if(customString == 'rC_Bios__Account_Address__c' && asyncType == 'accAddr_updateCountryCode'){
            Account a = new Account(Name = 'Test', Affiliation__c = 'NY', Lock_Affiliation__c = true);

            insert a;
    
            List<Contact> cs = new List<Contact>{ new Contact(FirstName = 'Testy', LastName = 'Testerson', AccountId = a.Id),
                                                  new Contact(FirstName = 'Testy', LastName = 'McTest', AccountId = a.Id) };
    
            insert cs;
    
            List<Email__c> ems = new List<Email__c>{ new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@test.com', Opt_In__c = true, Primary__c = true),
                                                     new Email__c(Contact__c = cs[0].Id, Email_address__c = 'test@z.com', Opt_In__c = false, Primary__c = false),
                                                     new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@example.com', Opt_In__c = true, Primary__c = true),
                                                     new Email__c(Contact__c = cs[1].Id, Email_address__c = 'test@qexample.com', Opt_In__c = false, Primary__c = false) };
    
            insert ems;
    
            a.Affiliation__c = 'TX';
    
            update a;
    
            Map<Id, String> newAffiliationMap = new Map<Id, String>(); 
            Map<Id, String> oldAffiliatioNmap = new Map<Id, String>();
    
            newAffiliationMap.put(a.Id, 'TX');
            oldAffiliationMap.put(a.Id, 'NY');
    
            List<Map<Id, String>> l = new List<Map<Id, String>>{ newAffiliationMap, oldAffiliationMap };
            TestUtils.createAsyncRequest(customString, asyncType, JSON.serialize(l), true);
        }
        else
        
        if(customString == 'Account_Team__c' && asyncType == 'removeUserAccess'){
            map1.put(accteam.Id, 'TX');
            map2.put(accteam.Id, 'TX');
            delete [select id,AsyncType__c, Object_API_Name__c,Error__c from AsyncRequest__c];
            List<Map<Id, String>> emailMapList = new List<Map<Id, String>>{ map1 };
            TestUtils.createAsyncRequest(customString, asyncType,JSON.serialize(map1), true); 
            
        }
        else
        if(customString == 'Confidential_Data__c' && asyncType == 'share_WithAccountTeam'){
            map1.put(cd.Id, 'TX');
            List<Map<Id, String>> addressMapList = new List<Map<Id, String>>{ map1 };
            TestUtils.createAsyncRequest(customString, asyncType, JSON.serialize(addressMapList), true);
        }
        else
        if(customString == 'Opportunity' && asyncType == 'opp_rollToProposal'){
            map1.put(Opp.Id, 'TX');
            List<Map<Id, String>> addressMapList = new List<Map<Id, String>>{ map1 };
            delete [select id,AsyncType__c, Object_API_Name__c,Error__c from AsyncRequest__c];
            TestUtils.createAsyncRequest('Opportunity', asyncType, Opp.id, true);
            //System.assert(false, [select id,AsyncType__c, Object_API_Name__c,Error__c from AsyncRequest__c]);
        }
        else
        if(customString == 'Batch_Log__c' && asyncType == 'updateBatchLog_Status'){
            Map<String,Schema.RecordTypeInfo> blRTMap = Schema.SObjectType.Batch_Log__c.getRecordTypeInfosByName();

            //RecordType - Manual
            String BATCH_LOG_RT_MANUAL_Id = blRTMap.get('Manual').getRecordTypeId();
            Batch_Log__c testBatchLog = TestUtils.createBatchLog('testBatchName', false);
            //adding date to avoid onbeforeinsert trigger exception
            testBatchLog.Batch_Date__c = Date.today();
            testBatchLog.Batch_Type__c='Adjustment';
            testBatchLog.RecordTypeId = BATCH_LOG_RT_MANUAL_Id;
            testBatchLog.Expected_Count__c=20;
            testBatchLog.Expected_Amount__c = 100;
            testBatchLog.Actual_Count__c = 20;
            testBatchLog.Actual_Amount__c = 100;
            insert testBatchLog;
            
            delete [select id,AsyncType__c, Object_API_Name__c,Error__c from AsyncRequest__c];
            TestUtils.createAsyncRequest('Batch_Log__c', asyncType, testBatchLog.id, true);
            //System.assert(false, [select id,AsyncType__c, Object_API_Name__c,Error__c from AsyncRequest__c]);
        }
        
        
        /*AsyncRequest__c testAsyncReq = new AsyncRequest__c();
        testAsyncReq.Error__c = false;
        testAsyncReq.Object_API_Name__c = customString;
        testAsyncReq.AsyncType__c ='account_AffiliationChange';
        if(customString=='Phone__c'){
            testAsyncReq.AsyncType__c = 'phone_primarySet';
        }
        
        
        testAsyncReq.Params__c = JSON.serialize(emailMapList);*/
        
        //insert testAsyncReq;
        //System.debug('testAsyncReq::' + testAsyncReq.Params__c);
        
    }
}