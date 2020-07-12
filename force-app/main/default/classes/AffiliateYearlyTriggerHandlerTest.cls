/*
*
*Name  :  AffiliateYearlyTriggerHandlerTest
*Author:  Appirio India (Ashu Gupta)
*Date  :  October 24, 2016
*Purpose : Test class for AffiliateYearlyTriggerHandler
*
*/
@isTest
private class AffiliateYearlyTriggerHandlerTest {
    /*
    * Method to test the Handler Functionality 
    */
    private static testMethod void testRecord() {
        List<Affiliate_Yearly__c> afList = new list<Affiliate_Yearly__c>();
        List<Account> accList = [SELECT Id, Name FROM Account];
        
        //Create Affiliate_Yearly__c records
        for(Integer i=0; i<10; i++){  
             Affiliate_Yearly__c af = TestUtils.createAffiliateYearly('TestAF'+i, accList[i].Id, '2015', false);
             afList.add(af);
        }
        afList.get(0).Fiscal_Year__c = '1997';
        
        Test.startTest();
        insert afList;
        
        //Update Affiliate_Yearly__c records
        afList.get(0).Fiscal_Year__c = '2016';
        afList.get(9).Fiscal_Year__c = '2017';
        update afList;
        
        Affiliate_Yearly__c afObj = [SELECT Id, Union_Cost_Factor__c, Foundation_Cost_Factor__c, Incentive_National_Share__c
                                     FROM Affiliate_Yearly__c 
                                     WHERE Id = :afList[1].id];
        National_Fiscal_Year__c fiscalYear = [SELECT Id, Union_Cost_Factor__c, Foundation_Cost_Factor__c, Percent_GMI_Affiliates__c FROM National_Fiscal_Year__c LIMIT 1];                      
        System.assertEquals(afObj.Union_Cost_Factor__c, fiscalYear.Union_Cost_Factor__c);
        System.assertEquals(afObj.Foundation_Cost_Factor__c, fiscalYear.Foundation_Cost_Factor__c);
        System.assertEquals(afObj.Incentive_National_Share__c , fiscalYear.Percent_GMI_Affiliates__c);
        Test.stopTest();
    }
    
    /*
    * Method to create Test Data
    */
    @testSetup
    static void createTestData(){
        Id affAccId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        List<Account> accList = new List<Account>();
        List<Affiliate_Yearly__c> afList = new List<Affiliate_Yearly__c>();
        List<National_Fiscal_Year__c> fiscalYearList = new List<National_Fiscal_Year__c>();
        
        //Create Accounts
        for(Integer i=0; i<10; i++){   
            Account acc = TestUtils.createAccount('TestAcc'+i,false);
            acc.RecordTypeId = affAccId;
            accList.add(acc);
         }   
        insert accList;
        
        //Create Fiscal Year
        for(Integer i=0; i<2; i++){  
             fiscalYearList.add(TestUtils.createFiscalyearCSData('TestFY'+i, '201'+(i+5), 30, 20, 25, false));
        }
        insert fiscalYearList;
    }
}