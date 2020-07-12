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
*/

/*
*
*Name  :  PreferenceTriggerHandlerTest
*Author:  Appirio India (Sai Krishna )
*Date  :  NOvember 23, 2016
*Purpose : Reset the shareing for the lookups changes
*
*/
@isTest
private class PreferenceTriggerHandlerTest {
    public static Account acc = new Account();
    public static List<Account> Accounts;
    public static AccountTeamMember atm;
    Public static OpportunityTeamMember otm;
    public Static User usr;
    public static List<rC_Bios__Preference__c> listPreference ;
    public static List<rC_Bios__Preference__c> updatedPrefrence;
    public static List<Opportunity> listOpportunity ;
    /*
    *
    *Method preferenceAccountLookupSharingTest
    *Testing if preference record created then share is created based on related affiliate.
    */
    static testMethod void preferenceAccountLookupSharingTest() {
        //List<rC_Bios__Preference__c> updatedPrefrence = new List<rC_Bios__Preference__c>();
        setup();
        
        Test.startTest();
            insert listPreference;
        
            //insert listOpportunity;
        
            Integer j = 0 ;
            //update Preferences code value
            for(rC_Bios__Preference__c pre:listPreference){
                rC_Bios__Preference__c pref1 = new rC_Bios__Preference__c();
                pref1.Id= pre.id;
                if(j == 0){
                    pref1.rC_Bios__Code_Value__c = 'BA';
                }
                else if(j == 1){
                    pref1.rC_Bios__Code_Value__c = 'MQ';
                }
                else If(j == 2){
                    pref1.rC_Bios__Code_Value__c = 'ML';
                }
                j++;
                updatedPrefrence.add(pref1);
            }
        
            update updatedPrefrence;
        Test.stopTest();
        
        //verify the accountPreference String are updated or not.
        for(rC_Bios__Preference__c pre: [select id, rC_Bios__Account__r.Affiliate_Major_Donor_Prospect_MQ__c, rC_Bios__Code_Value__c FROM rC_Bios__Preference__c
                                             WHERE rC_Bios__Code_Value__c = 'MQ']){
            system.assertEquals(true, pre.rC_Bios__Account__r.Affiliate_Major_Donor_Prospect_MQ__c);
        }
        
        for(rC_Bios__Preference__c pre: [select id, rC_Bios__Account__r.Affiliate_Major_Gifts_Program_ML__c, rC_Bios__Code_Value__c FROM rC_Bios__Preference__c 
                                            WHERE rC_Bios__Code_Value__c = 'ML']){
            system.assertEquals(true, pre.rC_Bios__Account__r.Affiliate_Major_Gifts_Program_ML__c);
        }
        
        for(rC_Bios__Preference__c pre: [select id, rC_Bios__Account__r.Rpt_Board_Member__c, rC_Bios__Code_Value__c FROM rC_Bios__Preference__c 
                                            WHERE rC_Bios__Code_Value__c = 'BA']){
            system.assertEquals(true, pre.rC_Bios__Account__r.Rpt_Board_Member__c);
        }
    }
    
    //Method to cover the Deleteblocks
    private static testMethod void testDeletePrefrence(){
        setup();
        Test.StartTest();
            insert listPreference;
            
            Delete listPreference;
        Test.stopTest();
        for(Account acc: [SELECT Preference_String__c FROM Account]){
            system.assertEquals(acc.Preference_String__c, null);
        }
    }
    
    //Method checks the sharingApex for the prefrence record link with contact
    private static testMethod void testContactInsert(){
        Map<String,Id> mapGroupNameToId = new map<String,Id>();

        setup();        
        Test.startTest();
            Account acc = TestUtils.createAccount('Account',false);
            acc.Affiliation__c = 'NN';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            insert acc;
            Contact con = TestUtils.createContact(acc,'cons'+1,'testPhone'+1,false);
            insert con;
            
            //Setting up the contactId for the prefrences created.
          for(rC_Bios__Preference__c pre: listPreference ){
              pre.rC_Bios__Account__c = acc.id;
              pre.rC_Bios__Contact__c = con.Id;
          }
          
          insert listPreference;
          
          for(Group gp: [SELECT id, name FROM group ]){
                mapGroupNameToId.put(gp.name,gp.Id);
            }
          
        Test.StopTest();
        //verifying the preference Share records
        for(rC_Bios__Preference__share preShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Preference__share where UserOrGroupId =:mapGroupNameToId.get('NN') AND ParentId =:listPreference AND AccessLevel = 'Edit']){
           system.assertEquals(preShare.UserOrGroupId,mapGroupNameToId.get('NN'));
        }
    }
    
    // method updates the accountlookup on preference records.
    private static testMethod void testSharingUpdate(){
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapPrferenceIdToAffilate = new map<Id,String>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        List<rC_Bios__Preference__c> preferenceRecords = new List<rC_Bios__Preference__c>();    
        
        setup();
        Test.startTest();
            insert listPreference;
            
            for(Group gp: [SELECT id, name FROM group ]){
                mapGroupNameToId.put(gp.name,gp.Id);
            }
            
            // Preference Records
            for(rC_Bios__Preference__c pre: [SELECT id, rC_Bios__Account__r.Affiliation__c FROM rC_Bios__Preference__c]){   
                //rC_Bios__Preference__c Pre = TestUtils.CreatePreferences(acc.Id,true);
                mapPrferenceIdToAffilate.put(Pre.Id, Pre.rC_Bios__Account__r.Affiliation__c);
                preferenceRecords.add(pre); 
            }
            
            Account acc = TestUtils.createAccount('Account',false);
            acc.Affiliation__c = 'ZF';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            insert acc;
            
            //update account affiliation so that the preference records affiliation updates.
            for(rC_Bios__Preference__c pre: preferenceRecords ){
                system.debug('account is '+acc.Affiliation__c);
                pre.rC_Bios__Account__c = acc.Id;
                
                //AccountsToBeUpdate.add(acc);
            }
            update preferenceRecords;
            
        Test.StopTest();
        
        //verifying the preference Share records
        for(rC_Bios__Preference__share preShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Preference__share where UserOrGroupId =:mapGroupNameToId.get('ZF') AND ParentId =:mapPrferenceIdToAffilate.keySet() AND AccessLevel = 'Edit']){
           system.assertEquals(preShare.UserOrGroupId,mapGroupNameToId.get('ZF'));
        }
    }
    
    private static testMethod void testSharingContactUpdate(){
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapPrferenceIdToAffilate = new map<Id,String>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        List<rC_Bios__Preference__c> preferenceRecords = new List<rC_Bios__Preference__c>();    
        
        setup();
        Test.startTest();
            insert listPreference;
            
            for(Group gp: [SELECT id, name FROM group ]){
                mapGroupNameToId.put(gp.name,gp.Id);
            }
            
            // Preference Records
            for(rC_Bios__Preference__c pre: [SELECT id, rC_Bios__contact__r.account.Affiliation__c FROM rC_Bios__Preference__c]){   
                //rC_Bios__Preference__c Pre = TestUtils.CreatePreferences(acc.Id,true);
                mapPrferenceIdToAffilate.put(Pre.Id, Pre.rC_Bios__contact__r.account.Affiliation__c);
                preferenceRecords.add(pre); 
            }
            
            Account acc = TestUtils.createAccount('Account',false);
            acc.Affiliation__c = 'ZF';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            insert acc;
            
            Contact con = TestUtils.createContact(acc,'cons'+1,'testPhone'+1,false);
            insert con;
            
            //update account affiliation so that the preference records affiliation updates.
            for(rC_Bios__Preference__c pre: preferenceRecords ){
                system.debug('account is '+acc.Affiliation__c);
                pre.rC_Bios__contact__c = con.Id;
                
                //AccountsToBeUpdate.add(acc);
            }
            update preferenceRecords;
            
        Test.StopTest();
        
        //verifying the preference Share records
        for(rC_Bios__Preference__share preShare: [SELECT Id, AccessLevel, UserOrGroupId FROM rC_Bios__Preference__share where UserOrGroupId =:mapGroupNameToId.get('ZF') AND ParentId =:mapPrferenceIdToAffilate.keySet() AND AccessLevel = 'Edit']){
           system.assertEquals(preShare.UserOrGroupId,mapGroupNameToId.get('ZF'));
        }
            
    }
    
     private static testMethod void testDuplicatePreferenceCheck(){
      
        List<rC_Bios__Preference__c> preferenceRecords = new List<rC_Bios__Preference__c>();    
        
        setup();
       
        
            for(rC_Bios__Preference__c oPre : listPreference){
                oPre.rC_Bios__End_Date__c = null;
                oPre.rC_Bios__Account__c = Accounts[0].id;
                if(oPre.rC_Bios__Code_Value__c !='123' && oPre.rC_Bios__Code_Value__c <> null)
                preferenceRecords.add(oPre);
            }
            try{
            insert preferenceRecords;
            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            System.assertNotEquals(0, pageMessages.size());
            }catch(exception ex){}
         
    }
    
    
    /*
    *
    *Method setup
    *Testing if Affiliation updated then accountShare is re-calculated.
    */
    public static void setup(){
        Accounts = new List<Account>();
        listPreference = new list<rC_Bios__Preference__c>();
        updatedPrefrence = new List<rC_Bios__Preference__c>();
        listOpportunity = new List<Opportunity>();
        
        //Account team Member Records
        //  Public static AccountTeamMembers atm = new AccountTeamMembers();
        
        // Account Records
        for(Integer i=0;i<5;i++){   
            Account acc = TestUtils.createAccount('Account'+i,false);
            acc.Affiliation__c = 'NN';
            acc.BillingPostalCode = '00000';
            acc.BillingCountry = 'Japan';
            Accounts.add(acc);
        }   
        insert Accounts;
        
        //Opportunity Records
        for(Integer k=0;k<2;k++){
            Opportunity opp = TestUtils.createOpportunity(Accounts[0].Id,'Opp'+k, false);
            opp.recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
            listOpportunity.add(opp);
        }
        insert listOpportunity;
        
        //user records 
        usr = TestUtils.createUser( 'Test1','puser00011@amamama.com', null, true);
        
        
        atm = TestUtils.createAccountTeamMember(usr.Id,Accounts[0].Id,true);
  
        
        // create Opportunity team Member object 
        
        otm = TestUtils.createOpportunityTeamMember(usr.Id, listOpportunity[0].Id, true);
        
        //Preference records
        for(Integer i=0;i<5;i++) {
            rC_Bios__Preference__c pref = TestUtils.createPreferences(Accounts[i].Id,false);
            pref.rC_Bios__End_Date__c = System.Today();
            //pref.rC_Bios__Code_Value__c = 'MQ';
            pref.rC_Bios__Account__c = Accounts[0].id;
            pref.rC_Bios__Category__c = 'Programmatic';
            pref.rC_Bios__Subcategory__c = 'Major Gifts';
            pref.rC_Bios__Type__c= 'M1';
            pref.rC_Bios__Subtype__c='Top Prospects';
            pref.rC_Bios__Active__c =true;
            
            
            if(i == 0){
                pref.rC_Bios__Code_Value__c = 'BA';
            }
            else if(i == 1){
                pref.rC_Bios__Code_Value__c = 'MQ';
            }
            else If(i == 2){
                pref.rC_Bios__Code_Value__c = 'ML';
            }
            
            listPreference.add(pref);
            
        }
    }
    
}