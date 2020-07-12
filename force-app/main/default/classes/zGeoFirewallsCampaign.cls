/*
*
*Name  :  zGeoFirewallsCampaign
*Author:  Appirio  (Tom Burre)
*Date  :  May 22, 2017
*Purpose : Batch class to create CampaignShare records for one time run
*
*/
global class zGeoFirewallsCampaign implements Database.Batchable<sObject> {
/*
ID zGeoFirewallsCampaign_batchprocessid = Database.executeBatch( new zGeoFirewallsCampaign(), 1000 );

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


   global zGeoFirewallsCampaign(){
      //this.affCode = aff;
      

   }

   global Database.QueryLocator start(Database.BatchableContext Bc ){
       return Database.getQueryLocator([select id, Record_Sharing_Affiliate__c
                                        FROM Campaign
                                        WHERE Record_Sharing_Affiliate__c IN :this.affils LIMIT 9000000]);
   }

  global void execute(Database.BatchableContext BC, List<Campaign > scope) {
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name IN: this.affils OR Name =: ALLACLU OR Name =: NATIONAL]){
           mapGroupNameToId.put(grp.Name,grp.Id);
        }
        List<CampaignShare> sharesToBeInsert = new List<CampaignShare>();
        for(Campaign pm:scope){

                CampaignShare affShare = new CampaignShare();
                affShare.CampaignId = pm.Id;
                affShare.CampaignAccessLevel = 'Edit';
                affShare.UserOrGroupId = mapGroupNameToId.get(pm.Record_Sharing_Affiliate__c);
                sharesToBeInsert.add(affShare);

        }

        if(!sharesToBeInsert.IsEmpty()) {
            List<Database.SaveResult> acResults = Database.update(sharesToBeInsert,false);
            Utilities.processResults(acResults, sharesToBeInsert, 'zGeoFirewallsCampaign', '', 'InsertSharingRecords failed::  ');
        }

    }

    global void finish(Database.BatchableContext BC) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('zGeoFirewallsCampaign FINISHED' );
     log.saveLogs();
    }
}