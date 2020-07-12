/*
*
*Name  :  ConvertCountryNames
*Author:  Appirio India (Bhavesh Malviya)
*Date  :  Nov 16, 2017
*Purpose : For obj 'account address', update country value from country name while insert and udpate.
*
*/
public class ConvertCountryNames {
    public static Map<String,Country_Codes__c> returnCountryCodeFromCountryName( Set<String> countryNameSet ){
        Map<String, Country_Codes__c> countryToCountryCodeMap = new Map<String,Country_Codes__c>();
        if( countryNameSet.size() > 0 ){
            for( Country_Codes__c cc: [SELECT id, Name, Country_Code__c, Country_3_Char_Code__c 
                                       FROM Country_Codes__c 
                                       WHERE Name in: countryNameSet
                                         OR Country_3_Char_Code__c in : countryNameSet]
            ){
                countryToCountryCodeMap.put(cc.Name, cc);
            }
        }
        return countryToCountryCodeMap;
        
    }
}