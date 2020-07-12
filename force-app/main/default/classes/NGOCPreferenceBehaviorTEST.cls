@isTest
public class NGOCPreferenceBehaviorTEST {
    @isTest
    public static void testPreferenceBehavior() {
        Account a = TestUtils.createAccount('TestAccount', true);
        // NGOC's behavior upon insert of a Preference object appears to be as follows:
        // 1. Identify the Preference Code object whose Code Value matches that on the Preference.
        // 2. Identify all Preference Code objects whose hierarchy values are identical to the one selected.
        // 3. Reset the Code Value (and possibly hierarchy values) of the Preference object to that of the last Preference Code in the list 
        //    selected in (2), sorted in ascending order by creation date (or possibly modification date).
        //    
        // Whether or not the Preference Code objects have hierarchy values that are actually defined in the picklist structure seems
        // to be irrelevant.
        // 
        // The trigger runs on both update and insert. Prepopulating the hierarchy values on the Preference object does *not* suppress it.
        // 
        // Possible fix: force inclusion of the Code Value within the hierarchy for every Preference Code whose hierarchy values
        // aren't otherwise globally unique.
        // Note that existing mapped codes are impacted by this issue - see BN/BF.
        
        // Establish a list of preference codes.        
        List<rC_Bios__Preference_Code__c> pcs = new List<rC_Bios__Preference_Code__c>{
            // Start with two 'blank' preference codes, with no hierarchy values at all.
            new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'BLANK1', 
                                            Description__c = 'BLANK1'),
                new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'BLANK2', 
                                                Description__c = 'BLANK2'),
                // Note that TEST1, TEST3, and TEST4 have the same hierarchy values, differing only in code value.
                // These are 'real' hierarchy values, matching an actual fully-populated code.
                new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST1', 
                                                rC_Bios__Category__c = 'Programmatic', 
                                                rC_Bios__Subcategory__c = 'Major Gifts', 
                                                rC_Bios__Type__c = 'M1', 
                                                rC_Bios__Subtype__c = 'Top Prospects', 
                                                Description__c = 'TEST1'),
                // TEST2 has different hierarchy values and a category that is definitely not in the picklist definition.
                new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST2', 
                                                rC_Bios__Category__c = 'TESTC', 
                                                Description__c = 'TEST2'),
                new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST3', 
                                                rC_Bios__Category__c = 'Programmatic', 
                                                rC_Bios__Subcategory__c = 'Major Gifts', 
                                                rC_Bios__Type__c = 'M1', 
                                                rC_Bios__Subtype__c = 'Top Prospects', 
                                                Description__c = 'TEST3'),
                new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST4', 
                                                rC_Bios__Category__c = 'Programmatic', 
                                                rC_Bios__Subcategory__c = 'Major Gifts', 
                                                rC_Bios__Type__c = 'M1', 
                                                rC_Bios__Subtype__c = 'Top Prospects', 
                                                Description__c = 'TEST4'),
                // TEST5 comes alphabetically and creation-date-wise last, but doesn't overlap in the hierarchy.
                new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST5', 
                                                rC_Bios__Category__c = 'TEST5', 
                                                Description__c = 'TEST5'),
                // TEST6 overlaps with TEST5 at the category, but not the subcategory, level.
                new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST6', 
                                                rC_Bios__Category__c = 'TEST5', 
                                                rC_Bios__Subcategory__c = 'TEST6', 
                                                Description__c = 'TEST6')
                
                };
                    
                    insert pcs;
        
        // Create a list of Preferences, one for each above (except TEST6).
        List<rC_Bios__Preference__c> ps = new List<rC_Bios__Preference__c>{
            new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'TEST1', rC_Bios__Account__c = a.Id),
                new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'TEST2', rC_Bios__Account__c = a.Id),
                new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'TEST3', rC_Bios__Account__c = a.Id),
                new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'TEST4', rC_Bios__Account__c = a.Id),
                new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'TEST5', rC_Bios__Account__c = a.Id),
                new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'BLANK1', rC_Bios__Account__c = a.Id),
                new rC_Bios__Preference__c(rC_Bios__Code_Value__c = 'BLANK2', rC_Bios__Account__c = a.Id)
                };
                    
                    insert ps;
        
        // Check the resulting code values.
        
        Map<Id, rC_Bios__Preference__c> m = new Map<Id, rC_Bios__Preference__c>([SELECT Id, rC_Bios__Code_Value__c, rC_Bios__Account__c,
                                                                                 rC_Bios__Category__c, rC_Bios__Subcategory__c, rC_Bios__Type__c,
                                                                                 rC_Bios__Subtype__c
                                                                                 FROM rC_Bios__Preference__c]);
        // Expected behavior based on the above conjecture:
        // entry 0: TEST1 => TEST4
        // entry 1: TEST2 => TEST2 (no duplication in hierarchy)
        // entry 2: TEST3 => TEST4
        // entry 3: TEST4 => TEST4
        // entry 4: TEST5 => TEST5 
        // entry 5: BLANK1 => BLANK2
        // entry 6: BLANK2 => BLANK2
        // Note that reversing the creation order of BLANK1 and BLANK2 reverses the effects
        // because NGOC appears to be sorting on creation or mod date, not code value.
        // Log inspection suggests the query may not have a sort at all, meaning the ordering 
        // is an undefined platform behavior.
        
        for (Integer i = 0; i < m.size(); i++) {
            System.debug('entry ' + String.valueOf(i) + ': ' + m.get(ps[i].Id));
        }
        
        System.assertEquals('TEST4', m.get(ps[0].Id).rC_Bios__Code_Value__c);
        System.assertEquals('TEST2', m.get(ps[1].Id).rC_Bios__Code_Value__c);
        System.assertEquals('TEST4', m.get(ps[2].Id).rC_Bios__Code_Value__c);
        System.assertEquals('TEST4', m.get(ps[3].Id).rC_Bios__Code_Value__c);
        System.assertEquals('TEST5', m.get(ps[4].Id).rC_Bios__Code_Value__c);
        System.assertEquals('BLANK2', m.get(ps[5].Id).rC_Bios__Code_Value__c);
        System.assertEquals('BLANK2', m.get(ps[6].Id).rC_Bios__Code_Value__c);
    }
    
}