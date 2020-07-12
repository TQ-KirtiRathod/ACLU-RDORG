/*
*
*Name  :  ViewPreferencesController
*Author:  ACLU (David Reed)
*Date  :  May 12, 2017
*Purpose : Controller class for ViewPreferences page. Logic displays preferences on account layout
*
*/
public with sharing class ViewPreferencesController {
    private ApexPages.StandardController c;
    
    private class ViewPreferencesException extends Exception {}
    
    // Inner class conjoins the Preference object with the critical Description field from its associated Preference Code.
    // There is no direct relationship between the objects.
    public class PreferenceEntry {
        public String description { get; set; }
        public rC_Bios__Preference__c preference { get; set; }
        public Boolean userCanEdit {
            get {
                // Enforce ACLU requirements on who can edit which code, as well as Salesforce CRUD permissions.
                return PreferenceUtility.canUserEditCodeValue(PreferenceUtility.isAffiliateUser(), preference.rC_Bios__Code_Value__c)
                    && Schema.sObjectType.rC_Bios__Preference__c.isUpdateable();
            }
            
            private set;
        }
        public Boolean userCanDelete {
            get {
                // Enforce ACLU requirements on who can remove which code, as well as Salesforce CRUD permissions.
                
                return PreferenceUtility.canUserEditCodeValue(PreferenceUtility.isAffiliateUser(), preference.rC_Bios__Code_Value__c)
                    && Schema.sObjectType.rC_Bios__Preference__c.isDeletable();
            }
            
            private set;
        }
        
        public PreferenceEntry(rC_Bios__Preference__c p, String d) {
            preference = p;
            description = d;
        }
    }
    
    public ViewPreferencesController(ApexPages.StandardController ctrl) {
        c = ctrl;
    }
    
    // Generate and return a list of PreferenceEntry objects for this account
    public List<PreferenceEntry> getPreferences() {
        List<rC_Bios__Preference__c> ps;
        List<rC_Bios__Preference_Code__c> pcs;
        List<PreferenceEntry> pes;
        Set<String> codeValues;
        Map<String, rC_Bios__Preference_Code__c> pcsByCode;
        // Since we're not displaying this value direct from the sObject in Visualforce, enforce FLS.
        Boolean canViewDescriptions = Schema.sObjectType.rC_Bios__Preference_Code__c.fields.Description__c.isAccessible();
        
        // Query all Preference objects on this Account.
        if (c.getRecord().Id != null) {
            ps = [SELECT Id,
                  rC_Bios__Contact__r.Name,
                  rC_Bios__Code_Value__c,
                  rC_Bios__Start_Date__c,
                  rC_Bios__End_Date__c,
                  rC_Bios__Active__c,
                  rC_Bios__Comments__c,
                  rC_Bios__Status__c,
                  rC_Bios__Category__c
                  FROM rC_Bios__Preference__c
                  WHERE rC_Bios__Account__c = :c.getRecord().Id
                  ORDER BY rC_Bios__Active__c DESC, rC_Bios__End_Date__c, rC_Bios__Code_Value__c];
        } else {
            return new List<PreferenceEntry>();
        }
        
        // Collect their unique code values.
        codeValues = new Set<String>();
        for (rC_Bios__Preference__c p : ps) {
            codeValues.add(p.rC_Bios__Code_Value__c);
        }
        
        // Locate and map the corresponding Preference Code objects.
        // (Note that Code_Value__c is an External ID and hence automatically indexed).
        if (canViewDescriptions) {
            pcs = [SELECT Id, rC_Bios__Code_Value__c, Description__c
                   FROM rC_Bios__Preference_Code__c
                   WHERE rC_Bios__Code_Value__c IN :codeValues];
            
            pcsByCode = new Map<String, rC_Bios__Preference_Code__c>();
            
            for (rC_Bios__Preference_Code__c pc : pcs) {
                pcsByCode.put(pc.rC_Bios__Code_Value__c, pc);
            }
        }
        
        // Build and return the PreferenceEntries.
        pes = new List<PreferenceEntry>();
        for (rC_Bios__Preference__c p : ps) {
            String description;
            
            if (canViewDescriptions) {
                rC_Bios__Preference_Code__c thisPC = pcsByCode.get(p.rC_Bios__Code_Value__c);
                if (thisPC != null)
                    description = thisPC.Description__c;
            } else {
                description = '';
            }
            
            pes.add(new PreferenceEntry(p, description));
        }
        
        return pes;
    }
}