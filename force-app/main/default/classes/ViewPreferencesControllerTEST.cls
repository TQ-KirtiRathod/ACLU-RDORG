/*****
* Test class for ViewPreferencesController
*****/
@isTest
public class ViewPreferencesControllerTEST {
    
    @testSetup
    public static void testSetup() {
        Account a = TestUtils.createAccount('TestAccount', true);
        
        List<rC_Bios__Preference_Code__c> pcs = new List<rC_Bios__Preference_Code__c>{
            new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST1', Description__c = 'TEST1'),
                new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST2', Description__c = 'TEST2'),
                new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST3', Description__c = 'TEST3')
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
    public static void testGetPreferences() {
        
        ViewPreferencesController c = new ViewPreferencesController(new ApexPages.StandardController([SELECT Id FROM Account LIMIT 1]));
        List<ViewPreferencesController.PreferenceEntry> pes;
        
        pes = c.getPreferences();
        
        System.assertEquals(3, pes.size());
        for (Integer i = 0; i < 3; i++) {
            System.assertEquals(pes[i].description, pes[i].preference.rC_Bios__Code_Value__c);
        }
    }
    
    @isTest
    public static void testNoAccount() {
        ViewPreferencesController c = new ViewPreferencesController(new ApexPages.StandardController(new Account(Name = 'Test')));
        
        System.assertNotEquals(null, c.getPreferences());
        System.assertEquals(0, c.getPreferences().size());
    }
    
    @isTest
    public static void testPreferenceEntry() {
        ViewPreferencesController.PreferenceEntry pe = new ViewPreferencesController.PreferenceEntry(new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'OQ'), 'Test');
        
        System.assertEquals('Test', pe.description);
        
        PreferenceUtility.forceAffiliateUserContext();
        
        System.assertEquals(false, pe.userCanEdit);
        System.assertEquals(false, pe.userCanDelete);
    }
}