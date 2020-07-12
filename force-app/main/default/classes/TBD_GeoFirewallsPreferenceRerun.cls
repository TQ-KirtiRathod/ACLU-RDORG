global class TBD_GeoFirewallsPreferenceRerun implements Database.Batchable<sObject> {

    public set<String> codeValues = new set<String>{
        'ML', 
'MM',
'MJ', 
'PA', 
'PB', 
'PC', 
'PP'
    };
    public set<String> affils = new set<String>{
        'AA',
'AK',
'AL',
'AR',
'AZ',
'CD',
'CN',
'CO',
'CS',
'CT',
'DC',
'DE',
'EM',
'FL',
'GA',
'GU',
'HI',
'IA',
'ID',
'IL',
'IN',
'KM',
'KS',
'KY',
'LA',
'MA',
'MD',
'ME',
'MI',
'MN',
'MO',
'MS',
'MT',
'NA',
'NC',
'ND',
'NE',
'NH',
'NJ',
'NM',
'NN',
'NNA',
'NV',
'NY',
'OH',
'OK',
'OR',
'PA',
'PR',
'RI',
'SC',
'SD',
'TN',
'TX',
'US',
'UT',
'VA',
'VT',
'WA',
'WI',
'WV',
'WY',
'ZF'
    };
  public static final String ALLACLU = Label.All_ACLU;
  public static final String NATIONAL = Label.National;
  public static Map<String,Id> mapGroupNameToId = new Map<String,Id>();

   global Database.QueryLocator start(Database.BatchableContext Bc ){
       return Database.getQueryLocator([select id, Affiliation__c from Account]);// where id = '001W000000NzcIeIAJ']);//[select id, rC_Bios__Account__r.Affiliation__c
                                        //FROM rC_Bios__Preference__c
                                        //]);
   }
/*
  global void execute(Database.BatchableContext BC, List<Account> scope) {
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name IN: this.affils OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        
        List<rC_Bios__Preference__share> sharesToBeInsert = new List<rC_Bios__Preference__share>();
        Set<ID> setAccountID = new set<ID>();
        for(rC_Bios__Preference__c pm: [Select Id, rC_Bios__Account__r.Affiliation__c, rC_Bios__Account__c, rC_Bios__Code_Value__c 
                                        FROM rC_Bios__Preference__c 
                                        WHERE rC_Bios__Account__c IN : scope
                                        AND rC_Bios__Code_Value__c IN: codeValues]){
                     setAccountID.add(pm.rC_Bios__Account__c);                   
                                            
        }
        map<Id,String> mapPrefIDToAccountAffiliation =  new map<id,String>();
        for(rC_Bios__Preference__c pm: [Select Id, rC_Bios__Account__r.Affiliation__c, rC_Bios__Account__c, rC_Bios__Code_Value__c 
                                        FROM rC_Bios__Preference__c 
                                        WHERE rC_Bios__Account__c IN : setAccountID]) {
                           mapPrefIDToAccountAffiliation.put(pm.ID, pm.rC_Bios__Account__r.Affiliation__c);                 
        }
        
        set<Id> setPrefIdWithExistingShareRecAff = new set<Id>();
        set<Id> setPrefIdWithExistingShareRecNational = new set<Id>();
        set<Id> setPrefIdWithExistingShareRecACLU = new set<Id>();
        
        if(!mapPrefIDToAccountAffiliation.isEmpty()) {
            // querry existing share records
            for(rC_Bios__Preference__share pfShare : [SELECT Id, UserOrGroupId, ParentId,AccessLevel
                                         FROM rC_Bios__Preference__share
                                         WHERE ParentId IN: mapPrefIDToAccountAffiliation.KeySet() and RowCause = 'Manual']) {
                if(pfShare.AccessLevel == 'Edit') {
                    if(pfShare.UserOrGroupId == mapGroupNameToId.get(mapPrefIDToAccountAffiliation.get(pfShare.ParentId))) {
                        setPrefIdWithExistingShareRecAff.add(pfShare.ParentId);
                    }
                    if(pfShare.UserOrGroupId == mapGroupNameToId.get(NATIONAL)){
                        setPrefIdWithExistingShareRecNational.add(pfShare.ParentId);
                    } 
                }
                if(pfShare.AccessLevel == 'Read' && pfShare.UserOrGroupId == mapGroupNameToId.get(ALLACLU)) {
                    setPrefIdWithExistingShareRecACLU.add(pfShare.ParentId);
                }
            }
        }

        for(rC_Bios__Preference__c pm: [Select Id, rC_Bios__Account__r.Affiliation__c, rC_Bios__Account__c, rC_Bios__Code_Value__c 
                                        FROM rC_Bios__Preference__c 
                                        WHERE Id IN : mapPrefIDToAccountAffiliation.KeySet()]) {
            if(!setPrefIdWithExistingShareRecAff.contains(pm.Id)) {
                rC_Bios__Preference__share affShare = new rC_Bios__Preference__share();
                affShare.ParentId = pm.Id;
                affShare.AccessLevel = 'Edit';
                affShare.UserOrGroupId = mapGroupNameToId.get(pm.rC_Bios__Account__r.Affiliation__c);
                sharesToBeInsert.add(affShare);
            }
            if(!setPrefIdWithExistingShareRecACLU.contains(pm.Id)) {
                rC_Bios__Preference__share acluShare = new rC_Bios__Preference__share();
                acluShare.ParentId = pm.Id;
                acluShare.AccessLevel = 'Read';
                acluShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
                sharesToBeInsert.add(acluShare);
            }
            if(!setPrefIdWithExistingShareRecNational.contains(pm.Id)) {
                rC_Bios__Preference__share natShare = new rC_Bios__Preference__share();
                natShare.ParentId = pm.Id;
                natShare.AccessLevel = 'Edit';
                natShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
                sharesToBeInsert.add(natShare);
            }
        }

        if(!sharesToBeInsert.IsEmpty()) {
            List<Database.saveresult> acResults = Database.insert(sharesToBeInsert,false);
              integer i = 0;
              set<String> messages; 
              apexLogHandler.apexLog log; 
              
              Boolean foundError = false;
              
                for (Database.saveresult result : acResults) {
                  messages = new set<String>();
                  if (!result.isSuccess() && !foundError ){
                    
                    foundError = true;
                    log = new apexLogHandler.apexLog('TBD_GeoFirewallsPrefRerun','execute',
                                                 'foundError: ' + String.valueOf(sharesToBeInsert)  );
                  
                    //for (Database.Error err : result.getErrors()){
                    //  if(!messages.contains(err.getMessage())) {
                    //    log = new apexLogHandler.apexLog('TBD_GeoFirewallsPreferenceRerun','',
                    //                                     'InsertSharingRecords failed::  '+ sharesToBeInsert[i].id + '\n' + err.getMessage());
                    //    messages.add(err.getMessage() + '/n' + err.getFields());
                    //  }
                    //}
                   
                  }
                  i++;
                }
              if(log != null) {
                log.saveLogs();
              }
        }

    }
*/
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Account> acctScope = new List<Account>();
        for(Account acct: scope){
          if(this.affils.contains(acct.Affiliation__c)){
            acctScope.add(acct);
          }
        }
        
        if(!acctScope.isEmpty()){
        
          for(Group grp: [SELECT Id, Name FROM Group WHERE Name IN: this.affils OR Name =: ALLACLU OR Name =: NATIONAL]){
              mapGroupNameToId.put(grp.Name,grp.Id);
          }
          
          List<rC_Bios__Preference__share> sharesToBeInsert = new List<rC_Bios__Preference__share>();
          map<Id,String> mapPrefIDToAccountAffiliation =  new map<id,String>();
          for(rC_Bios__Preference__c pm: [Select Id, rC_Bios__Account__r.Affiliation__c, rC_Bios__Account__c, rC_Bios__Code_Value__c 
                                          FROM rC_Bios__Preference__c 
                                          WHERE rC_Bios__Account__c IN : acctScope ]){
                        mapPrefIDToAccountAffiliation.put(pm.ID, pm.rC_Bios__Account__r.Affiliation__c);                  
                                              
          }
          
          set<Id> setPrefIdWithExistingShareRecAff = new set<Id>();
          set<Id> setPrefIdWithExistingShareRecNational = new set<Id>();
          set<Id> setPrefIdWithExistingShareRecACLU = new set<Id>();
          
          if(!mapPrefIDToAccountAffiliation.isEmpty()) {
              // querry existing share records
              for(rC_Bios__Preference__share pfShare : [SELECT Id, UserOrGroupId, ParentId,AccessLevel
                                           FROM rC_Bios__Preference__share
                                           WHERE ParentId IN: mapPrefIDToAccountAffiliation.KeySet() and RowCause = 'Manual']) {
                  if(pfShare.AccessLevel == 'Edit') {
                      if(pfShare.UserOrGroupId == mapGroupNameToId.get(mapPrefIDToAccountAffiliation.get(pfShare.ParentId))) {
                          setPrefIdWithExistingShareRecAff.add(pfShare.ParentId);
                      }
                      if(pfShare.UserOrGroupId == mapGroupNameToId.get(NATIONAL)){
                          setPrefIdWithExistingShareRecNational.add(pfShare.ParentId);
                      } 
                  }
                  if(pfShare.AccessLevel == 'Read' && pfShare.UserOrGroupId == mapGroupNameToId.get(ALLACLU)) {
                      setPrefIdWithExistingShareRecACLU.add(pfShare.ParentId);
                  }
              }
          }
  
          for(rC_Bios__Preference__c pm: [Select Id, rC_Bios__Account__r.Affiliation__c, rC_Bios__Account__c, rC_Bios__Code_Value__c 
                                          FROM rC_Bios__Preference__c 
                                          WHERE Id IN : mapPrefIDToAccountAffiliation.KeySet()]) {
              if(!setPrefIdWithExistingShareRecAff.contains(pm.Id)) {
                  rC_Bios__Preference__share affShare = new rC_Bios__Preference__share();
                  affShare.ParentId = pm.Id;
                  affShare.AccessLevel = 'Edit';
                  affShare.UserOrGroupId = mapGroupNameToId.get(pm.rC_Bios__Account__r.Affiliation__c);
                  sharesToBeInsert.add(affShare);
              }
              if(!setPrefIdWithExistingShareRecACLU.contains(pm.Id)) {
                  rC_Bios__Preference__share acluShare = new rC_Bios__Preference__share();
                  acluShare.ParentId = pm.Id;
                  acluShare.AccessLevel = 'Read';
                  acluShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
                  sharesToBeInsert.add(acluShare);
              }
              if(!setPrefIdWithExistingShareRecNational.contains(pm.Id)) {
                  rC_Bios__Preference__share natShare = new rC_Bios__Preference__share();
                  natShare.ParentId = pm.Id;
                  natShare.AccessLevel = 'Edit';
                  natShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
                  sharesToBeInsert.add(natShare);
              }
          }
  
          if(!sharesToBeInsert.IsEmpty()) {
              List<Database.saveresult> acResults = Database.insert(sharesToBeInsert,false);
                integer i = 0;
                set<String> messages; 
                apexLogHandler.apexLog log; 
                
                Boolean foundError = false;
                
                  for (Database.saveresult result : acResults) {
                    messages = new set<String>();
                    if (!result.isSuccess() && !foundError ){
                      
                      foundError = true;
                      log = new apexLogHandler.apexLog('TBD_GeoFirewallsPrefRerun','execute',
                                                   'foundError: ' + String.valueOf(sharesToBeInsert)  );
                    /*
                      for (Database.Error err : result.getErrors()){
                        if(!messages.contains(err.getMessage())) {
                          log = new apexLogHandler.apexLog('TBD_GeoFirewallsPreferenceRerun','',
                                                           'InsertSharingRecords failed::  '+ sharesToBeInsert[i].id + '\n' + err.getMessage());
                          messages.add(err.getMessage() + '/n' + err.getFields());
                        }
                      }
                     */
                    }
                    i++;
                  }
                if(log != null) {
                  log.saveLogs();
                }
          }
        }

    }
    
    global void finish(Database.BatchableContext BC) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('TBD_GeoFirewallsPreferenceRerun FINISHED' );
     log.saveLogs();
    }
}