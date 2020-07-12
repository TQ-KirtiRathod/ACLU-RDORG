/**
 * @name trac_BupOpportunityHelper
 * @description Class to Support Helper Method 
 * @date 27 May 2020
 * @author Nchandwani, Traction on Demand
 */
public with sharing class trac_BupOpportunityHelper {
    
     /**
     * @name associateBupOpp
     * @description Method to associate BUP with the correct child opportunity
     * @date 1 June 2020
     * @author Nchandwani, Traction On Demand
     */
    public static void associateBupOpp( List<rC_Connect__Batch_Upload__c> bups, Map<Id, rC_Connect__Batch_Upload__c> oldMap ){
        if( bups != null ){
            Map<String, rC_Connect__Batch_Upload__c> bupMap = new Map<String, rC_Connect__Batch_Upload__c>();
            Set<Id> givingIds = new Set<Id>();
            for( rC_Connect__Batch_Upload__c bup : bups ){
                if( bup.rC_Connect__Batch_Upload_Giving_Matched__c != null && 
                    bup.rC_Connect__Batch_Upload_Status__c == 'Committed' ){
                    
                    givingIds.add( bup.rC_Connect__Batch_Upload_Giving_Matched__c );
                    String bupKey = bup.rC_Connect__Batch_Upload_Giving_Matched__c;
                    bupKey += String.valueOf( bup.rC_Connect__Giving_Close_Date__c );
                    bupKey += String.valueOf( bup.rC_Connect__Giving_Giving_Amount__c );
                    bupKey += bup.rC_Connect__Batch_Upload_Payment_Method_Matched__c;
                    bupMap.put( bupKey, bup );
                    
                }
            }
            List<Opportunity> opportunites = selectOpportunityByParent( givingIds );
            populateRelatedBup( bupMap, opportunites );
        }
    }


    /**
     * @name selectOpportunityByParent
     * @description Method to select opportunity by relating it with BUP
     * @date 1 June 2020
     * @author Nchandwani, Traction On Demand
     */
    private static List<Opportunity> selectOpportunityByParent( Set<Id> givingIds ){

       return [ SELECT rC_Giving__Parent__c, CloseDate, 
                rC_Giving__Payment_Method_Selected__c, Amount 
                FROM Opportunity 
                WHERE rC_Giving__Parent__c IN: givingIds AND StageName = 'Completed'];
    }

    /**
     * @name populateRelatedBup
     * @description Method to populate Related Bup on Child Opportunities
     * @date 1 June 2020
     * @author Nchandwani, Traction On Demand
     */
    private static void populateRelatedBup( Map<String, rC_Connect__Batch_Upload__c> bupMap, List<Opportunity> opportunites ){
        if( opportunites != null && bupMap != null ){
            Map<String, Opportunity> bupOppMap = getOppBupMap( opportunites );
            if( bupMap != null && !bupMap.isEmpty() ){
                for( String oppBupKey :  bupMap.keySet() ){
                    if( bupOppMap.containsKey( oppBupKey ) ){
                        populatePaymentTransac( bupMap.get( oppBupKey ), bupOppMap.get( oppBupKey ) );
                    }
                }
            }
            
        }
    }

    /**
     * @name getOppBupMap
     * @description Method to get opprtunity with bup key map
     * @date 22 May 2020
     * @author Nchandwani, Traction On Demand
     */
    private static Map<String, Opportunity> getOppBupMap( List<Opportunity> opportunities ){
        Map<String, Opportunity> bupOppMap = new Map<String, Opportunity>();
        for( Opportunity opp : opportunities){
            String oppKey = opp.rC_Giving__Parent__c;
            oppKey += String.valueOf( opp.CloseDate ) ;
            oppKey += String.valueOf( opp.Amount );
            oppKey += opp.rC_Giving__Payment_Method_Selected__c;
            bupOppMap.put( oppKey, opp );
        }
        return bupOppMap;
    }
    /**
     * @name populatePaymentTransac
     * @description Method to populate Batch_Upload_Child_Giving_Matched and Batch_Upload_Dup_Child_Giving_Matched__c
     * @date 28 May 2020
     * @author Nchandwani, Traction On Demand
     */
    private static void populatePaymentTransac( rC_Connect__Batch_Upload__c bup, Opportunity opp){
        if( bup.Batch_Upload_Child_Giving_Matched__c == null ){
            bup.Batch_Upload_Child_Giving_Matched__c = opp.Id;
        } else if( bup.Batch_Upload_Child_Giving_Matched__c != opp.Id ) {
            bup.Batch_Upload_Dup_Child_Giving_Matched__c = bup.Batch_Upload_Child_Giving_Matched__c + ';' + opp.Id;
            bup.Batch_Upload_Child_Giving_Matched__c = null;
        }
    }
}