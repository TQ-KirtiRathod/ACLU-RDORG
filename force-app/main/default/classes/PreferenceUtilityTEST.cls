/**
 * Test Class for PreferenceUtility
 **/
@isTest
private class PreferenceUtilityTEST {
    @isTest
    public static void testIsAffiliateUser() {
        System.assertEquals([SELECT Is_Affiliate_User__c 
        							FROM User 
        							WHERE Id = :UserInfo.getUserId() LIMIT 1].Is_Affiliate_User__c, 
        					 PreferenceUtility.isAffiliateUser());
        PreferenceUtility.forceAffiliateUserContext();
        System.assertEquals(true, PreferenceUtility.isAffiliateUser());
    }

    @isTest
    public static void testCanUserEditCodeValue() {
        System.assertEquals(true, PreferenceUtility.canUserEditCodeValue(true, 'OXXTEST'));
        System.assertEquals(true, PreferenceUtility.canUserEditCodeValue(true, 'TEST'));
        System.assertEquals(false, PreferenceUtility.canUserEditCodeValue(true, 'OTEST'));
        System.assertEquals(false, PreferenceUtility.canUserEditCodeValue(true, 'NTEST'));
        System.assertEquals(true, PreferenceUtility.canUserEditCodeValue(false, 'OXXTEST'));
        System.assertEquals(true, PreferenceUtility.canUserEditCodeValue(false, 'OTEST'));
        System.assertEquals(true, PreferenceUtility.canUserEditCodeValue(false, 'NTEST'));
        System.assertEquals(true, PreferenceUtility.canUserEditCodeValue(false, 'TEST'));
    }
}