/*
*
*Name  :  Utilities
*Author:  Appirio India (Sai Krishna )
*Date  :  November 15, 2016
*Purpose : Class contains multple utility methods to be used in classes Methods:
*          Checks the FutureCalls Limits in the CurrentTransaction as well as the 24-Hours Limits(T-555213) Account Checkdigit
*          Process resutls to break Apex Log SaveResult
*ACLU Updates : 2019-01-29 - Dave Seidman - getObjectName, addQuotesToStringArray
*Modified by :: Salesforce.org :: 21-June-2019 :: Zendesk: #68203
*/
public class Utilities{

    public static Boolean IsUpsert = false;
    public static Boolean runOnce = false;
    public static Boolean invokedByContactTrigger = false;
    public static Map<String, Schema.SObjectType> globalDescribe;

/*
*
*Method: CanUseFutureContext

*It checks the future limits at 24 hour period as well as the in the current Apex transaction.
*
*/
    public static boolean CanUseFutureContext() {
        //boolean callStackLimitExceeded = Limits.getFutureCalls() <= Limits.getLimitFutureCalls();

        /*if (!callStackLimitExceeded) {
            // Check 24-hour rolling window limit
            // of 200 * # of Salesforce, Salesforce Platform, or Force.com One App Licenses
           return GetNumFutureCallsInLast24Hours() < getMaxFutureCallsAllowed();
        } else return false;*/
        return true;
    }

/*
*
*Method: getMaxFutureCallsAllowed

*It returns the maxfuturecallsAllowed in Org.
*
*/
    public static Integer getMaxFutureCallsAllowed() {
        Integer usersCount = [SELECT COUNT() FROM User WHERE Profile.UserLicense.LicenseDefinitionKey IN ('SFDC','AUL','PID_FDC_FREE') AND isActive=true];
        return Math.max(250000, usersCount*200);
    }

/*
*
*Method: GetNumFutureCallsInLast24Hours

*It returns the futureCalls completed in last24hours
*/

    public static Integer GetNumFutureCallsInLast24Hours() {
        return [select count() from AsyncApexJob where CreatedDate >= :Datetime.now().addHours(-24) AND JobType = 'Future'];
    }

    public static String getFiscalYearFromDate(Date dateValue) {
        Integer month = dateValue.month();
        Integer year = dateValue.year();
        system.debug('month');
        system.debug('year');
        if((month >= 4 && month < 12) || (month == 12)) {
            year = year + 1;
        }
        else if(month == 1 || month == 2 || month == 3) {
            year = year;
        }
        String yearValue = String.valueOf(year);
        return yearValue;
    }

    /*
    *
    *Method: calculateCheckDigit
    *Createdby: Aashita Sharma
    *Task :T-657330
    *It returns a list of Account with override Account Number
    */
    public static Integer calculateCheckDigit(String autoAcctNumber) {

        String v_AccountID = autoAcctNumber.leftPad(10,'0');
        String v_ResultStr = '';
        Integer v_ResultInt = 0;
        Integer v_SumDigits = 0;

        String v_Pos_2 = String.valueOf(Integer.valueOf(v_AccountID.substring(1, 2)) * 2).leftPad(2, '0');
        String v_Pos_4 = String.valueOf(Integer.valueOf(v_AccountID.substring(3, 4)) * 2).leftPad(2, '0');
        String v_Pos_6 = String.valueOf(Integer.valueOf(v_AccountID.substring(5, 6)) * 2).leftPad(2, '0');
        String v_Pos_8 = String.valueOf(Integer.valueOf(v_AccountID.substring(7, 8)) * 2).leftPad(2, '0');
        String v_Pos_10 = String.valueOf(Integer.valueOf(v_AccountID.substring(9, 10)) * 2).leftPad(2, '0');

        v_SumDigits =
                Integer.valueOf( v_AccountID.substring(0,1) ) +
                        Integer.valueOf( v_AccountID.substring(2,3) ) +
                        Integer.valueOf( v_AccountID.substring(4,5) ) +
                        Integer.valueOf( v_AccountID.substring(6,7) ) +
                        Integer.valueOf( v_AccountID.substring(8,9) ) +
                        Integer.valueOf( v_Pos_2.substring(0,1) ) +
                        Integer.valueOf( v_Pos_2.substring(1,2) ) +
                        Integer.valueOf( v_Pos_4.substring(0,1) ) +
                        Integer.valueOf( v_Pos_4.substring(1,2) ) +
                        Integer.valueOf( v_Pos_6.substring(0,1) ) +
                        Integer.valueOf( v_Pos_6.substring(1,2) ) +
                        Integer.valueOf( v_Pos_8.substring(0,1) ) +
                        Integer.valueOf( v_Pos_8.substring(1,2) ) +
                        Integer.valueOf( v_Pos_10.substring(0,1) ) +
                        Integer.valueOf( v_Pos_10.substring(1,2) );

        String v_SumDigitsString = String.valueOf(v_SumDigits).leftPad(3,'0');
        if( v_SumDigitsString.substring(2,3) != '0' ){
            v_ResultInt = Integer.valueOf(v_AccountID) * 10 + (10 - Integer.valueOf(v_SumDigitsString.substring(2,3)) );
        } else {
            v_ResultInt = Integer.valueOf(v_AccountID) * 10;
        }
        return v_ResultInt;
    }

    //Generic method to create apex logs for DMLs
    public static void processResults(List<Database.SaveResult> results, List<sObject> lstObj, String Classname,String Methodname,
            String ErrorMessage ){
        integer i = 0;
        set<String> messages;
        apexLogHandler.apexLog log;
        for (Database.SaveResult result : results) {
            messages = new set<String>();
            if (!result.isSuccess()){
                for (Database.Error err : result.getErrors()){
                    if(!messages.contains(err.getMessage())) {
                        log = new apexLogHandler.apexLog(Classname,Methodname,
                                ErrorMessage+ lstObj[i].id + '\n' + err.getMessage());
                        messages.add(err.getMessage());
                    }
                }
            }
            i++;
        }
        if(log != null) {
            log.saveLogs();
        }
    }

    /*
    *
    *Method: getSObjectName
    *Createdby: Dave Seidman
    *Returns name of SOobject, given a record Id


    public static String getObjectName(Id myId) {

        Schema.SObjectType sobjectType = myId.getSObjectType();
        String sobjectName = String.valueOf(sobjectType);
        return sobjectName;
    }

    /*
    *
    *Method: getSObjectName
    *Createdby: Dave Seidman
    *Takes an array of strings (use case is really for Ids) and returns a string with the needed parentheses inserted;
    *Use case: to allow a list of IDs to be dynamically inserted into a query string
 .  *Example: (a3f4A000000VZLBQA4, a3f4A000000VYkBQAW) => ('a3f4A000000VZLBQA4','a3f4A000000VYkBQAW')


    public static String addQuotesToStringArray(List<String> stringList) {
        String listString = '(';
        Integer idCount = 0;
        while (idCount < stringList.size()) {
            String idString = '\''+ stringList[idCount] + '\'';
            listString += idString;
            idCount++;
            if (idCount < stringList.size()) {
                listString += ',';
            }
        }
        listString += ')';
        system.debug(stringList);
        system.debug(listString);
        return listString;
    }

      */
    /*
    *
    *Method: getType
    *Createdby: Dave Seidman; based on https://success.salesforce.com/ideaView?id=08730000000l9wHAAQ
    *Takes an obkect, returns string of the object type
    */

    public static string getType(Object o) {
        if(o==null) return '';              // we can't say much about null with our current techniques
        if(o instanceof SObject)            return ((SObject)o).getSObjectType().getDescribe().getName()+'';
        if(o instanceof Boolean)            return 'Boolean';
        if(o instanceof Id)                 return 'Id';
        if(o instanceof String)             return 'String';
        if(o instanceof Blob)               return 'Blob';
        if(o instanceof Date)               return 'Date';
        if(o instanceof Datetime)           return 'Datetime';
        if(o instanceof Time)               return 'Time';
        if(o instanceof String)             return 'String';
        if(o instanceof Integer)            return 'Integer';
        if(o instanceof Long)               return 'Long';
        if(o instanceof Decimal)            return 'Decimal';
        /* if(o instanceof Double)          return 'Double';   // we can't distinguish between decimal and double */
        if(o instanceof List<object>)       return 'List';
        return 'Object';                    // we can't detect maps and sets and maps
    }

    /** author Surya pratap Singh
     * Date 19/06/2019
   * getPickListOptions This method return the pick list values of a field from the specified sObject
   * @param sObjectName sObject name in which the field exists
  * @param fieldName Field Name to get the picklist values.
   * @return List<String>
   */

    public static List<String> getPickListOptions(String sObjectName, String fieldName) {

        List<String> options = new List<String>();
        if(!String.isEmpty(sObjectName) && !String.isEmpty(fieldName)) {
            sObjectType sObj = Schema.getGlobalDescribe().get(sObjectName);
            Map<String, Schema.SObjectField> fieldMap = sObj.getDescribe().fields.getMap();
            Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

            if (fieldResult.isNillable()) {
                options.add('');
            }

            for (Schema.PicklistEntry option : ple) {
                options.add(option.getValue());
            }
        }
        return options;
    }

    /** author Surya pratap Singh
     * Date 21/06/2019
   * getFieldsHelpText This method return the map of field name and related help text info
   * @param sObjectName sObject name in which the field exists
  * @param fields List of Fields to get inline text info
   * @return Map<String, String>
   */
    public static Map<String, String> getFieldsHelpText(String sObjectName, List<String> fieldToGetHelpText){
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        Map<String, String> fieldHelp = new Map<String, String>();

        for (String fieldName : fieldToGetHelpText) {
            if(fields.containsKey(fieldName)) {
                Schema.DescribeFieldResult field = fields.get(fieldName).getDescribe();
                fieldHelp.put(fieldName, field.getInlineHelpText());
            }
        }
        return fieldHelp;
    }

    //Zendesk: #68203 -- Get Deposit site from custom metadata Types
    public static list<String> getDepositSiteSet(String affiliate) {
        List<String> sharingAffiliationEntitySet = new list<String>();
        if(String.isNotBlank(affiliate) ) {
            List<Affiliate_Code_Mapping__mdt> affiliateCodeMapping = [SELECT id
                    , Deposit_Site__c
                    , DeveloperName
            FROM Affiliate_Code_Mapping__mdt
            WHERE DeveloperName = :affiliate];
            if(affiliateCodeMapping != null
                    && affiliateCodeMapping.size() > 0
                    && affiliateCodeMapping[0].Deposit_Site__c != null) {
                List<String> despositeSiteList  = affiliateCodeMapping[0].Deposit_Site__c.split(',');
                for(String despSite :despositeSiteList) {
                    if(despSite.contains('_')) {
                        sharingAffiliationEntitySet.add(despSite.substringBefore('_').trim());
                    }else if(despSite.contains('-')) {
                        sharingAffiliationEntitySet.add(despSite.substringBefore('-').trim());
                    }
                }
            }else {
                sharingAffiliationEntitySet.add(affiliate);
            }
            System.debug(sharingAffiliationEntitySet);

        }//END:Zendesk: #68203
        return sharingAffiliationEntitySet;
    }

    //Zendesk: #68203   : Added a method to check deposite site is same as opp's deposit site
    public static Boolean getIsDepositSiteSameAsAffiliate(opportunity oppObj
            , list<String> sharingAffiliationEntitySet
            , String depositSite){
        Boolean isDepositSiteSameAsAffiliate = false;
        String oppDespSite = oppObj.Deposit_Site__c;
        if(sharingAffiliationEntitySet.size() == 1 && sharingAffiliationEntitySet[0].equalsIgnoreCase(depositSite)) {

            isDepositSiteSameAsAffiliate = true;
        } else {
            String desp = '';
            if(oppDespSite.contains('_') && oppDespSite != null) {
                desp = oppDespSite.substringBefore('_').trim();
            }else if (oppDespSite.contains('-') && oppDespSite != null){
                desp = oppDespSite.substringBefore('_').trim();
            }
            for(String despSite :sharingAffiliationEntitySet) {
                if(despSite.equalsIgnoreCase(desp)){
                    isDepositSiteSameAsAffiliate = true;
                    break;
                }
            }

        }
        return isDepositSiteSameAsAffiliate;
    }

    /** Author  John Casimiro : https://gist.github.com/johncasimiro/734428
     * Date 2019-08-16 - copied from above by Dave Seidman
     * description: A code snippet that mimics the popular Select * SQL syntax in force.com's Apex language.
     * - useful when all fields are needed, such in the context of using the Duplicate Check Apex API
     * @param String sObject name to query
     * @return String - query of all fields from given sObjectString, String>
    */
    public static String getQueryOfAllFields(String sobjectName) {

        String query = 'SELECT';
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap();

        // Grab the fields from the describe method and append them to the queryString one by one.
        for(String s : objectFields.keySet()) {
            query += ' ' + s + ', ';
        }

        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-2,query.Length()) == ', '){
            query = query.subString(0,query.Length()-2);
        }

        // Add FROM statement
        query += ' FROM ' + sobjectName;
        // may not need as long as middle names are enabled; but SOQL error popping up suddenly in dev org
       /* if (sobjectName == 'Contact' && !(query.contains('MiddleName') || query.contains('middlename'))) {
            query = query.replace('firstname,','firstname, middlename,');
        }
        */

        // SOQL error suddenly popping up in dev org re InformalName not being in SOQL
       /* if (sobjectName == 'Contact' && !(query.contains('InformalName') || query.contains('informalname'))) {
            query = query.replace('firstname,','firstname, InformalName,');
        } */


        // error on informal name not being in SOQL query but being returned
      //  if (sobjectName == 'Contact') {
        //    query = query.replace('firstname,','firstname, middlename');
        //}

        return query;
    }
 
    public static String getObjectPrefix(String sobjectName) {
        if (globalDescribe == NULL) {
            globalDescribe = Schema.getGlobalDescribe();
        }
        Schema.SObjectType s = globalDescribe.get(sobjectName) ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        String prefix = r.getKeyPrefix();
        return prefix;
    }

    public static String stripNonNumeric(String stringToStrip) {
        return stringToStrip.replaceAll('[^0-9]', '');
    }
    //Added by : Kirti Rathod(SFDO)#77016 - This method is used to find the timezone of user
    public static String getTimeZone() {
        TimeZone tz = UserInfo.getTimeZone();
        String userDate = tz.getDisplayName();
        if(userDate.contains(')')) {
            userDate = userDate.substringBetween(')', '(');
        }
        List<String> lst = (userDate.trim()).split(' ');
        userDate= '';
        for(String s :lst) {
            userDate = userDate+s.subString(0,1);
        }
        return userDate;
    }

}