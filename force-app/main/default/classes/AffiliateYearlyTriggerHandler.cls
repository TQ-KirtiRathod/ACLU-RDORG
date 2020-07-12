/*
*
*Name  :  AffiliateYearlyTriggerHandler
*Author:  Appirio India (Ashu Gupta)
*Date  :  October 21, 2016
*Purpose : Handler Class for AffiliateYearlyTrigger( T-549595)
*          Before insert trigger to set default values from custom setting - "National Fiscal Year" 
*
*/

public class AffiliateYearlyTriggerHandler {
     //public static boolean preventRecursion = true;
     public static void mainEntry(List<Affiliate_Yearly__c> newList, List<Affiliate_Yearly__c> oldList, Map<Id, Affiliate_Yearly__c> newMap, Map<Id, Affiliate_Yearly__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
          if(TriggerState.isActive('AffiliateYearlytrigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)){  
        //Before Events
        if(isBefore){
            if(isInsert){
                BeforeInsert(newList);     
            }
         }
         
         if(isBefore){
            if(isUpdate){
                BeforeUpdate(newList,oldMap);     
            }
         }
      }
 }

    
    
    
    
    
/*Method name : BeforeInsert
*@param : newAF
*@description : method to fetch the data from custom setting and insert in the record
*/
    private static void BeforeInsert(List<Affiliate_Yearly__c> newAF){
        //fetch all values from the custom setting named National_Fiscal_Year__c
        List<National_Fiscal_Year__c> fetchCustomFields = National_Fiscal_Year__c.getall().values();
        
        for(Affiliate_Yearly__c af : newAF){
            for(National_Fiscal_Year__c fiscalYear : fetchCustomFields){
                //if fiscal year matches,then update as per below mapping
                if(fiscalYear.Fiscal_Year__c == af.Fiscal_Year__c){
                    af.Foundation_Cost_Factor__c = fiscalYear.Foundation_Cost_Factor__c;
                    af.Union_Cost_Factor__c = fiscalYear.Union_Cost_Factor__c;
                    af.Incentive_National_Share__c = fiscalYear.Percent_GMI_Affiliates__c;
                 }
                
            }//End of inner for loop(fetchCustomFields)
        }//End of outer for loop(newAF)
        
    }// END private static void updateRecord(List<Affiliate_Yearly__c> newAF)


/*Method name : BeforeUpdate
*@param : newAF
*@description : method to fetch the data from custom setting and update in the record
*/
   private static void BeforeUpdate(List<Affiliate_Yearly__c> newAF,map<Id,Affiliate_Yearly__c> mapAffiliate){
        //fetch all values from the custom setting named National_Fiscal_Year__c
        List<National_Fiscal_Year__c> fetchCustomFields = National_Fiscal_Year__c.getall().values();
        
        for(Affiliate_Yearly__c af : newAF){
            if(af.Fiscal_Year__c != mapAffiliate.get(af.Id).Fiscal_Year__c){
                
                for(National_Fiscal_Year__c fiscalYear : fetchCustomFields){
                    //if fiscal year matches,then update as per below mapping
                    if(fiscalYear.Fiscal_Year__c == af.Fiscal_Year__c){
                        af.Foundation_Cost_Factor__c = fiscalYear.Foundation_Cost_Factor__c;
                        af.Union_Cost_Factor__c = fiscalYear.Union_Cost_Factor__c;
                        af.Incentive_National_Share__c = fiscalYear.Percent_GMI_Affiliates__c;
                     }
                    
                }//End of inner for loop(fetchCustomFields)
             }   
        }//End of outer for loop(newAF)
        
    }// END private static void updateRecord
}