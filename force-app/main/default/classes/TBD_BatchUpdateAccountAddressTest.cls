@isTest
private class TBD_BatchUpdateAccountAddressTest {

    private static testMethod void testExecute() {
        
        Account acc = TestUtils.createAccount('testAcc', false);

        rC_Bios__Address__c add = TestUtils.createAddress('address', false);
        add.rC_Bios__Postal_Code__c = '12210-1944';
        insert acc;
        insert add;
        
        User sysAdmin = TestUtils.createSysAdminUser('System Administrator');
        sysAdmin.FirstName = 'Bup';
        sysAdmin.LastName = 'User';
        sysAdmin.Alias = 'buser';
        insert sysAdmin;
        
        system.runAs(sysAdmin){
        rC_Connect__Batch_Upload__c bup = new rC_Connect__Batch_Upload__c();
        bup.rC_Connect__Batch_Upload_Status__c = 'New';
        bup.rC_Connect__Batch_Upload_Account_Matched__c = acc.Id;
        bup.rC_Connect__Batch_Upload_Address_Matched__c = add.Id;
        bup.Name = 'Test';
        insert bup;
        bup.rC_Connect__Batch_Upload_Address_Matched__c = add.Id;
        update bup; 
        
        rC_Bios__Account_Address__c accntAddress = TestUtils.createAccountAddress(add.Id, acc.Id, false);
        accntAddress.rC_Bios__Original_Postal_Code__c = '12210-1944';
        accntAddress.rC_Bios__Account__c = acc.Id;
        accntAddress.rC_Bios__Address__c = add.Id;
        insert accntAddress;

        bup.rC_Connect__Batch_Upload_Address_Matched__c = accntAddress.rC_Bios__Address__c;
        update bup; 
        Database.executeBatch(new TBD_BatchUpdateAccountAddress(), 50);
        } 
        
    }
}