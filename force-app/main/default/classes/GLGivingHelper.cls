/*
*
*Name  :  GLGivingHelper
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  January 31, 2017
*Purpose :  GLGivingHelper is a helper class for RevenueSharingShareCodes, Cash_Receipt_ReportsController, Batch_SummaryReportGenerations.
            Contains methods to assign GL code values on Giving records like Fund_Code_National__c, Responsibility_Center_Code_National__c.  
            Bequests have additional fields that are populated
*
*/
public class GLGivingHelper {
    
    /*
    *
    *Method nationalGLCodeAssigner
    *@param : List<Opportunity> opptyLst
    *@description : To set GL Related fields
    *
    */ 
    public static List<Opportunity> nationalGLCodeAssigner(Opportunity objOppty) { 
        Map<Id, Opportunity> mapOpps = new Map<Id, Opportunity>();
        List<Opportunity> oppsWithFundFocusResCodeAndSplited = new List<Opportunity>();
        //for(Opportunity objOppty : opptyLst) {
            
            if(objOppty.Sharing_Code__c == 'A001' || objOppty.Sharing_Code__c == 'A002' || objOppty.Sharing_Code__c == 'A003' || objOppty.Sharing_Code__c == 'B003' || 
                objOppty.Sharing_Code__c == 'C005' || objOppty.Sharing_Code__c == 'C006' || objOppty.Sharing_Code__c == 'C008' || objOppty.Sharing_Code__c == 'C009' ||
                objOppty.Sharing_Code__c == 'P001' || objOppty.Sharing_Code__c == 'P002' || objOppty.Sharing_Code__c == 'P003') {
                objOppty.GL_Code_National__c = '40000';
                objOppty.Fund_Code_National__c = '3000';
                objOppty.Focus_Area_Code_National__c = '310';
                objOppty.Responsibility_Center_Code_National__c = '13000';
                oppsWithFundFocusResCodeAndSplited.add(objOppty);
            } else if(objOppty.Sharing_Code__c == 'H100' || objOppty.Sharing_Code__c == 'E131') {
                objOppty.GL_Code_National__c = '40100';
                objOppty.Fund_Code_National__c = '3000';
                objOppty.Focus_Area_Code_National__c = '310';
                objOppty.Responsibility_Center_Code_National__c = '13000';
                oppsWithFundFocusResCodeAndSplited.add(objOppty);
            } else if(objOppty.Sharing_Code__c == 'K171' || objOppty.Sharing_Code__c == 'R131' || objOppty.Sharing_Code__c == 'R131P') {
                objOppty.GL_Code_National__c = '40100';
                objOppty.Fund_Code_National__c = '1000';
                objOppty.Focus_Area_Code_National__c = '599';
                objOppty.Responsibility_Center_Code_National__c = '13000';
                oppsWithFundFocusResCodeAndSplited.add(objOppty);
            } else if(objOppty.Sharing_Code__c == 'N111') {
                objOppty.GL_Code_National__c = '40200';
                objOppty.Fund_Code_National__c = '1000';
                objOppty.Focus_Area_Code_National__c = '599';
                objOppty.Responsibility_Center_Code_National__c = '13000';
                oppsWithFundFocusResCodeAndSplited.add(objOppty);
            } else if(objOppty.Sharing_Code__c == 'C161' || objOppty.Sharing_Code__c == 'C165' || objOppty.Sharing_Code__c == 'K161' || objOppty.Sharing_Code__c == 'K165') {
                objOppty.GL_Code_National__c = '40500';
                oppsWithFundFocusResCodeAndSplited.add(focusAreaOrRestrictionCodeMapping(objOppty, false));
            } else if(objOppty.Sharing_Code__c == 'E121' || objOppty.Sharing_Code__c == 'E141' || objOppty.Sharing_Code__c == 'E151' || objOppty.Sharing_Code__c == 'E181' || 
                objOppty.Sharing_Code__c == 'E191' || objOppty.Sharing_Code__c == 'R113' || objOppty.Sharing_Code__c == 'R121' || objOppty.Sharing_Code__c == 'R141' ||
                objOppty.Sharing_Code__c == 'R151' || objOppty.Sharing_Code__c == 'R181' || objOppty.Sharing_Code__c == 'R191' || objOppty.Sharing_Code__c == 'R192') {
                objOppty.GL_Code_National__c = '40100';
                oppsWithFundFocusResCodeAndSplited.add(focusAreaOrRestrictionCodeMapping(objOppty, false));
            } else if(objOppty.Sharing_Code__c == 'N175') {
                objOppty.GL_Code_National__c = '41000';
                oppsWithFundFocusResCodeAndSplited.add(focusAreaOrRestrictionCodeMapping(objOppty, false));
            } else if(objOppty.Sharing_Code__c == 'Q001' || objOppty.Sharing_Code__c == 'Q002' || objOppty.Sharing_Code__c == 'Q003' || objOppty.Sharing_Code__c == 'Q004' || 
                objOppty.Sharing_Code__c == 'Q005' || objOppty.Sharing_Code__c == 'U001' || objOppty.Sharing_Code__c == 'U002' || objOppty.Sharing_Code__c == 'U003' ||
                objOppty.Sharing_Code__c == 'U004' || objOppty.Sharing_Code__c == 'U005') {
                oppsWithFundFocusResCodeAndSplited.addAll(bequestMapping(objOppty));
            } else if(objOppty.Sharing_Code__c == 'C171' || objOppty.Sharing_Code__c == 'D009' || objOppty.Sharing_Code__c == 'D010' || objOppty.Sharing_Code__c == 'D011' || 
                objOppty.Sharing_Code__c == 'D012' || objOppty.Sharing_Code__c == 'E013' || objOppty.Sharing_Code__c == 'E015' || objOppty.Sharing_Code__c == 'E016' ||
                objOppty.Sharing_Code__c == 'E017' || objOppty.Sharing_Code__c == 'U005') {
                objOppty.GL_Code_National__c = '40000';
                objOppty.Fund_Code_National__c = '3000';
                objOppty.Focus_Area_Code_National__c = '310';
                objOppty.Responsibility_Center_Code_National__c = '13000';
                oppsWithFundFocusResCodeAndSplited.add(objOppty);
            }
            
            return oppsWithFundFocusResCodeAndSplited; 
        //}
    }
    
    private static Opportunity focusAreaOrRestrictionCodeMapping(Opportunity objOppty, Boolean isBequest) {
        if(objOppty.Program_Type__c == '1' || objOppty.Program_Type__c == '2') {
            if(objOppty.Restriction__c != null && (String.ValueOf(objOppty.Restriction__c).contains(Label.Undefined_UNDEFINED) || String.ValueOf(objOppty.Restriction__c).contains(Label.Bill_of_Rights_Action_Fund_U_Major_Donors_300_BRAF))) {
                objOppty.Focus_Area_Code_National__c = '310';
                if(!isBequest){ 
                    objOppty.Fund_Code_National__c = '3000';
                    objOppty.Responsibility_Center_Code_National__c = '13000';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Unshared_No_Restriction_UNSHAREDNORESTRICT)) {
                objOppty.Focus_Area_Code_National__c = '310';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Church_State_Work_c3_160_or_c4_303_CHST)) {
                objOppty.Focus_Area_Code_National__c = '303';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Racial_Justice_Project_c4_304_RJP_C4_NATIONAL)) {
                objOppty.Focus_Area_Code_National__c = '';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && (String.ValueOf(objOppty.Restriction__c).contains(Label.LGBT_Rights_Project_c3_110_or_c4_306_LGBT) || String.ValueOf(objOppty.Restriction__c).contains(Label.LGBT_Transgender_Rights_Work_c3_110_or_c4_306_LGBTTRANS) || String.ValueOf(objOppty.Restriction__c).contains(Label.LGBT_Rights_National_Restriction_Unrestrcted_Affil_c3_110_or_c4_306_LGBTN))) {
                objOppty.Focus_Area_Code_National__c = '306';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Immigrants_Rights_Project_c3_115_or_c4_307_IRP)) {
                objOppty.Focus_Area_Code_National__c = '307';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Speech_Privacy_and_Technology_c3_170_or_c4_308_SPCHTECH)) {
                objOppty.Focus_Area_Code_National__c = '308';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Human_Rights_Project_c4_311_HRP)) {
                objOppty.Focus_Area_Code_National__c = '311';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Voting_Rights_Project_c4_National_312_VOTRGC4)) {
                objOppty.Focus_Area_Code_National__c = '312';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Out_For_Freedom_Campaign_c4_LGBT_313_OFFLGBTC4)) {
                objOppty.Focus_Area_Code_National__c = '313';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Reproductive_Freedom_ARNOLD_Advocacy_Fund_315_RFP_ARNOLD)) {
                objOppty.Focus_Area_Code_National__c = '315';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Immigration_SB1070_War_Chest_c3_116_or_c4_316_SB1070)) {
                objOppty.Focus_Area_Code_National__c = '316';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Prison_Project_Mass_Incarceration_c4_318_PRISMIC4)) {
                objOppty.Focus_Area_Code_National__c = '318';
                 if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                 }
            } else if(objOppty.Restriction__c != null && (String.ValueOf(objOppty.Restriction__c).contains(Label.Criminal_Law_Reform_Project_c3_135_or_c4_335_CLRM) || String.ValueOf(objOppty.Restriction__c).contains(Label.Drug_Policy_Reform_DPF))) {
                objOppty.Focus_Area_Code_National__c = '335';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Center_for_Justice_c3_139_or_c4_339_CNTRJUS)) {
                objOppty.Focus_Area_Code_National__c = '339';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Karpatkin_Fellow_425_KARP)) {
                objOppty.Focus_Area_Code_National__c = '425';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Second_Amendment_C4_319_2NDAMENDC4)) {
                objOppty.Focus_Area_Code_National__c = '319';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '3001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            }
        } else if(objOppty.Program_Type__c == '4') {
            if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Undefined_UNDEFINED)) {
                objOppty.Focus_Area_Code_National__c = '599';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1000';
                    objOppty.Responsibility_Center_Code_National__c = '13000';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Unshared_No_Restriction_UNSHAREDNORESTRICT)) {
                objOppty.Focus_Area_Code_National__c = '599';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Capital_Punishment_Project_100_CAPPU)) {
                objOppty.Focus_Area_Code_National__c = '100';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.National_Prison_Project_105_PRIS)) {
                objOppty.Focus_Area_Code_National__c = '105';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && (String.ValueOf(objOppty.Restriction__c).contains(Label.LGBT_Rights_Project_c3_110_or_c4_306_LGBT) || String.ValueOf(objOppty.Restriction__c).contains(Label.LGBT_Transgender_Rights_Work_c3_110_or_c4_306_LGBTTRANS) || String.ValueOf(objOppty.Restriction__c).contains(Label.LGBT_Rights_National_Restriction_Unrestrcted_Affil_c3_110_or_c4_306_LGBTN))) {
                objOppty.Focus_Area_Code_National__c = '110';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Out_For_Freedom_Campaign_c3_LGBT_111_OFFLGBTC3)) {
                objOppty.Focus_Area_Code_National__c = '111';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';                
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Henry_Haley_Trust_LGBT_112_HALEY)) {
                objOppty.Focus_Area_Code_National__c = '112';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Immigrants_Rights_Project_c3_115_or_c4_307_IRP)) {
                objOppty.Focus_Area_Code_National__c = '115';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Immigration_SB1070_War_Chest_c3_116_or_c4_316_SB1070)) {
                objOppty.Focus_Area_Code_National__c = '116';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Disability_Rights_c3_117_DISABLE)) {
                objOppty.Focus_Area_Code_National__c = '117';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Center_for_Democracy_c3_119_CNTRDEM)) {
                objOppty.Focus_Area_Code_National__c = '119';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Reproductive_Freedom_Project_120_RFP)) {
                objOppty.Focus_Area_Code_National__c = '120';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Women_s_Rights_Project_125_WOMR)) {
                objOppty.Focus_Area_Code_National__c = '125';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Center_for_Equality_c3_129_CNTREQU)) {
                objOppty.Focus_Area_Code_National__c = '129';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Voting_Rights_Project_130_VOTRG)) {
                objOppty.Focus_Area_Code_National__c = '130';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && (String.ValueOf(objOppty.Restriction__c).contains(Label.Criminal_Law_Reform_Project_c3_135_or_c4_335_CLRM) || String.ValueOf(objOppty.Restriction__c).contains(Label.Drug_Policy_Reform_DPF))) {
                objOppty.Focus_Area_Code_National__c = '135';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Center_for_Justice_c3_139_or_c4_339_CNTRJUS)) {
                objOppty.Focus_Area_Code_National__c = '139';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Racial_Justice_Project_140_RJP)) {
                objOppty.Focus_Area_Code_National__c = '140';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.National_Security_Project_145_NSP)) {
                objOppty.Focus_Area_Code_National__c = '145';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Molly_Ivins_Memorial_Fund_Unrestricted_148_IVINS)) {
                objOppty.Focus_Area_Code_National__c = '148';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Center_for_Liberty_c3_149_CNTRLIB)) {
                objOppty.Focus_Area_Code_National__c = '149';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Internationl_Human_Rights_150_IHR)) {
                objOppty.Focus_Area_Code_National__c = '150';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Church_State_Work_c3_160_or_c4_303_CHST)) {
                objOppty.Focus_Area_Code_National__c = '160';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Speech_Privacy_and_Technology_c3_170_or_c4_308_SPCHTECH)) {
                objOppty.Focus_Area_Code_National__c = '170';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Legal_Department_c3_199_LEGAL)) {
                objOppty.Focus_Area_Code_National__c = '199';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Karpatkin_Fellow_425_KARP)) {
                objOppty.Focus_Area_Code_National__c = '425';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Strategic_Affiliate_Initiative_500_SAI)) {
                objOppty.Focus_Area_Code_National__c = '500';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.General_Campaign_Leading_Freedom_Forward_505_GENCLFF)) {
                objOppty.Focus_Area_Code_National__c = '505';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            } else if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Second_Amendment_C3_156_2NDAMENDC3)) {
                objOppty.Focus_Area_Code_National__c = '156';
                if(!isBequest){
                    objOppty.Fund_Code_National__c = '1001';
                    objOppty.Responsibility_Center_Code_National__c = 'ZZZZZ';
                }
            }
        }
        return objOppty;
    }
    /*
    *
    *Method bequestMapping
    *@param : Opportunity objOppty
    *@description : To set GL Related fields for bequest records
    *
    */ 
    private static List<Opportunity> bequestMapping(Opportunity objOppty) {
        List<Opportunity> splitOpportunities = new List<Opportunity>();
        if(objOppty.Sharing_Code__c == 'Q001' ){
            if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Undefined_UNDEFINED)){
                //80 % of gift.
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = (objOppty.amount*0.8);
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '1000';
                opp.Focus_Area_Code_National__c = '599';
                opp.Responsibility_Center_Code_National__c = '13000';
                splitOpportunities.add(opp);
                // 20 % of gift
                Opportunity opp1 = new Opportunity();
                opp1.Program_Type__c = objOppty.Program_Type__c;
                opp1.Restriction__c = objOppty.Restriction__c;
                opp1.Bank_Date__c = objOppty.Bank_Date__c;
                opp1.amount = (objOppty.amount*0.2);
                opp1.GL_Code_National__c = '40300';
                opp1.Fund_Code_National__c = '1025';
                opp1.Focus_Area_Code_National__c = '999';
                opp1.Responsibility_Center_Code_National__c = 'ZZZZZ';
                splitOpportunities.add(opp1);
            }
            else{
                //80 % of gift.
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.amount = (objOppty.amount*0.8);
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '1001';
                opp.Responsibility_Center_Code_National__c = 'ZZZZZ';
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                splitOpportunities.add(focusAreaOrRestrictionCodeMapping(opp, true));
                // 20 % of gift
                Opportunity opp1 = new Opportunity();
                opp1.Program_Type__c = objOppty.Program_Type__c;
                opp1.Restriction__c = objOppty.Restriction__c;
                opp1.Bank_Date__c = objOppty.Bank_Date__c;
                opp1.amount = (objOppty.amount*0.2);
                opp1.GL_Code_National__c = '40300';
                opp1.Fund_Code_National__c = '1025';
                opp1.Focus_Area_Code_National__c = '999';
                opp1.Responsibility_Center_Code_National__c = 'ZZZZZ';
                splitOpportunities.add(opp1);
            }
            
        }
        else if (objOppty.Sharing_Code__c == 'Q002'){
            if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Undefined_UNDEFINED)){
                //87.5 % of gift.
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = (objOppty.amount*0.875);
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '1000';
                opp.Focus_Area_Code_National__c = '599';
                opp.Responsibility_Center_Code_National__c = '13000';
                splitOpportunities.add(opp);
                // 12.5 % of gift
                Opportunity opp1 = new Opportunity();
                opp1.Program_Type__c = objOppty.Program_Type__c;
                opp1.Restriction__c = objOppty.Restriction__c;
                opp1.Bank_Date__c = objOppty.Bank_Date__c;
                opp1.amount = (objOppty.amount*0.125);
                opp1.GL_Code_National__c = '40300';
                opp1.Fund_Code_National__c = '1025';
                opp1.Focus_Area_Code_National__c = '999';
                opp1.Responsibility_Center_Code_National__c = 'ZZZZZ';
                splitOpportunities.add(opp1);
            }
            else {
                //87.5 % of gift.
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = (objOppty.amount*0.875);
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '1001';
                opp.Responsibility_Center_Code_National__c = 'ZZZZZ';
                splitOpportunities.add(focusAreaOrRestrictionCodeMapping(opp, true));
                // 12.5 % of gift
                Opportunity opp1 = new Opportunity();
                opp1.Program_Type__c = objOppty.Program_Type__c;
                opp1.Restriction__c = objOppty.Restriction__c;
                opp1.Bank_Date__c = objOppty.Bank_Date__c;
                opp1.amount = (objOppty.amount*0.125);
                opp1.GL_Code_National__c = '40300';
                opp1.Fund_Code_National__c = '1025';
                opp1.Focus_Area_Code_National__c = '999';
                opp1.Responsibility_Center_Code_National__c = 'ZZZZZ';
                splitOpportunities.add(opp1);
            }
        }
        
        else if (objOppty.Sharing_Code__c == 'Q003'){
            if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Undefined_UNDEFINED)){
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = objOppty.amount;
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '1000';
                opp.Focus_Area_Code_National__c = '599';
                opp.Responsibility_Center_Code_National__c = '13000';
                splitOpportunities.add(opp);
            }
            else{
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = objOppty.amount;
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '1001';
                opp.Responsibility_Center_Code_National__c = 'ZZZZZ';
                splitOpportunities.add(focusAreaOrRestrictionCodeMapping(opp, true));
            }
        }
        
        else if (objOppty.Sharing_Code__c == 'Q004'){
            if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Undefined_UNDEFINED)){
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = objOppty.amount;
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '1000';
                opp.Focus_Area_Code_National__c = '599';
                opp.Responsibility_Center_Code_National__c = '13000';
                splitOpportunities.add(opp);
            }
            else{
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = objOppty.amount;
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '1001';
                opp.Responsibility_Center_Code_National__c = 'ZZZZZ';
                splitOpportunities.add(focusAreaOrRestrictionCodeMapping(opp, true));
            }
        }
        
        else if (objOppty.Sharing_Code__c == 'Q005'){
            if(objOppty.Restriction__c != null && String.ValueOf(objOppty.Restriction__c).contains(Label.Undefined_UNDEFINED)){
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = objOppty.amount;
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '1000';
                opp.Focus_Area_Code_National__c = '599';
                opp.Responsibility_Center_Code_National__c = '13000';
                splitOpportunities.add(opp);
            }
            else{
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = objOppty.amount;
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '1001';
                opp.Responsibility_Center_Code_National__c = 'ZZZZZ';
                splitOpportunities.add(focusAreaOrRestrictionCodeMapping(opp, true));
            }
        }
        
        else if(objOppty.Sharing_Code__c == 'U001' ){
            //80 % of gift.
            Opportunity opp = new Opportunity();
            opp.Program_Type__c = objOppty.Program_Type__c;
            opp.Restriction__c = objOppty.Restriction__c;
            opp.Bank_Date__c = objOppty.Bank_Date__c;
            opp.amount = (objOppty.amount*0.8);
            opp.GL_Code_National__c = '40300';
            opp.Fund_Code_National__c = '3000';
            opp.Focus_Area_Code_National__c = '310';
            opp.Responsibility_Center_Code_National__c = '13000';
            splitOpportunities.add(opp);
            // 20 % of gift
            Opportunity opp1 = new Opportunity();
            opp1.Program_Type__c = objOppty.Program_Type__c;
            opp1.Restriction__c = objOppty.Restriction__c;
            opp1.Bank_Date__c = objOppty.Bank_Date__c;
            opp1.amount = (objOppty.amount*0.2);
            opp1.GL_Code_National__c = '40300';
            opp1.Fund_Code_National__c = '3025';
            opp1.Focus_Area_Code_National__c = '999';
            opp1.Responsibility_Center_Code_National__c = 'ZZZZZ';
            splitOpportunities.add(opp1);
            
        }
        
        else if(objOppty.Sharing_Code__c == 'U002' ){
            //87.5 % of gift.
            Opportunity opp = new Opportunity();
            opp.Program_Type__c = objOppty.Program_Type__c;
            opp.Restriction__c = objOppty.Restriction__c;
            opp.Bank_Date__c = objOppty.Bank_Date__c;
            opp.amount = (objOppty.amount*0.875);
            opp.GL_Code_National__c = '40300';
            opp.Fund_Code_National__c = '3000';
            opp.Focus_Area_Code_National__c = '310';
            opp.Responsibility_Center_Code_National__c = '13000';
            opp.Bank_Date__c = objOppty.Bank_Date__c;
            splitOpportunities.add(opp);
            // 12.5 % of gift
            Opportunity opp1 = new Opportunity();
            opp1.Program_Type__c = objOppty.Program_Type__c;
            opp1.Restriction__c = objOppty.Restriction__c;
            opp1.Bank_Date__c = objOppty.Bank_Date__c;
            opp1.amount = (objOppty.amount*0.125);
            opp1.GL_Code_National__c = '40300';
            opp1.Fund_Code_National__c = '3025';
            opp1.Focus_Area_Code_National__c = '999';
            opp1.Responsibility_Center_Code_National__c = 'ZZZZZ';
            splitOpportunities.add(opp1);
            
        }
        
        else if(objOppty.Sharing_Code__c == 'U003'){
            if(objOppty.Restriction__c != null && (String.ValueOf(objOppty.Restriction__c).contains(Label.Undefined_UNDEFINED) || String.ValueOf(objOppty.Restriction__c).contains(Label.Bill_of_Rights_Action_Fund_U_Major_Donors_300_BRAF))) {
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = objOppty.amount;
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '3000';
                opp.Focus_Area_Code_National__c = '310';
                opp.Responsibility_Center_Code_National__c = '13000';
                splitOpportunities.add(opp);
            }
            else if(objOppty.Restriction__c != null && (!String.ValueOf(objOppty.Restriction__c).contains(Label.Undefined_UNDEFINED) && !String.ValueOf(objOppty.Restriction__c).contains(Label.Bill_of_Rights_Action_Fund_U_Major_Donors_300_BRAF))){
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = objOppty.amount;
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '3001';
                opp.Responsibility_Center_Code_National__c = 'ZZZZZ';
                splitOpportunities.add(focusAreaOrRestrictionCodeMapping(opp, true));
            }
        }
        
        else if(objOppty.Sharing_Code__c == 'U004'){
            if(objOppty.Restriction__c != null && (String.ValueOf(objOppty.Restriction__c).contains(Label.Undefined_UNDEFINED) || String.ValueOf(objOppty.Restriction__c).contains(Label.Bill_of_Rights_Action_Fund_U_Major_Donors_300_BRAF))) {
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = objOppty.amount;
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '3000';
                opp.Focus_Area_Code_National__c = '310';
                opp.Responsibility_Center_Code_National__c = '13000';
                splitOpportunities.add(opp);
            }
            else if(objOppty.Restriction__c != null && (!String.ValueOf(objOppty.Restriction__c).contains(Label.Undefined_UNDEFINED) && !String.ValueOf(objOppty.Restriction__c).contains(Label.Bill_of_Rights_Action_Fund_U_Major_Donors_300_BRAF))){
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = objOppty.amount;
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '3001';
                opp.Responsibility_Center_Code_National__c = 'ZZZZZ';
                splitOpportunities.add(focusAreaOrRestrictionCodeMapping(opp, true));
            }
        }
        
        else if(objOppty.Sharing_Code__c == 'U005'){
            if(objOppty.Restriction__c != null && (String.ValueOf(objOppty.Restriction__c).contains(Label.Undefined_UNDEFINED) || String.ValueOf(objOppty.Restriction__c).contains(Label.Bill_of_Rights_Action_Fund_U_Major_Donors_300_BRAF))) {
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = objOppty.amount;
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '3000';
                opp.Focus_Area_Code_National__c = '310';
                opp.Responsibility_Center_Code_National__c = '13000';
                splitOpportunities.add(opp);
            }
            else if(objOppty.Restriction__c != null && (!String.ValueOf(objOppty.Restriction__c).contains(Label.Undefined_UNDEFINED) && !String.ValueOf(objOppty.Restriction__c).contains(Label.Bill_of_Rights_Action_Fund_U_Major_Donors_300_BRAF))){
                Opportunity opp = new Opportunity();
                opp.Program_Type__c = objOppty.Program_Type__c;
                opp.Restriction__c = objOppty.Restriction__c;
                opp.Bank_Date__c = objOppty.Bank_Date__c;
                opp.amount = objOppty.amount;
                opp.GL_Code_National__c = '40300';
                opp.Fund_Code_National__c = '3001';
                opp.Responsibility_Center_Code_National__c = 'ZZZZZ';
                splitOpportunities.add(focusAreaOrRestrictionCodeMapping(opp, true));
            }
        }
        
        return splitOpportunities;
    }
}