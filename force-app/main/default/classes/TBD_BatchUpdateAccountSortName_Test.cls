@isTest
private class TBD_BatchUpdateAccountSortName_Test {
    public static Id organizationId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
    public static Id houseHoldId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
	
	private static testMethod void testTBD_BatchUpdateAccountSortName() {
        
        Contact con = TestUtils.createContact(null,'Test','Preferred',false);
        insert con;
        
        List<Account> accountList = new List<Account>();

        for(Integer i=0;i<2;i++){   
            Account acc = TestUtils.createAccount('Account'+i,false);
            acc.Lock_Affiliation__c = false;
            if (i==0) {
                acc.rC_Bios__Preferred_Contact__c = con.Id;
                acc.RecordTypeId = organizationId;
                acc.BillingPostalCode = '8201'+i;
                acc.BillingCountry = 'USA';
            } else  {
                acc.RecordTypeId = householdId;
            } 
            accountList.add(acc);
        }
        
        insert accountList;
        Database.executeBatch(new TBD_BatchUpdateAccountSortName(), 50);

	}

}