/*
*
*Name  :  AccountAddressAsyncProcessor
*Author:  Appirio India (Gagandeep Kaur)
*Date  :  Dec 18, 2017
*Purpose : Async Processor methods include querries Account Address and Update Country Code
*
*/
public class AccountAddressAsyncProcessor {
    public list<rC_Bios__Account_Address__c> incomingObjs = new list<rC_Bios__Account_Address__c>();
    public AsyncRequest__c incomingRequest = new AsyncRequest__c();
    // Added
    public list<rC_Bios__Account_Address__c> accAddrObjs = new list<rC_Bios__Account_Address__c>();
    //Ended
    public AccountAddressAsyncProcessor( AsyncRequest__c request ) {
    incomingRequest = request;
    list<ID> idsAfterSplit = incomingRequest.Params__c.split(',');

    // the FOR UPDATE gives the async processor control over the record so locking can't occur.
    incomingObjs = [SELECT ID, Country_Name__c, rC_Bios__Original_Country__c
                    FROM rC_Bios__Account_Address__c
                    WHERE ID IN :idsAfterSplit FOR UPDATE];
  }
  
  // Singe AsyncType method
  public void accAddr_updateCountryCode(){
    Set<String> countryNameSet = new Set<String>();
    for(rC_Bios__Account_Address__c accAddr : incomingObjs) {
        countryNameSet.add( accAddr.Country_Name__c );
    }
    Map<String, Country_Codes__c> countryToCountryCodeMap = new Map<String, Country_Codes__c>();
    List<rC_Bios__Account_Address__c> addrListToUpdate = new List<rC_Bios__Account_Address__c>();
    
    countryToCountryCodeMap = ConvertCountryNames.returnCountryCodeFromCountryName(countryNameSet);

    for ( rC_Bios__Account_Address__c a : incomingObjs ) {
      if(a.Country_Name__c != null && countryToCountryCodeMap.containsKey(a.Country_Name__c)
        && a.Country_Name__c != 'United States of America' ){
        a.rC_Bios__Original_Country__c = countryToCountryCodeMap.get(a.Country_Name__c).Country_Code__c;
        accAddrObjs.add(a);
      }
    }
  }
}