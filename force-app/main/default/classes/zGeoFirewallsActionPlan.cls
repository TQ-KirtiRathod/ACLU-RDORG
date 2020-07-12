/*
*
*Name  :  zGeoFirewallsActionPlan
*Author:  Appirio (Tom Burre)
*Date  :  May 22, 2017
*Purpose : Batch Class to create Action Plan share records for one time use
*
*/
global class zGeoFirewallsActionPlan implements Database.Batchable<sObject> {
/*
ID zGeoFirewallsActionPlan_batchprocessid = Database.executeBatch( new zGeoFirewallsActionPlan() );

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
'KY',
'LA',
'MA',
'MD',
'ME',
'MI',
'MN',
'MS',
'MT',
'NC',
'ND',
'NE',
'NH',
'NJ',
'NM',
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
'WM',
'WV',
'WY',
'ZF',
'NAA',
'NN',
'NNA'
	};
	public static final String ALLACLU = Label.All_ACLU;
  public static final String NATIONAL = Label.National;
  public static Map<String,Id> mapGroupNameToId = new Map<String,Id>();


   global zGeoFirewallsActionPlan(){
      //this.affCode = aff;
      

   }

   global Database.QueryLocator start(Database.BatchableContext Bc ){
       return Database.getQueryLocator([select id, rC_Bios__Account__r.Affiliation__c
                                        FROM rC_Bios__Action_Plan__c
                                        WHERE rC_Bios__Account__r.Affiliation__c
                                        IN :this.affils LIMIT 9000000]);
   }

  global void execute(Database.BatchableContext BC, List<rC_Bios__Action_Plan__c > scope) {
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name IN: this.affils OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
          }
  	    /*List<rC_Bios__Action_Plan__share> sharesToBeInsert = new List<rC_Bios__Action_Plan__share>();
        for(rC_Bios__Action_Plan__c pm:scope){

	        	rC_Bios__Action_Plan__share affShare = new rC_Bios__Action_Plan__share();
	        	affShare.ParentId = pm.Id;
	        	affShare.AccessLevel = 'Edit';
	        	affShare.UserOrGroupId = mapGroupNameToId.get(pm.rC_Bios__Account__r.Affiliation__c);
        		sharesToBeInsert.add(affShare);

        		rC_Bios__Action_Plan__share acluShare = new rC_Bios__Action_Plan__share();
	        	acluShare.ParentId = pm.Id;
	        	acluShare.AccessLevel = 'Read';
	        	acluShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
        		sharesToBeInsert.add(acluShare);

        		rC_Bios__Action_Plan__share natShare = new rC_Bios__Action_Plan__share();
	        	natShare.ParentId = pm.Id;
	        	natShare.AccessLevel = 'Edit';
	        	natShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
        		sharesToBeInsert.add(natShare);
        }

        if(!sharesToBeInsert.IsEmpty()) {
            try{
        	    insert sharesToBeInsert;
            } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('zGeoFirewallsActionPlan','InsertSharingRecords',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
        }*/

	}

	global void finish(Database.BatchableContext BC) {
		apexLogHandler.apexLog log = new apexLogHandler.apexLog('zGeoFirewallsActionPlan FINISHED' );
     log.saveLogs();
	}
}