/*
*
*Name  :  BatchPopulateActPreferences
*Author:  Appirio  (James)
*Date  :  March 27, 2018
*Purpose : Batch Class to update reporting fields on Account. Intended use for One Time Use
*
*/
global class BatchPopulateActPreferences implements Database.Batchable<sObject> {

  global BatchPopulateActPreferences() {
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator([
                                      select id
                                      from Account
                                      //where id IN ('001W000000LWELZIA5', '001W000000LWoOLIA1')
                                    ]);

    /*
    select id, rC_Bios__Code_Value__c, rC_Bios__Category__c,  rC_Bios__Account__c
    from rC_Bios__Preference__c
    where rC_Bios__Active__c = True
       and rC_Bios__Account__c != ''
       //and rC_Bios__Code_Value__c != ''
       //and (rC_Bios__Account__c = '001W000000RUCTU'
       //  OR  rC_Bios__Account__c = '001W000000QG8OL'
       //  OR  rC_Bios__Account__c = '001W000000QkmPn')
       order by rC_Bios__Account__c, rC_Bios__Code_Value__c
    //Limit 400
    */

    //select id, name, Rpt_Board_Member__c, Affiliate_Major_Gifts_Program_ML__c,
    //Affiliate_Major_Donor_Prospect_MQ__c, Rpt_Common_Preference_Filters__c, Rpt_Interest_String__c, Preference_String__c,
    //(select rC_Bios__Code_Value__c, rC_Bios__Category__c from rC_Bios__Preferences__r where rC_Bios__Active__c = True order by rC_Bios__Code_Value__c ASC)
    //from Account
    //where Id IN (select rC_Bios__Account__c from rC_Bios__Preference__c )
    //where id = '001W000000RUCTU'

  }

  global void execute(Database.BatchableContext BC, List<Account> scope) {

    Set<Id> accountIdSet = (new Map<Id, SObject>(scope)).keySet();
    //PreferenceTriggerHandler.updateAccountPrefStrings(accountIdSet);

    Set<String> commonPreValues = new Set<String> {'AL', 'AN', 'AY', 'FA', 'FN', 'U1', 'UA', 'UN', 'Z1', 'ZD', 'ZN',
        'AXXAPNO', 'AXXBNNO', 'AXXCUNO', 'AXXEMNO', 'AXXINNO',
        'AXXNWNO', 'AXXPHNO', 'AXXTMNO', 'OXXAKNO', 'OXXAPNO',
        'OXXCTNO', 'OXXINNO', 'OXXIPNO', 'OXXNWNO', 'OXXPCNO',
        'OXXPHNO', 'OXXPUNA', 'OXXPUNL', 'OXXPUNO', 'OXXTMNO', 'OXXVDNO',
        'AXXTRANS', 'AJ', 'AN', 'AL', 'PX', 'PA', 'PB', 'PC', 'MM'
                                                  };
    list<Account> accountsToProcess = [ select  id, name, Rpt_Board_Member__c, Affiliate_Major_Gifts_Program_ML__c,
                                          Affiliate_Major_Donor_Prospect_MQ__c, Rpt_Common_Preference_Filters__c, Rpt_Interest_String__c, Preference_String__c,
                                          (select rC_Bios__Code_Value__c, rC_Bios__Category__c, rC_Bios__Active__c from rC_Bios__Preferences__r
                                        order by rC_Bios__Code_Value__c ASC)//where rC_Bios__Active__c = True
                                        from    Account
                                        where   Id IN :accountIdSet];
    List<Account> accountsToUpdate = new List<Account>();
    if (accountsToProcess.size() > 0) {

      for (Account a : accountsToProcess) {
        if( String.isBlank(a.Rpt_Interest_String__c)
            && String.isBlank(a.Preference_String__c)
            && String.isBlank(a.Rpt_Common_Preference_Filters__c)
            && a.Affiliate_Major_Donor_Prospect_MQ__c == false
            && a.Affiliate_Major_Gifts_Program_ML__c == false
            && a.Rpt_Board_Member__c == false
            && a.rC_Bios__Preferences__r.size() == 0
        ){
          //system.debug('reached here 1');
          continue;
        }
        //system.debug('reached here 2');

        a.Rpt_Interest_String__c = '';
        a.Preference_String__c = '';
        a.Rpt_Common_Preference_Filters__c = '';
        a.Affiliate_Major_Donor_Prospect_MQ__c = false;
        a.Affiliate_Major_Gifts_Program_ML__c = false;
        a.Rpt_Board_Member__c = false;

        if (a.rC_Bios__Preferences__r.size() > 0) {
          for (rC_Bios__Preference__c pref :  a.rC_Bios__Preferences__r) {
            if (pref.rC_Bios__Code_Value__c != null) {
              if (commonPreValues.contains(pref.rC_Bios__Code_Value__c) && pref.rC_Bios__Active__c) { //Common Preference Filters
                a.Rpt_Common_Preference_Filters__c = add_dedup(a.Rpt_Common_Preference_Filters__c, pref.rC_Bios__Code_Value__c);
              }
              if (pref.rC_Bios__Active__c) { //check added for only active pref records
                if (pref.rC_Bios__Category__c == 'Interests') { //Interest String
                  a.Rpt_Interest_String__c = add_dedup(a.Rpt_Interest_String__c, pref.rC_Bios__Code_Value__c);
                } else {  //Preference String
                  a.Preference_String__c = add_dedup(a.Preference_String__c, pref.rC_Bios__Code_Value__c);
                }
              }
              if (pref.rC_Bios__Active__c) {
                if (pref.rC_Bios__Code_Value__c == 'MQ') {
                  a.Affiliate_Major_Donor_Prospect_MQ__c = true;
                }
                if (pref.rC_Bios__Code_Value__c == 'ML') {
                  a.Affiliate_Major_Gifts_Program_ML__c = true;
                }
                if (pref.rC_Bios__Code_Value__c == 'BA') {
                  a.Rpt_Board_Member__c = true;
                }
              }
            }
          }//end pref loop
          //accountsToUpdate.add(a);
        }
        accountsToUpdate.add(a);
      }//end account for loop



    }

    try {
      if (!accountsToUpdate.isEmpty()) {
        update accountsToUpdate;
      }
    } catch (Exception e) {
      Exceptionutils.createApexLog('PreferenceTriggerHandler ', 'updateAccountPrefStrings', e);
    }


  }

  global void finish(Database.BatchableContext BC) {

    apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchPopulateActPreferencesForGoLive FINISHED');
    log.saveLogs();
  }


  public static String add_dedup(String prefString, String codeVal) {
    if (String.isBlank(prefstring)) {
      prefString = ':' + codeVal + ':';
    } else if (!prefstring.contains(':' + codeVal + ':')) {
      prefString = prefString + codeVal + ':';
    }
    return prefString;
  }



}