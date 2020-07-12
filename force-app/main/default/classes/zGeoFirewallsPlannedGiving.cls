/*
*
*Name  :  zGeoFirewallsPlannedGiving
*Author:  Appirio India (Tom Burre)
*Date  :  May 22, 2017
*Purpose : Create share records for Planned Giving for one time run
*
*/
global class zGeoFirewallsPlannedGiving implements Database.Batchable<sObject>, Database.stateful {
    
    /*
ID zGeoFirewallsPlannedGiving_batchprocessid = Database.executeBatch( new zGeoFirewallsPlannedGiving( 2017-02-25T00:00:01z ), 1000 );

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
    
    
    global zGeoFirewallsPlannedGiving(String aff, Datetime ddt){
        //this.affCode = aff;
        deltaDT = ddt;
        
    }
    global zGeoFirewallsPlannedGiving(Datetime ddt){
        //this.affCode = aff;
        deltaDT = ddt;
        
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext Bc ){
        if(null<>deltaDT) {
            return Database.getQueryLocator([select id, rC_Giving__Account__r.Affiliation__c
                                             FROM rC_Giving__Planned_Giving__c
                                             WHERE
                                             
                                             
                                             CreatedDate >= :deltaDT
                                             
                                             
                                             AND rC_Giving__Account__r.Affiliation__c
                                             IN :this.affils LIMIT 9000000]);
        } else {
            
            return Database.getQueryLocator([select id, rC_Giving__Account__r.Affiliation__c
                                             FROM rC_Giving__Planned_Giving__c
                                             ]);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<rC_Giving__Planned_Giving__c > scope) {
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name IN: this.affils OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }
        List<rC_Giving__Planned_Giving__share> sharesToBeInsert = new List<rC_Giving__Planned_Giving__share>();
        for(rC_Giving__Planned_Giving__c pm:scope){
            
            rC_Giving__Planned_Giving__share affShare = new rC_Giving__Planned_Giving__share();
            affShare.ParentId = pm.Id;
            affShare.AccessLevel = 'Edit';
            affShare.UserOrGroupId = mapGroupNameToId.get(pm.rC_Giving__Account__r.Affiliation__c);
            sharesToBeInsert.add(affShare);
            
            rC_Giving__Planned_Giving__share acluShare = new rC_Giving__Planned_Giving__share();
            acluShare.ParentId = pm.Id;
            acluShare.AccessLevel = 'Read';
            acluShare.UserOrGroupId = mapGroupNameToId.get(ALLACLU);
            sharesToBeInsert.add(acluShare);
            
            rC_Giving__Planned_Giving__share natShare = new rC_Giving__Planned_Giving__share();
            natShare.ParentId = pm.Id;
            natShare.AccessLevel = 'Edit';
            natShare.UserOrGroupId = mapGroupNameToId.get(NATIONAL);
            sharesToBeInsert.add(natShare);
        }
        
        if(!sharesToBeInsert.IsEmpty()) {
            List<Database.SaveResult> acResults = Database.update(sharesToBeInsert,false);
            Utilities.processResults(acResults, sharesToBeInsert, 'zGeoFirewallsPlannedGiving', '', 'InsertSharingRecords failed::  ');
        }
        
    }
    
    global void finish(Database.BatchableContext BC) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('zGeoFirewallsPlannedGiving FINISHED' );
        log.saveLogs();
    }
}