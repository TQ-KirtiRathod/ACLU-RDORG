/*
*
*Name  :  zGeoFirewallsPreference
*Author:  Appirio (Tom Burre)
*Date  :  Dec 05, 2017
*Purpose : Create share records for Preference for one time run
*
*/
global class zGeoFirewallsPreference implements Database.Batchable<sObject> {

/*
ID zGeoFirewallsPreference_batchprocessid = Database.executeBatch( new zGeoFirewallsPreference() );

*/
    //public String affCode = '';
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
'NAA',
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


   global zGeoFirewallsPreference(String aff){
      //this.affCode = aff;

   }
   global zGeoFirewallsPreference(){
      //this.affCode = aff;
      

   }

   global Database.QueryLocator start(Database.BatchableContext Bc ){
       return Database.getQueryLocator([select id, rC_Bios__Account__r.Affiliation__c
                                        FROM rC_Bios__Preference__c
                                        ]);
   }

  global void execute(Database.BatchableContext BC, List<rC_Bios__Preference__c > scope) {
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name IN: this.affils OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        List<rC_Bios__Preference__share> sharesToBeInsert = new List<rC_Bios__Preference__share>();
        for(rC_Bios__Preference__c pm:scope){

                rC_Bios__Preference__share affShare = new rC_Bios__Preference__share();
                affShare.ParentId = pm.Id;
                affShare.AccessLevel = 'Edit';
                affShare.UserOrGroupId = mapGroupNameToId.get(pm.rC_Bios__Account__r.Affiliation__c);
                sharesToBeInsert.add(affShare);

                rC_Bios__Preference__share acluShare = new rC_Bios__Preference__share();
                acluShare.ParentId = pm.Id;
                acluShare.AccessLevel = 'Read';
                acluShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
                sharesToBeInsert.add(acluShare);

                rC_Bios__Preference__share natShare = new rC_Bios__Preference__share();
                natShare.ParentId = pm.Id;
                natShare.AccessLevel = 'Edit';
                natShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
                sharesToBeInsert.add(natShare);
        }

        if(!sharesToBeInsert.IsEmpty()) {
            List<Database.SaveResult> acResults = Database.insert(sharesToBeInsert,false);
            Utilities.processResults(acResults, sharesToBeInsert, 'zGeoFirewallsPreference', '', 'InsertSharingRecords failed::  ');
        }

    }

    global void finish(Database.BatchableContext BC) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('zGeoFirewallsPreference FINISHED' );
     log.saveLogs();
    }
}