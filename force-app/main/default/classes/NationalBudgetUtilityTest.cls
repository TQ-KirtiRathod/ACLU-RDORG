/**
 *Test class for NationalBudgetUtility
 **/
@isTest
private class NationalBudgetUtilityTest {
    
    private static List<National_Budget__c> nbList = new List<National_Budget__c>();
    private static Account acc = new Account();
    private static Opportunity opp = new Opportunity();
    private static List<Opportunity> oppList = new List<Opportunity>();
    
    @TestSetup
    private static void createTestData(){
          acc = testUtils.createAccount('test', true);
    }
    @isTest
    private static void testNbu(){
        acc = [SELECT ID FROM Account LIMIT 1];
        
        //Test data creation
        for(Integer i=0; i<4; i++){
            National_Budget__c nb = new National_Budget__c();
            nb.Name = 'test'+i;
            nbList.add(nb);
        }
        insert nbList;
        
        for(Integer i=0; i<22; i++){
            Opportunity opp1 = testUtils.createOpportunity(acc.id, 'op'+i, false);
            oppList.add(opp1);
        }
        insert oppList;
        
        
        //Update data to fulfill the criteria
        oppList[0].Sharing_Code__c = 'E181';
        oppList[1].Sharing_Code__c = null ;
        oppList[1].Fundraising_Department__c = 'Foundation Relations';
        oppList[2].Sharing_Code__c = null ;
        oppList[2].Fundraising_Department__c = 'Leadership Gifts';
        oppList[3].Sharing_Code__c = null ;
        oppList[3].Fundraising_Department__c = 'Membership';
        oppList[4].Sharing_Code__c = null ;
        oppList[4].Fundraising_Department__c = 'Planned Giving';
        oppList[5].Fundraising_Department__c = 'Special Gifts';
        oppList[5].Sharing_Code__c = null ;
        oppList[6].Fundraising_Department__c = 'Special Gifts';
        oppList[6].Sharing_Code__c = 'T400';
        oppList[6].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[6].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[6].Fund__c = 'CHST';
        oppList[7].Fundraising_Department__c = 'Special Gifts';
        oppList[7].Sharing_Code__c = 'T400';
        oppList[7].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[7].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[7].Fund__c = 'LGRP';
        oppList[8].Fundraising_Department__c = 'Special Gifts';
        oppList[8].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[8].Fund__c = 'LGRP';
        oppList[8].Deposit_Site__c = null;
        oppList[8].Sharing_Code__c = 'Q001';
        oppList[9].Fundraising_Department__c = 'Special Gifts';
        oppList[9].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[9].Fund__c = 'LGRP';
        oppList[9].Deposit_Site__c = null;
        oppList[9].Sharing_Code__c = 'Q002';
        oppList[10].Fundraising_Department__c = 'Special Gifts';
        oppList[10].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[10].Fund__c = 'LGRP';
        oppList[10].Deposit_Site__c = null;
        oppList[10].Sharing_Code__c = 'Q003';
        oppList[11].Fundraising_Department__c = 'Special Gifts';
        oppList[11].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[11].Fund__c = 'LGRP';
        oppList[11].Deposit_Site__c = null;
        oppList[11].Sharing_Code__c = 'Q004';
        oppList[12].Fundraising_Department__c = 'Special Gifts';
        oppList[12].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[12].Deposit_Site__c = null;
        oppList[12].Sharing_Code__c = 'K161';
        oppList[12].Fund__c = 'RFP';
        oppList[13].Fundraising_Department__c = 'Special Gifts';
        oppList[13].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[13].Fund__c = 'LGRP';
        oppList[13].Deposit_Site__c = null;
        oppList[13].Sharing_Code__c = 'R191';
        oppList[14].Fundraising_Department__c = 'Special Gifts';
        oppList[14].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[14].Fund__c = 'LGRP';
        oppList[14].Deposit_Site__c = null;
        oppList[14].Sharing_Code__c = 'K165';
        oppList[15].Fundraising_Department__c = 'Special Gifts';
        oppList[15].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[15].Deposit_Site__c = null;
        oppList[15].Sharing_Code__c = 'R113';
        oppList[15].Fund__c = 'RJP';
        oppList[16].Fundraising_Department__c = 'Special Gifts';
        oppList[16].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[16].Fund__c = 'LGRP';
        oppList[16].Deposit_Site__c = null;
        oppList[16].Sharing_Code__c = 'K165';
        oppList[17].Fundraising_Department__c = 'Special Gifts';
        oppList[17].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[17].Deposit_Site__c = null;
        oppList[17].Sharing_Code__c = 'R113';
        oppList[17].Fund__c = 'SAIC';
        oppList[18].Fundraising_Department__c = 'Special Gifts';
        oppList[18].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[18].Deposit_Site__c = null;
        oppList[18].Fund__c = 'SAIC';
        oppList[18].Sharing_Code__c = 'K161';
        oppList[19].Fundraising_Department__c = 'Special Gifts';
        oppList[19].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[19].Deposit_Site__c = null;
        oppList[19].Sharing_Code__c = 'R191';
        oppList[19].Fund__c = 'WOMR';
        oppList[20].Fundraising_Department__c = 'Special Gifts';
        oppList[20].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[20].Deposit_Site__c = null;
        oppList[20].Fund__c = 'SAIC';
        oppList[20].Sharing_Code__c = 'K161';
        oppList[21].Fundraising_Department__c = 'Special Gifts';
        oppList[21].Restriction__c = 'CHST - Church-State Work (c3-160 or c4-303)';
        oppList[21].Deposit_Site__c = null;
        oppList[21].Fund__c = 'SAIC';
        oppList[21].Sharing_Code__c = 'K165';
        update oppList;
        
        NationalBudgetUtility.getSummaryLabel(oppList[0], nbList[0]);
        
        nbList[0].Tax_Designation__c = 'Union';
        nbList[1].Budget_Category__c = ' ';
        nbList[1].Tax_Designation__c = ' ';
        nbList[2].Budget_Category__c = 'Centennial Campaign';
        nbList[3].Budget_Category__c = 'LFF Campaign';
        update nbList;
        
        //Testing the methods of the class
        NationalBudgetUtility.getSummaryLabel(oppList[1], nbList[0]);
        NationalBudgetUtility.getSummaryLabel(oppList[1], nbList[1]);
        NationalBudgetUtility.getSummaryLabel(oppList[2], nbList[2]);
        NationalBudgetUtility.getSummaryLabel(oppList[2], nbList[3]);
        NationalBudgetUtility.getSummaryLabel(oppList[3], nbList[3]);
        NationalBudgetUtility.getSummaryLabel(oppList[4], nbList[3]);
        NationalBudgetUtility.getSummaryLabel(oppList[5], nbList[3]);
        NationalBudgetUtility.getC3StaticBudgetData();
        NationalBudgetUtility.getC4StaticBudgetData();
        NationalBudgetUtility.updateReportStatus(true);
        
        //Verify the value updated for Report Status
        system.assertEquals(true, [SELECT id,Report_Request_In_Progress__c from National_Budget_Report_Status__c limit 1].Report_Request_In_Progress__c);
        
        NationalBudgetUtility.updateReportStatus(false);
        system.assertEquals(false, [SELECT id,Report_Request_In_Progress__c from National_Budget_Report_Status__c limit 1].Report_Request_In_Progress__c);
        
        List<String> C3CategoryList = new List<String>();
        for(Integer i=0; i<16; i++){
            String C3Category = NationalBudgetUtility.fetchC3BudgetCategory(oppList[i+6]);
            C3CategoryList.add(C3Category);
        }

        //Verify the values updated by fetchC3BudgetCategory Method
        system.assertEquals('Bequests - General 90/10', C3CategoryList[3]);
        system.assertEquals('LGBT - Grants', C3CategoryList[8]);
    }

    @isTest
    private static void testNbu1(){
        Test.StartTest();
        acc = [SELECT ID FROM Account LIMIT 1];
        oppList.clear();
        
        //Test data creation
        for(Integer i=0; i<50; i++){
            Opportunity opp1 = testUtils.createOpportunity(acc.id, 'op'+i, false);
            opp1.RPT_Package_Code__c = 'CA';
            opp1.Fundraising_Department__c = 'Affiliate';
            oppList.add(opp1);
        }
        insert oppList;
        
        //Update data to fulfill criteria
        oppList[0].Sharing_Code__c = 'E121';
        oppList[1].Sharing_Code__c = 'C161';
        oppList[2].Sharing_Code__c = 'C165';
        oppList[3].Fund__c = null;
        oppList[3].Deposit_Site__c = '';
        oppList[3].Sharing_Code__c = 'U001';  
        oppList[4].Sharing_Code__c = 'U002';  
        oppList[4].Fund__c = null;
        oppList[4].Deposit_Site__c = '';
        oppList[5].Fund__c = null;
        oppList[5].Deposit_Site__c = '';
        oppList[5].Sharing_Code__c = 'U003';  
        oppList[6].Fund__c = null;
        oppList[6].Deposit_Site__c = '';
        oppList[6].Sharing_Code__c = 'U004';  
        oppList[7].Sharing_Code__c = 'U005'; 
        oppList[7].Fund__c = null;
        oppList[7].Deposit_Site__c = '';
        oppList[8].Fund__c = null;
        oppList[8].Deposit_Site__c = '';
        oppList[8].Sharing_Code__c = 'C171';  
        oppList[9].Deposit_Site__c = '';
        oppList[9].Fund__c = 'CNTRJUS';
        oppList[9].Sharing_Code__c = 'E121';  
        oppList[10].Fund__c = 'SCTY';
        oppList[10].Deposit_Site__c = '';
        oppList[10].Sharing_Code__c = 'E131';  
        oppList[11].Sharing_Code__c =  'C161';  
        oppList[11].Fund__c = 'CNTRJUS';
        oppList[11].Deposit_Site__c = '';
        oppList[12].Fund__c = 'CNTRJUS';
        oppList[12].Deposit_Site__c = '';
        oppList[12].Sharing_Code__c = 'C165'; 
        oppList[13].Deposit_Site__c = '';
        oppList[13].Sharing_Code__c = 'C165'; 
        oppList[13].Fund__c = 'IHR';
        oppList[14].Deposit_Site__c = '';
        oppList[14].Sharing_Code__c = 'C165'; 
        oppList[14].Fund__c = 'IRP';
        oppList[15].Sharing_Code__c = 'C161';  
        oppList[15].Fund__c = 'SEC';
        oppList[15].Deposit_Site__c = '';
        oppList[16].Sharing_Code__c = 'C165';
        oppList[16].Fund__c = 'SEC';
        oppList[16].Deposit_Site__c = '';
        oppList[17].Deposit_Site__c = '';
        oppList[17].Sharing_Code__c = 'E181';  
        oppList[17].Fund__c = 'LGRP';
        oppList[18].Fund__c = 'SEC';
        oppList[18].Deposit_Site__c = '';
        oppList[18].Sharing_Code__c = 'E191';
        oppList[19].Fund__c = 'SEC';
        oppList[19].Deposit_Site__c = '';
        oppList[19].Sharing_Code__c = 'C165';  
        oppList[20].Deposit_Site__c = '';
        oppList[20].Sharing_Code__c = 'C165'; 
        oppList[20].Fund__c = 'RJP';
        oppList[21].Sharing_Code__c = 'C161';  
        oppList[21].Fund__c = 'RFP';
        oppList[21].Deposit_Site__c = '';
        oppList[22].Sharing_Code__c = 'C165';  
        oppList[22].Fund__c = 'SPT';
        oppList[22].Deposit_Site__c = '';
        oppList[23].Sharing_Code__c = 'E121';  
        oppList[23].Fund__c = 'VOTRG';
        oppList[23].Deposit_Site__c = '';
        oppList[24].Sharing_Code__c = 'C161'; 
        oppList[24].Fund__c = 'VOTRG';
        oppList[24].Deposit_Site__c = '';
        oppList[25].Sharing_Code__c = 'P001';  
        oppList[25].Amount = 2000;
        oppList[25].Fund__c = 'VOTRG';
        oppList[25].Deposit_Site__c = '';
        oppList[26].Sharing_Code__c = 'D009'; 
        oppList[26].Amount = 2000;
        oppList[26].Fund__c = 'VOTRG';
        oppList[26].Deposit_Site__c = '';
        oppList[27].Sharing_Code__c = 'E013'; 
        oppList[27].Amount = 2000;
        oppList[27].Fund__c = 'VOTRG';
        oppList[27].Deposit_Site__c = '';
        oppList[28].Sharing_Code__c = 'E191';
        oppList[28].Amount = 2000;
        oppList[28].Fund__c = 'VOTRG';
        oppList[28].Deposit_Site__c = '';
        oppList[29].Sharing_Code__c = 'A001';
        oppList[29].Amount = 2000;
        oppList[29].Fund__c = 'VOTRG';
        oppList[29].Deposit_Site__c = '';
        oppList[30].Sharing_Code__c = 'B003';
        oppList[30].Amount = 2000;
        oppList[30].Fund__c = 'VOTRG';
        oppList[30].Deposit_Site__c = '';
        oppList[31].Sharing_Code__c = 'C161'; 
        oppList[31].Amount = 2000;
        oppList[31].Fund__c = 'VOTRG';
        oppList[31].Deposit_Site__c = '';
        oppList[32].Sharing_Code__c = null; 
        oppList[32].Amount = 2000;
        oppList[32].Fund__c = 'VOTRG';
        oppList[32].Deposit_Site__c = '';
        oppList[33].Sharing_Code__c = 'U001';  
        oppList[33].Fund__c = 'LGRP';
        oppList[33].Amount = 2000;
        oppList[33].Deposit_Site__c = '';
        oppList[34].Sharing_Code__c = 'C165'; 
        oppList[34].Amount = 2000;
        oppList[34].Fund__c = 'VOTRG';
        oppList[34].Deposit_Site__c = '';
        oppList[35].Sharing_Code__c = 'U001';  
        oppList[35].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[35].Amount = 2000;
        oppList[35].Fund__c = 'VOTRG';
        oppList[36].Sharing_Code__c = 'U001';  
        oppList[36].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[36].Amount = 2000;
        oppList[36].Fund__c = 'LGRP';
        oppList[37].Fund__c = 'GENF';
        oppList[37].Sharing_Code__c = 'U001';  
        oppList[37].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[37].Amount = 2000;
        oppList[38].Fund__c = 'GENF';
        oppList[38].Sharing_Code__c = 'R113';
        oppList[38].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[38].Amount = 2000;
        oppList[39].Sharing_Code__c = 'R191';
        oppList[39].Fund__c = 'GENF';
        oppList[39].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[39].Amount = 2000;
        oppList[40].Sharing_Code__c = 'K161';
        oppList[40].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[40].Amount = 2000;
        oppList[40].Fund__c = 'GENF';
        oppList[41].Sharing_Code__c = 'K165';
        oppList[41].Deposit_Site__c = 'NAE_NatF_Endowment';
        oppList[41].Amount = 2000;
        oppList[41].Fund__c = 'GENF';
        update oppList;
            
        List<String> fetchC4BudgetCategoryList = new List<String>();
        for(Integer i=1 ;i<42; i++){
            String fetchC4BudgetCategory = NationalBudgetUtility.fetchC4BudgetCategory(oppList[i]);
            fetchC4BudgetCategoryList.add(fetchC4BudgetCategory);
        }
        
        //Verify the updated fetchC4Category
        System.assertEquals('Bequests - General Other', fetchC4BudgetCategoryList[6]);
        System.assertEquals('Bequests - Endowment', fetchC4BudgetCategoryList[34]);
        
        Test.StopTest();
        for(integer i=42; i<50; i++){
            oppList[i].Deposit_Site__c = 'NAE_NatF_Endowment';
            oppList[i].Amount = 2000;
            oppList[i].Fund__c = null;
        }
        oppList[42].Restriction__c = 'CNTRDEM - Center for Democracy (c3-119)';
        oppList[42].Sharing_Code__c = 'R113';
        oppList[43].Sharing_Code__c = 'K161';
        oppList[43].Restriction__c = 'CNTRDEM - Center for Democracy (c3-119)';
        oppList[44].Sharing_Code__c = 'K165';
        oppList[44].Restriction__c = 'CNTRDEM - Center for Democracy (c3-119)';
        oppList[45].Sharing_Code__c = 'R191';
        oppList[45].Restriction__c = 'CNTRDEM - Center for Democracy (c3-119)';
        oppList[46].Restriction__c = 'CNTREQU - Center for Equality (c3-129)';
        oppList[46].Sharing_Code__c = 'R131';
        oppList[47].Sharing_Code__c = 'K161';
        oppList[47].Restriction__c = 'CNTREQU - Center for Equality (c3-129)';
        oppList[48].Sharing_Code__c = 'K165';
        oppList[48].Restriction__c = 'CNTREQU - Center for Equality (c3-129)';
        oppList[49].Sharing_Code__c = 'R191';
        oppList[49].Restriction__c = 'CNTREQU - Center for Equality (c3-129)';
        update oppList;
        
        List<String> fetchC3BudgetCategoryList = new List<String>();
        for(Integer i=42; i<50; i++){
            String fetchC3BudgetCategory = NationalBudgetUtility.fetchC3BudgetCategory(oppList[i]);
            fetchC3BudgetCategoryList.add(fetchC3BudgetCategory);
        }
        
        //Verify the updated fetchC4Category
        System.assertEquals('Center for Equality - Incentive', fetchC3BudgetCategoryList[4]);
               
    }
    
     @isTest
     private static void testNbu1part2(){
        
        acc = [SELECT ID FROM Account LIMIT 1];
        oppList.clear();
        
        //Test data created 
        for(Integer i=0; i<12; i++){
            Opportunity opp1 = testUtils.createOpportunity(acc.id, 'op'+i, false);
            opp1.Restriction__c =  null;
            opp1.Fund__c = 'CNTRJUS';
            oppList.add(opp1);
        }
        insert oppList;
        
        //Update data to fulfill conditions
        oppList[0].Sharing_Code__c = 'R131';
        oppList[1].Sharing_Code__c = 'K161';
        oppList[2].Sharing_Code__c = 'R191';
        oppList[3].Sharing_Code__c = 'K165';
        oppList[4].Fund__c = null;
        oppList[4].Restriction__c = 'CNTRLIB - Center for Liberty (c3-149)';
        oppList[4].Sharing_Code__c = 'R131';
        oppList[5].Sharing_Code__c = 'K161';
        oppList[5].Fund__c = null;
        oppList[5].Restriction__c = 'CNTRLIB - Center for Liberty (c3-149)';
        oppList[6].Sharing_Code__c = 'R191';
        oppList[6].Fund__c = null;
        oppList[6].Restriction__c = 'CNTRLIB - Center for Liberty (c3-149)';
        oppList[7].Fund__c = null;
        oppList[7].Restriction__c = 'CNTRLIB - Center for Liberty (c3-149)';
        oppList[7].Sharing_Code__c = 'K165';
        oppList[8].Restriction__c = 'CLRM - Criminal Law Reform Project (c3-135 or c4-335)';
        oppList[8].Sharing_Code__c = 'R131';
        oppList[8].Fund__c = null;
        oppList[9].Sharing_Code__c = 'K161';
        oppList[9].Restriction__c = 'CLRM - Criminal Law Reform Project (c3-135 or c4-335)';
        oppList[9].Fund__c = null;
        oppList[10].Restriction__c = 'CLRM - Criminal Law Reform Project (c3-135 or c4-335)';
        oppList[10].Fund__c = null;
        oppList[10].Sharing_Code__c = 'R191';
        oppList[11].Restriction__c = 'CLRM - Criminal Law Reform Project (c3-135 or c4-335)';
        oppList[11].Fund__c = null;
        oppList[11].Sharing_Code__c = 'K165';
        update oppList;
        
        List<String> fetchC3BudgetCategoryList = new List<String>();
        for(Integer i=0; i<12; i++){
            String fetchC3BudgetCategory = NationalBudgetUtility.fetchC3BudgetCategory(oppList[i]);
            fetchC3BudgetCategoryList.add(fetchC3BudgetCategory);
        }
        
        //Verify the updated values of fetchC3BudgetCategory
        System.assertEquals('Center for Liberty - Incentive', fetchC3BudgetCategoryList[4]);
        System.assertEquals('CLRP - Incentive', fetchC3BudgetCategoryList[8]);
         
     }

     @isTest
     private static void testNbu2(){
         
        acc = [SELECT ID FROM Account LIMIT 1];
        oppList.clear();
        
       //Test data creation  
       for(Integer i=0; i<38; i++){
            Opportunity opp1 = testUtils.createOpportunity(acc.id, 'op'+i, false);
            opp1.Restriction__c =  null;
            opp1.Fund__c = 'DPF';
            oppList.add(opp1);
        }
        insert oppList;
        
        //Update data to fulfill criteria
        oppList[0].Sharing_Code__c = 'R131';
        oppList[1].Sharing_Code__c = 'K161';
        oppList[2].Sharing_Code__c = 'R191';
        oppList[3].Sharing_Code__c = 'K165';
        oppList[4].Fund__c = null;
        oppList[4].Restriction__c = 'DISABLE - Disability Rights c3 (117)';
        oppList[4].Sharing_Code__c = 'R165';
        oppList[5].Restriction__c = 'DORSEN - Norman Dorsen President\'s Award (1076)';
        oppList[5].Fund__c = null;
        oppList[5].Sharing_Code__c = 'K161';
        oppList[6].Sharing_Code__c = 'R113';
        oppList[6].Restriction__c = null;
        oppList[6].Fund__c = 'IHR';
        oppList[7].Sharing_Code__c = 'K161';
        oppList[7].Restriction__c = null;
        oppList[7].Fund__c = 'IHR';
        oppList[8].Sharing_Code__c = 'K165';
        oppList[8].Restriction__c = null;
        oppList[8].Fund__c = 'IHR';
        oppList[9].Fund__c = 'IHR';
        oppList[9].Sharing_Code__c = 'R113'; 
        oppList[9].Restriction__c = null;
        oppList[10].Restriction__c = null;
        oppList[10].Sharing_Code__c = 'K161';
        oppList[10].Fund__c = 'IHR';
        oppList[11].Sharing_Code__c = 'K165';
        oppList[11].Fund__c = 'IRP';
        oppList[10].Restriction__c = null;
        oppList[12].Fund__c = null;
        oppList[12].Restriction__c = 'SB1070 - Immigration - SB1070 War Chest (c3-116 or c4-316)';
        oppList[12].Sharing_Code__c = 'R113';
        oppList[13].Sharing_Code__c = 'K191';
        oppList[13].Fund__c = null;
        oppList[13].Restriction__c = 'SB1070 - Immigration - SB1070 War Chest (c3-116 or c4-316)';
        oppList[14].Sharing_Code__c = 'K165';
        oppList[14].Fund__c = null;
        oppList[14].Restriction__c = 'SB1070 - Immigration - SB1070 War Chest (c3-116 or c4-316)';
        oppList[15].Restriction__c = null;
        oppList[15].Fund__c = 'KARP';
        oppList[15].Sharing_Code__c = 'K161';
        oppList[16].Fund__c = 'OFFLGBTC3';
        oppList[16].Sharing_Code__c = 'R141';
        oppList[16].Restriction__c = null;
        oppList[17].Sharing_Code__c = 'R113';
        oppList[17].Fund__c = 'OFFLGBTC3';
        oppList[17].Restriction__c = null;
        oppList[18].Sharing_Code__c = 'R191';
        oppList[18].Fund__c = 'OFFLGBTC3';
        oppList[18].Restriction__c = null;
        oppList[19].Sharing_Code__c = 'K161';
        oppList[19].Fund__c = 'OFFLGBTC3';
        oppList[19].Restriction__c = null;
        oppList[20].Sharing_Code__c = 'K165';
        oppList[20].Fund__c = 'OFFLGBTC3';
        oppList[20].Restriction__c = null;
        oppList[21].Fund__c = 'LGBTTRANS';
        oppList[21].Restriction__c = null;
        oppList[21].Sharing_Code__c = 'R113';
        oppList[22].Fund__c = 'PRIS';
        oppList[22].Sharing_Code__c = 'R113';
        oppList[22].Restriction__c = null;
        oppList[23].Sharing_Code__c = 'K165';
        oppList[23].Fund__c = 'PRIS';
        oppList[23].Restriction__c = null;
        oppList[24].Sharing_Code__c = 'K161';
        oppList[24].Fund__c = 'PRIS';
        oppList[24].Restriction__c = null;
        oppList[25].Sharing_Code__c = 'R191';
        oppList[25].Fund__c = 'PRIS';
        oppList[25].Restriction__c = null;
        oppList[26].Fund__c = 'CAPPU';
        oppList[26].Sharing_Code__c = 'R113';
        oppList[26].Restriction__c = null;
        oppList[27].Sharing_Code__c = 'K165';
        oppList[27].Fund__c = 'CAPPU';
        oppList[27].Restriction__c = null;
        oppList[28].Sharing_Code__c = 'K161';
        oppList[28].Fund__c = 'CAPPU';
        oppList[28].Restriction__c = null;
        oppList[29].Sharing_Code__c = 'R191';
        oppList[29].Fund__c = 'CAPPU';
        oppList[29].Restriction__c = null;
        oppList[30].Fund__c = 'SEC';
        oppList[30].Sharing_Code__c = 'R113';
        oppList[30].Restriction__c = null;
        oppList[31].Sharing_Code__c = 'K165';
        oppList[31].Restriction__c = null;
        oppList[31].Fund__c = 'SEC';
        oppList[32].Sharing_Code__c = 'K161';
        oppList[32].Restriction__c = null;
        oppList[32].Fund__c = 'SEC';
        oppList[33].Sharing_Code__c = 'R191';
        oppList[33].Restriction__c = null;
        oppList[33].Fund__c = 'SEC';
        oppList[34].Fund__c = 'RFP';
        oppList[34].Sharing_Code__c = 'R113';
        oppList[34].Restriction__c = null;
        oppList[35].Sharing_Code__c = 'K165';
        oppList[35].Fund__c = 'RFP';
        oppList[35].Restriction__c = null;
        oppList[36].Sharing_Code__c = 'K161';
        oppList[36].Fund__c = 'RFP';
        oppList[36].Restriction__c = null;
        oppList[37].Sharing_Code__c = 'R191';
        oppList[37].Fund__c = 'RFP';
        oppList[37].Restriction__c = null;
        update oppList;
         
         List<String> fetchC3BudgetCategoryList = new List<String>();
         for(Integer i=0; i<38; i++){
             String fetchC3BudgetCategory = NationalBudgetUtility.fetchC3BudgetCategory(oppList[i]);
             fetchC3BudgetCategoryList.add(fetchC3BudgetCategory);
        }
         
         //Verify the updated value of fetchC3BudgetCategory
         System.assertEquals('Human Rights - Incentive', fetchC3BudgetCategoryList[6]);
         System.assertEquals('RFP - Unshared Individuals', fetchC3BudgetCategoryList[36]);
         
     }

     @isTest
     private static void testNbu3(){
        acc = [SELECT ID FROM Account LIMIT 1];
        oppList.clear();
        
        //Test data creation
        for(Integer i=0; i<6; i++){
            Opportunity opp1 = testUtils.createOpportunity(acc.id, 'op'+i, false);
            opp1.Restriction__c = 'SB1070 - Immigration - SB1070 War Chest (c3-116 or c4-316)';
            oppList.add(opp1);
        }
        insert oppList;
        
        //Update data to verify the various conditions
        oppList[0].Sharing_Code__c = 'K165';
        oppList[1].Sharing_Code__c = 'R191';
        oppList[2].Sharing_Code__c = 'R113';
        oppList[3].Sharing_Code__c = 'R191';
        oppList[4].Sharing_Code__c = 'K161';
        oppList[4].Fund__c = 'SAIC' ;
        oppList[5].Fund__c = ' ' ;
        oppList[5].Sharing_Code__c = 'K161';
        oppList[5].rC_Giving__Source_Code__c = 'CWSFCAA';
        update oppList;
         
        List<String> fetchC3BudgetCategoryList = new List<String>();
        for(Integer i=0; i<6; i++){
            String fetchC3BudgetCategory = NationalBudgetUtility.fetchC3BudgetCategory(oppList[i]);
            fetchC3BudgetCategoryList.add(fetchC3BudgetCategory);
        }
         
        //Verify the updated values of fetchC3BudgetCategory
        System.assertEquals('Immigrants SB1070 - Incentive', fetchC3BudgetCategoryList[2]);
        System.assertEquals('SAI (non-LFF) - Unshared Individuals', fetchC3BudgetCategoryList[4]);
              
     }

      @isTest
      private static void testNbu4(){
        
        acc = [SELECT ID FROM Account LIMIT 1];
        oppList.clear();
        
        //Test data creation  
        for(Integer i=0; i<11; i++){
            Opportunity opp1 = testUtils.createOpportunity(acc.id, 'op'+i, false);
            opp1.Restriction__c = 'SB1070 - Immigration - SB1070 War Chest (c3-116 or c4-316)';
            oppList.add(opp1);
        }
        insert oppList;
        
        //Update data to match various conditions
        oppList[0].Sharing_Code__c = 'R131';
        oppList[1].Fund__c = 'GENF';
        oppList[1].Sharing_Code__c = 'R131';
        oppList[2].Fund__c = 'GENF';
        oppList[2].Sharing_Code__c = 'N111';
        oppList[3].Sharing_Code__c = 'N175';
        oppList[3].Fund__c = 'GENF';
        oppList[4].RPT_Package_Code__c = 'CCCPA';
        oppList[4].Sharing_Code__c = 'R113';
        oppList[4].Fund__c = 'GENF';
        oppList[5].Sharing_Code__c = 'R191';
        oppList[5].Fund__c = 'GENF';
        //oppList[5].RPT_Package_Code__c = 'CCCPA';
        oppList[6].Sharing_Code__c = null;
        oppList[6].Fund__c = 'SAIC';
        oppList[6].RPT_Package_Code__c = 'CCCPA';
        oppList[7].RPT_Package_Code__c = 'CCCPCCAA';
        oppList[7].Sharing_Code__c = 'R113';
        oppList[7].Fund__c = 'SAIC';
        oppList[8].Sharing_Code__c = 'K161';
        oppList[8].Fund__c = 'SAIC';
        oppList[8].RPT_Package_Code__c = 'CCCPCCAA';
        oppList[9].Sharing_Code__c = 'R191';
        oppList[9].Fund__c = 'SAIC';
        oppList[9].RPT_Package_Code__c = 'CCCPCCAA';
        oppList[10].Sharing_Code__c = 'K165';
        oppList[10].Fund__c = 'SAIC';
        oppList[10].RPT_Package_Code__c = 'CCCPCCAA';
        update oppList;
          
        List<String> fetchC3BudgetCategoryList = new List<String>();
        for(Integer i=0; i<11; i++){
            String fetchC3BudgetCategory = NationalBudgetUtility.fetchC3BudgetCategory(oppList[i]);
            fetchC3BudgetCategoryList.add(fetchC3BudgetCategory);
        }
         
         //Verify the updated values of fetchC3BudgetCategory
         System.assertEquals('LFF Campaign - Incentive', fetchC3BudgetCategoryList[4]);
         System.assertEquals('LFF Campaign - Unshared SAI', fetchC3BudgetCategoryList[6]);
         
     }

      @isTest
      private static void testNbu5(){
        
        acc = [SELECT ID FROM Account LIMIT 1];
        oppList.clear();
        
        //Test data creation
        for(Integer i=0; i<11; i++){
            Opportunity opp1 = testUtils.createOpportunity(acc.id, 'op'+i, true);
            oppList.add(opp1);
        }
        
        //Update data to match the various conditions
        oppList[0].Sharing_Code__c = 'E121';
        oppList[0].Fund__c = 'CNTRJUS';
        oppList[1].Sharing_Code__c = 'C165';
        oppList[1].Fund__c = 'CNTRJUS';
        oppList[2].RPT_Package_Code__c = 'CCCPCCAA';
        oppList[2].Sharing_Code__c = 'E191';
        oppList[2].Fund__c = 'OFFLGBTC4';
        oppList[3].Sharing_Code__c = 'E181';  
        oppList[3].Fund__c = 'OFFLGBTC4';
        oppList[4].Sharing_Code__c = 'C161'; 
        oppList[4].Fund__c = 'OFFLGBTC4';
        oppList[5].Sharing_Code__c = 'E191';  
        oppList[5].Fund__c = null;
        oppList[6].Sharing_Code__c = 'C165'; 
        oppList[6].Fund__c = null;
        oppList[7].Sharing_Code__c =  'E151';  
        oppList[7].Fund__c = 'CNTRJUS';
        oppList[8].Sharing_Code__c = 'K165';
        oppList[8].Fund__c = 'SAIC';
        oppList[8].RPT_Package_Code__c = 'CCCPCCAA';
        oppList[9].Sharing_Code__c = 'C165';
        oppList[9].RPT_Package_Code__c = 'CCCPCCAA';
        oppList[10].Sharing_Code__c = 'E141';
        oppList[10].RPT_Package_Code__c = 'CCCPCCAA';
        oppList[10].Fund__c = 'CNTRJUS';
        update oppList;
          
        List<String> fetchC4BudgetCategoryList = new List<String>();
        for(Integer i=0; i<11; i++){
            String fetchC4BudgetCategory = NationalBudgetUtility.fetchC4BudgetCategory(oppList[i]);
            fetchC4BudgetCategoryList.add(fetchC4BudgetCategory);
        }
          
         //Verify the updated values of fetchC3BudgetCategory
         System.assertEquals('Unbudgeted - OFFLGBTC4 - null', fetchC4BudgetCategoryList[3]);
         System.assertEquals('Shared - LG Center for Justice', fetchC4BudgetCategoryList[7]);
         
      }
}