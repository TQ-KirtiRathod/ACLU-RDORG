/*
*
*Name  :  zGeoFirewallsConfidentialData
*Author:  Appirio  (Tom Burre)
*Date  :  May 22, 2017
*Purpose : Create share records for Confidential Data  for one time run
*
*/
global class zGeoFirewallsConfidentialData implements Database.Batchable<sObject> {

/*
ID zGeoFirewallsConfidentialData_batchprocessid = Database.executeBatch( new zGeoFirewallsConfidentialData() );

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


   global zGeoFirewallsConfidentialData(){
      //this.affCode = aff;
      

   }

   global Database.QueryLocator start(Database.BatchableContext Bc ){
       return Database.getQueryLocator([select id, Account__r.Affiliation__c
                                        FROM Confidential_Data__c
                                        ]);
   }

  global void execute(Database.BatchableContext BC, List<Confidential_Data__c > scope) {
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name IN: this.affils OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        List<Confidential_Data__share> sharesToBeInsert = new List<Confidential_Data__share>();
        for(Confidential_Data__c pm:scope){

                Confidential_Data__share affShare = new Confidential_Data__share();
                affShare.ParentId = pm.Id;
                affShare.AccessLevel = 'Edit';
                affShare.UserOrGroupId = mapGroupNameToId.get(pm.Account__r.Affiliation__c);
                sharesToBeInsert.add(affShare);

                Confidential_Data__share acluShare = new Confidential_Data__share();
                acluShare.ParentId = pm.Id;
                acluShare.AccessLevel = 'Read';
                acluShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
                sharesToBeInsert.add(acluShare);

                Confidential_Data__share natShare = new Confidential_Data__share();
                natShare.ParentId = pm.Id;
                natShare.AccessLevel = 'Edit';
                natShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
                sharesToBeInsert.add(natShare);
        }

        if(!sharesToBeInsert.IsEmpty()) {
            List<Database.SaveResult> acResults = Database.update(sharesToBeInsert,false);
            Utilities.processResults(acResults, sharesToBeInsert, 'zGeoFirewallsConfidentialData', '', 'InsertSharingRecords failed::  ');
        }

    }

    global void finish(Database.BatchableContext BC) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('zGeoFirewallsConfidentialData FINISHED' );
     log.saveLogs();
    }
}