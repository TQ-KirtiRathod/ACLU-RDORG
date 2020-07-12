/*
*
*Name  :  RevSharingTestDataGenerator
*Author:  Appirio India (Sai Krishna )
*Date  :  December 27, 2016
*Purpose : Generates the Oppty Records as per the Criteria  
*
*Change Log : 2019-04: DS: createOpptyRecordsForSharingCode broken up into several methods due to SOQL limits
*             being reached early in the rule iteration. 
*/

public with sharing class RevSharingTestDataGenerator {
    public static Id pledgeOppPaymentId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    public static Id pledgeOppId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge').getRecordTypeId();
    
    // DS - Rules 1-4
    public static void createOpptyRecordsForSharingCode_01(){
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();
        Campaign objCampaign = TestUtils.createCampaign('Testcampaign',false);
        objCampaign.Bequest_Sharing_Code__c = 'Q001';
        objCampaign.rC_Giving__Sub_Affiliation__c = '4 - National Foundation';
        insert objCampaign;
    
        Account acc = createAccount('Default', null, 'NN', Date.Today(), '00000', 'Japan', false, true);
        
        List<Opportunity> oppToInsertList = new List<Opportunity>();

        //Opportunity with certain criteria
        Opportunity oppOrder14 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 4, 'Completed', 'NM_NewMexico', false);
        oppToInsertList.add(oppOrder14);
        insert oppToInsertList;
        system.debug('*** QUERIES queries after insert initial opps *** ' + Limits.getQueries());

        //Account 
        Account a = createAccount('Account', oppOrder14.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        accs.add( a);
       
        if(!accs.IsEmpty())
            insert accs;

                            system.debug('*** QUERIES queries after insert accounts *** ' + Limits.getQueries());


        List <rC_Bios__Preference__c> preferences = new List<rC_Bios__Preference__c>();
        
        rC_Bios__Preference__c bpAL1 = TestUtils.createPreferences(a.id, false);
        bpAL1.rC_Bios__Active__c = true;
        bpAL1.rC_Bios__Code_Value__c = 'AL';
        bpAL1.rC_Bios__Category__c = 'Constituent Type';
        bpAL1.rC_Bios__Subcategory__c = 'ACLU Member';
        bpAL1.rC_Bios__Type__c = 'Life Member';
        preferences.add(bpAL1);
        
        insert preferences;
        
        Test.startTest();
        // Order 1
        opps.add( CreateOpportunity(accs[0].Id,  '1', Date.Today(), null, '1', 'B', 50, 50, 'Completed', null, false));
        opps.add( CreateOpportunity(accs[0].Id,  '1', Date.Today(), null, '3', 'B', 50, 50, 'Completed', 'NM_NewMexico', false));
 
        // Order 2
        opps.add( CreateOpportunity(accs[0].Id, '2', Date.Today(), null, '1', 'E', 50, 50, 'Completed', null, false));
        opps.add( CreateOpportunity(accs[0].Id, '2', Date.Today(), null, '3', 'E', 50, 50, 'Completed', 'NM_NewMexico', false));
  
        // Order 3
        opps.add( CreateOpportunity(accs[0].Id, '3', Date.Today(), null, '1', 'K', 50, 50, 'Completed', null, false));
        opps.add( CreateOpportunity(accs[0].Id, '3', Date.Today(), null, '3', 'K', 50, 50, 'Completed', 'NM_NewMexico', false));
        opps.add( CreateOpportunity(accs[0].Id, '3', Date.Today(), null, '3', 'K', 50, 50, 'Completed', 'NM_NewMexico', false));
    
        // Order 4
        opps.add( CreateOpportunity(accs[0].Id, '4', Date.Today(), null, '1', 'G', 50, 50, 'Completed', null, false));
        opps.add( CreateOpportunity(accs[0].Id, '4', Date.Today(), null, '3', 'G', 50, 50, 'Completed', 'NM_NewMexico', false));  
        
        if(!opps.IsEmpty()){
            insert opps;
        }
        Test.stopTest();
    }

// DS - Rules 5-8
    public static void createOpptyRecordsForSharingCode_02(){
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();
        Campaign objCampaign = TestUtils.createCampaign('Testcampaign',false);
        objCampaign.Bequest_Sharing_Code__c = 'Q001';
        objCampaign.rC_Giving__Sub_Affiliation__c = '4 - National Foundation';
        insert objCampaign;

        Account acc = createAccount('Default', null, 'NN', Date.Today(), '00000', 'Japan', false, true);
        
        List<Opportunity> oppToInsertList = new List<Opportunity>();
       

        //Opportunity with certain criteria

        Opportunity oppOrder14 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 4, 'Completed', 'NM_NewMexico', false);
        oppToInsertList.add(oppOrder14);
        insert oppToInsertList;

        //Account 
        Account a = createAccount('Account', oppOrder14.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        accs.add( a);
     
        if(!accs.IsEmpty())
            insert accs;

        List <rC_Bios__Preference__c> preferences = new List<rC_Bios__Preference__c>();

        rC_Bios__Preference__c bpAL1 = TestUtils.createPreferences(a.id, false);
        bpAL1.rC_Bios__Active__c = true;
        bpAL1.rC_Bios__Code_Value__c = 'AL';
        bpAL1.rC_Bios__Category__c = 'Constituent Type';
        bpAL1.rC_Bios__Subcategory__c = 'ACLU Member';
        bpAL1.rC_Bios__Type__c = 'Life Member';
        preferences.add(bpAL1);
        
        insert preferences;

        // Order 5
        opps.add( CreateOpportunity(accs[0].Id, '5', Date.Today(), null, '1', 'I', 50, 50, 'Completed', null, false));
        opps.add( CreateOpportunity(accs[0].Id, '5', Date.Today(), null, '3', 'I', 50, 50, 'Completed', 'NM_NewMexico', false));
        

        // Order 6
        opps.add( CreateOpportunity(accs[0].Id, '6', Date.Today(), null, '1', 'C', 50, 50, 'Completed', null, false));
        opps.add( CreateOpportunity(accs[0].Id, '6', Date.Today(), null, '3', 'C', 50, 50, 'Completed', 'NM_NewMexico', false));
        
        // Order 7
        opps.add( CreateOpportunity(accs[0].Id, '7', Date.Today(), null, '1', 'Q', 50, 50, 'Completed', null, false));
        opps.add( CreateOpportunity(accs[0].Id, '7', Date.Today(), null, '3', 'Q', 50, 50, 'Completed', 'NM_NewMexico', false));
        
        // Order 8
        opps.add( CreateOpportunity(accs[0].Id, '8', Date.Today(), null, '1', 'H', 50, 50, 'Completed', null, false));
          
        if(!opps.IsEmpty()){
            insert opps;
        }
           
    }

    // DS - Rules 9-11
    public static void createOpptyRecordsForSharingCode_03(){
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();
        Campaign objCampaign = TestUtils.createCampaign('Testcampaign',false);
        objCampaign.Bequest_Sharing_Code__c = 'Q001';
        objCampaign.rC_Giving__Sub_Affiliation__c = '4 - National Foundation';
        insert objCampaign;
                                    system.debug('*** QUERIES queries after insert campaign *** ' + Limits.getQueries());
            
        List<Opportunity> oppToInsertList = new List<Opportunity>();


        Account acc = createAccount('Default', null, 'NN', Date.Today(), '00000', 'Japan', false, true);

        //Opportunity with certain criteria
        Opportunity opp = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-16), 'A', '1', 'B', 50, 50, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOverTwoYrs = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 50, 'Completed', 'NM_NewMexico', false);

        Opportunity oppOrder12 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 4, 4, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder13 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 4, 4, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder14 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 4, 4, 'Completed', 'NM_NewMexico', false);
        oppToInsertList.add(opp);
        oppToInsertList.add(oppOverTwoYrs);
        oppToInsertList.add(oppOrder12);
        oppToInsertList.add(oppOrder13);
        oppToInsertList.add(oppOrder14);
        insert oppToInsertList;

        //Account 
        Account acc1 = createAccount('ExpirationDateNull&NotRenewed', null, 'NN', null, '00000', 'Japan', true, false);   
        Account acc2 = createAccount('Renewed', oppOrder13.id, 'NN', Date.Today(), '00000', 'Japan', true, false);
        Account a = createAccount('Account', oppOrder14.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        a.Last_Membership_Gift__c=opp.id;
       
        accs.add( a);
        accs.add( createAccount('WithOpportunity', opp.Id, 'NN', Date.Today()-366, '00000', 'Japan', false, false));
        accs.add(acc1);
        accs.add(acc2);
        accs.add( createAccount('WithOpportunityOverTwoYears', oppOverTwoYrs.Id, 'NN', Date.Today()-366, '00000', 'Japan', false, false));

        
        if(!accs.IsEmpty())
            insert accs;

        List <rC_Bios__Preference__c> preferences = new List<rC_Bios__Preference__c>();
        
        rC_Bios__Preference__c bp = TestUtils.createPreferences(accs[2].id, false);
        bp.rC_Bios__Active__c = true;
        bp.rC_Bios__Code_Value__c = 'AL';
        bp.rC_Bios__Category__c = 'Constituent Type';
        bp.rC_Bios__Subcategory__c = 'ACLU Member';
        bp.rC_Bios__Type__c = 'Life Member';
        preferences.add(bp);
        
        rC_Bios__Preference__c bpAL1 = TestUtils.createPreferences(a.id, false);
        bpAL1.rC_Bios__Active__c = true;
        bpAL1.rC_Bios__Code_Value__c = 'AL';
        bpAL1.rC_Bios__Category__c = 'Constituent Type';
        bpAL1.rC_Bios__Subcategory__c = 'ACLU Member';
        bpAL1.rC_Bios__Type__c = 'Life Member';
        preferences.add(bpAL1);
        
        insert preferences;
      
       
        // Order 9
        opps.add( CreateOpportunity(accs[4].Id, '9', Date.Today(), null, '1', 'Z', 50, 50, 'Completed', null, false));
        opps.add( CreateOpportunity(accs[4].Id, '9', Date.Today(), null, '3', 'Z', 50, 50, 'Completed', 'NM_NewMexico', false));
       
        // Order 10
        opps.add( CreateOpportunity(accs[0].Id, '10', Date.Today(), null, '1', 'S', 50, 50, 'Completed', null, false));
       
        // Order 11
        opps.add( CreateOpportunity(accs[2].Id, '11', Date.Today(), null, '2', 'U',  50, 50, 'Completed', null, false));
        
        if(!opps.IsEmpty()){
            insert opps;

        }      
    }

    // DS - Rules 12-14 
    public static void createOpptyRecordsForSharingCode_04(){
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();
        Campaign objCampaign = TestUtils.createCampaign('Testcampaign',false);
        objCampaign.Bequest_Sharing_Code__c = 'Q001';
        objCampaign.rC_Giving__Sub_Affiliation__c = '4 - National Foundation';
        insert objCampaign;
    
        Account acc = createAccount('Default', null, 'NN', Date.Today(), '00000', 'Japan', false, true);
        
        List<Opportunity> oppToInsertList = new List<Opportunity>();

        //Opportunity with certain criteria
        Opportunity opp = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 50, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder12 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 4, 4, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder13 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 4, 4, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder14 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-8), 'A', '1', 'B', 4, 4, 'Completed', 'NM_NewMexico', false);
        oppToInsertList.add(opp);
        oppToInsertList.add(oppOrder12);
        oppToInsertList.add(oppOrder13);
        oppToInsertList.add(oppOrder14);
        insert oppToInsertList;

        //Account 
        Account a = createAccount('Account', oppOrder14.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        Account acc2 = createAccount('Renewed', oppOrder13.id, 'NN', Date.Today(), '00000', 'Japan', true, false);
        Account ac = createAccount('Account', oppOrder12.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        
        accs.add(a);
        accs.add(acc2);
        accs.add(ac);
        
        if(!accs.IsEmpty())
            insert accs;

        List <rC_Bios__Preference__c> preferences = new List<rC_Bios__Preference__c>();
        rC_Bios__Preference__c bp = TestUtils.createPreferences(accs[2].id, false);
        bp.rC_Bios__Active__c = true;
        bp.rC_Bios__Code_Value__c = 'AL';
        bp.rC_Bios__Category__c = 'Constituent Type';
        bp.rC_Bios__Subcategory__c = 'ACLU Member';
        bp.rC_Bios__Type__c = 'Life Member';
        preferences.add(bp);
        
        rC_Bios__Preference__c bpAL1 = TestUtils.createPreferences(a.id, false);
        bpAL1.rC_Bios__Active__c = true;
        bpAL1.rC_Bios__Code_Value__c = 'AL';
        bpAL1.rC_Bios__Category__c = 'Constituent Type';
        bpAL1.rC_Bios__Subcategory__c = 'ACLU Member';
        bpAL1.rC_Bios__Type__c = 'Life Member';
        preferences.add(bpAL1);
        
        insert preferences;

        // Order 12
        opps.add( CreateOpportunity(ac.Id, '12', Date.Today(), null, '2', 'V', 50, 50, 'Completed', null, false));
        
        // Order 13
        opps.add( CreateOpportunity(acc2.Id, '13', Date.Today(), null, '2', 'V', 50, 50, 'Completed', null, false));
        
        // Order 14
        opps.add( CreateOpportunity(accs[0].Id, '14', Date.Today().addMonths(-9), null, '2', 'V', 50, 50, 'Completed', null, false));
        

        
        if(!opps.IsEmpty()){
            insert opps;

        }
        
    }

    // DS - Rules 20-23 (ORDER 15 previous commented out; ORDERS 16-19; 21 had previously been ignored)
    public static void createOpptyRecordsForSharingCode_05(){
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();
        Campaign objCampaign = TestUtils.createCampaign('Testcampaign',false);
        objCampaign.Bequest_Sharing_Code__c = 'Q001';
        objCampaign.rC_Giving__Sub_Affiliation__c = '4 - National Foundation';
        insert objCampaign;
    
        List<Account> initialAcctsToAdd = new List<Account>();
        Account acc = createAccount('Default', null, 'NN', Date.Today(), '00000', 'Japan', false, false);
        Account acc1 = createAccount('ExpirationDateNull&NotRenewed', null, 'NN', null, '00000', 'Japan', true, false);
        Account nullDate_MembershipAccount = createAccount('LastMembershipGift&ExpirationNull', null, 'NN', null, '00000', 'Japan', false, false);

        initialAcctsToAdd.add(acc);
        initialAcctsToAdd.add(acc1);
        initialAcctsToAdd.add(nullDate_MembershipAccount);
        insert initialAcctsToAdd;
    
        List<Opportunity> oppToInsertList = new List<Opportunity>();

        //Opportunity with certain criteria
        Opportunity opp = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 50, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder12 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 4, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder13 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 4, 'Completed', 'NM_NewMexico', false);
        oppToInsertList.add(opp);
        oppToInsertList.add(oppOrder12);
       
        insert oppToInsertList;


        //Account 
        Account ac = createAccount('Account', oppOrder12.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        Account ac1 = createAccount('Account', oppOrder12.id, 'NN', Date.Today(), '00000', 'Japan', true, false);
        Account nullDateAccount = createAccount('ExpirationNull', oppOrder13.Id, 'NN', null, '00000', 'Japan', false, false);

        accs.add(ac);
        accs.add(ac1);
        accs.add(nullDateAccount);
        
        if(!accs.IsEmpty())
            insert accs;

        List <rC_Bios__Preference__c> preferences = new List<rC_Bios__Preference__c>();
        rC_Bios__Preference__c bpAL = TestUtils.createPreferences(nullDateAccount.id, false);
        bpAL.rC_Bios__Active__c = true;
        bpAL.rC_Bios__Code_Value__c = 'AL';
        bpAL.rC_Bios__Category__c = 'Constituent Type';
        bpAL.rC_Bios__Subcategory__c = 'ACLU Member';
        bpAL.rC_Bios__Type__c = 'Life Member';
        preferences.add(bpAL);
      
        insert preferences;
               
        //Order 15
        // DS - 2019-04-16 changed from 5000 because it was firing newly changed rule 6; but still fails, skips to rule 19;
        // the AL preference not getting set
        // leaving commented out as it already had been commented out
        //opps.add( CreateOpportunity(nullDateAccount.Id, '15', Date.Today(), null, '3', 'V', 4000, 4000, 'Completed', null, false));
        
        //Order 20
        opps.add( CreateOpportunity(ac.Id, '20', Date.Today(), null, '3', 'Z', 50, 5, 'Completed', null, false));
        
        //Order 22
        // DSD - 2019-04 - had been previously commented out so leaving alone for now
        //opps.add( CreateOpportunity(ac1.Id, '22', Date.Today(), null, '1', 'Z', 4, 4, 'Completed', null, false));
    
        //Order 23
        opps.add( CreateOpportunity(accs[0].Id, '23', Date.Today().addMonths(-5), null, '1', 'Z', 50, 50, 'Completed', null, false));
        
        if(!opps.IsEmpty()){
            insert opps;
        }
        
    }

    // DS - Rules 24-28 
    public static void createOpptyRecordsForSharingCode_06(){
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();

        List<Account> initialAcctsToAdd = new List<Account>();
        Account acc = createAccount('Default', null, 'NN', Date.Today(), '00000', 'Japan', false, false);
       
        initialAcctsToAdd.add(acc);
      
        insert initialAcctsToAdd;
    
        List<Opportunity> oppToInsertList = new List<Opportunity>();

        //Opportunity with certain criteria
        Opportunity opp = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 50, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder14 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 4, 'Completed', 'NM_NewMexico', false);
        oppToInsertList.add(opp);
        oppToInsertList.add(oppOrder14);
        insert oppToInsertList;

        //Account 
        Account a = createAccount('Account', oppOrder14.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        
        a.Last_Membership_Gift__c=opp.id;
        
        accs.add(a);
        
        if(!accs.IsEmpty())
            insert accs;

        List <rC_Bios__Preference__c> preferences = new List<rC_Bios__Preference__c>();

        rC_Bios__Preference__c bpAL1 = TestUtils.createPreferences(a.id, false);
        bpAL1.rC_Bios__Active__c = true;
        bpAL1.rC_Bios__Code_Value__c = 'AL';
        bpAL1.rC_Bios__Category__c = 'Constituent Type';
        bpAL1.rC_Bios__Subcategory__c = 'ACLU Member';
        bpAL1.rC_Bios__Type__c = 'Life Member';
        preferences.add(bpAL1);
      
        insert preferences;
        
        //Order 24
        opps.add( CreateOpportunity(accs[0].Id, '24', Date.Today(), null, '4', 'E', 50, 50, 'Completed', 'LA_Louisiana', false));
        opps.add( CreateOpportunity(accs[0].Id, '24', Date.Today(), null, '4', 'E', 50, 50, 'Completed', 'NM_NewMexico', false));
        
        //Order 25
        opps.add( CreateOpportunity(accs[0].Id, '25', Date.Today(), null, '4', 'K', 50, 50, 'Completed', 'NM_NewMexico', false));
        opps.add( CreateOpportunity(accs[0].Id, '25', Date.Today(), null, '4', 'K', 50, 50, 'Completed', 'LA_Louisiana', false));
        
        //Order 26
        opps.add( CreateOpportunity(accs[0].Id, '26', Date.Today(), null, '4', 'F', 50, 50, 'Completed', 'NM_NewMexico', false));
        opps.add( CreateOpportunity(accs[0].Id, '26', Date.Today(), null, '4', 'F', 50, 50, 'Completed', 'LA_Louisiana', false));
        
        //Order 27
        opps.add( CreateOpportunity(accs[0].Id, '27', Date.Today(), null, '4', 'G', 50, 50, 'Completed', 'NM_NewMexico', false));
        opps.add( CreateOpportunity(accs[0].Id, '26', Date.Today(), null, '4', 'F', 50, 50, 'Completed', 'LA_Louisiana', false));
        
        //Order 28
        opps.add( CreateOpportunity(accs[0].Id, '28', Date.Today(), null, '4', 'C', 50, 50, 'Completed', 'NM_NewMexico', false));
        opps.add( CreateOpportunity(accs[0].Id, '28', Date.Today(), null, '4', 'C', 50, 50, 'Completed', 'LA_Louisiana', false));
        
        if(!opps.IsEmpty()){
            insert opps;
        }
           
    }
 
  // DS - Rules 29-33 
    public static void createOpptyRecordsForSharingCode_07(){
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();
    
        List<Account> initialAcctsToAdd = new List<Account>();
        Account acc = createAccount('Default', null, 'NN', Date.Today(), '00000', 'Japan', false, false);
       
        initialAcctsToAdd.add(acc);
      
        insert initialAcctsToAdd;
    
        List<Opportunity> oppToInsertList = new List<Opportunity>();

        //Opportunity with certain criteria
        Opportunity opp = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 50, 'Completed', 'NM_NewMexico', false);
     
        Opportunity oppOrder14 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 4, 'Completed', 'NM_NewMexico', false);
        oppToInsertList.add(opp);
       
        oppToInsertList.add(oppOrder14);
        insert oppToInsertList;


        //Account 
        Account a = createAccount('Account', oppOrder14.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        
        a.Last_Membership_Gift__c=opp.id;
        
        accs.add(a);
        
        if(!accs.IsEmpty())
            insert accs;

        List <rC_Bios__Preference__c> preferences = new List<rC_Bios__Preference__c>();

        rC_Bios__Preference__c bpAL1 = TestUtils.createPreferences(a.id, false);
        bpAL1.rC_Bios__Active__c = true;
        bpAL1.rC_Bios__Code_Value__c = 'AL';
        bpAL1.rC_Bios__Category__c = 'Constituent Type';
        bpAL1.rC_Bios__Subcategory__c = 'ACLU Member';
        bpAL1.rC_Bios__Type__c = 'Life Member';
        preferences.add(bpAL1);
      
        insert preferences;
        
        //Order 29
        opps.add( CreateOpportunity(accs[0].Id, '29', Date.Today(), null, '4', 'S', 50, 50, 'Completed', 'NM_NewMexico', false));
       // opps.add( CreateOpportunity(accs[0].Id, '29', Date.Today(), null, '4', 'S', 50, 50, 'Completed', 'LA_Louisiana', false));
        
        //Order 30
        Opportunity order30 = CreateOpportunity(accs[0].Id, '30', Date.Today(), null, '5', 'S', 50, 50, 'Completed', 'NM_NewMexico', false);
        order30.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        opps.add( order30);
        //opps.add( CreateOpportunity(accs[0].Id, '30', Date.Today(), null, '5', 'S', 50, 50, 'Completed', 'LA_Louisiana', false));
                
        //Order 31
        opps.add( CreateOpportunity(accs[0].Id, '31', Date.Today(), null, '4', 'S', 3500, 3500, 'Completed', 'NM_NewMexico', false));
        //opps.add( CreateOpportunity(accs[0].Id, '31', Date.Today(), null, '4', 'S', 3500, 3500, 'Completed', 'LA_Louisiana', false));
        
        //Order 32
        opps.add( CreateOpportunity(accs[0].Id, '32', Date.Today(), null, '5', 'H', 50, 50, 'Completed', 'NM_NewMexico', false));
      //  opps.add( CreateOpportunity(accs[0].Id, '32', Date.Today(), null, '5', 'H', 50, 50, 'Completed', 'LA_Louisiana', false));
        
        //Order 33
        opps.add( CreateOpportunity(accs[0].Id, '33', Date.Today(), null, '5', 'I', 50, 50, 'Completed', 'NM_NewMexico', false));
      //  opps.add( CreateOpportunity(accs[0].Id, '33', Date.Today(), null, '5', 'I', 50, 50, 'Completed', 'LA_Louisiana', false));
        
        if(!opps.IsEmpty()){
            insert opps;
        }
        
    }


  // DS - Rules 34-37
    public static void createOpptyRecordsForSharingCode_08(){
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();
    
        List<Account> initialAcctsToAdd = new List<Account>();
        Account acc = createAccount('Default', null, 'NN', Date.Today(), '00000', 'Japan', false, false);
       
        initialAcctsToAdd.add(acc);
      
        insert initialAcctsToAdd;
    
        List<Opportunity> oppToInsertList = new List<Opportunity>();

        //Opportunity with certain criteria
        Opportunity opp = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 50, 'Completed', 'NM_NewMexico', false);
     
        Opportunity oppOrder14 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 4, 'Completed', 'NM_NewMexico', false);
        oppToInsertList.add(opp);
       
        oppToInsertList.add(oppOrder14);
        insert oppToInsertList;


        //Account 
        Account a = createAccount('Account', oppOrder14.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        
        a.Last_Membership_Gift__c=opp.id;
        
        accs.add(a);
        
        if(!accs.IsEmpty())
            insert accs;

        List <rC_Bios__Preference__c> preferences = new List<rC_Bios__Preference__c>();

        rC_Bios__Preference__c bpAL1 = TestUtils.createPreferences(a.id, false);
        bpAL1.rC_Bios__Active__c = true;
        bpAL1.rC_Bios__Code_Value__c = 'AL';
        bpAL1.rC_Bios__Category__c = 'Constituent Type';
        bpAL1.rC_Bios__Subcategory__c = 'ACLU Member';
        bpAL1.rC_Bios__Type__c = 'Life Member';
        preferences.add(bpAL1);
      
        insert preferences;
        
        //Order 34
        opps.add( CreateOpportunity(accs[0].Id, '34', Date.Today(), null, '5', 'Q', 50, 50, 'Completed', 'NM_NewMexico', false));
        opps.add( CreateOpportunity(accs[0].Id, '34', Date.Today(), null, '5', 'Q', 50, 50, 'Completed', 'NAA_NatU_Operating_chk/cash', false));
        
        //Order 35
        opps.add( CreateOpportunity(accs[0].Id, '35', Date.Today(), null, '5', 'B', 50, 50, 'Completed', 'NM_NewMexico', false));
        opps.add( CreateOpportunity(accs[0].Id, '35', Date.Today(), null, '5', 'B', 50, 50, 'Completed', 'NAA_NatU_Operating_chk/cash', false));
        
        //Order 36
        opps.add( CreateOpportunity(accs[0].Id, '36', Date.Today(), null, '4', 'M', 50, 50, 'Completed', 'NM_NewMexico', false));
        opps.add( CreateOpportunity(accs[0].Id, '36', Date.Today(), null, '4', 'M', 50, 50, 'Completed', 'NAA_NatU_Operating_chk/cash', false));
        
        //Order 37
        opps.add( CreateOpportunity(accs[0].Id, '37', Date.Today(), null, '5', 'M', 50, 50, 'Completed', 'NM_NewMexico', false));
        opps.add( CreateOpportunity(accs[0].Id, '37', Date.Today(), null, '5', 'M', 50, 50, 'Completed', 'NAA_NatU_Operating_chk/cash', false));
        
        if(!opps.IsEmpty()){
            insert opps;
        }
        
    }

    public static void additionalGCLCodesRecords_CampaignType_T(){
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();
        Campaign objCampaign = TestUtils.createCampaign('Testcampaign',false);
        objCampaign.Bequest_Sharing_Code__c = 'Q001';
        objCampaign.rC_Giving__Sub_Affiliation__c = '4 - National Foundation';
        insert objCampaign;
        
        Account acc = createAccount('Default', null, 'NN', Date.Today(), '00000', 'Japan', false, true);
        Opportunity opp = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-24), 'A', '1', 'B', 50, 50, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder12 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 4, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder13 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 4, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder14 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-28), 'A', '1', 'B', 50, 50000, 'Completed', 'NM_NewMexico', false);
        List<Opportunity> oppToInsert = new List<Opportunity>{opp, oppOrder12, oppOrder13, oppOrder14};
        insert oppToInsert;
        Account acc1 = createAccount('ExpirationDateNull&NotRenewed', null, 'NN', null, '00000', 'Japan', true, false);
        Account nullDate_MembershipAccount = createAccount('LastMembershipGift&ExpirationNull', null, 'NN', null, '00000', 'Japan', false, false);
              
        
        //Account 
        Account acc2 = createAccount('Renewed', oppOrder13.id, 'NN', Date.Today(), '00000', 'Japan', true, false);
        Account a = createAccount('Account', oppOrder14.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        Account ac = createAccount('Account', oppOrder12.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        Account ac1 = createAccount('Account', oppOrder12.id, 'NN', Date.Today(), '00000', 'Japan', true, false);
        Account nullDateAccount = createAccount('ExpirationNull', oppOrder13.Id, 'NN', null, '00000', 'Japan', false, false);
        
        accs.add( a);
        accs.add( createAccount('WithOpportunity', opp.Id, 'NN', Date.Today()-366, '00000', 'Japan', false, false));
        accs.add(acc1);
        accs.add(acc2);
        
        List<Account> accToInsert = new List<Account>{acc1,nullDate_MembershipAccount,acc2,a,ac,ac1,nullDateAccount };
       
        if(!accToInsert.IsEmpty())
            insert accToInsert;
        //Opportunity with certain criteria
        
        Opportunity sustainerPledge = new Opportunity();
        sustainerPledge.name = 'Pledge Sustainer';
        sustainerPledge.closeDate = Date.Today();
        sustainerPledge.AccountId = accs[0].Id;
        sustainerPledge.Campaignid = objCampaign.id;
        sustainerPledge.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge.RecordtypeId = pledgeOppId;
        sustainerPledge.stageName = 'Closed';
        insert sustainerPledge;
        
        //Addintional GCS
        opps.add( CreateOpportunity(accs[0].Id, 'T', Date.Today(), null, '5', 'T', 50, 50, 'Completed', 'NM_NewMexico', false));
              
        if(!opps.IsEmpty()){
            insert opps;
        }
    }
    
    public static void additionalGCLCodesRecords_CampaignType_1(Opportunity sustainerPledge, List<Account> accs){
        List<Opportunity> opps = new List<Opportunity>();
      /*List<Account> accs = new List<Account>();
        
        Campaign objCampaign = TestUtils.createCampaign('Testcampaign',false);
        objCampaign.Bequest_Sharing_Code__c = 'Q001';
        objCampaign.rC_Giving__Sub_Affiliation__c = '4 - National Foundation';
        insert objCampaign;
        
        Account acc = createAccount('Default', null, 'NN', Date.Today(), '00000', 'Japan', false, true);
        
        Opportunity opp = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-24), 'A', '1', 'B', 50, 50, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder12 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 4, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder13 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 4, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder14 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-28), 'A', '1', 'B', 50, 50000, 'Completed', 'NM_NewMexico', false);
        List<Opportunity> oppToInsert = new List<Opportunity>{opp, oppOrder12, oppOrder13, oppOrder14};
        
        insert oppToInsert;
        
        Account acc1 = createAccount('ExpirationDateNull&NotRenewed', null, 'NN', null, '00000', 'Japan', true, false);
        Account nullDate_MembershipAccount = createAccount('LastMembershipGift&ExpirationNull', null, 'NN', null, '00000', 'Japan', false, false);
        
        
        
        //Account 
        Account acc2 = createAccount('Renewed', oppOrder13.id, 'NN', Date.Today(), '00000', 'Japan', true, false);
        Account a = createAccount('Account', oppOrder14.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        Account ac = createAccount('Account', oppOrder12.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        Account ac1 = createAccount('Account', oppOrder12.id, 'NN', Date.Today(), '00000', 'Japan', true, false);
        Account nullDateAccount = createAccount('ExpirationNull', oppOrder13.Id, 'NN', null, '00000', 'Japan', false, false);
        Account nullDateAccount = createAccount('ExpirationNull', null, 'NN', null, '00000', 'Japan', false, false);
        accs.add( a);
        accs.add( createAccount('WithOpportunity', opp.Id, 'NN', Date.Today()-366, '00000', 'Japan', false, false));
        accs.add(acc1);
        accs.add(nullDate_MembershipAccount);
        accs.add(nullDateAccount);
        List<Account> accToInsert = new List<Account>{acc1,nullDate_MembershipAccount,acc2,a,ac,ac1,nullDateAccount };

        if(!accs.IsEmpty())
            insert accs;
        //Opportunity with certain criteria
         Test.startTest();
        Opportunity sustainerPledge = new Opportunity();
        sustainerPledge.name = 'Pledge Sustainer';
        sustainerPledge.closeDate = Date.Today();
        sustainerPledge.AccountId = accs[0].Id;
        sustainerPledge.Campaignid = objCampaign.id;
        sustainerPledge.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge.RecordtypeId = pledgeOppId;
        sustainerPledge.stageName = 'Closed';
        insert sustainerPledge;
      */
        //Addintional GCS
       
        opps.add( CreateOpportunity(accs[0].Id, '1', Date.Today(), null, '5', '1', 50, 50, 'Completed', 'NM_NewMexico', false));
        
        Opportunity sustainerPledgePayment9_1 = CreateOpportunity(accs[0].Id, '9', Date.Today()+370, null, '1', 'K', 50, 50, 'Completed', 'NM_NewMexico', false);
        sustainerPledgePayment9_1.rC_Giving__Parent__c = sustainerPledge.Id;
        sustainerPledgePayment9_1.Sharing_Code_Override__c = false;
        opps.add( sustainerPledgePayment9_1);
        
        Opportunity sustainerPledgePayment9_3 = CreateOpportunity(accs[0].Id, '9', Date.Today()+370, null, '3', 'K', 50, 50, 'Completed', 'NM_NewMexico', false);
        sustainerPledgePayment9_3.rC_Giving__Parent__c = sustainerPledge.Id;
        sustainerPledgePayment9_3.Sharing_Code_Override__c = false;
        opps.add( sustainerPledgePayment9_3);
        
        Opportunity sustainerPledgePayment = CreateOpportunity(accs[0].Id, '10', Date.Today(), null, '1', 'K', 50, 50, 'Completed', 'NM_NewMexico', false);
        sustainerPledgePayment.rC_Giving__Parent__c = sustainerPledge.Id;
        opps.add( sustainerPledgePayment);
        /*
        Opportunity sustainerPledgePayment11 = CreateOpportunity(accs[2].Id, '11', Date.Today()+370, null, '2', 'K', 50, 50, 'Completed', 'NM_NewMexico', false);
        sustainerPledgePayment11.rC_Giving__Parent__c = sustainerPledge.Id;
        opps.add( sustainerPledgePayment11);
        */
        Opportunity sustainerPledgePayment12 = CreateOpportunity(accs[0].Id, '12', Date.Today()+370, null, '2', 'K', 50, 50, 'Completed', 'NM_NewMexico', false);
        sustainerPledgePayment12.rC_Giving__Parent__c = sustainerPledge.Id;
      //  opps.add( sustainerPledgePayment12);
        
        Opportunity sustainerPledgePayment15_1 = CreateOpportunity(accs[0].Id, '15', Date.Today()-210, null, '1', 'K', 50, 1000, 'Completed', 'NM_NewMexico', false);
        sustainerPledgePayment15_1.rC_Giving__Parent__c = sustainerPledge.Id;
      //  opps.add( sustainerPledgePayment15_1);
        
        Opportunity sustainerPledgePayment15_3 = CreateOpportunity(accs[0].Id, '15', Date.Today()-210, null, '3', 'K', 50, 1000, 'Completed', 'NM_NewMexico', false);
        sustainerPledgePayment15_3.rC_Giving__Parent__c = sustainerPledge.Id;
       // opps.add( sustainerPledgePayment15_3);
        
        
        Opportunity sustainerPledgePayment16_1 = CreateOpportunity(accs[0].Id, '16', Date.Today()+370, null, '1', 'K', 50, 1000, 'Completed', 'NM_NewMexico', false);
        sustainerPledgePayment16_1.rC_Giving__Parent__c = sustainerPledge.Id;
        //opps.add( sustainerPledgePayment16_1);
        
        Opportunity sustainerPledgePayment16_3 = CreateOpportunity(accs[0].Id, '16', Date.Today()+370, null, '3', 'K', 50, 1000, 'Completed', 'NM_NewMexico', false);
        sustainerPledgePayment16_3.rC_Giving__Parent__c = sustainerPledge.Id;
       // opps.add( sustainerPledgePayment16_3);
        
       // Opportunity sustainerPledgePayment20 = CreateOpportunity(ac.Id, '20', Date.Today(), null, '3', 'Z', 50, 5, 'Completed', null, false);
        //sustainerPledgePayment20.rC_Giving__Parent__c = sustainerPledge.Id;
       // opps.add( sustainerPledgePayment20);
        
        if(!opps.IsEmpty()){
            insert opps;
        }
    }

    public static void additionalGCLCodesRecords_CampaignType_D(){
        List<Opportunity> opps = new List<Opportunity>();
        List<Account> accs = new List<Account>();
        Campaign objCampaign = TestUtils.createCampaign('Testcampaign',false);
        objCampaign.Bequest_Sharing_Code__c = 'Q001';
        objCampaign.rC_Giving__Sub_Affiliation__c = '4 - National Foundation';
        insert objCampaign;
        
        Account acc = createAccount('Default', null, 'NN', Date.Today(), '00000', 'Japan', false, true);
        Opportunity opp = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-24), 'A', '1', 'B', 50, 50, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder12 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 4, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder13 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-26), 'A', '1', 'B', 50, 4, 'Completed', 'NM_NewMexico', false);
        Opportunity oppOrder14 = CreateOpportunity(acc.Id, 'Test'+acc.Name, Date.Today().addMonths(-28), 'A', '1', 'B', 50, 50000, 'Completed', 'NM_NewMexico', false);
        List<Opportunity> oppToInsert = new List<Opportunity>{opp, oppOrder12, oppOrder13, oppOrder14};
        insert oppToInsert;
        Account acc1 = createAccount('ExpirationDateNull&NotRenewed', null, 'NN', null, '00000', 'Japan', true, false);
        Account nullDate_MembershipAccount = createAccount('LastMembershipGift&ExpirationNull', null, 'NN', null, '00000', 'Japan', false, false);
        
        
        
        //Account 
        Account acc2 = createAccount('Renewed', oppOrder13.id, 'NN', Date.Today(), '00000', 'Japan', true, false);
        Account a = createAccount('Account', oppOrder14.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        Account ac = createAccount('Account', oppOrder12.id, 'NN', Date.Today(), '00000', 'Japan', false, false);
        Account ac1 = createAccount('Account', oppOrder12.id, 'NN', Date.Today(), '00000', 'Japan', true, false);
        Account nullDateAccount = createAccount('ExpirationNull', oppOrder13.Id, 'NN', null, '00000', 'Japan', false, false);
        
        accs.add( a);
        accs.add( createAccount('WithOpportunity', opp.Id, 'NN', Date.Today()-366, '00000', 'Japan', false, false));
        accs.add(acc1);
        accs.add(acc2);
        
        List<Account> accToInsert = new List<Account>{acc1,nullDate_MembershipAccount,acc2,a,ac,ac1,nullDateAccount };
       
        if(!accToInsert.IsEmpty())
            insert accToInsert;
        //Opportunity with certain criteria
        
        Opportunity sustainerPledge = new Opportunity();
        sustainerPledge.name = 'Pledge Sustainer';
        sustainerPledge.closeDate = Date.Today();
        sustainerPledge.AccountId = accs[0].Id;
        sustainerPledge.Campaignid = objCampaign.id;
        sustainerPledge.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge.RecordtypeId = pledgeOppId;
        sustainerPledge.stageName = 'Closed';
        insert sustainerPledge;
        
        //Addintional GCS
        
        Opportunity pledgePaymentD = CreateOpportunity(accs[0].Id, 'D', Date.Today(), null, '5', 'D', 50, 50, 'Completed', 'NM_NewMexico', false);
        pledgePaymentD.rC_Giving__Parent__c = sustainerPledge.Id;
        pledgePaymentD.campaignId = objCampaign.Id;
        pledgePaymentD.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        pledgePaymentD.Sharing_Code_Override__c = false;
        opps.add(pledgePaymentD);
       
        if(!opps.IsEmpty()){
            insert opps;
        }
    }
    
      public static void additionalGCLTest(){
        List<Opportunity> opps = new List<Opportunity>();
        List<Opportunity> lstParentOpps = new List<Opportunity>();
        List<Opportunity> lstParentOppsFirst = new List<Opportunity>();
        List<Campaign> lstCampaign = new List<Campaign>();
        List<Account> lstAccs = new List<Account>();
        Campaign objCampaign = TestUtils.createCampaign('Testcampaign',false);
        objCampaign.rC_Giving__Sub_Affiliation__c = '3 - Affiliate Union';
        lstCampaign.add(objCampaign);
        
        Campaign objCampaign1 = TestUtils.createCampaign('Testcampaign',false);
        objCampaign1.rC_Giving__Sub_Affiliation__c = '1 - National Union';
        lstCampaign.add(objCampaign1);
        
        Campaign objCampaign2 = TestUtils.createCampaign('Testcampaign',false);
        objCampaign2.rC_Giving__Sub_Affiliation__c = '2 - Sustainers';
        lstCampaign.add(objCampaign2);
        
        insert lstCampaign;
        
        Account acc = createAccount('Default', null, 'NN', Date.Today(), '00000', 'Japan', false, true);
        
        Opportunity sustainerPledge = new Opportunity();
        sustainerPledge.name = 'Pledge Sustainer';
        sustainerPledge.closeDate = Date.Today().addMonths(-25);
        sustainerPledge.AccountId = acc.Id;
        sustainerPledge.Campaignid = objCampaign.id;
        sustainerPledge.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge.RecordtypeId = pledgeOppId;
        sustainerPledge.stageName = 'Closed';
        sustainerPledge.amount = 6.0;
        lstParentOppsFirst.add(sustainerPledge);
       
        
        Opportunity sustainerPledge4 = new Opportunity();
        sustainerPledge4.name = 'Pledge Sustainer';
        sustainerPledge4.closeDate = Date.Today().addMonths(-25);
        sustainerPledge4.AccountId = acc.Id;
        sustainerPledge4.Campaignid = objCampaign.id;
        sustainerPledge4.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge4.RecordtypeId = pledgeOppId;
        sustainerPledge4.stageName = 'Closed';
        sustainerPledge4.amount = 3.0;
        lstParentOppsFirst.add(sustainerPledge4);
        
        insert lstParentOppsFirst;
     
        Account acc2 = new Account(Name = 'Default', BillingCountry = 'Japan', BillingPostalCode = '00000', Last_Membership_Gift__c = sustainerPledge.id, Has_Renewed_Before__c = false, Affiliation__c = 'NN', Membership_Expiration_date__c = Date.Today() );
        Account acc3 = new Account(Name = 'Default', BillingCountry = 'Japan', BillingPostalCode = '00000', Last_Membership_Gift__c = sustainerPledge4.id, Has_Renewed_Before__c = false, Affiliation__c = 'NN', Membership_Expiration_date__c = Date.Today() );
        Account acc4 = new Account(Name = 'Default', BillingCountry = 'Japan', BillingPostalCode = '00000', Last_Membership_Gift__c = sustainerPledge4.id, Has_Renewed_Before__c = true, Affiliation__c = 'NN', Membership_Expiration_date__c = Date.Today() );
        lstAccs.add(acc2);
        lstAccs.add(acc3);
        lstAccs.add(acc4);
        
        Insert lstAccs;
        
        Opportunity sustainerPledge1 = new Opportunity();
        sustainerPledge1.name = 'Pledge Sustainer';
        sustainerPledge1.closeDate = Date.Today();
        sustainerPledge1.AccountId = acc2.Id;
        sustainerPledge1.Campaignid = objCampaign.id;
        sustainerPledge1.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge1.RecordtypeId = pledgeOppId;
        sustainerPledge1.stageName = 'Closed';
        lstParentOpps.add(sustainerPledge1);
        
        Opportunity sustainerPledge2 = new Opportunity();
        sustainerPledge2.name = 'Pledge Sustainer';
        sustainerPledge2.closeDate = Date.Today().addMonths(-25);
        sustainerPledge2.AccountId = acc2.Id;
        sustainerPledge2.Campaignid = objCampaign1.id;
        sustainerPledge2.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge2.RecordtypeId = pledgeOppId;
        sustainerPledge2.stageName = 'Closed';
        sustainerPledge2.amount = 6.0;
        lstParentOpps.add(sustainerPledge2);
        
        Opportunity sustainerPledge3 = new Opportunity();
        sustainerPledge3.name = 'Pledge Sustainer';
        sustainerPledge3.closeDate = Date.Today().addMonths(8);
        sustainerPledge3.AccountId = acc3.Id;
        sustainerPledge3.Campaignid = objCampaign2.id;
        sustainerPledge3.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge3.RecordtypeId = pledgeOppId;
        sustainerPledge3.stageName = 'Closed';
        sustainerPledge3.amount = 3.0;
        lstParentOpps.add(sustainerPledge3);
        
        Opportunity sustainerPledge5 = new Opportunity();
        sustainerPledge5.name = 'Pledge Sustainer';
        sustainerPledge5.closeDate = Date.Today().addMonths(8);
        sustainerPledge5.AccountId = acc4.Id;
        sustainerPledge5.Campaignid = objCampaign2.id;
        sustainerPledge5.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge5.RecordtypeId = pledgeOppId;
        sustainerPledge5.stageName = 'Closed';
        sustainerPledge5.amount = 3.0;
        lstParentOpps.add(sustainerPledge5);
        
        insert lstParentOpps;
        
        //Addintional GCS
        //Order 11 , 14
        Opportunity pledgePaymentD = CreateOpportunity(acc.Id, 'D1', Date.Today(), null, '5', 'S', 50, 50, 'Completed', 'NM_NewMexico', false);
        pledgePaymentD.rC_Giving__Parent__c = sustainerPledge.Id;
        pledgePaymentD.campaignId = objCampaign.Id;
        pledgePaymentD.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        pledgePaymentD.Sharing_Code_Override__c = false;
        opps.add(pledgePaymentD);
        //order 9
        Opportunity pledgePaymentD1 = CreateOpportunity(acc2.Id, 'D2', Date.Today(), null, '5', 'S', 50, 50, 'Completed', 'NM_NewMexico', false);
        pledgePaymentD1.rC_Giving__Parent__c = sustainerPledge1.Id;
        pledgePaymentD1.campaignId = objCampaign.Id;
        pledgePaymentD1.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        pledgePaymentD1.Sharing_Code_Override__c = false;
        opps.add(pledgePaymentD1);
        //order 9
        Opportunity pledgePaymentD2 = CreateOpportunity(acc2.Id, 'D3', Date.Today(), null, '1', 'S', 50, 50, 'Completed', 'NM_NewMexico', false);
        pledgePaymentD2.rC_Giving__Parent__c = sustainerPledge2.Id;
        pledgePaymentD2.campaignId = objCampaign1.Id;
        pledgePaymentD2.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        pledgePaymentD2.Sharing_Code_Override__c = false;
        opps.add(pledgePaymentD2);
        //Order 12
        Opportunity pledgePaymentD3 = CreateOpportunity(acc3.Id, 'D4', Date.Today().addMonths(8), null, '2', 'S', 50, 50, 'Completed', 'NM_NewMexico', false);
        pledgePaymentD3.rC_Giving__Parent__c = sustainerPledge3.Id;
        pledgePaymentD3.campaignId = objCampaign2.Id;
        pledgePaymentD3.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        pledgePaymentD3.Sharing_Code_Override__c = false;
      //  opps.add(pledgePaymentD3);
        
        Opportunity pledgePaymentD6 = CreateOpportunity(acc4.Id, 'D4', Date.Today().addMonths(8), null, '2', 'S', 50, 50, 'Completed', 'NM_NewMexico', false);
        pledgePaymentD6.rC_Giving__Parent__c = sustainerPledge5.Id;
        pledgePaymentD6.campaignId = objCampaign2.Id;
        pledgePaymentD6.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        pledgePaymentD6.Sharing_Code_Override__c = false;
        opps.add(pledgePaymentD6);
       
        if(!opps.IsEmpty()){
            insert opps;
        }
    }
    
    public static void additionalGCLTest_15_20(){
        List<Opportunity> opps = new List<Opportunity>();
        List<Opportunity> lstParentOpps = new List<Opportunity>();
        List<Opportunity> lstParentOppsFirst = new List<Opportunity>();
        List<Campaign> lstCampaign = new List<Campaign>();
        List<Account> lstAccs = new List<Account>();
        List<rC_Bios__Preference__c> lstPreferences = new List<rC_Bios__Preference__c>();
        
        Campaign objCampaign = TestUtils.createCampaign('Testcampaign',false);
        objCampaign.rC_Giving__Sub_Affiliation__c = '3 - Affiliate Union';
        lstCampaign.add(objCampaign);
        
        insert lstCampaign; 
        
        Account acc = createAccount('Default', null, 'NN', Date.Today(), '00000', 'Japan', false, true);
        
        Opportunity sustainerPledge = new Opportunity();
        sustainerPledge.name = 'Pledge Sustainer';
        sustainerPledge.closeDate = Date.Today().addMonths(8);
        sustainerPledge.AccountId = acc.Id;
        sustainerPledge.Campaignid = objCampaign.id;
        sustainerPledge.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge.RecordtypeId = pledgeOppId;
        sustainerPledge.stageName = 'Closed';
        sustainerPledge.amount = 1001.0;
        lstParentOppsFirst.add(sustainerPledge);
        
        insert lstParentOppsFirst;
        
        Account acc2 = new Account(Name = 'Default', BillingCountry = 'Japan', BillingPostalCode = '00000', Last_Membership_Gift__c = sustainerPledge.id, Has_Renewed_Before__c = false, Affiliation__c = 'NN', Membership_Expiration_date__c = date.Today() );
        Account acc3 = new Account(Name = 'Default', BillingCountry = 'Japan', BillingPostalCode = '00000', Last_Membership_Gift__c = sustainerPledge.id, Has_Renewed_Before__c = true, Affiliation__c = 'NN', Membership_Expiration_date__c = Date.Today() );

        lstAccs.add(acc2);
        lstAccs.add(acc3);
        
        Insert lstAccs; 
        
        rC_Bios__Preference__c opre = new rC_Bios__Preference__c ();
        opre.rC_Bios__Code_Value__c = 'AN';
        opre.rC_Bios__Active__c = TRUE;
        opre.rC_Bios__Account__c = acc.id;
        lstPreferences.add(opre);
        
        rC_Bios__Preference__c opre1 = new rC_Bios__Preference__c ();
        opre1.rC_Bios__Code_Value__c = 'AL';
        opre1.rC_Bios__Active__c = TRUE;
        opre1.rC_Bios__Account__c = acc3.id;
        lstPreferences.add(opre1);
        insert lstPreferences;
        
        Opportunity sustainerPledge1 = new Opportunity();
        sustainerPledge1.name = 'Pledge Sustainer';
        sustainerPledge1.closeDate = Date.Today().addMonths(8);
        sustainerPledge1.AccountId = acc2.Id;
        sustainerPledge1.Campaignid = objCampaign.id;
        sustainerPledge1.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge1.RecordtypeId = pledgeOppId;
        sustainerPledge1.stageName = 'Closed';
        sustainerPledge.amount = 1001.0;
        lstParentOpps.add(sustainerPledge1);
        
        Opportunity sustainerPledge2 = new Opportunity();
        sustainerPledge2.name = 'Pledge Sustainer';
        sustainerPledge2.closeDate = Date.Today().addMonths(8);
        sustainerPledge2.AccountId = acc3.Id;
        sustainerPledge2.Campaignid = objCampaign.id;
        sustainerPledge2.rC_Giving__Is_Sustainer__c = true;
        sustainerPledge2.RecordtypeId = pledgeOppId;
        sustainerPledge2.stageName = 'Closed';
        sustainerPledge2.amount = 1001.0;
        lstParentOpps.add(sustainerPledge2);
        
        insert lstParentOpps;
        
        //Addintional GCS
        Opportunity pledgePaymentD = CreateOpportunity(acc2.Id, 'D1', Date.Today(), null, '5', 'S', 50, 50, 'Completed', 'NM_NewMexico', false);
        pledgePaymentD.rC_Giving__Parent__c = sustainerPledge1.Id;
        pledgePaymentD.campaignId = objCampaign.Id;
        pledgePaymentD.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        pledgePaymentD.Sharing_Code_Override__c = false;
        opps.add(pledgePaymentD);
        
        Opportunity pledgePaymentD1 = CreateOpportunity(acc3.Id, 'D1', Date.Today(), null, '5', 'S', 1000, 50, 'Completed', 'NM_NewMexico', false);
        pledgePaymentD1.rC_Giving__Parent__c = sustainerPledge1.Id;
        pledgePaymentD1.campaignId = objCampaign.Id;
        pledgePaymentD1.Deposit_Site__c = 'NAA_NatU_Operating_chk/cash';
        pledgePaymentD1.Sharing_Code_Override__c = false;
        opps.add(pledgePaymentD1);

        if(!opps.IsEmpty()){
            insert opps;
        }
    }
    public static date addMonths(date expDate, Integer months){
        Date d = expdate.addMonths(months);
        return Date.newInstance(d.Year(), d.month(), Date.daysInMonth(d.Year(), d.month()));
    }
    
    //Sai:6/9-Commented below Test methods, because the test data for these calculations are being used in their respective Test Classes.
    /*
    *
    *Method BenifitSetup
    *Testing data for Benifit Calculation.
    */
    /*public static void BenifitSetup(){
        List<Account> Accounts = new List<Account>();
        List <Income_Type_Distribution__c> IntDs= new List <Income_Type_Distribution__c>(); 
        List<rC_Giving__Opportunity_Credit__c> credits = new List<rC_Giving__Opportunity_Credit__c>();
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Affiliate_Yearly__c> affYearls = new List<Affiliate_Yearly__c> ();
        
        // Account Records
        for(Integer i=0;i<10;i++){   
            Account acc = TestUtils.createAccount('Account'+i,false);
            acc.Membership_Expiration_date__c = Date.Today();
            acc.Affiliation__c = 'NN';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            acc.RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
            Accounts.add(acc);
        }
        if(!Accounts.isEmpty())
           insert Accounts;
        
        // Insert Opportunities
        for(Account acc: [SELECT Id,Name FROM Account ]){
            Opportunity opp= TestUtils.CreateOpportunity(acc.Id,'Test'+acc.Name,false);
            opp.stageName = 'Completed';
            opp.closeDate = date.newInstance(2016,5,12);
            opp.Sharing_Code__c = 'R141';
            opp.Program_Type__c ='1';
            opp.amount = 100;
            opp.Cost_Factor__c =10;
            //opp.Fiscal_Year_of_Close_Date__c = '2016'; 
            opp.Sharing_Entity_Affiliation__c = 'NN';
            opp.rC_Giving__Is_Giving__c = true;
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
            opportunities.add(opp);
        }
        
        if(!opportunities.isEmpty())
            insert opportunities;
            
        // Insert Credits
        for(Integer i=0; i<2; i++){
            rC_Giving__Opportunity_Credit__c objcredit = TestUtils.createOpportunityCredits(opportunities[0].Id, 'Account Only', 50, 'N111', false); 
            objcredit.Sharing_Code__c = 'R141';
            objcredit.rC_Giving__Amount__c = 10;
            objcredit.Cost_Factor__c =10;
            objcredit.Sharing_Entity__c = 'NN';
            credits.add(objcredit);
        }      
        
        if(!credits.isEmpty())
            insert credits;  
        
        // affiliateYearly records insert
        for(Integer i=0;i<1;i++){
            Affiliate_Yearly__c aff = TestUtils.createAffiliateYearly('Test1',Accounts[0].Id, String.valueOf(system.today().year()),false);
            aff.BRI_Affiliate_Share__c = 10;
            aff.Foundation_Cost_Factor__c = 10;
            aff.Union_Cost_Factor__c = 10;
            affYearls.add(aff);
        }
        
        if(!affYearls.isEmpty())
            insert affYearls;
        
        //Income TypeDistribution
        for(Affiliate_Yearly__c aff: [SELECT Id FROM Affiliate_Yearly__c ]){
            Income_Type_Distribution__c iTD = TestUtils.createIncomeTypeDistribution(aff.Id, 'Benefit', 10, false);
            IntDs.add(iTD);
        }
        
        if(!IntDs.isEmpty())
            insert IntDs;
        
        
    }*/
    
     /*
    *
    *Method Incentivesetup
    *Testing data for Incentive Calculation.
    */
    /*public static void Incentivesetup(){
        List<Account> Accounts = new List<Account>();
        List <Income_Type_Distribution__c> IntDs= new List <Income_Type_Distribution__c>(); 
        List<rC_Giving__Opportunity_Credit__c> credits = new List<rC_Giving__Opportunity_Credit__c>();
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Affiliate_Yearly__c> affYearls = new List<Affiliate_Yearly__c> ();
        
        // Account Records
        for(Integer i=0;i<10;i++){   
            Account acc = TestUtils.createAccount('Account'+i,false);
            acc.Membership_Expiration_date__c = Date.Today();
            acc.Affiliation__c = 'NN';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            acc.RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
            Accounts.add(acc);
        }
        if(!Accounts.isEmpty())
           insert Accounts;
        
        // Insert Opportunities
        for(Account acc: [SELECT Id,Name FROM Account ]){
            Opportunity opp= TestUtils.CreateOpportunity(acc.Id,'Test'+acc.Name,false);
            opp.stageName = 'Completed';
            opp.closeDate = date.newInstance(2016,5,12);
            opp.Sharing_Code__c = 'R131';
            opp.Program_Type__c ='1';
            opp.amount = 100;
            opp.Cost_Factor__c =10;
            //opp.Fiscal_Year_of_Close_Date__c = '2016'; 
            opp.Sharing_Entity_Affiliation__c = 'NN';
            opp.rC_Giving__Is_Giving__c = true;
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
            opportunities.add(opp);
        }
        
        if(!opportunities.isEmpty())
            insert opportunities;
            
        // Insert Credits
        for(Integer i=0; i<2; i++){
            rC_Giving__Opportunity_Credit__c objcredit = TestUtils.createOpportunityCredits(opportunities[0].Id, 'Account Only', 50, 'N111', false); 
            objcredit.Sharing_Code__c = 'R131';
            objcredit.rC_Giving__Amount__c = 10;
            objcredit.Cost_Factor__c =10;
            objcredit.Sharing_Entity__c = 'NN';
            credits.add(objcredit);
        }      
        
        if(!credits.isEmpty())
            insert credits;  
        
        // affiliateYearly records insert
        for(Integer i=0;i<1;i++){
            Affiliate_Yearly__c aff = TestUtils.createAffiliateYearly('Test1',Accounts[0].Id, String.valueOf(system.today().year()),false);
            aff.BRI_Affiliate_Share__c = 10;
            affYearls.add(aff);
        }
        
        if(!affYearls.isEmpty())
            insert affYearls;
        
        //Income TypeDistribution
        for(Affiliate_Yearly__c aff: [SELECT Id FROM Affiliate_Yearly__c ]){
            Income_Type_Distribution__c iTD = TestUtils.createIncomeTypeDistribution(aff.Id, 'Incentive', 10, false);
            IntDs.add(iTD);
        }
        
        if(!IntDs.isEmpty())
            insert IntDs;
        
        
    }*/
    
     /*
    *
    *Method unsharedsetup
    *Testing data for Unshared Calculation.
    */
    /*public static void unsharedsetup(){
        List<Account> Accounts = new List<Account>();
        List <Income_Type_Distribution__c> IntDs= new List <Income_Type_Distribution__c>(); 
        List<Opportunity> opportunities = new List<Opportunity>();
        List<Affiliate_Yearly__c> affYearls = new List<Affiliate_Yearly__c> ();
        
        // Account Records
        for(Integer i=0;i<10;i++){   
            Account acc = TestUtils.createAccount('Account'+i,false);
            acc.Membership_Expiration_date__c = Date.Today();
            acc.Affiliation__c = 'NN';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            acc.RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
            Accounts.add(acc);
        }
        if(!Accounts.isEmpty())
           insert Accounts;
        
        list<String> sharingCodes = new list<String>{'A001','P002','B003'};
        list<String> sharingEntities = new list<String>{'NN','FN'};
        Integer x = 0;
        Integer y = 0;
        // Insert Opportunities
        for(Account acc: [SELECT Id,Name FROM Account ]){
            if(x >= 3) x = 0;
            if(y >= 2) y = 0;
            Opportunity opp= TestUtils.CreateOpportunity(acc.Id,'Test'+acc.Name,false);
            opp.stageName = 'Completed';
            opp.Sharing_Code__c = sharingCodes.get(x);
            x++;
            opp.closeDate = date.newInstance(2016,5,12);
            opp.amount = 100;
            opp.Cost_Factor__c =10;
            //opp.Fiscal_Year_of_Close_Date__c = '2016'; 
            opp.Sharing_Entity_Affiliation__c = sharingEntities.get(y);
            y++;
            opp.rC_Giving__Is_Giving__c = true;
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
            opportunities.add(opp);
        }
        
        if(!opportunities.isEmpty()) {
            //opportunities.get(0).Sharing_Code__c = 'P002';
            //opportunities.get(0).Sharing_Entity_Affiliation__c = 'FN';
            //opportunities.get(1).Sharing_Code__c = 'B003';
            
            insert opportunities;
        }
        // affiliateYearly records insert
        for(Integer i=0;i<1;i++){
            Affiliate_Yearly__c aff = TestUtils.createAffiliateYearly('Test1',Accounts[0].Id, String.valueOf(system.today().year()),false);
            aff.BRI_Affiliate_Share__c = 10;
            affYearls.add(aff);
        }
        
        if(!affYearls.isEmpty())
            insert affYearls;
        
        //Income TypeDistribution
        for(Affiliate_Yearly__c aff: [SELECT Id FROM Affiliate_Yearly__c ]){
            Income_Type_Distribution__c iTD = TestUtils.createIncomeTypeDistribution(aff.Id, 'Unshared Restricted Gifts', 10, false);
            IntDs.add(iTD);
        }
        
        if(!IntDs.isEmpty())
            insert IntDs;
        
        
    }*/
    
    /*
    *
    *Method FBRIsetup
    *Testing data for FBRI Calculation.
    */
    /*public static void FBRIsetup(){
        List<Account> Accounts = new List<Account>();
        List<Opportunity> opportunities = new List<Opportunity>();
        List <Income_Type_Distribution__c> IntDs= new List <Income_Type_Distribution__c>(); 
        List<rC_Giving__Opportunity_Credit__c> credits = new List<rC_Giving__Opportunity_Credit__c>();
        List<Affiliate_Yearly__c> affYearls = new List<Affiliate_Yearly__c> ();
        // Account Records
        for(Integer i=0;i<10;i++){   
            Account acc = TestUtils.createAccount('Account'+i,false);
            acc.Membership_Expiration_date__c = Date.Today();
            acc.Affiliation__c = 'NN';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            acc.RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
            Accounts.add(acc);
        }
        
        if(!Accounts.isEmpty())
            insert Accounts;
        
        // Insert Opportunities
        for(Account acc: [SELECT Id,Name FROM Account ]){
            Opportunity opp= TestUtils.CreateOpportunity(acc.Id,'Test'+acc.Name,false);
            opp.stageName = 'Completed';
            opp.Sharing_Code__c = 'N111';
            opp.amount = 100;
            opp.closeDate = date.newInstance(2016,5,12);
            opp.Cost_Factor__c =10;
            opp.Use_Campaign_Cost__c = true;
            //opp.Fiscal_Year_of_Close_Date__c = '2016'; 
            opp.Sharing_Entity__c = 'NN';
            Opp.Sharing_Entity_Affiliation__c = 'NN';
            opp.rC_Giving__Is_Giving__c = true;
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
            opportunities.add(opp);
        }
        if(!opportunities.isEmpty())
            insert opportunities;
        
        // affiliateYearly records insert
        for(Integer i=0;i<1;i++){
            Affiliate_Yearly__c aff = TestUtils.createAffiliateYearly('Test1',Accounts[0].Id, String.valueOf(system.today().year()),false);
            aff.BRI_Affiliate_Share__c = 10;
            affYearls.add(aff);
        }
        
        if(!affYearls.isEmpty())
            insert affYearls;
        
        // Insert Credits
        for(Integer i=0; i<2; i++){
            rC_Giving__Opportunity_Credit__c objcredit = TestUtils.createOpportunityCredits(opportunities[0].Id, 'Account Only', 50, 'N111', false); 
            objcredit.Sharing_Code__c = 'N111';
            objcredit.rC_Giving__Amount__c = 10;
            objcredit.Cost_Factor__c =10;
            objcredit.Sharing_Entity__c = 'NN';
            credits.add(objcredit);
        }      
        
        if(!credits.isEmpty())
            insert credits;  
            
        //Income TypeDistribution
        for(Affiliate_Yearly__c aff: [SELECT Id FROM Affiliate_Yearly__c ]){
            Income_Type_Distribution__c iTD = TestUtils.createIncomeTypeDistribution(aff.Id, 'FBRI', 10, false);
            IntDs.add(iTD);
        }
        
        if(!IntDs.isEmpty())
            insert IntDs;
    }*/
    
    /*
    *
    *Method UBRIsetup
    *Testing data for UBRI Calculation.
    */
    /*public static void UBRIsetup(){
        List<Account> Accounts = new List<Account>();
        List<Opportunity> opportunities = new List<Opportunity>();
        List <Income_Type_Distribution__c> IntDs= new List <Income_Type_Distribution__c>(); 
        List<rC_Giving__Opportunity_Credit__c> credits = new List<rC_Giving__Opportunity_Credit__c>();
        List<Affiliate_Yearly__c> affYearls = new List<Affiliate_Yearly__c> ();
        // Account Records
        for(Integer i=0;i<10;i++){   
            Account acc = TestUtils.createAccount('Account'+i,false);
            acc.Membership_Expiration_date__c = Date.Today();
            acc.Affiliation__c = 'NN';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            acc.RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
            Accounts.add(acc);
        }
        
        if(!Accounts.isEmpty())
            insert Accounts;
        
        // Insert Opportunities
        for(Account acc: [SELECT Id,Name FROM Account ]){
            Opportunity opp= TestUtils.CreateOpportunity(acc.Id,'Test'+acc.Name,false);
            opp.stageName = 'Completed';
            opp.Sharing_Code__c = 'E017';
            opp.amount = 100;
            opp.closeDate = date.newInstance(2016,5,12);
            opp.Cost_Factor__c =10;
            opp.Use_Campaign_Cost__c = true;
            //opp.Fiscal_Year_of_Close_Date__c = '2016'; 
            opp.Sharing_Entity__c = 'NN';
            Opp.Sharing_Entity_Affiliation__c = 'NN';
            opp.rC_Giving__Is_Giving__c = true;
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
            opportunities.add(opp);
        }
        if(!opportunities.isEmpty())
            insert opportunities;
        
        // affiliateYearly records insert
        for(Integer i=0;i<1;i++){
            Affiliate_Yearly__c aff = TestUtils.createAffiliateYearly('Test1',Accounts[0].Id, String.valueOf(system.today().year()),false);
            aff.BRI_Affiliate_Share__c = 10;
            affYearls.add(aff);
        }
        
        if(!affYearls.isEmpty())
            insert affYearls;
        
        // Insert Credits
        for(Integer i=0; i<2; i++){
            rC_Giving__Opportunity_Credit__c objcredit = TestUtils.createOpportunityCredits(opportunities[0].Id, 'Account Only', 50, 'N111', false); 
            objcredit.Sharing_Code__c = 'N111';
            objcredit.rC_Giving__Amount__c = 10;
            objcredit.Cost_Factor__c =10;
            objcredit.Sharing_Entity__c = 'NN';
            credits.add(objcredit);
        }      
        
        if(!credits.isEmpty())
            insert credits;  
            
        //Income TypeDistribution
        for(Affiliate_Yearly__c aff: [SELECT Id FROM Affiliate_Yearly__c ]){
            Income_Type_Distribution__c iTD = TestUtils.createIncomeTypeDistribution(aff.Id, 'UBRI', 10, false);
            IntDs.add(iTD);
        }
        
        if(!IntDs.isEmpty())
            insert IntDs;
    }*/
    
    
    // Not using the method present in the TestUtilis as requires custom fields for long records
    private static Opportunity createOpportunity(Id AccountId, String Name, date closeDate, String sharingCode, String programType, String campaignType, Integer givingAmount, Integer Iamount, String Stage, String depositSite, Boolean doInsert){
        Opportunity opp = new Opportunity(rC_Giving__Affiliation__c = 'NGO', Campaign_Type__c = campaignType,Program_Type__c = programType, amount = Iamount, RecordtypeId = pledgeOppPaymentId, Deposit_Site__c = depositSite, Sharing_Code__c = sharingCode,rC_Giving__Giving_Amount__c = givingAmount, AccountId = AccountId ,Name = Name, CloseDate = closeDate, StageName = stage);
        if(doInsert)
            insert opp;
        return opp;
    }
    
    private static Account createAccount(String name, Id oppId, String Affiliation, date Membership, String PostalCode, String Country, Boolean hasRenewed, Boolean doInsert){
        Account acc = new Account(Name = name, BillingCountry = Country, BillingPostalCode = PostalCode, Last_Membership_Gift__c = oppId, Has_Renewed_Before__c = hasRenewed, Affiliation__c = Affiliation, Membership_Expiration_date__c = Membership );
        if(doInsert)
            insert acc;
        return acc;
    }

    // DS - 2019-04-15 - Pulling exisitng method out of RevenueSharingShareCodesTest, as it needs to be repeated frequently
    public static User createAndInsertTestUser() {
        User usr = TestUtils.createUser('userTest', 'usert25@aclu.org' + Math.random(), null, false);
        usr.Is_Affiliate_User__c = false;
        usr.Denied_Access_to_Open_Givings__c = false;
        usr.Email = 'usertes25@aclu.org';
        insert usr;
        return usr;
    }
}