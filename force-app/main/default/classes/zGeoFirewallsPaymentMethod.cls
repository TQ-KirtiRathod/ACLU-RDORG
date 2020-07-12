/*
*
*Name  :  zGeoFirewallsPaymentMethod
*Author:  Appirio India (Tom Burre)
*Date  :  May 22, 2017
*Purpose : Create share records for Payment Method for one time run
*
*/
global class zGeoFirewallsPaymentMethod implements Database.Batchable<sObject> {

/*
ID batchprocessid = Database.executeBatch( new zGeoFirewallsPaymentMethod(), 2000 );

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

  public static Datetime deltaDT;


   global zGeoFirewallsPaymentMethod(String aff, Datetime ddt){
      //this.affCode = aff;
      deltaDT = ddt;

   }
   global zGeoFirewallsPaymentMethod(Datetime ddt){
      //this.affCode = aff;
      deltaDT = ddt;
      

   }

   global Database.QueryLocator start(Database.BatchableContext Bc ){
      if(null<>deltaDT) {
        return Database.getQueryLocator([select id, rC_Giving__Account__r.Affiliation__c
                                        FROM rC_Giving__Payment_Method__c
                                        WHERE CreatedDate >= :deltaDT
                                        LIMIT 20000000]);
      } else {
        return Database.getQueryLocator([select id, rC_Giving__Account__r.Affiliation__c
                                        FROM rC_Giving__Payment_Method__c
                                        ]);
      }
   }

  global void execute(Database.BatchableContext BC, List<rC_Giving__Payment_Method__c> scope) {
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name IN: this.affils OR Name =: ALLACLU OR Name =: NATIONAL]){
             mapGroupNameToId.put(grp.Name,grp.Id);
        }
        List<rC_Giving__Payment_Method__share> PaymentMSharesToBeInsert = new List<rC_Giving__Payment_Method__share>();

        for(rC_Giving__Payment_Method__c pm:scope){
            if(pm.rC_Giving__Account__r.Affiliation__c != null && affils.contains(pm.rC_Giving__Account__r.Affiliation__c)){
            rC_Giving__Payment_Method__share affShare = new rC_Giving__Payment_Method__share();
            affShare.ParentId = pm.Id;
            affShare.AccessLevel = 'Edit';
            affShare.UserOrGroupId = mapGroupNameToId.get(pm.rC_Giving__Account__r.Affiliation__c);
            PaymentMSharesToBeInsert.add(affShare);

            rC_Giving__Payment_Method__share acluShare = new rC_Giving__Payment_Method__share();
            acluShare.ParentId = pm.Id;
            acluShare.AccessLevel = 'Read';
            acluShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
            PaymentMSharesToBeInsert.add(acluShare);

            rC_Giving__Payment_Method__share natShare = new rC_Giving__Payment_Method__share();
            natShare.ParentId = pm.Id;
            natShare.AccessLevel = 'Edit';
            natShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
            PaymentMSharesToBeInsert.add(natShare);
            }
        }

        if(!PaymentMSharesToBeInsert.IsEmpty()) {
            List<Database.SaveResult> acResults = Database.insert(PaymentMSharesToBeInsert,false);
            Utilities.processResults(acResults, PaymentMSharesToBeInsert, 'zGeoFirewallsPaymentMethod', '', 'InsertSharingRecords failed::  ');
        }

  }

  global void finish(Database.BatchableContext BC) {
    apexLogHandler.apexLog log = new apexLogHandler.apexLog('zGeoFirewallsPaymentMethod FINISHED' );
     log.saveLogs();
  }

}