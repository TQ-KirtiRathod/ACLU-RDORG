/*
*Name  :  AddressTriggerHandlerTest
*Author:  Appirio India (Poonam Singh)
*Date  :  May 16, 2017
*Purpose : Test Class for AddressTriggerHandler
*/
@isTest
public class AddressTriggerHandlerTest {
    /*
    *Method AccountAddressTriggerFunctionalityTest
    *Testing if rC_Bios__Address__c record inserted or updated then rC_Bios__State__c is created based on related zip affiliate.
    */
    static testMethod void AddressTriggerFunctionalityTest() {
        List<rC_Bios__Address__c> addressList =  new List<rC_Bios__Address__c>();
        List<Account> accountList = [SELECT Id, Name FROM Account];
        List<Zip_Affiliate__c> zipList = [SELECT Id, State__c, City__c  FROM Zip_Affiliate__c];
        
        //Creating test data of Address
        for(Integer i=0 ; i<5 ; i++){
            rC_Bios__Address__c address = TestUtils.createAddress('address'+i, false);
            address.rC_Bios__Postal_Code__c = '5560'+i;
            addressList.add(address);
        }
        
        Test.startTest();
        insert addressList;
        List<rC_Bios__Address__c> insertedList = [SELECT rC_Bios__State__c,rC_Bios__City__c from rC_Bios__Address__c where id=:addressList[3].id];
        System.assertEquals(null, insertedList[0].rC_Bios__City__c );
        
        addressList[2].rC_Bios__Postal_Code__c = '55605';
        update addressList[2];
        List<rC_Bios__Address__c> updatedList = [SELECT rC_Bios__State__c,rC_Bios__City__c from rC_Bios__Address__c where id=:addressList[2].id];
        System.assertEquals('ZY', updatedList[0].rC_Bios__State__c );
        Test.stopTest();
    }
    
    /*
    * Method to Create Test Data
    */
    @testSetup
    public static void createData(){
        List<Account> accountList = new List<Account>();
        List<rC_Bios__Address__c> addressList = new List<rC_Bios__Address__c>();
        List<Zip_Affiliate__c> zipList = new List<Zip_Affiliate__c>(); 
        
        //Creating test data of Account and Zip Affiliate
        for(Integer i=0 ; i<5 ; i++){
            Account acc = TestUtils.createAccount('testAcc'+i, false);
            accountList.add(acc);
            
            Zip_Affiliate__c zip = TestUtils.createZipAffiliate('5560'+i,false);
            //zip.city__c = 'AB';
            zip.State__c = 'ZY';
            zipList.add(zip);
        }
        insert accountList;
        insert zipList;
    }
}