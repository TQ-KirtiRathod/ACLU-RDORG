/*
*Name  :  AccountAddressTriggerHandlerTest
*Author:  Appirio India (Poonam Singh)
*Date  :  May 16, 2017
*Purpose : Test Class for AccountAddressTriggerHandler
*
*/
@isTest
public class AccountAddressTriggerHandlerTest {
    /*
*Method  to test AccountAddressTriggerHandler functionality
*Testing if rC_Bios__Account_Address__c record inserted or updated then rC_Bios__Original_State__c is created based on related zip affiliate.
*/
    @testSetup
    public static void createData(){
        List<Account> accountList = new List<Account>();
        List<Zip_Affiliate__c> zipList = new List<Zip_Affiliate__c>(); 
        List<rC_Bios__Address__c> addressList = new List<rC_Bios__Address__c>();
        
        //Creating test data of Account, Address and Zip Affiliate
        for(Integer i=0 ; i<5 ; i++){
            Account acc = TestUtils.createAccount('testAcc'+i, false);
            accountList.add(acc);
            
            rC_Bios__Address__c address = TestUtils.createAddress('address'+i, false);
            address.rC_Bios__Postal_Code__c = '5432'+i;
            addressList.add(address);
            
            Zip_Affiliate__c zip = TestUtils.createZipAffiliate('55-60'+i, false);
            //zip.city__c = 'AB';
            zip.State__c = 'ZY';
            zipList.add(zip);
        }
        insert accountList;
        insert addressList;
        insert zipList;
        List<Country_Codes__c> ccLIst = new List<Country_Codes__c>();
        Country_Codes__c cc1 = new Country_Codes__c(Name = 'Afghanistan', Country_Code__c = 'AF', Country_3_Char_Code__c = 'AFG');
        Country_Codes__c cc2 = new Country_Codes__c(Name = 'Aland Islands', Country_Code__c = 'AX', Country_3_Char_Code__c = 'ALA');
        Country_Codes__c cc3 = new Country_Codes__c(Name = 'Albania', Country_Code__c = 'AL', Country_3_Char_Code__c = 'ALB');
        Country_Codes__c cc4 = new Country_Codes__c(Name = 'Algeria', Country_Code__c = 'DZ', Country_3_Char_Code__c = 'DZA');
        Country_Codes__c cc5 = new Country_Codes__c(Name = 'American Samoa', Country_Code__c = 'AS', Country_3_Char_Code__c = 'ASM');
        ccLIst.add(cc1);
        ccLIst.add(cc2);
        ccLIst.add(cc3);
        ccLIst.add(cc4);
        ccLIst.add(cc5);
        insert ccList;
        
    }
    @isTest
    public static void testUpdateContryCodeFromCOuntryNameUpdate(){
        Test.startTest();
        List<Account> accountList = [SELECT Id FROM Account];
        List<rC_Bios__Address__c> addressList = [SELECT Id FROM rC_Bios__Address__c];
        List<rC_Bios__Account_Address__c> accountAddressList = new List<rC_Bios__Account_Address__c>();
        List<String> countryList = new LIst<String>{'Afghanistan','Aland Islands','Albania','Algeria','American Samoa'};
        //Creating test data for Account Address
        Integer i = 0;
        for( String str: countryList ){
            rC_Bios__Account_Address__c accAddress = TestUtils.createAccountAddress(addressList[i].Id, accountList[i].Id, false);
            accAddress.rC_Bios__Original_Postal_Code__c = '55-60'+i;
            accAddress.Country_Name__c = str;
            accountAddressList.add(accAddress);
            i++;
        }
        rC_Bios__Account_Address__c accAddress = TestUtils.createAccountAddress(addressList[0].Id, accountList[0].Id, false);
        accAddress.rC_Bios__Original_Postal_Code__c = '55-60'+i;
        accAddress.Country_Name__c = null;
        accountAddressList.add(accAddress);
        //Testing Insert Conditions
        insert accountAddressList;
        rC_Bios__Account_Address__c accAdd1 = [Select id, rC_Bios__Original_Country__c,Country_Name__c FROM rC_Bios__Account_Address__c where Country_Name__c = 'Afghanistan' LIMIT 1];
        rC_Bios__Account_Address__c accAdd2 = [Select id, rC_Bios__Original_Country__c,Country_Name__c FROM rC_Bios__Account_Address__c where Country_Name__c = 'Albania' LIMIT 1];
        accountAddressList.clear();
        accAdd1.Country_Name__c = 'Albania';
        accAdd2.Country_Name__c = 'Algeria';
        accountAddressList.add(accAdd1);
        accountAddressList.add(accAdd2);
        update  accountAddressList;
        Test.stopTest(); 
        System.assertEquals('AL', [Select id, rC_Bios__Original_Country__c FROM rC_Bios__Account_Address__c where id = :accAdd1.id LIMIT 1].rC_Bios__Original_Country__c);
        System.assertEquals('DZ', [Select id, rC_Bios__Original_Country__c FROM rC_Bios__Account_Address__c where id = :accAdd2.id LIMIT 1].rC_Bios__Original_Country__c);
        System.assertNOTEquals(accAdd1.rC_Bios__Original_Country__c, [Select id, rC_Bios__Original_Country__c FROM rC_Bios__Account_Address__c where id = :accAdd1.id LIMIT 1].rC_Bios__Original_Country__c);
        System.assertNOTEquals(accAdd2.rC_Bios__Original_Country__c, [Select id, rC_Bios__Original_Country__c FROM rC_Bios__Account_Address__c where id = :accAdd2.id LIMIT 1].rC_Bios__Original_Country__c);
        
    }
}