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
* coverage, and provent regressions. All Apex classes are
* required to have at least 75% code coverage in order to be deployed
* to a production organization. In addition, all triggers must have some code coverage.
* 
* The @isTest class annotation indicates this class only contains test
* methods. Classes defined with the @isTest annotation do not count against
* the organization size limit for all Apex scripts.
*
* See the Apex Language Reference for more information about Testing and Code Coverage.
Modified by :: roundCorner Inc. :: 12-Feb-2019 :: Zendesk: #58568
*/

/*
*
*Name  :  ProsResearchTriggerHandlerTest
*Author:  Appirio India (Sakshi Arora)
*Date  :  May 19,2017
*Purpose : Reset the shareing for the lookups changes
*
*/
@isTest
public class ProsResearchTriggerHandlerTest {
    public static List<Account> Accounts;
    public static List<Contact> Contacts;
    public Static Contact con;
    public static List<Prospect_Research__c> listProspect;
    /*
*
*Method ProspectResearchTest 
*Testing if proference record created then share is created based on related affiliate.
*/
    static testMethod void prospectResearchTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapProResearchIdToAffilate = new map<Id,String>();
        List<Account> AccountsToBeUpdate = new List<Account>();
        List<Prospect_Research__c> proResearchUpdate = new List<Prospect_Research__c>();  
        listProspect = new List<Prospect_Research__c>(); 
        
        
        setup();
        
        Test.startTest();
        
        insert listProspect;
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        
        // Prospect Research Records
        for(Contact con: [SELECT Id, account.Affiliation__c,accountId FROM Contact]){   
            Prospect_Research__c pr = TestUtils.createProspectResearch(con.Id,true);
            mapProResearchIdToAffilate.put(pr.Id,con.account.Affiliation__c); 
        }  
        
        // changing the Prospect account lookup 
        
        Prospect_Research__c pr = [SELECT Id, Account__c FROM Prospect_Research__c LIMIT 1];
        Account acc = TestUtils.createAccount('Account'+10,true);
        
        pr.Account__c = acc.id;
        update pr;
        
        //changing the prospect Account Lookup 
        Contact con = TestUtils.createContact(acc,'con'+1,'test'+1,true);
        update con;
        
        
        for(Id objId: mapProResearchIdToAffilate.Keyset()){
            Prospect_Research__c pro = new Prospect_Research__c();
            pro.Id = objId;
            pro.Account__c = acc.id;
            pro.Contact__c = con.id;
            
            proResearchUpdate.add(pro);
        }
        
        if(!proResearchUpdate.isEmpty()){
            upsert proResearchUpdate;
        }
        
        if(!proResearchUpdate.isEmpty()){
            delete proResearchUpdate;
        } 
        
        Test.stopTest();
        
        for(Prospect_Research__share proShare: [SELECT Id, AccessLevel, ParentId FROM Prospect_Research__share 
                                                WHERE ParentId =:mapProResearchIdToAffilate.keySet() 
                                                AND AccessLevel = 'Edit']){
                                                    system.assertEquals(proShare.UserOrGroupId,mapGroupNameToId.get('NN'));
                                                }
        
        // check the provious deleted records
        List<Prospect_Research__share> prShare = [SELECT Id, AccessLevel, ParentId FROM Prospect_Research__share
                                                  where UserOrGroupId =:mapGroupNameToId.get('ZF')
                                                  AND ParentId =:mapProResearchIdToAffilate.keySet()
                                                  AND AccessLevel = 'Edit'];
        system.assertEquals(prShare.size(),0); 
        
    }
    //Created a method to check Gift Date and Gift year
    //Zendesk: #58568
    static testMethod void prospectResearchGiftDateTest() { 
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapProResearchIdToAffilate = new map<Id,String>();
        List<Account> AccountsToBeUpdate = new List<Account>();
        List<Prospect_Research__c> proResearchUpdate = new List<Prospect_Research__c>();  
        listProspect = new List<Prospect_Research__c>(); 
        
        
        setup();
        
        Test.startTest();
        
        insert listProspect;
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        
        // Prospect Research Records
        for(Contact con: [SELECT Id, account.Affiliation__c,accountId FROM Contact]){   
            Prospect_Research__c pr = TestUtils.createProspectResearch(con.Id,true);
            mapProResearchIdToAffilate.put(pr.Id,con.account.Affiliation__c); 
        }  
        
        // changing the Prospect account lookup 
        
        Prospect_Research__c pr = [SELECT Id, Account__c FROM Prospect_Research__c LIMIT 1];
        Account acc = TestUtils.createAccount('Account'+10,true);
        
        pr.Account__c = acc.id;
        update pr;
        
        //changing the prospect Account Lookup 
        Contact con = TestUtils.createContact(acc,'con'+1,'test'+1,true);
        update con;
        
        String otherCharitableId = Schema.SObjectType.Prospect_Research__c.getRecordTypeInfosByName().get('Other Charitable Giving').getRecordTypeId();
        for(Id objId: mapProResearchIdToAffilate.Keyset()){
            Prospect_Research__c pro = new Prospect_Research__c();
            pro.Id = objId;
            pro.Account__c = acc.id;
            pro.Contact__c = con.id;
            pro.recordTypeId = otherCharitableId;
            pro.Gift_Year__c = '2019';
            proResearchUpdate.add(pro);
        }
        
        if(!proResearchUpdate.isEmpty()){
            upsert proResearchUpdate;
        }
        
        if(!proResearchUpdate.isEmpty()){
            delete proResearchUpdate;
        } 
        
        Test.stopTest();
        
        for(Prospect_Research__share proShare: [SELECT Id, AccessLevel, ParentId FROM Prospect_Research__share 
                                                WHERE ParentId =:mapProResearchIdToAffilate.keySet() 
                                                AND AccessLevel = 'Edit']){
                                                    system.assertEquals(proShare.UserOrGroupId,mapGroupNameToId.get('NN'));
                                                }
        
        // check the provious deleted records
        List<Prospect_Research__share> prShare = [SELECT Id, AccessLevel, ParentId FROM Prospect_Research__share
                                                  where UserOrGroupId =:mapGroupNameToId.get('ZF')
                                                  AND ParentId =:mapProResearchIdToAffilate.keySet()
                                                  AND AccessLevel = 'Edit'];
        system.assertEquals(prShare.size(),0); 
    	    
    }
    //Created a method to check Gift Date and Gift year
    //Zendesk: #58568
	static testMethod void prospectResearchGiftYearTest() { 
        Test.startTest();
        List<Prospect_Research__c> proResearchUpdate = new List<Prospect_Research__c>();  
        String otherCharitableId = Schema.SObjectType.Prospect_Research__c.getRecordTypeInfosByName().get('Other Charitable Giving').getRecordTypeId();
        for(integer i=0;i<5;i++){
            Prospect_Research__c pro = new Prospect_Research__c();
            pro.recordTypeId = otherCharitableId;
            pro.Gift_Date__c = System.today();
            proResearchUpdate.add(pro);
        }
        
        if(!proResearchUpdate.isEmpty()){
            upsert proResearchUpdate;
        }
        Test.stopTest();
        List<Prospect_Research__c> proResearchList = [SELECT id,Gift_Date__c,Gift_Year__c
                                                        FROM  Prospect_Research__c];
        System.assertEquals(true,proResearchList[0].Gift_Year__c != null);
    }    
    /*
*
*Method setup
*Testing if Affiliation updated then accountShare is re-calculated.
*/
    public static void setup(){
        Accounts = new List<Account>();
        
        // Account Records
        for(Integer i=0;i<2;i++){   
            Account acc = TestUtils.createAccount('Account'+i,false);
            acc.Affiliation__c = 'DC';
            acc.Restricted_Account__c = False;
            Accounts.add(acc);
        }  
        insert Accounts;
        
        //Contact Records
        con = TestUtils.createContact(Accounts[0],'cons'+1,'testPhone'+1,false);
        insert con; 
        
        //Prospect Records
        for(Integer j=0;j<2;j++){
            Prospect_Research__c pro1 = TestUtils.createProspectResearch(con.Id,false);
            pro1.Account__c = Accounts[j].Id;
            pro1.Contact__c = con.id;
            listProspect.add(pro1);
        }
        
    }
    
    
}