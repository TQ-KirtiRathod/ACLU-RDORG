@isTest
public class ConfDataTriggerHandlerTest {
    public static List<Account> Accounts;
    public static List<Contact> Contacts;
    public Static Contact con;
    public static Opportunity opp;
    public static List<Confidential_Data__c> listConfData;
    /*
*
*Method cdospectResearchTest 
*Testing if cdoference record created then share is created based on related affiliate.
*/
    static testMethod void confDataTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapConfDataIdToAffliate = new map<Id,String>();
        List<Account> AccountsToBeUpdate = new List<Account>();
        List<Confidential_Data__c> ConfDataUpdate = new List<Confidential_Data__c>();  
        listConfData = new List<Confidential_Data__c>(); 
        
        
        setup();
        
        Test.startTest();
        
        insert listConfData;
        
        for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
        
        // Confidential Data Records
        for(Contact con: [SELECT Id, account.Affiliation__c,accountId FROM Contact]){   
            Confidential_Data__c cd = TestUtils.createConfidentialData(con.accountId,con.Id,null,true);
            mapConfDataIdToAffliate.put(cd.Id,con.account.Affiliation__c); 
        }  
        
        // changing the confidential data account lookup 
        
        Confidential_Data__c cd = [SELECT Id, Account__c FROM Confidential_Data__c LIMIT 1];
        Account acc = TestUtils.createAccount('Account'+1,true);
        
        cd.Account__c = acc.id;
        update cd;
        
        //changing the confidential data contact Lookup 
        Contact con = TestUtils.createContact(acc,'con'+1,'test'+1,true);
        update con;
        
        //changing the confidential data Opportunity Lookup 
        Opportunity opp = TestUtils.createOpportunity(acc.Id, 'opp'+1,true);
        update opp;
        
        for(Id objId: mapConfDataIdToAffliate.Keyset()){
            Confidential_Data__c cdo = new Confidential_Data__c();
            cdo.Id = objId;
            cdo.Account__c = acc.id;
            cdo.Contact__c = con.id;
            cdo.Opportunity__c = opp.Id;
            
            ConfDataUpdate.add(cdo);
        }
        
        if(!ConfDataUpdate.isEmpty()){
            upsert ConfDataUpdate;
        }
        
        List<Confidential_Data__share> cds = new List<Confidential_Data__share>([Select Id, AccessLevel 
                                                                                 FROM Confidential_Data__share
                                                                                 WHERE AccessLevel = 'Edit'
                                                                                 AND ParentId =: ConfDataUpdate
                                                                                 ]);
        
        System.assertEquals(listConfData.size(),cds.size());
        
        if(!ConfDataUpdate.isEmpty()){
            delete ConfDataUpdate;
        } 
        
        Test.stopTest();
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
        con = TestUtils.createContact(Accounts[0] ,'cons'+1,'testPhone'+1,false);
        insert con; 
        
        //opportunity Records
        Opportunity opp = TestUtils.createOpportunity(Accounts[0].Id, 'opp'+1,true);
        
        //conf data Records
        for(Integer j=0;j<2;j++){
            Confidential_Data__c cdo1 = TestUtils.createConfidentialData(Accounts[0].Id,con.Id,opp.Id,false);
            cdo1.Account__c = Accounts[j].Id;
            cdo1.Contact__c = con.id;
            listConfData.add(cdo1);
        }
       
    }
    
    
}