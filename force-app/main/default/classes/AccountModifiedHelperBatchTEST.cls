@isTest
private class AccountModifiedHelperBatchTEST {
    /*@testSetup
    public static void setup() {
        Last_Run_Time_Of_Batch__c lstRT = new Last_Run_Time_Of_Batch__c(Name = 'AccountModifiedHelperBatch', 
                                                                        Last_Run_Time__c = Date.newInstance(2012,11,23));
        insert lstRT;
    }*/
    
    public static TestMethod void testRDAmountsPropagation1(){
        Test.startTest();
        Database.executeBatch(new AccountModifiedHelperBatch());
        Test.stopTest();
        system.assertEquals(0, [SELECT Id FROM Account].size());
    }
    
    public static TestMethod void testRDAmountsPropagation2(){
        Last_Run_Time_Of_Batch__c lstRT = new Last_Run_Time_Of_Batch__c(Name = 'AccountModifiedHelperBatch');
        insert lstRT;
        Test.startTest();
        Database.executeBatch(new AccountModifiedHelperBatch());
        Test.stopTest();
        system.assertEquals(0, [SELECT Id FROM Account].size());
    }
    
	public static TestMethod void testRDAmountsPropagation3() {
        Account a = new Account(Name='q');

        insert a;

        Account a2 = new Account(Name='q2');

        insert a2;

        List<Contact> cs = new List<Contact> {
        new Contact(LastName='Test1', AccountId = a.Id),
        new Contact(LastName='Test2', AccountId = a.Id)
        };

        insert cs;

        Contact c3 = new Contact(LastName='Test3', AccountId = a2.Id);

        insert c3;

        a.GOL_Current_Amount__c = 1;
        a.HPC36_Amount__c = 2;

        Last_Run_Time_Of_Batch__c lstRT = new Last_Run_Time_Of_Batch__c(Name = 'AccountModifiedHelperBatch', 
                                                                        Last_Run_Time__c = Date.newInstance(2012,11,23));
        insert lstRT;
        
        Test.startTest();
        update a;
        Database.executeBatch(new AccountModifiedHelperBatch());
        Test.stopTest();

        cs = [SELECT GOL_Current_Amount__c, HPC36_Amount__c FROM Contact WHERE AccountId = :a.Id];

        for (Contact c : cs) {
            System.assertEquals(a.GOL_Current_Amount__c, c.GOL_Current_Amount__c);
            System.assertEquals(a.HPC36_Amount__c, c.HPC36_Amount__c);
        }

        c3 = [SELECT GOL_Current_Amount__c, HPC36_Amount__c FROM Contact WHERE Id = :c3.Id];

        System.assertEquals(null, c3.GOL_Current_Amount__c);
        System.assertEquals(null, c3.HPC36_Amount__c);
    }
    
    public static TestMethod void testScheduler() {
        String jobId = System.schedule('Test', '0 0 23 * * ?', new AccountModifiedHelperBatch_Schedule());
        system.assert(jobId != null);
    }
}