// Given
/*
*
*Name  :  BatchPopulateActPreferencesTest
*Author:  Appirio : Shobhit Pant
*Date  :  June 14, 2017
*Purpose : Test Class for BatchPopulateActPreferences
*/
@isTest
public class BatchPopulateActPreferencesTest {
  @isTest
  static void testPopulateActPreferences() {
    Test.startTest();
    createTestData(6);
    BatchPopulateActPreferences obj = new BatchPopulateActPreferences();
    Database.executeBatch(obj);
    Id assertAccountId = [SELECT rC_Bios__Account__c FROM rC_Bios__Preference__c WHERE rC_Bios__Code_Value__c = 'BA'].get(0).rC_Bios__Account__c;
    System.assertEquals(true, [SELECT Rpt_Board_Member__c FROM Account WHERE Id = : assertAccountId].get(0).Rpt_Board_Member__c);
    Test.stopTest();
  }
  static void createTestData(Integer count) {
    List<rC_Bios__Preference__c> prefList = new List<rC_Bios__Preference__c>();
    //creating 2 accounts to increase code coverage (meeting criteria)
    Account testAccount1 = TestUtils.createAccount('testAccount' , true);
    Account testAccount2 = TestUtils.createAccount('testAccount' , true);
    for ( Integer i = 0 ; i < count ; i++) {
      rC_Bios__Preference__c preference = TestUtils.createPreferences(testAccount1.Id , false);
      //below logic is not necessary, just to have preferences with different accounts
      if ( (i / 2) != 0) {
        preference.rC_Bios__Account__c = testAccount2.Id;
      }
      preference.rC_Bios__Active__c = True;
      preference.rC_Bios__Category__c = 'GEN';
      prefList.add(preference);
    }
    if (prefList.size() > 0) {
      insert prefList;
    }
    //updating Code Values to meet different cases
    prefList.get(0).rC_Bios__Code_Value__c = 'BA';
    prefList.get(1).rC_Bios__Code_Value__c = 'ML';
    prefList.get(2).rC_Bios__Code_Value__c = 'MQ';
    prefList.get(3).rC_Bios__Code_Value__c = 'AJ';
    prefList.get(4).rC_Bios__Code_Value__c = 'Interests';
    prefList.get(5).rC_Bios__Code_Value__c = 'anytestvalue';
    update prefList;
  }

}