/*
*
*Name  :  ZipAffiliateBatchTest
*Author:  Appirio India (Kajal Jalan)
*Date  :  October 26, 2016
*Purpose : Test Coverage for ZipAffiliateBatch
*
*/
@isTest
private class ZipAffiliateBatchTest {
    static Zip_Affiliate__c zip;
    static List<Zip_Affiliate__c> zipArray;
    
    /*
    *
    *Method testForBatch
    *Testing if Account affiliation is updated if
    *its Zif affiliate gets changed
    *
    */
    private static testMethod void testForBatch() {
        createTestData();
        Test.startTest();
        insert zipArray;
        Database.executebatch(new ZipAffiliateBatch());
        zip = [SELECT id,Affiliation__c,Chapter__c,Chapter_Changed__c,Affiliate_Changed__c
               FROM Zip_Affiliate__c WHERE name = '00001'];
        
        zip.Chapter__c = 'ALU - Auburn Chapter';
        zip.Affiliation__c = 'VT';
        update zip;
        test.stopTest();
        
        Account acco = [SELECT id ,chapter__c,Affiliation__c FROM Account WHERE BillingPostalCode = '00001'];
        System.assertEquals(acco.chapter__c,zip.Chapter__c);
        System.assertEquals(acco.Affiliation__c,zip.Affiliation__c);
        
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = System.schedule('ZipAffiliateBatch', CRON_EXP, new ZipAffiliateBatch() );
    }
    
    /*
    *
    *Method createTestData
    *Sample Data for testing
    *
    */
    private static void createTestData(){
        zipArray = new List<Zip_Affiliate__c>();
        
        for (Integer i=0;i<10;i++) {
            
            Zip_Affiliate__c m = testUtils.createZipAffiliate('0000'+i,false);
            
            m.chapter__c = 'ALC - Lincoln';
            m.Affiliation__c = 'TX';
            
            zipArray.add(m);
        }
         
        Account [] accArray = new List<Account>();
        for(Integer i =0;i<10;i++){
            Account acc = testUtils.createAccount('Acc'+i,false);
            acc.BillingPostalCode = '0000'+i;
            accArray.add(acc);
        }
        insert accArray;
    }
    
}