/**
**Test Class for EmailPreferenceTriggerHandler
**/
@isTest
private class EmailPreferenceTriggerHandlerTEST {
	
	@isTest static void testTrigger() {
        Contact c = new Contact(FirstName='Thucydides', LastName='son of Oloros');
        insert c;

        Email__c em = new Email__c(Contact__c = c.Id, Email_address__c = 'test@example.com', Opt_in__c = true, Primary__c = true);
        insert em;

        Email_Preference__c ep = new Email_Preference__c(Email__c = em.Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational');
        insert ep;

        ep = [SELECT Opt_in__c, Opt_In_Status_Changed__c FROM Email_Preference__c WHERE Id = :ep.Id];

        System.assert(ep.Opt_In_Status_Changed__c);

        ep.Opt_In__c = false;
        ep.Opt_In_Status_Changed__c = false;

        update ep;

        ep = [SELECT Opt_in__c, Opt_In_Status_Changed__c FROM Email_Preference__c WHERE Id = :ep.Id];

        System.assert(ep.Opt_In_Status_Changed__c);
        System.assert(!ep.Opt_In__c);
	}
	
	@isTest static void testOptOutDate1() {
	    Contact c = new Contact(FirstName='Thucydidea', LastName='daughter of Oloros');
        insert c;

        Email__c em = new Email__c(Contact__c = c.Id, Email_address__c = 'test2@example.com', Opt_in__c = true, Primary__c = true);
        insert em;

        Email_Preference__c ep = new Email_Preference__c(Email__c = em.Id, Opt_in__c = true, Email_List_Code__c = 'ActionNational');
        insert ep;

        ep = [SELECT Opt_in__c, Opt_In_Status_Changed__c FROM Email_Preference__c WHERE Id = :ep.Id];
        ep.Opt_In__c = false;
        update ep;
        
        ep = [SELECT Opt_in__c, opt_out_date__c FROM Email_Preference__c WHERE Id = :ep.Id];
		
		Date t = Date.today();
        System.assertEquals(t, ep.opt_out_date__c);           
	}
	
	@isTest static void testOptOutDate2() {
	    Contact c = new Contact(FirstName='Thucydidea', LastName='daughter of Oloros');
        insert c;

        Email__c em = new Email__c(Contact__c = c.Id, Email_address__c = 'test2@example.com', Opt_in__c = true, Primary__c = true);
        insert em;

        Email_Preference__c ep = new Email_Preference__c(Email__c = em.Id, Opt_in__c = false, Email_List_Code__c = 'ActionNational');
        insert ep;

        ep = [SELECT opt_out_date__c FROM Email_Preference__c WHERE Id = :ep.Id];
        System.assertEquals(null, ep.opt_out_date__c);                
	}
	
	@isTest static void testOptOutDate3() {
	    Contact c = new Contact(FirstName='Thucydidea3', LastName='daughter of Oloros');
        insert c;

        Email__c em = new Email__c(Contact__c = c.Id, Email_address__c = 'test3@example.com', Opt_in__c = true, Primary__c = true);
        insert em;

        Email_Preference__c ep = new Email_Preference__c(Email__c = em.Id, Opt_in__c = false, opt_out_date__c = Date.newInstance(2018,1,1), Email_List_Code__c = 'ActionNational');
        insert ep;

        ep = [SELECT Opt_in__c, Opt_In_Status_Changed__c FROM Email_Preference__c WHERE Id = :ep.Id];
        ep.Opt_In__c = true;
        update ep;
        
        ep = [SELECT Opt_in__c, Opt_In_Status_Changed__c FROM Email_Preference__c WHERE Id = :ep.Id];
        ep.Opt_In__c = false;
        update ep;
        
        ep = [SELECT opt_out_date__c FROM Email_Preference__c WHERE Id = :ep.Id];
		
		Date t = Date.today();
		Date x = Date.newInstance(2018,1,1);
        System.assertEquals(x, ep.opt_out_date__c);           
	}
	
}