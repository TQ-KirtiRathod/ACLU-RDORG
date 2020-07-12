@isTest
private class TBD_BatchUpdateChapterOnAccounts_Test {

  private static testMethod void testTBD_BatchUpdateChapterOnAccounts() {
        Zip_Affiliate__c za = TestUtils.createZipAffiliate('12210',false);
        za.chapter__c = 'AKY - Fairbanks';
        insert za;
        
        List<Account> AccountList = new List<Account>();
        Account acc2 = TestUtils.createAccount('Account1',false);
        acc2.Membership_Expiration_date__c = Date.Today();
        acc2.Affiliation__c = 'NA';
        acc2.BillingPostalCode = '12210';
        acc2.Lock_Affiliation__c = false;
        acc2.Has_Renewed_Before__c = false;
        AccountList.add(acc2);
        insert accountList;
        accountList[0].chapter__c = '';
        update accountList[0];
        Database.executeBatch(new TBD_BatchUpdateChapterOnAccounts(), 50);

  }

}