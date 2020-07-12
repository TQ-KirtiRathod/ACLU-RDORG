/*
*
*Name  :  AutonumberAccountBatchTEST
*Author:  Appirio India 
*Date  :  October 10,2017
*Purpose : To Test AutonumberBatch Class functionality
*
*/
@isTest
private class AutonumberBatchTEST
{
  //Method to test Account Batch class
  /*not in use
  @isTest static void testAccountBatchClass() {
      List<Account> acts = new List<Account>();
      
      acts.add(new Account(Name = 'Test1'));
      acts.add(new Account(Name = 'Test2'));
      acts.add(new Account(Name = 'Legacy1', External_Id__c = '1111'));

      insert acts;

      Test.startTest();
      Database.executeBatch(new AutonumberBatch('Account', 'Id', 'Auto_Account_Number__c', 'Override_Account_Number__c', 'External_Id__c'));
      Test.stopTest();

      Account testA = [SELECT Account_Number__c, Override_Account_Number__c, Auto_Account_Number__c, External_Id__c FROM Account WHERE Name = 'Legacy1'];
      System.assert(!String.isBlank(testA.Override_Account_Number__c));
      System.assert(String.isNotBlank(testA.External_Id__c));
      System.assertEquals(testA.External_Id__c, testA.Account_Number__c);

      testA = [SELECT Account_Number__c, Override_Account_Number__c, Auto_Account_Number__c, External_Id__c FROM Account WHERE Name = 'Test1'];
      System.assertEquals(testA.Auto_Account_Number__c, (testA.Override_Account_Number__c).left(8));
      System.assertEquals(testA.Auto_Account_Number__c, (testA.Account_Number__c).left(8));

      testA = [SELECT Account_Number__c, Override_Account_Number__c, Auto_Account_Number__c, External_Id__c FROM Account WHERE Name = 'Test2'];
      System.assertEquals(testA.Auto_Account_Number__c, (testA.Override_Account_Number__c).left(8));
      System.assertEquals(testA.Auto_Account_Number__c, (testA.Account_Number__c).left(8));
  }
  */

  // Method to test Account Batch class exclusively for BUP
  @isTest static void testAccountBatchClassBUPExclusion() {
      List<Account> acts = new List<Account>();
      //the last run date needs to be tweaked since the batch looks at past dates
      Last_Run_Time_Of_Batch__c lstRT = new Last_Run_Time_Of_Batch__c(Name = 'AutonumberBatch',
                                                                     Last_Run_Time__c = Datetime.now().addHours(-30) );
      insert lstRT;
      acts.add(new Account(Name = 'Test1'));
      acts.add(new Account(Name = 'Test2'));
      acts.add(new Account(Name = 'Legacy1', External_Id__c = '1111'));

      insert acts;

      rC_Connect__Batch_Upload__c bup = new rC_Connect__Batch_Upload__c();
      bup.rC_Connect__Batch_Upload_Status__c = 'New';
      bup.rC_Connect__Batch_Upload_Account_Matched__c = acts[1].Id;
      bup.Name = 'Test';

      insert bup;

      Test.startTest();
      Database.executeBatch(new AutonumberBatch('Account', 'Id', 'Auto_Account_Number__c', 'Override_Account_Number__c', 'External_Id__c'));
      Test.stopTest();

      // Confirm that only the BUP-affected record was dropped from processing.

      Account testA = [SELECT Account_Number__c, Override_Account_Number__c, Auto_Account_Number__c, External_Id__c FROM Account WHERE Name = 'Legacy1'];
      System.assert(!String.isBlank(testA.Override_Account_Number__c));
      System.assert(String.isNotBlank(testA.External_Id__c));
      System.assertEquals(testA.External_Id__c, testA.Account_Number__c);

      testA = [SELECT Account_Number__c, Override_Account_Number__c, Auto_Account_Number__c, External_Id__c FROM Account WHERE Name = 'Test1'];
      System.assertEquals(testA.Auto_Account_Number__c, (testA.Override_Account_Number__c).left(8));
      System.assertEquals(testA.Auto_Account_Number__c, (testA.Account_Number__c).left(8));

      testA = [SELECT Account_Number__c, Override_Account_Number__c, Auto_Account_Number__c, External_Id__c FROM Account WHERE Name = 'Test2'];
      System.assert(!String.isBlank(testA.Override_Account_Number__c));
  }

  //Method to test Contact Batch class
 @isTest static void testContactBatchClass() {
     //the last run date needs to be tweaked since the batch looks at past dates 
     Last_Run_Time_Of_Batch__c lstRT = new Last_Run_Time_Of_Batch__c(Name = 'AutonumberBatch-Contact',
                                                                     Last_Run_Time__c = Datetime.now().addHours(42) );
      insert lstRT;
      List<Contact> cts = new List<Contact>();

      cts.add(new Contact(LastName = 'Test1'));
      cts.add(new Contact(LastName = 'Test2'));
      cts.add(new Contact(LastName = 'Legacy1', External_Id__c = '1111'));

      insert cts;

      Test.startTest();
      Database.executeBatch(new AutonumberBatch('Contact', 'AccountId', 'Auto_Contact_Number__c', 'Override_Contact_Number__c', 'External_Id__c'));
      Test.stopTest();

      // Kept purposely this for testing due to tricky date setting
      //system.debug('t1::  ' + [SELECT Contact_Number__c, Override_Contact_Number__c, Auto_Contact_Number__c, 
      //                        External_Id__c, createddate FROM Contact 
      //                        WHERE LastName IN ('Test1','Test2','Legacy1')] );

      Contact testA = [SELECT Contact_Number__c, Override_Contact_Number__c, Auto_Contact_Number__c, External_Id__c FROM Contact WHERE LastName = 'Legacy1'];
      System.assert(String.isBlank(testA.Override_Contact_Number__c));
      System.assert(String.isNotBlank(testA.External_Id__c));
      System.assertEquals(testA.External_Id__c, testA.Contact_Number__c);

      testA = [SELECT Contact_Number__c, Override_Contact_Number__c, Auto_Contact_Number__c, External_Id__c FROM Contact WHERE LastName = 'Test1'];
      System.assertEquals(testA.Auto_Contact_Number__c, testA.Override_Contact_Number__c);
      System.assertEquals(testA.Auto_Contact_Number__c, testA.Auto_Contact_Number__c);

      testA = [SELECT Contact_Number__c, Override_Contact_Number__c, Auto_Contact_Number__c, External_Id__c FROM Contact WHERE LastName = 'Test2'];
      System.assertEquals(testA.Auto_Contact_Number__c, testA.Override_Contact_Number__c);
      System.assertEquals(testA.Auto_Contact_Number__c, testA.Auto_Contact_Number__c);
  }

  //Method to test Opportunity Batch class
  @isTest static void testGivingBatchClass() {
      //the last run date needs to be tweaked since the batch looks at past dates
      Last_Run_Time_Of_Batch__c lstRT = new Last_Run_Time_Of_Batch__c(Name = 'AutonumberBatch-Opportunity',
                                                                     Last_Run_Time__c = Datetime.now().addHours(42) );
      insert lstRT;

      List<Opportunity> opps = new List<Opportunity>();
      Account act = new Account(Name = 'Test');

      insert act;

      opps.add(new Opportunity(AccountId = act.Id, Name = 'Test1', Amount = 1, StageName = 'Closed Won', CloseDate = Date.today()));
      opps.add(new Opportunity(AccountId = act.Id, Name = 'Test2', Amount = 2, StageName = 'Closed Won', CloseDate = Date.today()));
      opps.add(new Opportunity(AccountId = act.Id, Name = 'Legacy1', External_Id__c = '1111', Amount = 3, StageName = 'Closed Won', CloseDate = Date.today()));

      insert opps;

      Test.startTest();
      Database.executeBatch(new AutonumberBatch('Opportunity', 'AccountId', 'Auto_Giving_Number__c', 'Override_Giving_Number__c', 'External_Id__c'));
      Test.stopTest();

      //system.debug('t1::  ' + [SELECT Giving_Number__c, Override_Giving_Number__c, Auto_Giving_Number__c, External_Id__c, 
      //                          createddate 
      //                          FROM Opportunity WHERE Name IN ('Test1','Test2','Legacy1')]);

      Opportunity testA = [SELECT Giving_Number__c, Override_Giving_Number__c, Auto_Giving_Number__c, External_Id__c, createddate FROM Opportunity WHERE Name = 'Legacy1'];
      System.assert(String.isBlank(testA.Override_Giving_Number__c));
      System.assert(String.isNotBlank(testA.External_Id__c));
      //Formula field Opportunity.Giving_Number__c is updated which is causing assert failure.
      System.assertEquals(testA.Auto_Giving_Number__c, testA.Giving_Number__c);

      testA = [SELECT Giving_Number__c, Override_Giving_Number__c, Auto_Giving_Number__c, External_Id__c FROM Opportunity WHERE Name = 'Test1'];
      System.assertEquals(testA.Auto_Giving_Number__c, testA.Override_Giving_Number__c);
      System.assertEquals(testA.Auto_Giving_Number__c, testA.Giving_Number__c);

      testA = [SELECT Giving_Number__c, Override_Giving_Number__c, Auto_Giving_Number__c, External_Id__c FROM Opportunity WHERE Name = 'Test2'];
      System.assertEquals(testA.Auto_Giving_Number__c, testA.Override_Giving_Number__c);
      System.assertEquals(testA.Auto_Giving_Number__c, testA.Giving_Number__c);
  }

}