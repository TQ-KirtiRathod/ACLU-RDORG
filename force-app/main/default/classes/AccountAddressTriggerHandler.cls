/*
*
*Name  :  AccountAddressTriggerHandler
*Author:  Appirio India (Shikha Gupta)
*Date  :  Feb 28, 2017
*Purpose : Handler class for AccountAddressTrigger. Logic Includes but limited to
           - Populate City and State from Zip_Affiliate__c obj
           - Calls async Update Country Code
*
*/
public class AccountAddressTriggerHandler {

private static Boolean beforeInsertProcessed = false;
private static Boolean afterInsertProcessed = false;
private static Boolean beforeUpdateProcessed = false;
private static Boolean afterUpdateProcessed = false;
private static Integer counter = 0;
public static list<AsyncRequest__c> newAsyncRequest = new list<AsyncRequest__c>();
public static double accAddrAsyncBatchMax;
static {
      Queueable_Control__c q = Queueable_Control__c.getInstance('MainQueueable');
      if (q != null) {
          accAddrAsyncBatchMax = q.Batch_Size_Account_Address__c;
      } else {
          accAddrAsyncBatchMax = 100;
      }
}

  public static void mainEntry(List<rC_Bios__Account_Address__c> newList, List<rC_Bios__Account_Address__c> oldList, 
                               Map<Id, rC_Bios__Account_Address__c> newMap, Map<Id, rC_Bios__Account_Address__c> oldMap, 
                               Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, 
                               Boolean isBefore, Boolean isAfter) {
    //if trigger is active
    if(TriggerState.isActive('AccountAddressTrigger') && !(UserInfo.getName() == Label.Data_Migration 
       && UserInfo.getProfileId() == Label.SysAdminProfileId) 
       && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)
      ){ 

      counter++;
      if(isBefore){
        if(isInsert){
          beforeInsert(newList);
        }
        if(isUpdate){
          beforeUpdate(newList, oldMap);
        }
      }
      if(isAfter) {
          if(isUpdate) {
            afterUpdate(newList, oldMap);
          }
          if(isInsert) {
              afterInsert(newList, oldMap);
          }
      }
    }
  }

  private static void beforeInsert(List<rC_Bios__Account_Address__c> newList){
    if(beforeInsertProcessed) return;
    beforeInsertProcessed = true; //prevents recursion, ensure first run completes needs

    autoPopulateCityAndState(newList);
  }
    
  private static void afterInsert(List<rC_Bios__Account_Address__c> newList, Map<Id, rC_Bios__Account_Address__c> oldMap){
    if(afterInsertProcessed) return;
    afterInsertProcessed = true; //prevents recursion, ensure first run completes needs
    //I-305949
    list<Id> idsForAsync_AccAddr = new list<Id>();

    for( rC_Bios__Account_Address__c accAdd : newList ){
      if( accAdd.Country_Name__c != null ) {
        idsForAsync_AccAddr.add(accAdd.Id);
      }
      if( accAdd.Country_Name__c == null && accAdd.rC_Bios__Original_Country__c != null){
        accAdd.rC_Bios__Original_Country__c = null;
      }
    }
    
    //I-305949
    // Controls the number of Ids passed into a single AsyncRequest__c record for async processing
    if(idsForAsync_AccAddr.size() > accAddrAsyncBatchMax){
        newAsyncRequest.add( new AsyncRequest__c(
                                    AsyncType__c ='accAddr_updateCountryCode', Object_API_Name__c = 'rC_Bios__Account_Address__c',
                                    Params__c = String.join(idsForAsync_AccAddr,',')));
        idsForAsync_AccAddr.clear();
    }

    // Picks up any remaining Ids (less than max batch size) to be passed into a single AsyncRequest__c record for async processing
    if(idsForAsync_AccAddr.size() > 0){
      newAsyncRequest.add( new AsyncRequest__c(
                            AsyncType__c ='accAddr_updateCountryCode', Object_API_Name__c = 'rC_Bios__Account_Address__c',
                            Params__c = String.join(idsForAsync_AccAddr,',')));
        try {
            insert newAsyncRequest;
        } catch(Exception ex){
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('AccountAddressTriggerHandler','afterInsert',ex.getMessage());
            log.logException(ex);
            log.saveLogs();            
            // or suggest using our ApexLog Asset to record the fail!
        }
    }

  }
    
  private static void beforeUpdate(List<rC_Bios__Account_Address__c> newList, Map<Id, rC_Bios__Account_Address__c> oldMap) {
    if(beforeUpdateProcessed) return;
    beforeUpdateProcessed = true; //prevents recursion, ensure first run completes needs
    List<rC_Bios__Account_Address__c> listOfAddress = new List<rC_Bios__Account_Address__c>();
    
    Set<String> countryNameSet = new Set<String>();

    for(rC_Bios__Account_Address__c accountAddress : newList) {
      if(accountAddress.rC_Bios__Original_Postal_Code__c != null 
         && accountAddress.rC_Bios__Original_Postal_Code__c != oldMap.get(accountAddress.Id).rC_Bios__Original_Postal_Code__c
      ){
        listOfAddress.add(accountAddress);
      }
      //Get country names: Task: T-647439
      if( accountAddress.Country_Name__c != null ) 
        countryNameSet.add( accountAddress.Country_Name__c );
      else 
          accountAddress.rC_Bios__Original_Country__c = null;
    }
    
    if(!listOfAddress.isEmpty()) {
      autoPopulateCityAndState(listOfAddress);
    }

    if( countryNameSet.size() > 0 ){ //Added by Bhavesh, Task: T-647439
        setCountryCode(newList, countryNameSet);
    }
  }
  
  private static void afterUpdate(List<rC_Bios__Account_Address__c> newList, Map<Id, rC_Bios__Account_Address__c> oldMap) {
    if(afterUpdateProcessed) return;
    afterUpdateProcessed = true;  //prevents recursion, ensure first run completes needs
  }

  private static void autoPopulateCityAndState(List<rC_Bios__Account_Address__c> listOfAddressesToProcess) {
    Set<String> setOfZipCodes = new Set<String>();
    map<String,String> mapOfZipAndCityStateKey = new map<String,String>();
    for(rC_Bios__Account_Address__c address : listOfAddressesToProcess) {
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
    
    for(rC_Bios__Account_Address__c address: listOfAddressesToProcess) {
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
  /**************************************************
   * Method: updateCountryCode
   * Desc: update countrycode value from countryname.
   * Created By: Bhavesh
   * Task: T-647439
  ***************************************************/
  private static void setCountryCode(List<rC_Bios__Account_Address__c> countryAddressList, Set<String> countryNameSet ){
        Map<String, Country_Codes__c> countryToCountryCodeMap = new Map<String,Country_Codes__c>();
        
        countryToCountryCodeMap = ConvertCountryNames.returnCountryCodeFromCountryName(countryNameSet);
        for( rC_Bios__Account_Address__c accAdd : countryAddressList ){
            if( accAdd.Country_Name__c != null && countryToCountryCodeMap.containsKey(accAdd.Country_Name__c) )
                accAdd.rC_Bios__Original_Country__c = countryToCountryCodeMap.get(accAdd.Country_Name__c).Country_Code__c;
            else if( accAdd.Country_Name__c == null && accAdd.rC_Bios__Original_Country__c != null )
                accAdd.rC_Bios__Original_Country__c = null;
        }
  }

}