/*
*Name  :  AccountTriggerHandlerTest
*Author:  Appirio India (Kajal Jalan)
*Date  :  October 26, 2016
*Purpose : Test Coverage for AccountTriggerHandler
*/
@isTest
public class AccountTriggerHandlerTest {
    public static Id organizationId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
    public static Id householdId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    
    /*
*Method testAccountAffiliation
*Test if Affiliation and Chapter are updated when BillingPostalCode already exist on Zip Affiliate
*else if they update based on BillingCountry.
*/
    public static TestMethod void testAccountAffiliation() {
        List<Account> accountList = new List<Account>();
        List<Contact> contactList = [SELECT Id FROM Contact];
        Contact primaryCon = [SELECT Id FROM Contact WHERE LastName = 'Primary' Limit 1];
        Contact secondaryCon = [SELECT Id FROM Contact WHERE LastName = 'Secondary' Limit 1];
        
        for(Integer i=0;i<20;i++){   
            Account acc = TestUtils.createAccount('Account'+i,false);
            acc.Lock_Affiliation__c = false;
            if (i<5) {
                acc.rC_Bios__Preferred_Contact__c = contactList.get(i).Id;
                acc.RecordTypeId = organizationId;
                acc.BillingPostalCode = '8201'+i;
                acc.BillingCountry = 'USA';
            } else if (i>=5 && i<10) {
                acc.rC_Bios__Preferred_Contact__c = contactList.get(i).Id;
                acc.RecordTypeId = organizationId;
                acc.BillingPostalCode = '82011'+i;
                acc.BillingCountry = 'USA';
            } else if (i>=10 && i<12) {
                acc.rC_Bios__Preferred_Contact__c = contactList.get(i).Id;
                acc.RecordTypeId = organizationId;
                acc.BillingPostalCode = '00000';
                acc.BillingCountry = 'USA';
            } else if (i>=12 && i<14) {
                acc.RecordTypeId = householdId;
                acc.BillingCountry = 'USA';
            } else if (i>=14 && i<16) {
                acc.rC_Bios__Preferred_Contact__c = primaryCon.Id;
                acc.rC_Bios__Secondary_Contact__c = secondaryCon.Id;
                acc.RecordTypeId = householdId;
                acc.BillingCountry = 'IND';
            } else if (i>=16 && i<18) {
                acc.PG_level__c = 3;
                acc.rC_Bios__Preferred_Contact__c = primaryCon.Id;
                acc.rC_Bios__Secondary_Contact__c = secondaryCon.Id;
                acc.RecordTypeId = householdId;
                acc.BillingCountry = 'IND';
            } else if (i>=18 && i<20) {
                acc.rC_Bios__Preferred_Contact__c = contactList.get(i).Id;
                acc.RecordTypeId = organizationId;
                acc.BillingCountry = 'IND';
            }
            accountList.add(acc);
        }
        
        Test.startTest();
        insert accountList;
        createAdditionalData(accountList, contactList);
        
        Account acc = [SELECT Id,Affiliation__c,Chapter__c 
                       FROM Account
                       WHERE Id =: accountList[1].Id];
        System.assertEquals(acc.Affiliation__c,'OK');
        System.assertEquals(acc.Chapter__c,'AK - ACLU of Alaska');
        
        accountList[16].PG_level__c = 4;
        accountList[17].PG_level__c = 5;
        update accountList[16];
        Database.merge(accountList[1], accountList[2], true);
        System.assert(String.isBlank(accountList[1].MasterRecordId),'ENTERED!!!');
        
        acc = [SELECT Id,Affiliation__c,Chapter__c 
               FROM Account
               WHERE Id =: accountList[5].Id];
        System.assertEquals(acc.Affiliation__c,'NN');
        
        acc = [SELECT Id,BillingPostalCode,Affiliation__c,Chapter__c 
               FROM Account 
               WHERE Id =: accountList[3].Id];
        acc.BillingPostalCode = '80110';
        acc.Salutation_Choices__c = 'Mr. and Mrs.';
        acc.Affiliation__c = '';
        AccountTriggerHandler.doChainJob = FALSE;
        update acc;
        
        acc = [SELECT Id,Affiliation__c,Chapter__c 
               FROM Account 
               WHERE Id =: acc.Id];
        System.assertEquals(acc.Affiliation__c,'NN');
        
        acc = [SELECT Id,Affiliation__c,Chapter__c, Override_Account_Number__c, Auto_Account_Number__c
               FROM Account
               WHERE Id =: accountList[18].Id];
        System.assertEquals(acc.Affiliation__c,'ZF');
        //Task T-657330
        System.assertNotEquals(acc.Override_Account_Number__c, '');
        Test.stopTest(); 
    }
    
    /*
* Test AccountAsyncProcessor
*/
    public static TestMethod void testRunAccountAsyncProcessor() {
        // Disable Queueable Control so we can verify the inserted AsyncRequests.
        QueueableControlSetting.getAppConfig().Queueable_Enabled__c = false;
        
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accList.add(new Account(Name = 'Test', Affiliation__c = 'NY', Lock_Affiliation__c = true));
        }
        insert accList;
        for (Integer i = 0; i < 5; i++) {
            accList.get(i).Affiliation__c = 'TX';
        }
        
        Test.startTest();
        update accList;
        
        // Greater-than because trigger recursion is causing extra records to be inserted.
        System.assert([SELECT count() 
                       FROM AsyncRequest__c 
                       WHERE Object_API_Name__c = 'Account'
                       AND AsyncType__c = 'account_AffiliationChange'] > 1);
        
        AsyncRequest__c aReq = [SELECT Params__c 
                                FROM AsyncRequest__c 
                                WHERE Object_API_Name__c = 'Account'
                                AND AsyncType__c = 'account_AffiliationChange'
                                LIMIT 1];
        List<Map<Id, String>> l = (List<Map<Id, String>>)JSON.deserialize(aReq.Params__c, List<Map<Id, String>>.class);
        System.assertEquals(5, l[0].size());
        System.assertEquals(5, l[1].size());
        System.assertEquals('TX', l[0].get(accList[0].Id));
        System.assertEquals('NY', l[1].get(accList[0].Id));
        Test.stopTest();
    }
    
    public static TestMethod void testRunAccountAsyncProcessorWithAA() {
        // Disable Queueable Control so we can verify the inserted AsyncRequests.
        QueueableControlSetting.getAppConfig().Queueable_Enabled__c = false;
        
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accList.add(new Account(Name = 'Test', Affiliation__c = 'NY', Lock_Affiliation__c = true));
        }
        insert accList;
        for (Integer i = 0; i < 5; i++) {
            accList.get(i).Affiliation__c = 'AA';
        }
        
        Test.startTest();
        update accList;
        
        System.assertEquals(0, [SELECT count() 
                                FROM AsyncRequest__c 
                                WHERE Object_API_Name__c = 'Account'
                                AND AsyncType__c = 'account_AffiliationChange']);
        
        accList = [SELECT Id, Previous_State_Affiliation__c, Previous_State_Affiliation_Date__c 
                   FROM Account
                   WHERE Id IN :accList];
        System.assertEquals('NY', accList[0].Previous_State_Affiliation__c);
        System.assertNotEquals(null, accList[0].Previous_State_Affiliation_Date__c);
        
        for (Integer i = 0; i < 5; i++) {
            accList.get(i).Affiliation__c = 'TX';
        }
        update accList;
        
        accList = [SELECT Id, Previous_State_Affiliation__c, Previous_State_Affiliation_Date__c 
                   FROM Account
                   WHERE Id IN :accList];
        System.assertEquals('NY', accList[0].Previous_State_Affiliation__c);
        System.assertNotEquals(null, accList[0].Previous_State_Affiliation_Date__c);
        
        // Greater-than because trigger recursion is causing extra records to be inserted.
        System.assert([SELECT count() 
                       FROM AsyncRequest__c 
                       WHERE Object_API_Name__c = 'Account'
                       AND AsyncType__c = 'account_AffiliationChange'] > 1);
        
        
        AsyncRequest__c aReq = [SELECT Params__c 
                                FROM AsyncRequest__c 
                                WHERE Object_API_Name__c = 'Account'
                                AND AsyncType__c = 'account_AffiliationChange'
                                LIMIT 1];
        
        List<Map<Id, String>> l = (List<Map<Id, String>>)JSON.deserialize(aReq.Params__c, List<Map<Id, String>>.class);
        System.assertEquals(5, l[0].size());
        System.assertEquals(5, l[1].size());
        System.assertEquals('TX', l[0].get(accList[0].Id));
        System.assertEquals('NY', l[1].get(accList[0].Id));
        Test.stopTest();
    }
    
    public static TestMethod void testRunAccountAsyncProcessorAAWithoutMove() {
        // Disable Queueable Control so we can verify the inserted AsyncRequests.
        QueueableControlSetting.getAppConfig().Queueable_Enabled__c = false;
        
        List<Account> accList = new List<Account>();
        for (Integer i=0; i<5 ; i++) {
            accList.add(new Account(Name = 'Test', Affiliation__c = 'NY',
                                    Previous_State_Affiliation__c = 'TX', 
                                    Previous_State_Affiliation_Date__c = Datetime.now().addDays(-1),
                                    Lock_Affiliation__c = true));
        }
        insert accList;
        
        for (Integer i=0; i<5 ; i++) {
            accList.get(i).Affiliation__c = 'AA';
        }
        
        Test.startTest();
        update accList;
        
        System.assertEquals(0, [SELECT count() 
                                FROM AsyncRequest__c 
                                WHERE Object_API_Name__c = 'Account'
                                AND AsyncType__c = 'account_AffiliationChange']);
        
        Account acc = [SELECT Id, Previous_State_Affiliation__c, Previous_State_Affiliation_Date__c 
                       FROM Account
                       WHERE Id = :accList[0].Id];
        System.assertEquals('NY', acc.Previous_State_Affiliation__c);
        System.assertNotEquals(null, acc.Previous_State_Affiliation_Date__c);
        Test.stopTest();
    }
    
    public static TestMethod void testRunAccountAsyncProcessorAgedOut() {
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accList.add(new Account(Name = 'Test', Affiliation__c = 'AA',
                                    Previous_State_Affiliation__c = 'TX', 
                                    Previous_State_Affiliation_Date__c = Datetime.now().addDays(-1),
                                    Lock_Affiliation__c = true));
        }
        insert accList;
        
        // This is NOT a state-to-state move. The account has been in AA too long.
        for (Integer i = 0; i < 5; i++) {
            accList.get(i).Affiliation__c = 'FL';
        }
        
        Test.startTest();
        update accList;
        
        System.assertEquals(0, [SELECT count() 
                                FROM AsyncRequest__c 
                                WHERE Object_API_Name__c = 'Account'
                                AND AsyncType__c = 'account_AffiliationChange']);
        Test.stopTest();
    }
    
    public static TestMethod void testRunAccountAsyncProcessorBulk() {
        // Disable Queueable Control so we can verify the inserted AsyncRequests.
        // We will also force a low batch size to ensure that batching works correctly.
        QueueableControlSetting.getAppConfig().Queueable_Enabled__c = false;
        AccountTriggerHandler.accountAsyncBatchMax = 4;
        
        List<Account> acts = new List<Account>();
        for (Integer i = 0; i < 25; i++) {
            acts.add(new Account(Name = 'Test ' + String.valueOf(i), Affiliation__c = 'NY', Lock_Affiliation__c = true));
        }
        insert acts;
        
        for (Integer i = 0; i < 25; i++) {
            acts[i].Affiliation__c = (Math.random() < 0.5 ? 'TX' : 'CS');
        }
        
        Test.startTest();
        update acts;
        
        System.assert([SELECT count() 
                       FROM AsyncRequest__c 
                       WHERE Object_API_Name__c = 'Account'
                       AND AsyncType__c = 'account_AffiliationChange'] >= 7);
        
        Set<Id> recordCount = new Set<Id>();
        Map<Id, Account> accountMap = new Map<Id, Account>(acts);
        
        for (AsyncRequest__c ar : [SELECT Params__c 
                                   FROM AsyncRequest__c 
                                   WHERE Object_API_Name__c = 'Account'
                                   AND AsyncType__c = 'account_AffiliationChange']) {
                                       
                                       List<Map<Id, String>> l = (List<Map<Id, String>>)JSON.deserialize(ar.Params__c, List<Map<Id, String>>.class);
                                       
                                       for (Id aId : l[0].keySet()) {
                                           System.assertEquals(accountMap.get(aId).Affiliation__c, l[0].get(aId));
                                           recordCount.add(aId);
                                       }
                                       for (Id aId : l[1].keySet()) {
                                           System.assertEquals('NY', l[1].get(aId));
                                       }
                                   }
        
        System.assertEquals(25, recordCount.size());
        Test.stopTest();
    }
    
    private static TestMethod void testAccountTriggerHandler2(){
        List<Account> accList = new List<Account>();
        for(integer i=0; i<10; i++){
            accList.add(TestUtils.createAccount('tempAcc'+i,false));
        }
        
        Test.startTest();
        insert accList;
        
        accList = [SELECT Name,Formal_Outside_2__c,Formal_Outside_3__c,Informal_Inside__c,
                   Informal_Outside_1__c,Informal_Outside_2__c,Default_Email_Salutation__c,
                   Recognition_Formal__c,Recognition_Informal__c
                   FROM Account];
        for(Account tempAcc : accList){
            tempAcc.Formal_Outside_2__c = 'Formal_Outside_2__c';
            tempAcc.Formal_Outside_3__c = 'Formal_Outside_3__c';
            tempAcc.Informal_Inside__c = 'Informal_Inside__c';
            tempAcc.Informal_Outside_1__c = 'Informal_Outside_1__c';
            tempAcc.Informal_Outside_2__c = 'Informal_Outside_2__c';
            tempAcc.Default_Email_Salutation__c = 'Default_Email_Salutation__c';
            tempAcc.Recognition_Formal__c = 'Recognition_Formal__c';
            tempAcc.Recognition_Informal__c = 'Recognition_Informal__c';
        }
        update accList;
        
        accList = [SELECT Name,Formal_Outside_2__c,Formal_Outside_3__c,Informal_Inside__c, Is_Formal_Outside_3_Locked__c,
                          Informal_Outside_1__c,Informal_Outside_2__c,Default_Email_Salutation__c,
                          Recognition_Formal__c,Recognition_Informal__c, Is_Formal_Outside_2_Locked__c
                   FROM Account];
        System.assertEquals(true, accList.get(0).Is_Formal_Outside_2_Locked__c);
        System.assertEquals(true, accList.get(1).Is_Formal_Outside_3_Locked__c);
        Test.stopTest();
    }
    
    public static TestMethod void testDeleteTrigger() {
        List<Account> accList = new List<Account>();
        for(integer i=0; i<2; i++){
            accList.add(TestUtils.createAccount('tempAcc'+i,false));
        }
        insert accList;
        
        List<Account> accs = [SELECT Id, Account_Number__c, RecordType.Name FROM Account LIMIT 2];
        
        Account a = new Account(Id = accs[1].Id);
        Account b = new Account(Id = accs[0].Id);
        AccountTriggerHandler.doChainJob = FALSE;
        Database.merge(b,a);
        
        List<Account_Merge_History__c> hists;
        hists = [SELECT Deleted_Account_Number__c, Deleted_Id__c, Merged_Date__c, Record_Type__c,
                 Retained_Account__c, Retained_Account_Number__c, Retained_Id__c
                 FROM Account_Merge_History__c];
        
        System.assertEquals(1, hists.size());
        System.assertEquals(accs[0].Id, hists[0].Retained_Id__c);
        System.assertEquals(accs[0].Id, hists[0].Retained_Account__c);
        System.assertEquals(accs[0].Account_Number__c, hists[0].Retained_Account_Number__c);
        System.assertEquals(accs[1].Id, hists[0].Deleted_Id__c);
        System.assertEquals(accs[1].Account_Number__c, hists[0].Deleted_Account_Number__c);
        System.assertEquals(Date.today(), hists[0].Merged_Date__c);
        System.assertEquals(accs[1].RecordType.Name, hists[0].Record_Type__c);      
    }

    // Get explicit coverage for since two queueables cannot be called within the same test context
    public static TestMethod void testMergePostProcessingFutureWrapper() {
        List<Account> accList = new List<Account>();
        Set<Id> accIdSet = new Set<Id>();

        for(integer i=0; i<2; i++){
            accList.add(TestUtils.createAccount('tempAcc'+i,false));
        }
        insert accList;
        
        List<Account> accs = [SELECT Id FROM Account LIMIT 2];
        
        for (Account a : accs) {
            accIdSet.add(a.Id);
        }

        Test.startTest();
            System.enqueueJob(new AccountTriggerHandler.QueueMergePostProcessingFutureWrapper(accIdSet));
        Test.stopTest();
    }
    
    /*
*Creating Sample Data For Testing
*/
    @testSetup
    public static void createTestData() {
        Contact con;
        List<Contact> contactList = new List<Contact>();
        List<Zip_Affiliate__c> listZipAffiliate = new List<Zip_Affiliate__c>();
        
        //Create Contacts
        for(Integer i=0;i<20;i++) {
            con = TestUtils.createContact(null,'test'+i,'testAccount'+i,false);
            contactList.add(con);
        }
        con = TestUtils.createContact(null,'Test','Secondary',false);
        contactList.add(con);
        con = TestUtils.createContact(null,'Test','Primary',false);
        con.Salutation = 'The';
        contactList.add(con);
        insert contactList;
        
        //Create Zip Affiliations 
        for(Integer i=0;i<10;i++) {
            Zip_Affiliate__c zipAff = TestUtils.createZipAffiliate('8201'+i,false);
            zipAff.Affiliation__c = 'OK';
            zipAff.Chapter__c = 'AK - ACLU of Alaska';
            listZipAffiliate.add(zipAff);
        }
        insert listZipAffiliate;
    }
    
    private static void createAdditionalData(List<Account> accountList, List<Contact> contactList) {
        List<rC_Bios__Preference__c> preferenceList = new list<rC_Bios__Preference__c>();
        List<rC_Bios__Salutation__c> salutationList = new List<rC_Bios__Salutation__c>();
        List<rC_Giving__Planned_Giving__c> listOFPlannedGivingOnAccount = new List<rC_Giving__Planned_Giving__c>();
        
        //Create and update Preferences
        preferenceList.add(new rC_Bios__Preference__c(rC_Bios__Account__c = accountList.get(16).Id, rC_Bios__Code_Value__c = 'PZ'));
        preferenceList.add(new rC_Bios__Preference__c(rC_Bios__Account__c = accountList.get(17).Id, rC_Bios__Code_Value__c = 'PA'));
        insert preferenceList;
        
        preferenceList.get(0).rC_Bios__Code_Value__c = 'PA';
        preferenceList.get(1).rC_Bios__Code_Value__c = 'PZ';
        update preferenceList;
        
        //Create Salutations
        for(Integer i = 2 ; i<4 ;i++){
            rC_Bios__Salutation__c salutation = TestUtils.createSalutation(accountList[i].Id,false);
            salutation.Priority__c = 3;
            salutation.rC_Bios__Salutation_Type__c = 'AZ-Recognition';
            salutation.rC_Bios__Contact__c = contactList[i].Id;
            salutationList.add(salutation);
        }
        insert salutationList;
        
        //Create Planned Giving Account
        for(Integer i=14; i<16; i++) {
            listOFPlannedGivingOnAccount.add(new rC_Giving__Planned_Giving__c(rC_Giving__Account__c = accountList.get(i).Id,rC_Giving__Giving_Amount__c =100));
            listOFPlannedGivingOnAccount.add(new rC_Giving__Planned_Giving__c(rC_Giving__Account__c = accountList.get(i).Id,rC_Giving__Giving_Amount__c =300));
        }
        insert listOFPlannedGivingOnAccount;
    }
}