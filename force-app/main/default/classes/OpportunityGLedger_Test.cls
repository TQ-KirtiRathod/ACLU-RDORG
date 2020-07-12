/**
* Test Class for OpportunityGLedger
*/
@isTest
private class OpportunityGLedger_Test {
    public static User u1;
    
    static {
        // User record
        u1 = TestUtils.createSysAdminUser('System Administrator') ;
    }
    
    static testMethod void testDepositNumber() {
        system.runAs(u1) {
            setup();
            
            for(Opportunity opp: [SELECT Id, RecordTypeId, rC_Giving__Parent__c, Batch_Log__c, Batch_Log__r.Batch_Date__c, rC_Giving__Parent__r.Program_Type__c, Deposit_Site__c, Program_Type__c FROM Opportunity]){
                String depositNumber = OpportunityGLedger.populateDepositNumber(opp).Deposit_Number__c;
                if(String.ValueOf(opp.Deposit_Site__c).substring(0, 3) == 'NAI' && opp.rC_Giving__Parent__r.Program_Type__c == '4' )
                    system.assertEquals('CRFW170202',depositNumber);
                if(String.ValueOf(opp.Deposit_Site__c).substring(0, 3) == 'NAI' && opp.rC_Giving__Parent__r.Program_Type__c == '1')
                    system.assertEquals('CRUW170202',depositNumber);
                if(String.ValueOf(opp.Deposit_Site__c).substring(0, 3) != 'NAI' && opp.rC_Giving__Parent__r.Program_Type__c == '4' )
                    system.assertEquals('CRF170202',depositNumber);
                if(String.ValueOf(opp.Deposit_Site__c).substring(0, 3) != 'NAI' && opp.rC_Giving__Parent__r.Program_Type__c == '1')
                    system.assertEquals('CRU170202',depositNumber);
            }
        }  
    }
    
    
    public static void setup(){
        List<Account> Accounts = new List<Account>();
        List<Opportunity> listOpps = new List<Opportunity>();
        List<Opportunity> parentOpps = new List<Opportunity>();
        Id pledgeOppPaymentId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
        Batch_Log__c bl= TestUtils.batchLog('NAUE80101',false);
        bl.Expected_Amount__c =0;
        bl.Expected_Count__c =0;
        bl.Expected_Pledge_Amount__c =0;
        bl.Expected_Pledge_Count__c =0;
        bl.Batch_Date__c = Date.newInstance(2017,02,02);
        insert bl;
        
        Account acc = TestUtils.createAccount('Account',true);
        
        Opportunity opp = TestUtils.CreateOpportunity(acc.Id,'Test'+acc.Name,false);
        opp.Deposit_Site__c = 'NAC - Nat U cc- Sage / Chase';
        opp.Program_Type__c = '1';
        opp.RecordTypeId = pledgeOppPaymentId;
        parentOpps.add(opp);
        
        Opportunity opp0 = TestUtils.CreateOpportunity(acc.Id,'Test'+acc.Name,false);
        opp0.Deposit_Site__c = 'NAC - Nat U cc- Sage / Chase';
        opp0.Program_Type__c = '4';
        opp0.RecordTypeId = pledgeOppPaymentId;
        parentOpps.add(opp0);
        
        if(!parentOpps.IsEmpty()){
            insert parentOpps;
        }
        
        Opportunity opp1 = TestUtils.CreateOpportunity(acc.Id,'Test'+acc.Name,false);
        opp1.Deposit_Site__c = 'NAC - Nat U cc- Sage / Chase';
        opp1.rC_Giving__Parent__c = parentOpps[0].id;
        opp1.RecordTypeId = pledgeOppPaymentId;
        opp1.Batch_Log__c = bl.Id;
        listOpps.add(opp1);
        
        Opportunity opp2 = TestUtils.CreateOpportunity(acc.Id,'Test'+acc.Name,false);
        opp2.Deposit_Site__c = 'NAC - Nat U cc- Sage / Chase';
        opp2.rC_Giving__Parent__c = parentOpps[1].id;
        opp2.RecordTypeId = pledgeOppPaymentId;
        opp2.Batch_Log__c = bl.Id;
        listOpps.add(opp2);
        
        Opportunity opp3 = TestUtils.CreateOpportunity(acc.Id,'Test'+acc.Name,false);
        opp3.Deposit_Site__c = 'NAI_NatF_Operating_wiretransfer';
        opp3.rC_Giving__Parent__c = parentOpps[0].id;
        opp3.RecordTypeId = pledgeOppPaymentId;
        opp3.Batch_Log__c = bl.Id;
        listOpps.add(opp3);
        
        Opportunity opp4 = TestUtils.CreateOpportunity(acc.Id,'Test'+acc.Name,false);
        opp4.Deposit_Site__c = 'NAI_NatF_Operating_wiretransfer';
        opp4.rC_Giving__Parent__c = parentOpps[1].id;
        opp4.RecordTypeId = pledgeOppPaymentId;
        opp4.Batch_Log__c = bl.Id;
        listOpps.add(opp4);
        
        if(!listOpps.IsEmpty()){
            insert listOpps;
        }
    }
    
    
}