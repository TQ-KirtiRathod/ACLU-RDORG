/*
*
*Name  :  EmailOptOutProcessor
*Author:  ACLU (David Reed)
*Date  :  June 28, 2017
*Purpose : Contains methods to set Opt_In on Emails & Email Preferences. 
*          These methods are called by Batch classes created for the purpose.
*
*/
public without sharing class EmailOptOutProcessor {
    private static Boolean runningEmails;
    private static Boolean runningEmailPreferences;
    private static Set<Id> updatingEmails;
    private static Set<Id> updatingEmailPreferences;

    public static Boolean isEmailInScope(Id emailId) {
        if (runningEmails == true) {
            return updatingEmails.contains(emailId);
        }

        return false;
    }
    
    public static Boolean isEmailPreferenceInScope(Id emailPreferenceId) {
        if (runningEmailPreferences == true) {
            return updatingEmailPreferences.contains(emailPreferenceId);
        }

        return false;
    }

    public static void processOptOutsForEmails(List<Email__c> scope) {
        Set<String> emailAddresses = new Set<String>();
   		Map<String, Set<Email__c>> m = new Map<String, Set<Email__c>>();
   		Map<Id, Email__c> toUpdate = new Map<Id, Email__c>();
        
        updatingEmails = new Set<Id>();

        // Accumulate Email Addresses to query against.
		for (Email__c e : scope) {
			emailAddresses.add(e.Email_address__c);
		}

		// Build a mapping between Email Address and a set of Email__c objects
		// Note we're excluding items in our own queue via Opt_In_Status_Changed__c = false
		for (Email__c e : [SELECT Id, Opt_in__c, Email_address__c 
                           FROM Email__c WHERE Opt_In_Status_Changed__c = false 
                           AND Email_address__c IN :emailAddresses]) {
			if (!m.containsKey(e.Email_address__c)) {
				m.put(e.Email_address__c, new Set<Email__c>());
			}

			m.get(e.Email_address__c).add(e);
		}

		// Finally, iterate through our incoming changed Email set once more and apply changes.
		for (Email__c e : scope) {
			Set<Email__c> ems = m.get(e.Email_address__c);

            if (ems != null) {
    			for (Email__c eprime : ems) {
    				if (eprime.Opt_in__c != e.Opt_in__c) {
    					eprime.Opt_in__c = e.Opt_In__c;
    					toUpdate.put(eprime.Id, eprime);
                        updatingEmails.add(eprime.Id);
    				}
    			}
            }

			// Clear the flag that excludes this record from processing.
			// Future changes will affect it too. 
			// We will also add it to our email address dictionary in case a later entry in the same
			// scope should modify it.
			e.Opt_In_Status_Changed__c = false;
			toUpdate.put(e.Id, e);
            if (!m.containsKey(e.Email_address__c)) {
				m.put(e.Email_address__c, new Set<Email__c>());
			}
            m.get(e.Email_address__c).add(e);
		}

        runningEmails = true;
        update toUpdate.values();
        runningEmails = false;
    }

    public static void processOptOutsForEmailPreferences(List<Email_Preference__c> scope) {
        Set<String> emailAddresses = new Set<String>();
        Set<String> emailListCodes = new Set<String>();
        Map<String, Map<String, Set<Email_Preference__c>>> m = new Map<String, Map<String, Set<Email_Preference__c>>>();
        Map<Id, Email_Preference__c> toUpdate = new Map<Id, Email_Preference__c>();

        updatingEmailPreferences = new Set<Id>();

        // Accumulate Email Addresses and Email List Codes to query against.
        for (Email_Preference__c e : scope) {
            emailAddresses.add(e.Email__r.Email_address__c);
            emailListCodes.add(e.Email_List_Code__c);
        }

        // Build a mapping between Email Address and a map of Email List Codes to Email_Preference__c objects
        // Note we're excluding items in our own queue via Opt_In_Status_Changed__c = false
        for (Email_Preference__c e : [SELECT Id, Opt_in__c, Email_List_Code__c, Email__r.Email_address__c 
                                      FROM Email_Preference__c 
                                      WHERE Opt_In_Status_Changed__c = false 
                                            AND Email__r.Email_address__c IN :emailAddresses
                                            AND Email_List_Code__c IN :emailListCodes]) {
            if (!m.containsKey(e.Email__r.Email_address__c)) {
                m.put(e.Email__r.Email_address__c, new Map<String, Set<Email_Preference__c>>());
            }
            if (!m.get(e.Email__r.Email_address__c).containsKey(e.Email_List_Code__c)) {
                m.get(e.Email__r.Email_address__c).put(e.Email_List_Code__c, new Set<Email_Preference__c>());
            }

            m.get(e.Email__r.Email_address__c).get(e.Email_List_Code__c).add(e);
        }

        // Finally, iterate through our incoming changed Email Preference set once more and apply changes.
        for (Email_Preference__c e : scope) {
            Set<Email_Preference__c> ems;

            if (m.containsKey(e.Email__r.Email_address__c)) {
                ems = m.get(e.Email__r.Email_address__c).get(e.Email_List_Code__c);
            }
            
            if (ems != null) {
                for (Email_Preference__c eprime : ems) {
                    if (eprime.Opt_in__c != e.Opt_in__c) {
                        eprime.Opt_in__c = e.Opt_In__c;
                        toUpdate.put(eprime.Id, eprime);
                        updatingEmailPreferences.add(ePrime.Id);
                    }
                }
            }

            // Clear the flag that excludes this record from processing.
            // Future changes will affect it too. 
            // We will also add it to our email address dictionary in case a later entry in the same
            // scope should modify it.
            e.Opt_In_Status_Changed__c = false;
            toUpdate.put(e.Id, e);
            if (!m.containsKey(e.Email__r.Email_address__c)) {
                m.put(e.Email__r.Email_address__c, new Map<String, Set<Email_Preference__c>>());
            }
            if (!m.get(e.Email__r.Email_address__c).containsKey(e.Email_List_Code__c)) {
                m.get(e.Email__r.Email_address__c).put(e.Email_List_Code__c, new Set<Email_Preference__c>());
            }

            m.get(e.Email__r.Email_address__c).get(e.Email_List_Code__c).add(e);
        }

        runningEmailPreferences = true;
        update toUpdate.values();
        runningEmailPreferences = false;
    }
}