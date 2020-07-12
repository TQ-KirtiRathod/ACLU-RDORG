/*
*
*Name  :  zGeoFirewallsProspectResearch
*Author:  Appirio  (Tom Burre)
*Date  :  May 22, 2017
*Purpose : Create share records for Prospect Research  for one time run
*
*/
global class zGeoFirewallsProspectResearch implements Database.Batchable<sObject> {
    
    /*
ID zGeoFirewallsProspectResearch_batchprocessid = Database.executeBatch( new zGeoFirewallsProspectResearch() );

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
    
    
    global zGeoFirewallsProspectResearch(){
        //this.affCode = aff;
        
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext Bc ){
        return Database.getQueryLocator([select id, Account__r.Affiliation__c
                                         FROM Prospect_Research__c
                                         ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Prospect_Research__c > scope) {
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name IN: this.affils OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        List<Prospect_Research__share> sharesToBeInsert = new List<Prospect_Research__share>();
        for(Prospect_Research__c pm:scope){
            
            Prospect_Research__share affShare = new Prospect_Research__share();
            affShare.ParentId = pm.Id;
            affShare.AccessLevel = 'Edit';
            affShare.UserOrGroupId = mapGroupNameToId.get(pm.Account__r.Affiliation__c);
            sharesToBeInsert.add(affShare);
            
            Prospect_Research__share acluShare = new Prospect_Research__share();
            acluShare.ParentId = pm.Id;
            acluShare.AccessLevel = 'Read';
            acluShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
            sharesToBeInsert.add(acluShare);
            
            Prospect_Research__share natShare = new Prospect_Research__share();
            natShare.ParentId = pm.Id;
            natShare.AccessLevel = 'Edit';
            natShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
            sharesToBeInsert.add(natShare);
        }
        
        if(!sharesToBeInsert.IsEmpty()) {
            List<Database.SaveResult> acResults = Database.update(sharesToBeInsert,false);
            Utilities.processResults(acResults, sharesToBeInsert, 'zGeoFirewallsProspectResearch', '', 'InsertSharingRecords failed::  ');
        }
        
    }
    
    global void finish(Database.BatchableContext BC) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('zGeoFirewallsProspectResearch FINISHED' );
        log.saveLogs();
    }
}