/*
*
*Name  :  PreferenceUtility
*Author:  ACLU (David Reed)
*Date  :  June 17, 2017
*Purpose : Contains utility methods for Affiliate user. Used in AddPreferenceController & ViewPreferencesController
*
*/
public with sharing class PreferenceUtility {
    static private Boolean affiliateUser;

    private class PreferenceException extends Exception {}

	public static Boolean isAffiliateUser() {
        if (affiliateUser == null) {
            // Let's not run a query for every single table row. Cache this value for the transaction.
            User u = [SELECT Is_Affiliate_User__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

            affiliateUser = u.Is_Affiliate_User__c;
        }

        return affiliateUser;
    }

    public static Boolean canUserEditCodeValue(Boolean affiliateUser, String codeValue) {
        // Affiliate users cannot edit records whose code values start with N or with O, but can edit those starting with OXX.
        if (affiliateUser && codeValue != null)
	        return !codeValue.startsWith('N') && (!codeValue.startsWith('O') || codeValue.startsWith('OXX'));

        return true;
    }

    public static void forceAffiliateUserContext() {
        if (!Test.isRunningTest()) {
            throw new PreferenceException('PreferenceUtility.forceAffiliateUserContext() can only be used in testing.');
        }

        affiliateUser = true;
    }
}