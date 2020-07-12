// Modified by :: roundCorner Inc. :: 21-jan-2019

@isTest
public class AddPreferenceControllerTEST {
    @testSetup
    public static void testSetup() {
        Account a = new Account(Name='TestAccount');
        insert a;
        
        List<rC_Bios__Preference_Code__c> pcs = new List<rC_Bios__Preference_Code__c>{
            new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST1', 
                                            rC_Bios__Category__c = 'TEST1', 
                                            Description__c = 'TEST1', 
                                            Active__c = true),
            new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST2', 
                                            rC_Bios__Category__c = 'TEST2', 
                                            Description__c = 'TEST2', 
                                            Active__c = true),
            new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST3', 
                                            rC_Bios__Category__c = 'TEST3', 
                                            Description__c = 'TEST3', 
                                            Active__c = true)
        };
        
        insert pcs;
        
        List<rC_Bios__Preference__c> ps = new List<rC_Bios__Preference__c>{
            new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'TEST1', rC_Bios__Account__c = a.Id),
            new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'TEST2', rC_Bios__Account__c = a.Id),
            new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'TEST3', rC_Bios__Account__c = a.Id)
        };
        
        insert ps;
    }
    
    @isTest
    public static void testPageSizeSetter() {
        AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'TEST1')));

        a.pageSize = 0;
        System.assertEquals(1000, a.pageSize);
        a.pageSize = -1;
        System.assertEquals(1, a.pageSize);
    }
    
    @isTest
    public static void testGetCanUserEdit() {
    	
    	//Creating an non-affiliated user
        User u = TestUtils.createUser('testFirst', 'syst@testorg.com', null, false);
        u.Is_Affiliate_User__c = false;
        insert u;
        
        System.runAs(u){
	        System.assertEquals(true, 
	            new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'N1'))).getCanUserEdit());
	        System.assertEquals(true, 
	            new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'O1'))).getCanUserEdit());
	        System.assertEquals(true, 
	            new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'OXX1'))).getCanUserEdit());
        }
        
        PreferenceUtility.forceAffiliateUserContext();

        System.assertEquals(false, 
            new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'N1'))).getCanUserEdit());
        System.assertEquals(false, 
            new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'O1'))).getCanUserEdit());
        System.assertEquals(true, 
            new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'OXX1'))).getCanUserEdit());
    }

    @isTest
    public static void testGetCategorySelectOptions() {
        List<SelectOption> sos = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c())).getCategorySelectOptions();

        // This behavior is dependent on metadata, not code.

        System.assert(sos.size() > 1);
        System.assertEquals('All Categories', sos[0].getLabel());
    }
    
    @isTest 
    public static void testUpdatePreferenceCodeWithCode() {
		AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'TEST1')));
        
        a.selectPreferenceCode(); // Just calls through to updatePreferenceCode() again.
        System.assertEquals('TEST1', a.pc.rC_Bios__Code_Value__c);
    }

    @isTest
    public static void testUpdatePreferenceCodeWithBadCode() {
        AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'QQQ')));
        
        a.selectPreferenceCode(); // Just calls through to updatePreferenceCode() again.
        System.assertEquals(null, a.pc);
    }

    @isTest
    public static void testUpdatePreferenceCodeWithNoCode() {
        AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = '')));
        
        a.selectPreferenceCode(); // Just calls through to updatePreferenceCode() again.
        System.assertEquals(null, a.pc);
    }
    
    @isTest
    public static void testFilterPreferenceCodesNoFilter() {
        AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c()));
        
        a.filterPreferenceCodes();
        System.assertEquals(3, a.filteredPreferenceCodes.size());
    }

    @isTest
    public static void testFilterPreferenceCodesFilterOnly() {
		AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c()));
                
        a.filter = '3';
        a.filterPreferenceCodes();
        System.assertEquals(1, a.filteredPreferenceCodes.size());
        System.assertEquals('TEST3', a.filteredPreferenceCodes[0].rC_Bios__Code_Value__c);
    }

    @isTest
    public static void testFilterPreferenceCodesCategoryOnly() {
        AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c()));
                
        a.selectedCategory = 'TEST3';
        a.filterPreferenceCodes();
        System.assertEquals(1, a.filteredPreferenceCodes.size());
        System.assertEquals('TEST3', a.filteredPreferenceCodes[0].rC_Bios__Code_Value__c);
    }

    @isTest
    public static void testFilterPreferenceCodesFilterAndCategory() {
        AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c()));
        
        a.filter = '3';
        a.selectedCategory = 'TEST3';
        a.filterPreferenceCodes();
        System.assertEquals(1, a.filteredPreferenceCodes.size());
        System.assertEquals('TEST3', a.filteredPreferenceCodes[0].rC_Bios__Code_Value__c);
    }
    
    @isTest
    public static void testPaging() {
		AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c()));
        
        a.pageSize = 2;
       	
        System.assertEquals(2, a.pages);
        
        System.assertEquals(1, a.page);
        System.assertEquals(2, a.filteredPreferenceCodes.size());
        
        a.next();
        
        System.assertEquals(2, a.page);
        System.assertEquals(1, a.filteredPreferenceCodes.size());
        
        a.prev();
        System.assertEquals(1, a.page);
        System.assertEquals(2, a.filteredPreferenceCodes.size());
    }

    @isTest
    public static void testFailedFilter() {
        AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c()));

        a.filter = 'Q';
        a.filterPreferenceCodes();
        System.assertEquals(0, a.filteredPreferenceCodes.size());
        System.assertEquals(0, a.pages);

        // Ensure that paging does not raise an exception.

        a.next();
        a.prev();
    }
    
    @isTest
    public static void testSaveSuccess() {
        AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'TEST1')));
 
        a.p.rC_Bios__Account__c = [SELECT Id FROM Account LIMIT 1].Id;
        a.p.rC_Bios__Code_Value__c = 'TEST1';

        System.assertNotEquals(null, a.save());
		
        System.assertEquals(2, [SELECT count() 
                                FROM rC_Bios__Preference__c 
                                WHERE rC_Bios__Code_Value__c = 'TEST1']);
    }

    @isTest
    public static void testSaveAndNew() {
        AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'TEST1')));
 
        a.p.rC_Bios__Account__c = [SELECT Id FROM Account LIMIT 1].Id;
        a.p.rC_Bios__Code_Value__c = 'TEST1';

        System.assertNotEquals(null, a.saveAndNew());
        
        System.assertEquals(2, [SELECT count() 
                                FROM rC_Bios__Preference__c 
                                WHERE rC_Bios__Code_Value__c = 'TEST1']);
    }
    
    @isTest
    public static void testSaveFailNoAccount() {
        AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'TEST1')));

        System.assertEquals(null, a.save());
        System.assert(ApexPages.getMessages().size() > 0);
        System.assertEquals(1, [SELECT count() 
                                FROM rC_Bios__Preference__c 
                                WHERE rC_Bios__Code_Value__c = 'TEST1']);

    }
    
    @isTest
    public static void testSaveFailNoCodeValue() {
        AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Account__c = [SELECT Id FROM Account LIMIT 1].Id)));
        
        System.assertEquals(null, a.save());
        System.assert(ApexPages.getMessages().size() > 0);
        System.assertEquals(1, [SELECT count() 
                                FROM rC_Bios__Preference__c 
                                WHERE rC_Bios__Code_Value__c = 'TEST1']);

    }
     // start : Zendesk: #55328
    @isTest
    public static void testAccountIdPresentCancelMethod() {
        AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c(rC_Bios__Account__c = [SELECT Id FROM Account LIMIT 1].Id)));
        a.p.rC_Bios__Account__c = [SELECT Id FROM Account LIMIT 1].Id;
        a.p.rC_Bios__Code_Value__c = 'TEST1';
        a.cancel();
		System.assertEquals(1, [SELECT count() 
                                FROM rC_Bios__Preference__c 
                                WHERE rC_Bios__Code_Value__c = 'TEST1']);
    }
     @isTest
    public static void testAccountIdPresentNotCancelMethod() {
        AddPreferenceController a = new AddPreferenceController(new ApexPages.StandardController(new rC_Bios__Preference__c()));
        //a.p.rC_Bios__Account__c = [SELECT Id FROM Account LIMIT 1].Id;
        a.p.rC_Bios__Code_Value__c = 'TEST1';
        a.cancel();
		System.assertEquals(1, [SELECT count() 
                                FROM rC_Bios__Preference__c 
                                WHERE rC_Bios__Code_Value__c = 'TEST1']);
    }
     // End : Zendesk: #55328
    
}