/*
*
*Name  :  ContactAddressTriggerHandler
*Author:  Appirio India (Shikha Gupta)
*Date  :  Feb 27, 2017
*Purpose : Handler class for Contact Address Trigger. Logic populates City and State based on zipAffiliate
*
*/
public class ContactAddressTriggerHandler {
  public static void mainEntry(List<rC_Bios__Contact_Address__c> newList, List<rC_Bios__Contact_Address__c> oldList, Map<Id, rC_Bios__Contact_Address__c> newMap,
                               Map<Id, rC_Bios__Contact_Address__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
    //if trigger is active
    if(TriggerState.isActive('ContactAddressTrigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
      // It is called on before insert
      if(isBefore){
        if(isInsert){
          beforeInsert(newList);
        }
      }
      // It is called on before update
      if(isBefore){
        if(isUpdate){
          beforeUpdate(newList, oldMap);
        }
      }
    }
  }
    
  private static void beforeInsert(List<rC_Bios__Contact_Address__c> newList){
    autoPopulateCityAndState(newList);
  }
    
  private static void beforeUpdate(List<rC_Bios__Contact_Address__c> newList, Map<Id, rC_Bios__Contact_Address__c> oldMap) {
    List<rC_Bios__Contact_Address__c> listOfAddress = new List<rC_Bios__Contact_Address__c>();
    for(rC_Bios__Contact_Address__c contactAddress : newList) {
      if(contactAddress.rC_Bios__Original_Postal_Code__c != null && contactAddress.rC_Bios__Original_Postal_Code__c != oldMap.get(contactAddress.Id).rC_Bios__Original_Postal_Code__c) {
        listOfAddress.add(contactAddress);
      }
    }
    if(!listOfAddress.isEmpty()) {
      autoPopulateCityAndState(listOfAddress);
    }
  }
  
  private static void autoPopulateCityAndState(List<rC_Bios__Contact_Address__c> listOfAddressesToProcess) {
    Set<String> setOfZipCodes = new Set<String>();
    map<String,String> mapOfZipAndCityStateKey = new map<String,String>();
    for(rC_Bios__Contact_Address__c address : listOfAddressesToProcess) {
      if(address.rC_Bios__Original_Postal_Code__c != null) {
          setOfZipCodes.add(address.rC_Bios__Original_Postal_Code__c );
      }
    }
    String key = '';
    String city = '';
    String state = '';
    for(Zip_Affiliate__c zipAffiliate : [SELECT Id, Name, City__c, State__c
                                         FROM Zip_Affiliate__c
                                         WHERE Name IN : setOfZipCodes
                                         AND (City__c != NULL OR State__c != NULL)]) {
       key = zipAffiliate.City__c != null ? key + zipAffiliate.City__c + '-' : key + '-';
       key = zipAffiliate.State__c != null ? key + zipAffiliate.State__c : key;
       mapOfZipAndCityStateKey.put(zipAffiliate.Name,key); 
       key = '';
    }
    for(rC_Bios__Contact_Address__c address: listOfAddressesToProcess) {
      if(mapOfZipAndCityStateKey.get(address.rC_Bios__Original_Postal_Code__c) != null) {
        city = mapOfZipAndCityStateKey.get(address.rC_Bios__Original_Postal_Code__c).startsWith('-') ? '' : (mapOfZipAndCityStateKey.get(address.rC_Bios__Original_Postal_Code__c)).split('-').get(0);
        state = mapOfZipAndCityStateKey.get(address.rC_Bios__Original_Postal_Code__c).endsWith('-') ? '' : (mapOfZipAndCityStateKey.get(address.rC_Bios__Original_Postal_Code__c)).split('-').get(1);
        address.rC_Bios__Original_City__c = address.rC_Bios__Original_City__c == null && city != '' ? city : address.rC_Bios__Original_City__c;
        address.rC_Bios__Original_State__c = address.rC_Bios__Original_State__c == null && state != '' ? state : address.rC_Bios__Original_State__c;
        city = '';
        state = '';
      }
    }
  }
}