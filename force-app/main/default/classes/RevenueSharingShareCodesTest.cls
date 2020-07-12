/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 *	Ticket 		Modified Date		Modified by				Purpose
 *   #75631        04/07/2020        SFDO                    Sharing Code Entity Override on campaign
 */
@isTest
private class RevenueSharingShareCodesTest {
    private static User usr;
    private static User usr1;
    public static List<Account> Accounts;
    public static List<Campaign> Campaigns ;
    public static List<Opportunity> listOpps;
    public static Id pledgeOppId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
    public static Id pledgeOppPaymentId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    
    
    static testmethod void setGCLCodeTest() {
       List<Opportunity> opp = new List<Opportunity>();
       List<Campaign> camp   = new List<Campaign>();
       setup(); 

    }

    
    /*Set Expiration Date*/
    static testmethod void setExpirationDateTest() { 
        List<Account> accs = new List<Account>();
        Date expirationDate = Date.today();
        Date futureCloseDate = Date.today().addMonths(4);
        Date prevCloseDate = Date.today().addMonths(-1);
        setup(); 
        Test.startTest();
        for(Account acc: [SELECT id,Name FROM Account limit 15]){
            accs.add(acc);
        }
         
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        // Here the conditions are based on the Shraing code of the Opp records. refer to the RevenueSharingShareCodes class. 
        usr1 = TestUtils.createUser('use11', 'usert2@aclu.org' + Math.random(), null, false);
        usr1.Is_Affiliate_User__c = false;
        usr1.Denied_Access_to_Open_Givings__c = false;
        usr1.Email = 'usertes2@aclu.org';
        insert usr1;
        Account acc = TestUtils.createAccount('Account123',false);
            //acc.Membership_Expiration_date__c = Date.Today();
            acc.Affiliation__c = 'NN';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            acc.Has_Renewed_Before__c = false;
            insert acc; 
           
        System.runAs(usr1){
            map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
            Opportunity opp= CreateOpportunity(accs[0].Id,'Test'+accs[0].Name,prevCloseDate,'A002', '1', 'A', false);
            Opportunity opp1= CreateOpportunity(accs[1].Id,'Test'+accs[1].Name,futureCloseDate,'E131', '1', null, false);
            Opportunity opp2= CreateOpportunity(accs[2].Id,'Test'+accs[2].Name,futureCloseDate,'A003', '1', null, false);
            Opportunity opp3= CreateOpportunity(accs[3].Id,'Test'+accs[3].Name,futureCloseDate,'A003', '1', null, false);
            Opportunity opp4= CreateOpportunity(accs[4].Id,'Test'+accs[4].Name,futureCloseDate,'A001', '1', null, false);
            Opportunity opp5= CreateOpportunity(accs[5].Id,'Test'+accs[5].Name,expirationDate,'P003',  '1', null, false);
            Opportunity opp6= CreateOpportunity(accs[6].Id,'Test'+accs[6].Name,futureCloseDate,'D009', '1', null, false);
            Opportunity opp7= CreateOpportunity(accs[7].Id,'Test'+accs[7].Name,futureCloseDate,'B003', '1', null, false);
            Opportunity opp8= CreateOpportunity(accs[8].Id,'Test'+accs[8].Name,futureCloseDate,'A002', '1', 'A', false);
            Opportunity opp9= CreateOpportunity(accs[9].Id,'Test'+accs[9].Name,futureCloseDate,'A002', '2', 'V', false);
            Opportunity opp10= CreateOpportunity(acc.Id,'Test'+acc.Name,futureCloseDate,'E181', '1', 'A', false);
            List<Opportunity> oppList = new List<Opportunity>{opp,opp1,opp2,opp3,opp4,opp5,opp6,opp7,opp8,opp9,opp10};
            insert oppList;
        }    
        
        Test.stopTest();

        system.assertEquals(Date.today(),[SELECT Id,Membership_Expiration_date__c FROM Account WHERE Id = : accs[4].Id Limit 1].Membership_Expiration_date__c);

    }
    
    // DS Rules 1-4
    static testMethod void setSharingCodeTest_01() {
        // Method variables
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();

        //Source Codes insert
        // Load the StaticResource records from the static resource          
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        usr = RevSharingTestDataGenerator.createAndInsertTestUser();
    
        System.runAs(usr){
            RevSharingTestDataGenerator.createOpptyRecordsForSharingCode_01();
        }    

        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id, Name, rC_Giving__Primary_Membership_Expiration_Date__c, Membership_Expiration_date__c, Has_Renewed_Before__c, Last_Membership_Gift__r.amount, Last_Membership_Gift__r.rC_Giving__Giving_Amount__c, Last_Membership_Gift__r.closeDate, Last_Membership_Gift__r.Sharing_Code__c, Last_Membership_Gift__r.Sharing_Entity__c, 
                         (select id,rC_Bios__Code_Value__c FROM rC_Bios__Preferences__r WHERE rC_Bios__Code_Value__c = 'NM' OR rC_Bios__Code_Value__c = 'AL')
                            FROM Account]);
        list<Opportunity> oppList = [SELECT Id,  rC_Giving__Parent__c, RecordTypeId, CampaignIdText__c, Name,Sharing_Code_Override__c,Deposit_Site__c, 
                                                 rC_Giving__Source_Code__c, closeDate, accountId, Sharing_Code__c,Campaign_Type__c, Program_Type__c, 
                                                 Sharing_Code_Description__c, Sharing_Entity_Affiliation__c, Sharing_Entity__c, Amount 
                                                 FROM Opportunity 
                                                 Where Sharing_Code__c != 'A' AND
                                                 Recordtype.name = 'Pledge Payment'];
       for(Opportunity opp: [Select Id,Sharing_Code__c, Name FROM Opportunity WHERE Sharing_Code__c != NULL]){
            if( mapShareCodes.containsKey(opp.name)){
                system.assertEquals( mapShareCodes.get(opp.name).Share_Code__c, opp.Sharing_Code__c);
                System.debug(LoggingLevel.ERROR,'Assert'+ mapShareCodes.get(opp.name).Share_Code__c+' = '+ opp.Sharing_Code__c +'-'+ (mapShareCodes.get(opp.name).Share_Code__c == opp.Sharing_Code__c)+'>>'+opp.Name);
            }
            
            
        }
        
    }

    // DS Rules 5-8
    static testMethod void setSharingCodeTest_02() {
        // Method variables
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();

        //Source Codes insert
        // Load the StaticResource records from the static resource          
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        usr = RevSharingTestDataGenerator.createAndInsertTestUser();

        Test.StartTest();
        System.runAs(usr){
            RevSharingTestDataGenerator.createOpptyRecordsForSharingCode_02();
        }    
        Test.stopTest(); 
        
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id, Name, rC_Giving__Primary_Membership_Expiration_Date__c, Membership_Expiration_date__c, Has_Renewed_Before__c, Last_Membership_Gift__r.amount, Last_Membership_Gift__r.rC_Giving__Giving_Amount__c, Last_Membership_Gift__r.closeDate, Last_Membership_Gift__r.Sharing_Code__c, Last_Membership_Gift__r.Sharing_Entity__c, 
                         (select id,rC_Bios__Code_Value__c FROM rC_Bios__Preferences__r WHERE rC_Bios__Code_Value__c = 'NM' OR rC_Bios__Code_Value__c = 'AL')
                            FROM Account]);
        list<Opportunity> oppList = [SELECT Id,  rC_Giving__Parent__c, RecordTypeId, CampaignIdText__c, Name,Sharing_Code_Override__c,Deposit_Site__c, 
                                                 rC_Giving__Source_Code__c, closeDate, accountId, Sharing_Code__c,Campaign_Type__c, Program_Type__c, 
                                                 Sharing_Code_Description__c, Sharing_Entity_Affiliation__c, Sharing_Entity__c, Amount 
                                                 FROM Opportunity 
                                                 Where Sharing_Code__c != 'A' AND
                                                 Recordtype.name = 'Pledge Payment'];
        for(Opportunity opp: [Select Id,Sharing_Code__c, Name FROM Opportunity WHERE Sharing_Code__c != NULL]){
            if( mapShareCodes.containsKey(opp.name)){
                system.assertEquals( mapShareCodes.get(opp.name).Share_Code__c, opp.Sharing_Code__c);
                System.debug(LoggingLevel.ERROR,'Assert'+ mapShareCodes.get(opp.name).Share_Code__c+' = '+ opp.Sharing_Code__c +'-'+ (mapShareCodes.get(opp.name).Share_Code__c == opp.Sharing_Code__c)+'>>'+opp.Name);
            }
                       
        }
        
    }

    // DS Rules 9-11
    static testMethod void setSharingCodeTest_03() {
        // Method variables
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();

        //Source Codes insert
        // Load the StaticResource records from the static resource          
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        usr = RevSharingTestDataGenerator.createAndInsertTestUser();

        Test.StartTest();
        System.runAs(usr){
            RevSharingTestDataGenerator.createOpptyRecordsForSharingCode_03();
        }    
        Test.stopTest(); 
        
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id, Name, rC_Giving__Primary_Membership_Expiration_Date__c, Membership_Expiration_date__c, Has_Renewed_Before__c, Last_Membership_Gift__r.amount, Last_Membership_Gift__r.rC_Giving__Giving_Amount__c, Last_Membership_Gift__r.closeDate, Last_Membership_Gift__r.Sharing_Code__c, Last_Membership_Gift__r.Sharing_Entity__c, 
                         (select id,rC_Bios__Code_Value__c FROM rC_Bios__Preferences__r WHERE rC_Bios__Code_Value__c = 'NM' OR rC_Bios__Code_Value__c = 'AL')
                            FROM Account]);
        list<Opportunity> oppList = [SELECT Id,  rC_Giving__Parent__c, RecordTypeId, CampaignIdText__c, Name,Sharing_Code_Override__c,Deposit_Site__c, 
                                                 rC_Giving__Source_Code__c, closeDate, accountId, Sharing_Code__c,Campaign_Type__c, Program_Type__c, 
                                                 Sharing_Code_Description__c, Sharing_Entity_Affiliation__c, Sharing_Entity__c, Amount 
                                                 FROM Opportunity 
                                                 Where Sharing_Code__c != 'A' AND
                                                 Recordtype.name = 'Pledge Payment'];
        for(Opportunity opp: [Select Id,Sharing_Code__c, Name FROM Opportunity WHERE Sharing_Code__c != NULL]){
            if( mapShareCodes.containsKey(opp.name)){
                system.assertEquals( mapShareCodes.get(opp.name).Share_Code__c, opp.Sharing_Code__c);
                System.debug(LoggingLevel.ERROR,'Assert'+ mapShareCodes.get(opp.name).Share_Code__c+' = '+ opp.Sharing_Code__c +'-'+ (mapShareCodes.get(opp.name).Share_Code__c == opp.Sharing_Code__c)+'>>'+opp.Name);
            }
            
            
        }
        
    }

    // DS Rules 12-14
    static testMethod void setSharingCodeTest_04() {
        // Method variables
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();

        //Source Codes insert
        // Load the StaticResource records from the static resource          
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        usr = RevSharingTestDataGenerator.createAndInsertTestUser();

        Test.StartTest();
        System.runAs(usr){
            RevSharingTestDataGenerator.createOpptyRecordsForSharingCode_04();
        }    
        Test.stopTest(); 
        
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id, Name, rC_Giving__Primary_Membership_Expiration_Date__c, Membership_Expiration_date__c, Has_Renewed_Before__c, Last_Membership_Gift__r.amount, Last_Membership_Gift__r.rC_Giving__Giving_Amount__c, Last_Membership_Gift__r.closeDate, Last_Membership_Gift__r.Sharing_Code__c, Last_Membership_Gift__r.Sharing_Entity__c, 
                         (select id,rC_Bios__Code_Value__c FROM rC_Bios__Preferences__r WHERE rC_Bios__Code_Value__c = 'NM' OR rC_Bios__Code_Value__c = 'AL')
                            FROM Account]);
        list<Opportunity> oppList = [SELECT Id,  rC_Giving__Parent__c, RecordTypeId, CampaignIdText__c, Name,Sharing_Code_Override__c,Deposit_Site__c, 
                                                 rC_Giving__Source_Code__c, closeDate, accountId, Sharing_Code__c,Campaign_Type__c, Program_Type__c, 
                                                 Sharing_Code_Description__c, Sharing_Entity_Affiliation__c, Sharing_Entity__c, Amount 
                                                 FROM Opportunity 
                                                 Where Sharing_Code__c != 'A' AND
                                                 Recordtype.name = 'Pledge Payment'];
        for(Opportunity opp: [Select Id,Sharing_Code__c, Name FROM Opportunity WHERE Sharing_Code__c != NULL]){
            if( mapShareCodes.containsKey(opp.name)){
                system.assertEquals( mapShareCodes.get(opp.name).Share_Code__c, opp.Sharing_Code__c);
                System.debug(LoggingLevel.ERROR,'Assert'+ mapShareCodes.get(opp.name).Share_Code__c+' = '+ opp.Sharing_Code__c +'-'+ (mapShareCodes.get(opp.name).Share_Code__c == opp.Sharing_Code__c)+'>>'+opp.Name);
            }
            
            
        }
    }


    // DS Rules 20-23 (15-19;21 not previously tested)
    static testMethod void setSharingCodeTest_05() {
        // Method variables
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();

        //Source Codes insert
        // Load the StaticResource records from the static resource          
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        usr = RevSharingTestDataGenerator.createAndInsertTestUser();

        Test.StartTest();
        System.runAs(usr){
            RevSharingTestDataGenerator.createOpptyRecordsForSharingCode_05();
        }    
        Test.stopTest(); 
        
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id, Name, rC_Giving__Primary_Membership_Expiration_Date__c, Membership_Expiration_date__c, Has_Renewed_Before__c, Last_Membership_Gift__r.amount, Last_Membership_Gift__r.rC_Giving__Giving_Amount__c, Last_Membership_Gift__r.closeDate, Last_Membership_Gift__r.Sharing_Code__c, Last_Membership_Gift__r.Sharing_Entity__c, 
                         (select id,rC_Bios__Code_Value__c FROM rC_Bios__Preferences__r WHERE rC_Bios__Code_Value__c = 'NM' OR rC_Bios__Code_Value__c = 'AL')
                            FROM Account]);
        list<Opportunity> oppList = [SELECT Id,  rC_Giving__Parent__c, RecordTypeId, CampaignIdText__c, Name,Sharing_Code_Override__c,Deposit_Site__c, 
                                                 rC_Giving__Source_Code__c, closeDate, accountId, Sharing_Code__c,Campaign_Type__c, Program_Type__c, 
                                                 Sharing_Code_Description__c, Sharing_Entity_Affiliation__c, Sharing_Entity__c, Amount 
                                                 FROM Opportunity 
                                                 Where Sharing_Code__c != 'A' AND
                                                 Recordtype.name = 'Pledge Payment'];
        for(Opportunity opp: [Select Id,Sharing_Code__c, Name FROM Opportunity WHERE Sharing_Code__c != NULL]){
            if( mapShareCodes.containsKey(opp.name)){
                system.assertEquals( mapShareCodes.get(opp.name).Share_Code__c, opp.Sharing_Code__c);
                System.debug(LoggingLevel.ERROR,'Assert'+ mapShareCodes.get(opp.name).Share_Code__c+' = '+ opp.Sharing_Code__c +'-'+ (mapShareCodes.get(opp.name).Share_Code__c == opp.Sharing_Code__c)+'>>'+opp.Name);
            }
            
            
        }
    }
    
    // DS Rules 24-28
    static testMethod void setSharingCodeTest_06() {
        // Method variables
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();

        //Source Codes insert
        // Load the StaticResource records from the static resource          
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        usr = RevSharingTestDataGenerator.createAndInsertTestUser();

        Test.StartTest();
        System.runAs(usr){
            RevSharingTestDataGenerator.createOpptyRecordsForSharingCode_06();
        }    
        Test.stopTest(); 
        
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id, Name, rC_Giving__Primary_Membership_Expiration_Date__c, Membership_Expiration_date__c, Has_Renewed_Before__c, Last_Membership_Gift__r.amount, Last_Membership_Gift__r.rC_Giving__Giving_Amount__c, Last_Membership_Gift__r.closeDate, Last_Membership_Gift__r.Sharing_Code__c, Last_Membership_Gift__r.Sharing_Entity__c, 
                         (select id,rC_Bios__Code_Value__c FROM rC_Bios__Preferences__r WHERE rC_Bios__Code_Value__c = 'NM' OR rC_Bios__Code_Value__c = 'AL')
                            FROM Account]);
        list<Opportunity> oppList = [SELECT Id,  rC_Giving__Parent__c, RecordTypeId, CampaignIdText__c, Name,Sharing_Code_Override__c,Deposit_Site__c, 
                                                 rC_Giving__Source_Code__c, closeDate, accountId, Sharing_Code__c,Campaign_Type__c, Program_Type__c, 
                                                 Sharing_Code_Description__c, Sharing_Entity_Affiliation__c, Sharing_Entity__c, Amount 
                                                 FROM Opportunity 
                                                 Where Sharing_Code__c != 'A' AND
                                                 Recordtype.name = 'Pledge Payment'];
                                                 
        for(Opportunity opp: [Select Id,Sharing_Code__c, Name FROM Opportunity WHERE Sharing_Code__c != NULL]){
            if( mapShareCodes.containsKey(opp.name)){
                system.assertEquals( mapShareCodes.get(opp.name).Share_Code__c, opp.Sharing_Code__c);
                System.debug(LoggingLevel.ERROR,'Assert'+ mapShareCodes.get(opp.name).Share_Code__c+' = '+ opp.Sharing_Code__c +'-'+ (mapShareCodes.get(opp.name).Share_Code__c == opp.Sharing_Code__c)+'>>'+opp.Name);
            }
            
            
        }
    }

    // DS Rules 29-33
    static testMethod void setSharingCodeTest_07() {
        // Method variables
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();

        //Source Codes insert
        // Load the StaticResource records from the static resource          
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        usr = RevSharingTestDataGenerator.createAndInsertTestUser();

        Test.StartTest();
        System.runAs(usr){
            RevSharingTestDataGenerator.createOpptyRecordsForSharingCode_07();
        }    
        Test.stopTest(); 
        
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id, Name, rC_Giving__Primary_Membership_Expiration_Date__c, Membership_Expiration_date__c, Has_Renewed_Before__c, Last_Membership_Gift__r.amount, Last_Membership_Gift__r.rC_Giving__Giving_Amount__c, Last_Membership_Gift__r.closeDate, Last_Membership_Gift__r.Sharing_Code__c, Last_Membership_Gift__r.Sharing_Entity__c, 
                         (select id,rC_Bios__Code_Value__c FROM rC_Bios__Preferences__r WHERE rC_Bios__Code_Value__c = 'NM' OR rC_Bios__Code_Value__c = 'AL')
                            FROM Account]);
        list<Opportunity> oppList = [SELECT Id,  rC_Giving__Parent__c, RecordTypeId, CampaignIdText__c, Name,Sharing_Code_Override__c,Deposit_Site__c, 
                                                 rC_Giving__Source_Code__c, closeDate, accountId, Sharing_Code__c,Campaign_Type__c, Program_Type__c, 
                                                 Sharing_Code_Description__c, Sharing_Entity_Affiliation__c, Sharing_Entity__c, Amount 
                                                 FROM Opportunity 
                                                 Where Sharing_Code__c != 'A' AND
                                                 Recordtype.name = 'Pledge Payment'];
        for(Opportunity opp: [Select Id,Sharing_Code__c, Name FROM Opportunity WHERE Sharing_Code__c != NULL]){
            if( mapShareCodes.containsKey(opp.name)){
                system.assertEquals( mapShareCodes.get(opp.name).Share_Code__c, opp.Sharing_Code__c);
                System.debug(LoggingLevel.ERROR,'Assert'+ mapShareCodes.get(opp.name).Share_Code__c+' = '+ opp.Sharing_Code__c +'-'+ (mapShareCodes.get(opp.name).Share_Code__c == opp.Sharing_Code__c)+'>>'+opp.Name);
            }
            
            
        }
    }

 // DS Rules 34-37
    static testMethod void setSharingCodeTest_08() {
        // Method variables
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();

        //Source Codes insert
        // Load the StaticResource records from the static resource          
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        usr = RevSharingTestDataGenerator.createAndInsertTestUser();

        Test.StartTest();
        System.runAs(usr){
            RevSharingTestDataGenerator.createOpptyRecordsForSharingCode_08();
        }    
        Test.stopTest(); 
        
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id, Name, rC_Giving__Primary_Membership_Expiration_Date__c, Membership_Expiration_date__c, Has_Renewed_Before__c, Last_Membership_Gift__r.amount, Last_Membership_Gift__r.rC_Giving__Giving_Amount__c, Last_Membership_Gift__r.closeDate, Last_Membership_Gift__r.Sharing_Code__c, Last_Membership_Gift__r.Sharing_Entity__c, 
                         (select id,rC_Bios__Code_Value__c FROM rC_Bios__Preferences__r WHERE rC_Bios__Code_Value__c = 'NM' OR rC_Bios__Code_Value__c = 'AL')
                            FROM Account]);
        list<Opportunity> oppList = [SELECT Id,  rC_Giving__Parent__c, RecordTypeId, CampaignIdText__c, Name,Sharing_Code_Override__c,Deposit_Site__c, 
                                                 rC_Giving__Source_Code__c, closeDate, accountId, Sharing_Code__c,Campaign_Type__c, Program_Type__c, 
                                                 Sharing_Code_Description__c, Sharing_Entity_Affiliation__c, Sharing_Entity__c, Amount 
                                                 FROM Opportunity 
                                                 Where Sharing_Code__c != 'A' AND
                                                 Recordtype.name = 'Pledge Payment'];
        for(Opportunity opp: [Select Id,Sharing_Code__c, Name FROM Opportunity WHERE Sharing_Code__c != NULL]){
            if( mapShareCodes.containsKey(opp.name)){
                system.assertEquals( mapShareCodes.get(opp.name).Share_Code__c, opp.Sharing_Code__c);
                System.debug(LoggingLevel.ERROR,'Assert'+ mapShareCodes.get(opp.name).Share_Code__c+' = '+ opp.Sharing_Code__c +'-'+ (mapShareCodes.get(opp.name).Share_Code__c == opp.Sharing_Code__c)+'>>'+opp.Name);
            }
            
            
        }
    }

    /*Additional GCS Codes*/
    
    static testMethod void setSharingCodeGCSTest_CampaignType_T() {
        // Method variables
        List<Account> accs = new List<Account>();
        
        Test.startTest();
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        usr = TestUtils.createUser('userTest', 'usert25@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertes25@aclu.org';
        insert usr;
        System.runAs(usr){
            RevSharingTestDataGenerator.additionalGCLCodesRecords_CampaignType_T();
        }    
        Test.stopTest(); 
        
        list<Opportunity> oppList = [SELECT Id,  rC_Giving__Parent__c, Account_Affiliation__c, RecordTypeId, CampaignIdText__c, Name,Sharing_Code_Override__c,Deposit_Site__c, rC_Giving__Source_Code__c, closeDate, accountId, Sharing_Code__c,Campaign_Type__c, Program_Type__c, Sharing_Code_Description__c, Sharing_Entity_Affiliation__c, Sharing_Entity__c, Amount FROM Opportunity where Sharing_Code__c != 'A'];
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        List<Opportunity> oppsShareCodePopulated = RevenueSharingShareCodes.setShareCode(oppList);
        
        for(Opportunity opp: oppsShareCodePopulated){
            if(opp.name == 'T'){ 
                system.assertEquals( 'T400', opp.Sharing_Code__c);
            }
        }
    }
    
    static testMethod void setSharingCodeGCSTest_CampaignType_1() {
        // Method variables
        List<Account> accs = new List<Account>();
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        usr = TestUtils.createUser('userTest', 'usert25@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertes25@aclu.org';
        insert usr;
        
        Campaign objCampaign = TestUtils.createCampaign('Testcampaign',false);
        objCampaign.Bequest_Sharing_Code__c = 'Q001';
        objCampaign.rC_Giving__Sub_Affiliation__c = '4 - National Foundation';
        insert objCampaign;
        
        Account acc1 = New Account(Name = 'ExpirationDateNull&NotRenewed', Last_Membership_Gift__c = null, Affiliation__c = 'NN', Membership_Expiration_date__c = null, BillingPostalCode ='00000', BillingCountry = 'Japan',Has_Renewed_Before__c= true);
        Account nullDate_MembershipAccount = New Account(Name = 'LastMembershipGift&ExpirationNull', Last_Membership_Gift__c=null, Affiliation__c='NN', Membership_Expiration_date__c = null, BillingPostalCode='00000', BillingCountry='Japan', Has_Renewed_Before__c= false);        
        accs.add(acc1);
        accs.add(nullDate_MembershipAccount);
         
        if(!accs.IsEmpty())
            insert accs;
        //Opportunity with certain criteria
        
        Opportunity sustainerPledge = new Opportunity();
        sustainerPledge.name = 'Pledge Sustainer';
        sustainerPledge.closeDate = Date.Today();
        sustainerPledge.AccountId = accs[0].Id;
        sustainerPledge.Campaignid = objCampaign.id;
        sustainerPledge.Campaign_Type__c = 'K';
        sustainerPledge.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge.RecordtypeId = pledgeOppId;
        sustainerPledge.stageName = 'Closed';
        insert sustainerPledge;
        
        System.runAs(usr){
            Test.StartTest();
            RevSharingTestDataGenerator.additionalGCLCodesRecords_CampaignType_1(sustainerPledge,accs);
        }   Test.stopTest();

        list<Opportunity> oppList = [SELECT Id,  rC_Giving__Parent__c, Account_Affiliation__c, RecordTypeId, CampaignIdText__c, Name,Sharing_Code_Override__c,Deposit_Site__c, rC_Giving__Source_Code__c, closeDate, accountId, Sharing_Code__c,Campaign_Type__c, Program_Type__c, Sharing_Code_Description__c, Sharing_Entity_Affiliation__c, Sharing_Entity__c, Amount FROM Opportunity where Sharing_Code__c != 'A'];
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
       /* List<Opportunity> oppsShareCodePopulated = RevenueSharingShareCodes.setShareCode(oppList);
        
        for(Opportunity opp: oppsShareCodePopulated){
            if(opp.name == '1'){ 
                system.assertEquals( 'H100', opp.Sharing_Code__c);
            }
        }*/
    }

    static testMethod void setSharingCodeGCSTest_CampaignType_D() {
        // Method variables
        List<Account> accs = new List<Account>();
        
        Test.startTest();
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        usr = TestUtils.createUser('userTest', 'usert25@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertes25@aclu.org';
        insert usr;
        System.runAs(usr){
            RevSharingTestDataGenerator.additionalGCLCodesRecords_CampaignType_D();
        }    
        Test.stopTest(); 
        
        list<Opportunity> oppList = [SELECT Id, Sharing_Entity_Override__c,  rC_Giving__Parent__c, Account_Affiliation__c, RecordTypeId, CampaignIdText__c, Name,Sharing_Code_Override__c,Deposit_Site__c, rC_Giving__Source_Code__c, closeDate, accountId, Sharing_Code__c,Campaign_Type__c, Program_Type__c, Sharing_Code_Description__c, Sharing_Entity_Affiliation__c, Sharing_Entity__c, Amount FROM Opportunity where Sharing_Code__c != 'A'];
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        List<Opportunity> oppsShareCodePopulated = RevenueSharingShareCodes.setShareCode(oppList);
        
        for(Opportunity opp: oppsShareCodePopulated){
            if(opp.name == 'D'){ 
                system.assertEquals( 'Q001', opp.Sharing_Code__c);
            }
        }
    }
    
    static testMethod void additionalGCLTest() {
        // Method variables
        List<Account> accs = new List<Account>();
        
        Test.startTest();
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        usr = TestUtils.createUser('userTest', 'usert25@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertes25@aclu.org';
        insert usr;
        System.runAs(usr){
            RevSharingTestDataGenerator.additionalGCLTest();
        }    
        Test.stopTest(); 
        
        list<Opportunity> oppList = [SELECT Id, Sharing_Entity_Override__c,  rC_Giving__Parent__c, Account_Affiliation__c, RecordTypeId, CampaignIdText__c, Name,Sharing_Code_Override__c,Deposit_Site__c, rC_Giving__Source_Code__c, closeDate, accountId, Sharing_Code__c,Campaign_Type__c, Program_Type__c, Sharing_Code_Description__c, Sharing_Entity_Affiliation__c, Sharing_Entity__c, Amount FROM Opportunity where Sharing_Code__c != 'A'];
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        List<Opportunity> oppsShareCodePopulated = RevenueSharingShareCodes.setShareCode(oppList);
        
        for(Opportunity opp: oppsShareCodePopulated){
            if(opp.name == 'D1'){ 
                system.assertEquals( 'E017', opp.Sharing_Code__c);
            }
        }
    } 
    static testMethod void additionalGCLTest15_20() {
        // Method variables
        List<Account> accs = new List<Account>();
        List<Opportunity> NewOppLst = new List<Opportunity>();
        Map<id,Opportunity> oldmap = new map<id,Opportunity>();   
        Test.startTest();
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        usr = TestUtils.createUser('userTest', 'usert25@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertes25@aclu.org';
        insert usr;
        System.runAs(usr){
            RevSharingTestDataGenerator.additionalGCLTest_15_20();
        }    
        Test.stopTest(); 
        
        list<Opportunity> oppList = [SELECT Id, Sharing_Entity_Override__c,  rC_Giving__Parent__c, Account_Affiliation__c, RecordTypeId, CampaignIdText__c, Name,Sharing_Code_Override__c,Deposit_Site__c, rC_Giving__Source_Code__c, closeDate, accountId, Sharing_Code__c,Campaign_Type__c, Program_Type__c, Sharing_Code_Description__c, Sharing_Entity_Affiliation__c, Sharing_Entity__c, Amount FROM Opportunity where Sharing_Code__c != 'A'];
        map<String, Share_Source_Revenue_Codes__c> mapShareCodes = Share_Source_Revenue_Codes__c.getAll();
        List<Opportunity> oppsShareCodePopulated = RevenueSharingShareCodes.setShareCode(oppList);
         
        for(Opportunity opp: oppsShareCodePopulated){
            if(opp.name == 'D1'){ 
                system.assertEquals( 'E017', opp.Sharing_Code__c);
            }
          opp.Sharing_Code__c = 'A001';
          opp.Program_Type__c = '5';
          NewOppLst.add(opp);  
        }
         for(Opportunity opp: oppsShareCodePopulated){
          oldmap.put(opp.id,opp);
        }

        List<Opportunity> oppsflagMembership = RevenueSharingShareCodes.flagMembershipShareCodeReset(NewOppLst,oldmap);
    }
     /*
    *
    *Method setup
    *Testing if Affiliation updated then accountShare is re-calculated.
    */
    public static void setup(){
        Accounts = new List<Account>();
        listOpps = new List<Opportunity>();
        Campaigns = new List<Campaign>();
        // Account Records
        for(Integer i=0;i<10;i++){   
            Account acc = TestUtils.createAccount('Account'+i,false);
            acc.Membership_Expiration_date__c = Date.Today();
            acc.Affiliation__c = 'NN';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            acc.Has_Renewed_Before__c = false;
            
            Accounts.add(acc);
            
        }
        
        if(!Accounts.isEmpty())
            insert Accounts;
        
        List<rC_Bios__Preference__c> prefList = new LIst<rC_Bios__Preference__c>();
        rC_Bios__Preference__c bp = new rC_Bios__Preference__c();
        bp.rC_Bios__Active__c = true;
        bp.rC_Bios__Code_Value__c='AN';
        bp.rC_Bios__Account__c = Accounts[0].id;
        rC_Bios__Preference__c bp1 = new rC_Bios__Preference__c();
        bp1.rC_Bios__Active__c = true;
        bp1.rC_Bios__Code_Value__c='AN';
        bp1.rC_Bios__Account__c = Accounts[1].id;
        
        prefList.add(bp);
        prefList.add(bp1);
        insert prefList;
        // campaign Records
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        
    }
    // Not using the method present in the TestUtilis as requires custom fields for long records
    public static Opportunity createOpportunity(Id AccountId, String Name, date closeDate, String sharingCode, String programType, String campaignType, Boolean doInsert){
        Opportunity opp = new Opportunity(rC_Giving__Affiliation__c = 'NGO', Campaign_Type__c = campaignType,Program_Type__c = programType, RecordtypeId = pledgeOppPaymentId, Sharing_Code__c = sharingCode,rC_Giving__Giving_Amount__c = 20,Amount = 4, AccountId = AccountId ,Name = Name, CloseDate = closeDate, StageName = 'Completed');
        if(doInsert)
            insert opp;
        return opp;
    }
    
    // Custom setting Object Records
    public static Share_Source_Revenue_Codes__c createSourceCodes(String orderOfExecution, String shareCode, String ShareCodeDescription, Boolean doInsert){
        Share_Source_Revenue_Codes__c obj = new Share_Source_Revenue_Codes__c(Name = orderOfExecution, Share_Code__c = shareCode, Share_Code_Description__c = ShareCodeDescription);
        if(doInsert)
            insert obj;
        return obj;
    }
    public static testMethod void checkSharingCode(){
        setup();
        Accounts[0].Affiliation__c = 'AA';
        update Accounts[0];
        Opportunity opp1 = createOpportunity(Accounts[0].id,'test1', Date.today(), null, '12', 'A', false);
        opp1.Sharing_Entity_Override__c = false;
        opp1.Deposit_Site__c = 'AK_Alaska';
        Opportunity opp2 = createOpportunity(Accounts[0].id,'test2', Date.today(), null, '11', 'B', false);
        opp2.Sharing_Entity_Override__c = false;
        opp2.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        Insert new List<Opportunity>{opp1, opp2};
        RevenueSharingShareCodes.setAccountChapter(new List<Opportunity>{opp1, opp2});
        Boolean bool = RevenueSharingShareCodes.giftAfterBeginningOfRenewal(Date.today(), Date.today().addMonths(-4));
        System.assertEquals(True, bool);
    }
  
    /*Test Cast-1 & 2*******************************************************************************************************************************
        BillingPostalCode   /Lock Affiliation   /Affiliation            /Chapter                    /Result
        12210           FALSE               anything including null anything including null     Find from ZipToAffilate based on first 5 of zip
        12210-1234      FALSE               anything including null anything including null     Find from ZipToAffilate based on first 5 of zip
    */
    
    public static testMethod void testCase2(){
        Zip_Affiliate__c za = TestUtils.createZipAffiliate('12210',false);
        za.chapter__c = 'AKY - Fairbanks';
        insert za;
        
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc2 = TestUtils.createAccount('Account1',false);
        acc2.Membership_Expiration_date__c = Date.Today();
        acc2.Affiliation__c = 'NA';
        acc2.BillingPostalCode = '12210-1234';
        acc2.Lock_Affiliation__c = false;
        acc2.Has_Renewed_Before__c = false;
        acc2.chapter__c = 'AKZ - Juneau';
        AccountList.add(acc2);
        insert accountList;
        accountlist[0].Affiliation__c = 'ND';
        acc2.chapter__c = 'AKZ - Juneau';
        update accountlist[0];
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp2 = CreateOpportunity(acc2.id, 'Opp2', Date.today().addMonths(2), null, '5', 'G', false);
        opp2.deposit_site__c = 'NAX_NatU_Broadcast';
        insert opp2;
        opp2.Campaign_Type__c = '4';
        opp2.Program_Type__c = 'g';
        
        opp2.StageName = 'Completed';

        update opp2;
       // System.assertEquals('AKY', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        System.assertEquals('AKZ', [select id, Sharing_Entity__c FROM Opportunity where id =: opp2.id].Sharing_Entity__c);
    }
    public static testMethod void testCase3(){
        Zip_Affiliate__c za = TestUtils.createZipAffiliate('12210',false);
        za.chapter__c = 'AKY - Fairbanks';
        insert za;
        
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc2 = TestUtils.createAccount('Account1',false);
        acc2.Membership_Expiration_date__c = Date.Today();
        acc2.BillingPostalCode = '12210-1234';
        acc2.Lock_Affiliation__c = false;
        acc2.Has_Renewed_Before__c = false;
        acc2.chapter__c = 'AKZ - Juneau';
        AccountList.add(acc2);
        insert accountList;
        accountlist[0].Affiliation__c = '';
        acc2.chapter__c = '';
        update accountlist[0];
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp2 = CreateOpportunity(acc2.id, 'Opp2', Date.today().addMonths(2), null, '5', 'G', false);
        opp2.deposit_site__c = 'NAX_NatU_Broadcast';
        insert opp2;
        opp2.Campaign_Type__c = '4';
        opp2.Program_Type__c = 'g';
        
        opp2.StageName = 'Completed';

        update opp2;
        //System.assertEquals('AKY', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        System.assertEquals('ERROR', [select id, Sharing_Entity__c FROM Opportunity where id =: opp2.id].Sharing_Entity__c);
    }
    
    /*Test Cast-3 & 4*******************************************************************************************************************************
        BillingPostalCode   /Lock Affiliation   /Affiliation                /Chapter                    /Result
        H23J1               FALSE               anything including null     anything including null     Find from ZipToAffilate -- will be ZF / ZFA 
        H23 J14             FALSE               anything including null     anything including null     Find from ZipToAffilate -- will be ZF / ZFA 
    */
    public static testMethod void testCase3And4(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Affiliation__c = 'NN';
        acc.BillingPostalCode = 'H23J1';
        acc.Lock_Affiliation__c = false;
        acc.Has_Renewed_Before__c = false;
        AccountList.add(acc);
        Account acc2 = TestUtils.createAccount('Account1',false);
        acc2.Membership_Expiration_date__c = Date.Today();
        acc2.Affiliation__c = 'NN';
        acc2.BillingPostalCode = 'H23 J14';
        acc2.Lock_Affiliation__c = false;
        acc2.Has_Renewed_Before__c = false;
        acc2.Affiliation__c = 'CD';
        acc2.chapter__c = 'AKZ - Juneau';
        AccountList.add(acc2);
        insert accountList;
        //System.assert(false, [Select id, Chapter__c, Affiliation__c From Account where id IN: accountList]);
        Zip_Affiliate__c za = TestUtils.createZipAffiliate('00000',false);
        za.chapter__c = 'NNA - At-Large National Office ACLU';
        insert za;
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '1', 'B', false);
        Opportunity opp2 = CreateOpportunity(acc2.id, 'Opp2', Date.today().addMonths(2), null, '2', 'B', false);
        opplist.add(opp);
        oppList.add(opp2);
        insert oppList;
        opplist.clear();
        
        opp.StageName = 'Completed';
        opp2.StageName = 'Completed';
        opplist.add(opp);
        oppList.add(opp2);
        update oppList;
        System.assertEquals('ERROR', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        System.assertEquals('AKZ', [select id, Sharing_Entity__c FROM Opportunity where id =: opp2.id].Sharing_Entity__c);
    }
    
    /*Test Cast- 6 & 7*******************************************************************************************************************************
        BillingPostalCode       /Lock Affiliation   /Affiliation            /Chapter                    /Result
        anything including null TRUE                not null                not null                    Account.Affiliation / Account.Chapter
        null                    FALSE               not null                not null                    Account.Affiliation / Account.Chapter
    */
    public static testMethod void testCase6And7(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Affiliation__c = 'NN';
        acc.BillingPostalCode = '122104';
        acc.Lock_Affiliation__c = true;
        acc.Has_Renewed_Before__c = false;
        acc.Affiliation__c = 'CD';
        acc.chapter__c = 'AKZ - Juneau';
        AccountList.add(acc);
        Account acc2 = TestUtils.createAccount('Account1',false);
        acc2.Membership_Expiration_date__c = Date.Today();
        acc2.Affiliation__c = 'NN';
        //acc2.BillingPostalCode = 'H23 J14';
        acc2.Lock_Affiliation__c = false;
        acc2.Has_Renewed_Before__c = false;
        acc2.Affiliation__c = 'CD';
        acc2.chapter__c = 'AKZ - Juneau';
        AccountList.add(acc2);
        insert accountList;
        
        Zip_Affiliate__c za1 = TestUtils.createZipAffiliate('00000',false);
        za1.chapter__c = 'NNA';
        /*Zip_Affiliate__c za2 = TestUtils.createZipAffiliate('H23J1',false);
        za2.chapter__c = 'NNA';*/

        insert new List<Zip_Affiliate__c>{za1/*,za2*/};  
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '1', 'B', false);
        Opportunity opp2 = CreateOpportunity(acc2.id, 'Opp2', Date.today().addMonths(2), null, '2', 'B', false);
        opplist.add(opp);
        oppList.add(opp2);
        insert oppList;
        opplist.clear();
        
        opp.StageName = 'Completed';
        opp2.StageName = 'Completed';
        opplist.add(opp);
        oppList.add(opp2);
        update oppList;
        System.assertEquals('AKZ', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        System.assertEquals('AKZ', [select id, Sharing_Entity__c FROM Opportunity where id =: opp2.id].Sharing_Entity__c);
    }
    public static testMethod void testCase6(){
        Zip_Affiliate__c za = TestUtils.createZipAffiliate('12210',false);
        za.chapter__c = 'AKY - Fairbanks';
        insert za;
        
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Affiliation__c = 'ND';
        acc.BillingPostalCode = '1221000';
        acc.Lock_Affiliation__c = true;
        acc.Has_Renewed_Before__c = false;
        AccountList.add(acc);
        Account acc2 = TestUtils.createAccount('Account1',false);
        acc2.Membership_Expiration_date__c = Date.Today();
        acc2.Affiliation__c = 'ND';
        acc2.BillingPostalCode = '12210-1234';
        acc2.Lock_Affiliation__c = true;
        acc2.Has_Renewed_Before__c = false;
        acc2.Affiliation__c = 'ND';
        acc2.chapter__c = 'AKZ - Juneau';
        AccountList.add(acc2);
        insert accountList;
        accountlist[0].Affiliation__c = 'ND'; 
        accountlist[1].Affiliation__c = '';
        accountlist[0].Chapter__c = 'NYL - Capital Area';
        accountlist[1].Chapter__c = '';
        update accountlist;
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'g', false);
        Opportunity opp2 = CreateOpportunity(acc2.id, 'Opp2', Date.today().addMonths(2), null, '4', 'g', false);
        opp.deposit_site__c = 'NAA_NatU_Operating_chk/cash';
        opp2.deposit_site__c = 'NAA_NatU_Operating_chk/cash';
        opplist.add(opp);
        oppList.add(opp2);
        insert oppList;
        
        opplist[0].deposit_site__c = 'NAA_NatU_Operating_chk/cash';
        opplist[1].deposit_site__c = 'NAA_NatU_Operating_chk/cash';
        opplist[0].StageName = 'Completed';
        opplist[1].StageName = 'Completed';
        
        update oppList[0];
        update opplist[1];
        System.assertEquals('NYL', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        
    }

    
    
    /*Test Cast-5 *******************************************************************************************************************************
        BillingPostalCode       /Lock Affiliation   /Affiliation            /Chapter                    /Result
        122104                  FALSE               anything including null anything including null     Find from ZipToAffilate -- will be ZF / ZFA
    */
    public static testMethod void testCase5(){ 
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Affiliation__c = 'NN';
        acc.BillingPostalCode = '122104';
        acc.Lock_Affiliation__c = false;
        acc.Has_Renewed_Before__c = false;
        //acc.Affiliation__c = 'CD';
        //acc.chapter__c = 'AKZ - Juneau';
        AccountList.add(acc);
        Account acc2 = TestUtils.createAccount('Account1',false);
        acc2.Membership_Expiration_date__c = Date.Today();
        acc2.Affiliation__c = 'NN';
        acc2.BillingPostalCode = '122104';
        acc2.Lock_Affiliation__c = false;
        acc2.Has_Renewed_Before__c = false;
        acc2.Affiliation__c = 'CD';
        acc2.chapter__c = 'AKZ - Juneau';
        AccountList.add(acc2);
        insert accountList;
        
        Zip_Affiliate__c za1 = TestUtils.createZipAffiliate('00000',false);
        za1.chapter__c = 'NNA';

        insert new List<Zip_Affiliate__c>{za1};  
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '1', 'B', false);
        Opportunity opp2 = CreateOpportunity(acc2.id, 'Opp2', Date.today().addMonths(2), null, '2', 'B', false);
        opplist.add(opp);
        oppList.add(opp2);
        insert oppList;
        opplist.clear();
        
        opp.StageName = 'Completed';
        opp2.StageName = 'Completed';
        opplist.add(opp);
        oppList.add(opp2);
        update oppList;
        //System.assertEquals('NNA', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        System.assertEquals('AKZ', [select id, Sharing_Entity__c FROM Opportunity where id =: opp2.id].Sharing_Entity__c);
    }
    
    
    
    
    /*Test Cast-8 *******************************************************************************************************************************
        BillingPostalCode       /Lock Affiliation   /Affiliation            /Chapter                    /Result
        null                    FALSE               null                    null                        Find from ZipToAffilate based on zip of "00000" 
    */
    public static testMethod void testCase8(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Affiliation__c = 'NN';
        //acc.BillingPostalCode = 'H23J1';
        acc.Lock_Affiliation__c = false;
        acc.Has_Renewed_Before__c = false;
        acc.BillingCountry = null;
        //acc.Affiliation__c = 'CD';
        //acc.chapter__c = 'AKZ - Juneau';
        AccountList.add(acc);
        Account acc2 = TestUtils.createAccount('Account1',false);
        acc2.Membership_Expiration_date__c = Date.Today();
        acc2.Affiliation__c = 'NN';
        //acc2.BillingPostalCode = 'H23 J14';
        acc2.Lock_Affiliation__c = false;
        acc2.Has_Renewed_Before__c = false;
        acc2.BillingCountry = null;
        //acc2.Affiliation__c = 'CD';
        //acc2.chapter__c = 'AKZ - Juneau';
        AccountList.add(acc2);
        insert accountList;
        System.debug('>>accountList>>><<<<::::'+[Select id, Lock_Affiliation__c, chapter__c, Affiliation__c from account where id iN: accountList]);
        Zip_Affiliate__c za1 = TestUtils.createZipAffiliate('00000',false);
        za1.chapter__c = 'NNA';

        insert new List<Zip_Affiliate__c>{za1};  
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '1', 'B', false);
        Opportunity opp2 = CreateOpportunity(acc2.id, 'Opp2', Date.today().addMonths(2), null, '2', 'B', false);
        opplist.add(opp);
        oppList.add(opp2);
        insert oppList;
        opplist.clear();
        
        opp.StageName = 'Completed';
        opp2.StageName = 'Completed';
        opplist.add(opp);
        oppList.add(opp2);
        update oppList;
        System.assertEquals('NNA', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        System.assertEquals('NNA', [select id, Sharing_Entity__c FROM Opportunity where id =: opp2.id].Sharing_Entity__c);
    }
    
    public static testMethod void testCaseWithAllBlank(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Lock_Affiliation__c = false;
        acc.Has_Renewed_Before__c = false;
        insert acc;
        acc.Affiliation__c = '';
        acc.chapter__c = '';
        update acc;
        
        Zip_Affiliate__c za1 = TestUtils.createZipAffiliate('00000',false);
        za1.chapter__c = 'NNA';

        insert za1;  
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'G', false);
        opp.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        insert opp;
        
        opp.StageName = 'Completed';
        opp.Program_Type__c = '5';
        update opp;
        system.assertEquals('NNA', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        system.assertEquals('NN', [select id, Sharing_Entity_Affiliation__c FROM Opportunity where id =: opp.id].Sharing_Entity_Affiliation__c);
        
    }
    
    public static testMethod void testCaseWithAffiliationTrueAndAllBlank(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Lock_Affiliation__c = true;
        acc.Has_Renewed_Before__c = false;
        insert acc;
        acc.Affiliation__c = '';
        acc.chapter__c = '';
        update acc;
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'G', false);
        opp.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        insert opp;
        
        opp.StageName = 'Completed';
        opp.Program_Type__c = '5';
        update opp;
        system.assertEquals('ERROR', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        system.assertEquals('ER', [select id, Sharing_Entity_Affiliation__c FROM Opportunity where id =: opp.id].Sharing_Entity_Affiliation__c);
        
    }
    public static testMethod void testCaseWithNoPostalCode(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Lock_Affiliation__c = false;
        acc.Has_Renewed_Before__c = false;
        insert acc;
        acc.Affiliation__c = 'NY';
        acc.chapter__c = 'NYL - Capital Area';
        update acc; 
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'G', false);
        opp.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        insert opp;
        
        opp.StageName = 'Completed';
        opp.Program_Type__c = '5';
        update opp;
        system.assert([select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c.startsWith('NYL'));
        system.assertEquals('NY', [select id, Sharing_Entity_Affiliation__c FROM Opportunity where id =: opp.id].Sharing_Entity_Affiliation__c);
        
    }
    public static testMethod void testCaseToPopulateZFA(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Lock_Affiliation__c = false;
        acc.Has_Renewed_Before__c = false;
        acc.BillingPostalCode = '993388cs';
        insert acc;
        acc.Affiliation__c = '';
        acc.chapter__c = '';
        update acc; 
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'G', false);
        opp.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        insert opp;
        
        opp.StageName = 'Completed';
        opp.Program_Type__c = '5';
        update opp;
        system.assertEquals('ZFA', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        system.assertEquals('ZF', [select id, Sharing_Entity_Affiliation__c FROM Opportunity where id =: opp.id].Sharing_Entity_Affiliation__c);
        
    }
    public static testMethod void testCase1And2(){
        Zip_Affiliate__c za = TestUtils.createZipAffiliate('12210',false);
        za.chapter__c = 'AKY - Fairbanks';
        insert za;
        
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Affiliation__c = 'ND';
        acc.BillingPostalCode = '1221000';
        acc.Lock_Affiliation__c = true;
        acc.Has_Renewed_Before__c = false;
        AccountList.add(acc);
        Account acc2 = TestUtils.createAccount('Account1',false);
        acc2.Membership_Expiration_date__c = Date.Today();
        acc2.BillingPostalCode = '12210-1234';
        acc2.Lock_Affiliation__c = true;
        acc2.Has_Renewed_Before__c = false;
        acc2.Affiliation__c = 'CD';
        acc2.chapter__c = 'AKZ - Juneau';
        AccountList.add(acc2);
        insert accountList;
        //accountlist[0].Affiliation__c = 'NA';
        update accountlist[0];
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'g', false);
        Opportunity opp2 = CreateOpportunity(acc2.id, 'Opp2', Date.today().addMonths(2), null, '2', 'B', false);
        opplist.add(opp);
        oppList.add(opp2);
        insert oppList;
        opplist.clear();
        opp.StageName = 'Completed';
        opp2.StageName = 'Completed';
        opplist.add(opp);
        oppList.add(opp2);
        update oppList;
        System.assertEquals('ERROR', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        System.assertEquals('AKZ', [select id, Sharing_Entity__c FROM Opportunity where id =: opp2.id].Sharing_Entity__c);
    }
    public static testMethod void testCaseWithAffiliationPA(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Lock_Affiliation__c = false;
        acc.Has_Renewed_Before__c = false;
        insert acc;
        acc.Affiliation__c = 'PA';
        acc.chapter__c = 'NYL - Capital Area';
        update acc; 
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'G', false);
        opp.Deposit_Site__c = 'PA_Pennsylvania';
        insert opp;
        
        opp.StageName = 'Completed';
        opp.Program_Type__c = '5';
        update opp;
        system.assert([select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c.startsWith('NYL'));
        system.assertEquals('NY', [select id, Sharing_Entity_Affiliation__c FROM Opportunity where id =: opp.id].Sharing_Entity_Affiliation__c);
        
        
    }
    public static testMethod void testCaseWithLockAffiliation(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Lock_Affiliation__c = true;
        acc.Has_Renewed_Before__c = false;
        insert acc;
        acc.Affiliation__c = 'PA';
        acc.chapter__c = 'NYL - Capital Area';
        update acc; 
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'G', false);
        opp.Deposit_Site__c = 'PA_Pennsylvania';
        insert opp;
        
        opp.StageName = 'Completed';
        opp.Program_Type__c = '5';
        update opp;
        system.assert([select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c.startsWith('NYL'));
        system.assertEquals('NY', [select id, Sharing_Entity_Affiliation__c FROM Opportunity where id =: opp.id].Sharing_Entity_Affiliation__c);
        
        
    }
    public static testMethod void testCaseWithLockAffiliationAndNoChapter(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Lock_Affiliation__c = true;
        acc.Has_Renewed_Before__c = false;
        insert acc;
        acc.Affiliation__c = '';
        acc.chapter__c = '';
        update acc; 
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'G', false);
        opp.Deposit_Site__c = 'PA_Pennsylvania';
        insert opp;
        
        opp.StageName = 'Completed';
        opp.Program_Type__c = '5';
        update opp;
        system.assertEquals('PA99', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        system.assertEquals('PA', [select id, Sharing_Entity_Affiliation__c FROM Opportunity where id =: opp.id].Sharing_Entity_Affiliation__c);
        
        
    }
    public static testMethod void testCaseWithNOBillingAffiliationChapter(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Lock_Affiliation__c = false;
        acc.Has_Renewed_Before__c = false;
        insert acc;
        acc.Affiliation__c = '';
        acc.chapter__c = '';
        update acc; 
        
        Zip_Affiliate__c za = TestUtils.createZipAffiliate('00000',false);
        za.chapter__c = 'NNA';
        insert za;
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'G', false);
        opp.Deposit_Site__c = 'PA_Pennsylvania';
        insert opp;
        
        opp.StageName = 'Completed';
        opp.Program_Type__c = '5';
        update opp;
        system.assertEquals('PA99', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        system.assertEquals('PA', [select id, Sharing_Entity_Affiliation__c FROM Opportunity where id =: opp.id].Sharing_Entity_Affiliation__c);
        
        
    }
    public static testMethod void testCaseWithOnlyPostalCode(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Lock_Affiliation__c = false;
        acc.Has_Renewed_Before__c = false;
        acc.BillingPostalCode = '21212';
        insert acc;
        acc.Affiliation__c = '';
        acc.chapter__c = '';
        update acc; 
        
        Zip_Affiliate__c za = TestUtils.createZipAffiliate('00000',false);
        za.chapter__c = 'NNA';
        insert za;
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'G', false);
        opp.Deposit_Site__c = 'PA_Pennsylvania';
        insert opp;
        
        opp.StageName = 'Completed';
        opp.Program_Type__c = '5';
        update opp;
        system.assertEquals('PA99', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        system.assertEquals('PA', [select id, Sharing_Entity_Affiliation__c FROM Opportunity where id =: opp.id].Sharing_Entity_Affiliation__c);
        
        
    }
    public static testMethod void testCaseWithOnlyNonUSPostalCode(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Lock_Affiliation__c = false;
        acc.Has_Renewed_Before__c = false;
        acc.BillingPostalCode = '21212SS';
        insert acc;
        acc.Affiliation__c = '';
        acc.chapter__c = '';
        update acc; 
        
        Zip_Affiliate__c za = TestUtils.createZipAffiliate('00000',false);
        za.chapter__c = 'NNA';
        insert za;
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'G', false);
        opp.Deposit_Site__c = 'PA_Pennsylvania';
        insert opp;
        
        opp.StageName = 'Completed';
        opp.Program_Type__c = '5';
        update opp;
        system.assertEquals('PA99', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        system.assertEquals('PA', [select id, Sharing_Entity_Affiliation__c FROM Opportunity where id =: opp.id].Sharing_Entity_Affiliation__c);
        
        
    }
    public static testMethod void testCaseWithAllBillingAffiliationChapter(){
        List<Account> AccountList = new List<Account>();
        Campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Lock_Affiliation__c = false;
        acc.Has_Renewed_Before__c = false;
        acc.BillingPostalCode = '22222';
        insert acc;
        acc.Affiliation__c = 'NY';
        acc.chapter__c = 'NYL - Capital Area';
        update acc; 
        
        Zip_Affiliate__c za = TestUtils.createZipAffiliate('22222',false);
        za.chapter__c = 'NNA';
        insert za;
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        
        for(Integer i=0;i<2;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            //c.Restriction__c = 'Bill of Rights Trust (BRT)';
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            Campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!Campaigns.isEmpty())
                insert Campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'G', false);
        opp.Deposit_Site__c = 'PA_Pennsylvania';
        insert opp;
        
        opp.StageName = 'Completed';
        opp.Program_Type__c = '5';
        opp.Deposit_Site__c = 'NY_NewYork';
        update opp;
        system.assertEquals('NNA', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        system.assertEquals('NN', [select id, Sharing_Entity_Affiliation__c FROM Opportunity where id =: opp.id].Sharing_Entity_Affiliation__c);
        
        
    }
     public static testMethod void testCampaignWithOverrideSharingEntity(){//ACLU #75631: Added by - Kirti Rathod(SFDO) 
        List<Account> AccountList = new List<Account>();
        List<Campaign> campaigns = new List<Campaign>();
        Account acc = TestUtils.createAccount('Account1',false);
        acc.Membership_Expiration_date__c = Date.Today();
        acc.Lock_Affiliation__c = false;
        acc.Has_Renewed_Before__c = false;
        acc.BillingPostalCode = '22222';
        insert acc;
        acc.Affiliation__c = 'NY';
        acc.chapter__c = 'NYL - Capital Area';
        update acc; 
        
        Zip_Affiliate__c za = TestUtils.createZipAffiliate('22222',false);
        za.chapter__c = 'NNA';
        insert za;
        
        List<sObject> ls = Test.loadData(Share_Source_Revenue_Codes__c.sObjectType, 'SharingCodeValues');
        String overrideSE = 'NN - National ACLU';
        
        for(Integer i=0;i<1;i++){   
            campaign c= TestUtils.createCampaign('Test'+i, false);
            c.Override_Sharing_Entity__c =  overrideSE;
            c.rC_Giving__Source_Code__c = '-------161106005';
            c.Exclude_Cost_Factors_in_RevShare__c = true;
            campaigns.add(c);
        }
        usr = TestUtils.createUser('userTT', 'usertest12@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertest12@aclu.org';
        insert usr;
        System.runAs(usr){
            if(!campaigns.isEmpty())
                insert campaigns; 
        }   
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opp = CreateOpportunity(acc.id, 'Opp1', Date.today().addMonths(4), null, '4', 'G', false);
        opp.Deposit_Site__c = 'PA_Pennsylvania';
        insert opp;
        
        opp.StageName = 'Completed';
        opp.Program_Type__c = '5';
        opp.Deposit_Site__c = 'NY_NewYork';
        opp.CampaignIdText__c = campaigns[0].Id;
        update opp;
        system.assertEquals('NN', [select id, Sharing_Entity__c FROM Opportunity where id =: opp.id].Sharing_Entity__c);
        system.assertEquals('NN', [select id, Sharing_Entity_Affiliation__c FROM Opportunity where id =: opp.id].Sharing_Entity_Affiliation__c);
        
        
    }

  
   
    
}