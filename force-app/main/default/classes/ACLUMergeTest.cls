/*
* Developer     : Dave Seidman
* Created Date  : August 15, 2019
* Description   : Test class for the ACLUMerge class; for achieving code coverage w/o having to run ACLUMergeManager tests;
*                 Detailed functional and unit testing is achieved through ACLUMergeManager;
*                 ACLUMerge is only directly called via the ACLUMergeManagerTest methods that focus on Account merges, necessitating this simple test class to
*                 achieve code coverage for all of ACLUMerge
*/

@isTest
public with sharing class ACLUMergeTest {
     static testmethod void codeCoverageForACLUMerge_Accounts() {
        ACLUMerge aMerge = new ACLUMerge();
        
        List<Account> accounts = new List<Account>();
        Account acct1 = TestUtils.createAccount('Test 1', TRUE);
        Account acct2 = TestUtils.createAccount('Test 2', TRUE);

        String queryAccount = Utilities.getQueryOfAllFields('Account');
        
        accounts = database.query(queryAccount);
        Account masterAccount = accounts[0];
        List<Account> mergedAccounts = new List<Account>{accounts[1]};
        Set<Id> mergedAccountIds = new Set<Id>{accounts[1].Id};

        Test.startTest();
        aMerge.beforeMerge('001',masterAccount,mergedAccounts);
        aMerge.afterMerge('001',masterAccount,mergedAccountIds);
        Test.stopTest();
    }
    static testmethod void codeCoverageForACLUMerge_Contacts() {
        ACLUMerge aMerge = new ACLUMerge();
        
        List<Contact> contacts = new List<Contact>();
        Account acct = TestUtils.createAccount('Test 1', TRUE);
 
        Contact con1 = TestUtils.createContact(acct, 'J', 'Winner', false);
        Contact con2 = TestUtils.createContact(acct, 'J', 'Loser', false);
        contacts.add(con1);
        contacts.add(con2);
        insert contacts;

        String queryContact = Utilities.getQueryOfAllFields('Contact');
        
        contacts = database.query(queryContact);
        Contact masterContact = contacts[0];
        List<Contact> mergedContacts = new List<Contact>{contacts[1]};
        Set<Id> mergedContactIds = new Set<Id>{contacts[1].Id};

        Test.startTest();
        aMerge.beforeMerge('003',masterContact,mergedContacts);
        aMerge.afterMerge('003',masterContact,mergedContactIds);
        Test.stopTest();
   }
   
   static testmethod void codeCoverageForACLUMerge_Emails() {
        ACLUMerge aMerge = new ACLUMerge();
        String emailPrefix = Utilities.getObjectPrefix('Email__c');

        List<Email__c> emails = ACLUMergeManagerTest.testEmailSetup(FALSE, 0, FALSE);
  
        String queryEmail = Utilities.getQueryOfAllFields('Email__c');
        String queryContact = Utilities.getQueryOfAllFields('Contact');
        
        emails = database.query(queryEmail);
        Email__c masterEmail = emails[0];
        List<Email__c> mergedEmails = new List<Email__c>{emails[1]};
        Set<Id> mergedEmailIds = new Set<Id>{emails[1].Id};

        Test.startTest();
        aMerge.beforeMerge(emailPrefix,masterEmail,mergedEmails);
        aMerge.afterMerge(emailPrefix,masterEmail,mergedEmailIds);
        Test.stopTest();
   }

   static testmethod void codeCoverageForACLUMerge_Phones() {
        ACLUMerge aMerge = new ACLUMerge();
        String phonePrefix = Utilities.getObjectPrefix('Phone__c');

        List<Phone__c> phones = ACLUMergeManagerTest.testPhoneSetup(TRUE, 1, 2, FALSE);

        String queryPhone = Utilities.getQueryOfAllFields('Phone__c');
        
        phones = database.query(queryPhone);
        Phone__c masterPhone = phones[0];
        Set<Id> mergedPhoneIds = new Set<Id>{phones[1].Id};

        Test.startTest();
        aMerge.afterMerge(phonePrefix,masterPhone,mergedPhoneIds);
        Test.stopTest();
   }

}