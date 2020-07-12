/*
*
*Name  :  NationalBudgetUtility
*Author:  Appirio India (Sandeep Soni)
*Date  :  June 14, 2017
*Purpose :  NationalBudgetUtility is a utility class that is called from BatchNationalBudgetCreate batch class 
            to set C3budgetCategory and C4budgetCategory fields.
            Classification data is hard coded in this class.
*
*/
public class NationalBudgetUtility {

	public static Map<String, String> getC3StaticBudgetData() {
		Map<String, String> mapC3BudgetData = new Map<String, String>();
		mapC3BudgetData.put('BRI', 'C3 Budget Group 1');
		mapC3BudgetData.put('Workplace Giving', 'C3 Budget Group 1');
		mapC3BudgetData.put('General - Incentive', 'C3 Budget Group 1');
		mapC3BudgetData.put('General - Special Sharing', 'C3 Budget Group 1');
		mapC3BudgetData.put('General - Unshared Individuals', 'C3 Budget Group 1');
		mapC3BudgetData.put('General - Grants', 'C3 Budget Group 1');
		mapC3BudgetData.put('Center for Democracy - Incentive', 'C3 Budget Group 2');
		mapC3BudgetData.put('Center for Democracy - Unshared Individuals', 'C3 Budget Group 2');
		mapC3BudgetData.put('Center for Democracy - Grants', 'C3 Budget Group 2');
		mapC3BudgetData.put('Center for Equality - Incentive', 'C3 Budget Group 3');
		mapC3BudgetData.put('Center for Equality - Unshared Individuals', 'C3 Budget Group 4');
		mapC3BudgetData.put('Center for Equality - Grants', 'C3 Budget Group 5');
		mapC3BudgetData.put('Center for Justice - Incentive', 'C3 Budget Group 6');
		mapC3BudgetData.put('Center for Justice - Unshared Individuals', 'C3 Budget Group 6');
		mapC3BudgetData.put('Center for Justice - Grants', 'C3 Budget Group 6');
		mapC3BudgetData.put('Center for Liberty - Incentive', 'C3 Budget Group 7');
		mapC3BudgetData.put('Center for Liberty - Special Sharing', 'C3 Budget Group 7');
		mapC3BudgetData.put('Center for Liberty - Grants', 'C3 Budget Group 7');
		mapC3BudgetData.put('CLRP - Incentive', 'C3 Budget Group 7');
		mapC3BudgetData.put('CLRP - Unshared Individuals', 'C3 Budget Group 7');
		mapC3BudgetData.put('CLRP - Grants', 'C3 Budget Group 7');
		mapC3BudgetData.put('Disability Rights - Grants', 'C3 Budget Group 8');
		mapC3BudgetData.put('Human Rights - Unshared Individuals', 'C3 Budget Group 9');
		mapC3BudgetData.put('Human Rights - Grants', 'C3 Budget Group 9');
		mapC3BudgetData.put('IRP - Incentive', 'C3 Budget Group 10');
		mapC3BudgetData.put('IRP - Unshared Individuals', 'C3 Budget Group 10');
		mapC3BudgetData.put('IRP - Special Sharing', 'C3 Budget Group 10');
		mapC3BudgetData.put('IRP - Grants', 'C3 Budget Group 10');
		mapC3BudgetData.put('Karpatkin - Unshared Individuals', 'C3 Budget Group 11');
		mapC3BudgetData.put('LGBT - Incentive', 'C3 Budget Group 12');
		mapC3BudgetData.put('LGBT - Special Sharing', 'C3 Budget Group 12');
		mapC3BudgetData.put('LGBT - Unshared Individuals', 'C3 Budget Group 12');
		mapC3BudgetData.put('LGBT - Grants', 'C3 Budget Group 12');
		mapC3BudgetData.put('LGBTTRANS - Incentive', 'C3 Budget Group 12');
		mapC3BudgetData.put('NPP - Incentive', 'C3 Budget Group 13');
		mapC3BudgetData.put('NPP - Unshared Individuals', 'C3 Budget Group 13');
		mapC3BudgetData.put('NPP - Grants', 'C3 Budget Group 13');
		mapC3BudgetData.put('CPP - Grants', 'C3 Budget Group 14');
		mapC3BudgetData.put('NSP - Incentive', 'C3 Budget Group 15');
		mapC3BudgetData.put('NSP - Unshared Individuals', 'C3 Budget Group 15');
		mapC3BudgetData.put('NSP - Grants', 'C3 Budget Group 15');
		mapC3BudgetData.put('RFP - Incentive', 'C3 Budget Group 16');
		mapC3BudgetData.put('RFP - Special Sharing', 'C3 Budget Group 16');
		mapC3BudgetData.put('RFP - Unshared Individuals', 'C3 Budget Group 16');
		mapC3BudgetData.put('RFP - Grants', 'C3 Budget Group 16');
		mapC3BudgetData.put('RJP - Incentive', 'C3 Budget Group 17');
		mapC3BudgetData.put('RJP - Grants', 'C3 Budget Group 17');
		mapC3BudgetData.put('SPT - Incentive', 'C3 Budget Group 18');
		mapC3BudgetData.put('SPT - Unshared Individuals', 'C3 Budget Group 18');
		mapC3BudgetData.put('SPT - Special Sharing', 'C3 Budget Group 18');
		mapC3BudgetData.put('SPT - Grants', 'C3 Budget Group 18');
		mapC3BudgetData.put('VRP - Incentive', 'C3 Budget Group 19');
		mapC3BudgetData.put('VRP - Unshared Individuals', 'C3 Budget Group 19');
		mapC3BudgetData.put('VRP - Grants', 'C3 Budget Group 19');
		mapC3BudgetData.put('WRP - Incentive', 'C3 Budget Group 20');
		mapC3BudgetData.put('WRP - Unshared Individuals', 'C3 Budget Group 20');
		mapC3BudgetData.put('WRP - Grants', 'C3 Budget Group 20');
		mapC3BudgetData.put('HRP - Unshared Individuals', 'C3 Budget Group 21');
		mapC3BudgetData.put('HRP - Grants', 'C3 Budget Group 21');
		mapC3BudgetData.put('Freedom of Religion - Incentive', 'C3 Budget Group 22');
		mapC3BudgetData.put('Bequests - General 40/40/20', 'C3 Budget Group 23');
		mapC3BudgetData.put('Bequests - General 90/10', 'C3 Budget Group 23');
		mapC3BudgetData.put('Bequests - General 50/50', 'C3 Budget Group 23');
		mapC3BudgetData.put('Bequests - General 100', 'C3 Budget Group 23');
		mapC3BudgetData.put('Bequests - First Amendment 50/50', 'C3 Budget Group 23');
		mapC3BudgetData.put('Bequests - LGBT 100', 'C3 Budget Group 23');
		mapC3BudgetData.put('Bequests - General - Endowment', 'C3 Budget Group 24');
		mapC3BudgetData.put('Bequests - Church/State - Endowment', 'C3 Budget Group 24');
		mapC3BudgetData.put('Bequests - LGBT - Endowment', 'C3 Budget Group 24');
		mapC3BudgetData.put('Bequests - Bill of Rights Education - Endowment', 'C3 Budget Group 24');
		mapC3BudgetData.put('LFF Campaign - Incentive', 'C3 Budget Group 25');
		mapC3BudgetData.put('LFF Campaign - Special Sharing', 'C3 Budget Group 25');
		mapC3BudgetData.put('LFF Campaign - Unshared SAI', 'C3 Budget Group 25');
		mapC3BudgetData.put('Centennial Campaign - Center for Justice - Incentive', 'C3 Budget Group 26');
		mapC3BudgetData.put('Centennial Campaign - Center for Justice - Unshared Individuals', 'C3 Budget Group 26');
		mapC3BudgetData.put('Centennial Campaign - Center for Justice - Special Sharing', 'C3 Budget Group 26');
		mapC3BudgetData.put('Centennial Campaign - RFP - Unshared Individuals', 'C3 Budget Group 26');
		mapC3BudgetData.put('Centennial Campaign - Incentive', 'C3 Budget Group 26');
		mapC3BudgetData.put('Centennial Campaign - Unshared Individuals', 'C3 Budget Group 26');
		mapC3BudgetData.put('Centennial Campaign - Special Sharing', 'C3 Budget Group 26');
		mapC3BudgetData.put('Centennial Campaign - Grants', 'C3 Budget Group 26');
		mapC3BudgetData.put('Unbudgeted - DLP - Fnd. Solicited Earmarked (INC)', 'C3 Budget Group 27');
		mapC3BudgetData.put('Unbudgeted - DLP - Foundation Bequest Other', 'C3 Budget Group 27');
		mapC3BudgetData.put('Unbudgeted - GENF - Foundation Bequest Other', 'C3 Budget Group 27');
		mapC3BudgetData.put('Unbudgeted - LGBTTRANS - Fnd. Recognized Fnd./Gov\'t Grant (UNSH)', 'C3 Budget Group 27');
		mapC3BudgetData.put('Unbudgeted - PRISMIC4 - Fnd. Solicited Earmarked (INC)', 'C3 Budget Group 27');
		mapC3BudgetData.put('Unbudgeted - SPT - Foundation Bequest Other', 'C3 Budget Group 27');
		return mapC3BudgetData;
	}

	public static Map<String, String> getC4StaticBudgetData() {
		Map<String, String> mapC4BudgetData = new Map<String, String>();
		mapC4BudgetData.put('Shared - First Renewal', 'C4 Budget Group 1');
		mapC4BudgetData.put('Shared - Renewal', 'C4 Budget Group 1');
		mapC4BudgetData.put('Shared - Extra', 'C4 Budget Group 1');
		mapC4BudgetData.put('Shared - Leadership Gifts', 'C4 Budget Group 1');
		mapC4BudgetData.put('Special Sharing - Leadership Gifts', 'C4 Budget Group 1');
		mapC4BudgetData.put('Unshared - New Member', 'C4 Budget Group 2');
		mapC4BudgetData.put('Unshared - Recapture', 'C4 Budget Group 2');
		mapC4BudgetData.put('Unshared - Leadership Gifts', 'C4 Budget Group 2');
		mapC4BudgetData.put('Unshared - Grants', 'C4 Budget Group 2');
		mapC4BudgetData.put('Shared - LG Center for Justice', 'C4 Budget Group 3');
		mapC4BudgetData.put('Unshared - LG - Center for Justice', 'C4 Budget Group 3');
		mapC4BudgetData.put('Unshared - Grants - Center for Justice', 'C4 Budget Group 3');
		mapC4BudgetData.put('Unshared - Grants - Human Rights', 'C4 Budget Group 4');
		mapC4BudgetData.put('Unshared - Grants - Immig Rights', 'C4 Budget Group 5');
		mapC4BudgetData.put('Shared - LG - Natl Security', 'C4 Budget Group 6');
		mapC4BudgetData.put('Unshared - LG - Natl Security', 'C4 Budget Group 6');
		mapC4BudgetData.put('Unshared - Grants - Natl Security', 'C4 Budget Group 6');
		mapC4BudgetData.put('Shared - LG - LGBT/Out for Freedom', 'C4 Budget Group 7');
		mapC4BudgetData.put('Unshared - Grants - LGBT/Out for Freedom', 'C4 Budget Group 7');
		mapC4BudgetData.put('Special Sharing - LG - LGBT/Out for Freedom', 'C4 Budget Group 7');
		mapC4BudgetData.put('Unshared - Grants - Racial Justice', 'C4 Budget Group 8');
		mapC4BudgetData.put('Unshared - LG - Repro Rights', 'C4 Budget Group 9');
		mapC4BudgetData.put('Shared - LG - Voting Rights', 'C4 Budget Group 10');
		mapC4BudgetData.put('Unshared - LG - Voting Rights', 'C4 Budget Group 10');
		mapC4BudgetData.put('Unshared - Grants - SPT', 'C4 Budget Group 11');
		mapC4BudgetData.put('Bequests - General 40/40/20', 'C4 Budget Group 12');
		mapC4BudgetData.put('Bequests - General 90/10', 'C4 Budget Group 12');
		mapC4BudgetData.put('Bequests - General 50/50', 'C4 Budget Group 12');
		mapC4BudgetData.put('Bequests - General 100', 'C4 Budget Group 12');
		mapC4BudgetData.put('Bequests - General Other', 'C4 Budget Group 12');
		mapC4BudgetData.put('Bequests - Second Amendment 50/50', 'C4 Budget Group 12');
		mapC4BudgetData.put('Bequests - LGBT', 'C4 Budget Group 12');
		mapC4BudgetData.put('Bequests - Endowment', 'C4 Budget Group 13');
		mapC4BudgetData.put('Centennial Campaign - General - Incentive', 'C4 Budget Group 14');
		mapC4BudgetData.put('Centennial Campaign - Unshared Individuals', 'C4 Budget Group 14');
		mapC4BudgetData.put('Centennial Campaign - Special Sharing', 'C4 Budget Group 14');
		mapC4BudgetData.put('Centennial Campaign - Grants', 'C4 Budget Group 14');
		mapC4BudgetData.put('Centennial Campaign - Center for Justice - Incentive', 'C4 Budget Group 14');
		mapC4BudgetData.put('Centennial Campaign - Center for Justice - Grants', 'C4 Budget Group 14');
		mapC4BudgetData.put('Centennial Campaign - LGBT/OFF - Special Sharing', 'C4 Budget Group 14');
		mapC4BudgetData.put('Unbudgeted - GENU - Union General Incentive (INC)', 'C4 Budget Group 15');
		mapC4BudgetData.put('Unbudgeted - GENU - Union Memorial (UNSH)', 'C4 Budget Group 15');
		mapC4BudgetData.put('Unbudgeted - GENU - Union Recognized Fnd./Gov\'t Grant (UNSH)', 'C4 Budget Group 15');
		mapC4BudgetData.put('Unbudgeted - LGRPC4 - Union Recognized Fnd./Gov\'t Grant (UNSH)', 'C4 Budget Group 15');

		return mapC4BudgetData;
	}

	/*National Budget C3 Foundation method that will called from BatchNationalBudgetCreate.cls*/
	public static String fetchC3BudgetCategory(Opportunity opp) {
		if (opp.Fund__c == null) opp.Fund__c = '';
		if (opp.RPT_Package_Code__c == null) opp.RPT_Package_Code__c = '';
		if (opp.rC_Giving__Source_Code__c == null) opp.rC_Giving__Source_Code__c = '';
		if (opp.Restriction__c == null) opp.Restriction__c = '';
		if (opp.Deposit_Site__c == null) opp.Deposit_Site__c = '';
		String C3budgetCategory = '';
		if (opp.RPT_Package_Code__c.length() >= 6
		        && opp.RPT_Package_Code__c.subString(2, 6) == 'CPCC'
		        && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121' || opp.Sharing_Code__c == 'R131'
		            || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151' || opp.Sharing_Code__c == 'R181'
		            || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'Centennial Campaign - Incentive';
		} else if (opp.RPT_Package_Code__c.length() >= 6
		           && opp.RPT_Package_Code__c.subString(2, 6) == 'CPCC'
		           && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'Centennial Campaign - Unshared Individuals';
		} else if (opp.RPT_Package_Code__c.length() >= 6
		           && opp.RPT_Package_Code__c.subString(2, 6) == 'CPCC'
		           && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'Centennial Campaign - Special Sharing';
		} else if (opp.RPT_Package_Code__c.length() >= 6
		           && opp.RPT_Package_Code__c.subString(2, 6) == 'CPCC'
		           && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'Centennial Campaign - Grants';
		} else if (opp.RPT_Package_Code__c.length() >= 4 && opp.RPT_Package_Code__c.subString(2, 4) == 'CP'
		           && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121' || opp.Sharing_Code__c == 'R131'
		               || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151' || opp.Sharing_Code__c == 'R181')) {
			C3budgetCategory = 'LFF Campaign - Incentive';
		} else if (opp.RPT_Package_Code__c.length() >= 4 && opp.RPT_Package_Code__c.subString(2, 4) == 'CP'
		           && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'LFF Campaign - Special Sharing';
		} else if (opp.RPT_Package_Code__c.length() >= 4 && opp.RPT_Package_Code__c.subString(2, 4) == 'CP'
		           && opp.Fund__c.contains('SAIC') ) {
			C3budgetCategory = 'LFF Campaign - Unshared SAI';
		} else if (opp.RPT_Package_Code__c.length() >= 4 && opp.RPT_Package_Code__c.subString(2, 4) == 'CP'
		           && opp.Sharing_Code__c == 'K161' && (opp.Sharing_Code__c == 'KARP' || opp.Sharing_Code__c == 'KARP2')) {
			C3budgetCategory = 'LFF Campaign - Unshared Karpatkin';
		} else if (opp.rC_Giving__Source_Code__c.length() >= 4 && opp.rC_Giving__Source_Code__c.subString(2, 4) == 'SF'
		           && opp.Sharing_Code__c == 'K161' && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		                   || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		                   || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171' )) {
			C3budgetCategory = 'Shortfall - Incentive';
		} else if (opp.rC_Giving__Source_Code__c.length() >= 4 && opp.rC_Giving__Source_Code__c.subString(2, 4) == 'SF'
		           && opp.Sharing_Code__c == 'K161' && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'Shortfall - Special Sharing';
		} else if (opp.rC_Giving__Source_Code__c.length() >= 4 && opp.rC_Giving__Source_Code__c.subString(2, 4) == 'SF'
		           && opp.Sharing_Code__c == 'K161' && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'Shortfall - Unshared Individuals';
		} else if (opp.rC_Giving__Source_Code__c.length() >= 4 && opp.rC_Giving__Source_Code__c.subString(2, 4) == 'SF'
		           && opp.Sharing_Code__c == 'K161' && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'Shortfall - Grants';
		} else if (opp.Sharing_Code__c == 'N111' || opp.Sharing_Code__c == 'R112') {
			C3budgetCategory = 'BRI';
		} else if (opp.Sharing_Code__c == 'N175') {
			C3budgetCategory = 'Workplace Giving';
		} else if (opp.Fund__c.contains('GENF') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'General - Incentive';
		} else if (opp.Fund__c.contains('GENF') && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'General - Special Sharing';
		} else if (opp.Fund__c.contains('GENF') && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'General - Unshared Individuals';
		} else if (opp.Fund__c.contains('GENF') && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'General - Grants';
		} else if (opp.Restriction__c.contains('CNTRDEM') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'Center for Democracy - Incentive';
		} else if (opp.Restriction__c.contains('CNTRDEM') && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'Center for Democracy - Unshared Individuals';
		} else if (opp.Restriction__c.contains('CNTRDEM') && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'Center for Democracy - Special Sharing';
		} else if (opp.Restriction__c.contains('CNTRDEM') && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'Center for Democracy - Grants';
		} else if (opp.Restriction__c.contains('CNTREQU') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'Center for Equality - Incentive';
		} else if (opp.Restriction__c.contains('CNTREQU') && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'Center for Equality - Unshared Individuals';
		} else if (opp.Restriction__c.contains('CNTREQU') && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'Center for Equality - Special Sharing';
		} else if (opp.Restriction__c.contains('CNTREQU') && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'Center for Equality - Grants';
		} else if (opp.Fund__c.contains('CNTRJUS') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'Center for Justice - Incentive';
		} else if (opp.Fund__c.contains('CNTRJUS') && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'Center for Justice - Unshared Individuals';
		} else if (opp.Fund__c.contains('CNTRJUS') && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'Center for Justice - Special Sharing';
		} else if (opp.Fund__c.contains('CNTRJUS') && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'Center for Justice - Grants';
		} else if (opp.Restriction__c.contains('CNTRLIB') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'Center for Liberty - Incentive';
		} else if (opp.Restriction__c.contains('CNTRLIB') && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'Center for Liberty - Unshared Individuals';
		} else if (opp.Restriction__c.contains('CNTRLIB') && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'Center for Liberty - Special Sharing';
		} else if (opp.Restriction__c.contains('CNTRLIB') && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'Center for Liberty - Grants';
		} else if ((opp.Restriction__c.contains('CLRM')) && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'CLRP - Incentive';
		} else if (opp.Restriction__c.contains('CLRM') && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'CLRP - Unshared Individuals';
		} else if (opp.Restriction__c.contains('CLRM') && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'CLRP - Special Sharing';
		} else if (opp.Restriction__c.contains('CLRM') && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'CLRP - Grants';
		} else if (opp.Fund__c.contains('DPF') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'CLRP - Incentive';
		} else if (opp.Fund__c.contains('DPF') && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'CLRP - Unshared Individuals';
		} else if (opp.Fund__c.contains('DPF') && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'CLRP - Special Sharing';
		} else if (opp.Fund__c.contains('DPF') && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'CLRP - Grants';
		} else if (opp.Restriction__c.contains('DISABLE') && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'Disability Rights - Grants';
		} else if (opp.Restriction__c  == 'DORSEN' && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'Dorsen Prize - Unshared Individuals';
		} else if (opp.Fund__c.contains('IHR') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'Human Rights - Incentive';
		} else if (opp.Fund__c.contains('IHR') && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'Human Rights - Unshared Individuals';
		} else if (opp.Fund__c.contains('IHR') && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'Human Rights - Grants';
		} else if (opp.Fund__c.contains('IRP') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'IRP - Incentive';
		} else if (opp.Fund__c.contains('IRP') && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'IRP - Unshared Individuals';
		} else if (opp.Fund__c.contains('IRP') && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'IRP - Special Sharing';
		} else if (opp.Fund__c.contains('IRP') && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'IRP - Grants';
		} else if ((opp.Restriction__c.contains('SB1070')) && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181'
		           || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'Immigrants SB1070 - Incentive';
		} else if ((opp.Restriction__c.contains('SB1070')) && (opp.Sharing_Code__c == 'R191')) {
			C3budgetCategory = 'Immigrants SB1070 - Special Sharing';
		} else if ((opp.Restriction__c.contains('SB1070')) && (opp.Sharing_Code__c == 'K165')) {
			C3budgetCategory = 'Immigrants SB1070 - Grants';
		} else if ((opp.Fund__c.contains('KARP') || opp.Fund__c.contains('KARP2')) && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'Karpatkin - Unshared Individuals';
		} else if ((opp.Fund__c.contains('LGRP') || opp.Fund__c.contains('OFFLGBTC3')) && opp.Sharing_Code__c == 'R141') {
			C3budgetCategory = 'LGBT - Benefit';
		} else if ((opp.Fund__c.contains('LGRP') || opp.Fund__c.contains('OFFLGBTC3')) && (opp.Sharing_Code__c == 'R113'
		           || opp.Sharing_Code__c == 'R121' || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'LGBT - Incentive';
		} else if ((opp.Fund__c.contains('LGRP') || opp.Fund__c.contains('OFFLGBTC3')) && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'LGBT - Special Sharing';
		} else if ((opp.Fund__c.contains('LGRP') || opp.Fund__c.contains('OFFLGBTC3')) && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'LGBT - Unshared Individuals';
		} else if ((opp.Fund__c.contains('LGRP') || opp.Fund__c.contains('OFFLGBTC3')) && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'LGBT - Grants';
		} else if (opp.Fund__c.contains('LGBTTRANS') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'LGBTTRANS - Incentive';
		} else if (opp.Fund__c.contains('PRIS') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c ==  'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'NPP - Incentive';
		} else if (opp.Fund__c.contains('PRIS') && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'NPP - Special Sharing';
		} else if (opp.Fund__c.contains('PRIS') && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'NPP - Unshared Individuals';
		} else if (opp.Fund__c.contains('PRIS') && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'NPP - Grants';
		} else if (opp.Fund__c.contains('CAPPU') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141'
		           || opp.Sharing_Code__c == 'R151' || opp.Sharing_Code__c == 'R181'
		           || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'Capital Punishment - Incentive';
		} else if (opp.Fund__c.contains('CAPPU') && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'Capital Punishment - Special Sharing';
		} else if (opp.Fund__c.contains('CAPPU') && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'Capital Punishment - Unshared Individuals';
		} else if (opp.Fund__c.contains('CAPPU') && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'Capital Punishment - Grants';
		} else if ((opp.Fund__c.contains('SEC') || opp.Fund__c.contains('SCTY')) && (opp.Sharing_Code__c == 'R113'
		           || opp.Sharing_Code__c == 'R121' || opp.Sharing_Code__c == 'R131'
		           || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151' || opp.Sharing_Code__c == 'R181'
		           || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'NSP - Incentive';
		} else if ((opp.Fund__c.contains('SEC') || opp.Fund__c.contains('SCTY')) && (opp.Sharing_Code__c == 'K161')) {
			C3budgetCategory = 'NSP - Unshared Individuals';
		} else if ((opp.Fund__c.contains('SEC') || opp.Fund__c.contains('SCTY')) && (opp.Sharing_Code__c == 'R191')) {
			C3budgetCategory = 'NSP - Special Sharing';
		} else if ((opp.Fund__c.contains('SEC') || opp.Fund__c.contains('SCTY')) && (opp.Sharing_Code__c == 'K165')) {
			C3budgetCategory = 'NSP - Grants';
		} else if (opp.Fund__c.contains('RFP') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'RFP - Incentive';
		} else if (opp.Fund__c.contains('RFP') && opp.Sharing_Code__c == 'K161') {
			C3budgetCategory = 'RFP - Unshared Individuals';
		} else if (opp.Fund__c.contains('RFP') && opp.Sharing_Code__c == 'R191') {
			C3budgetCategory = 'RFP - Special Sharing';
		} else if (opp.Fund__c.contains('RFP') && opp.Sharing_Code__c == 'K165') {
			C3budgetCategory = 'RFP - Grants';
		} else if (opp.Fund__c.contains('RJP') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'RJP - Incentive';
		} else if (opp.Fund__c.contains('RJP') && (opp.Sharing_Code__c == 'K165')) {
			C3budgetCategory = 'RJP - Grants';
		} else if (opp.Fund__c.contains('SAIC') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141'
		           || opp.Sharing_Code__c == 'R151' || opp.Sharing_Code__c == 'R181')) {
			C3budgetCategory = 'SAI (non-LFF) - Incentive';
		} else if (opp.Fund__c.contains('SAIC') && (opp.Sharing_Code__c == 'K161')) {
			C3budgetCategory = 'SAI (non-LFF) - Unshared Individuals';
		} else if (opp.Fund__c.contains('SPT') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'SPT - Incentive';
		} else if (opp.Fund__c.contains('SPT') && (opp.Sharing_Code__c == 'R191')) {
			C3budgetCategory = 'SPT - Special Sharing';
		} else if (opp.Fund__c.contains('SPT') && (opp.Sharing_Code__c == 'K161')) {
			C3budgetCategory = 'SPT - Unshared Individuals';
		} else if (opp.Fund__c.contains('SPT') && (opp.Sharing_Code__c == 'K165')) {
			C3budgetCategory = 'SPT - Grants';
		} else if (opp.Fund__c.contains('VOTRG') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'VRP - Incentive';
		} else if (opp.Fund__c.contains('VOTRG') && (opp.Sharing_Code__c == 'R191')) {
			C3budgetCategory = 'VRP - Special Sharing';
		} else if (opp.Fund__c.contains('VOTRG') && (opp.Sharing_Code__c == 'K161')) {
			C3budgetCategory = 'VRP - Unshared Individuals';
		} else if (opp.Fund__c.contains('VOTRG') && (opp.Sharing_Code__c == 'K165')) {
			C3budgetCategory = 'VRP - Grants';
		} else if (opp.Fund__c.contains('WOMR') && (opp.Sharing_Code__c == 'R113' || opp.Sharing_Code__c == 'R121'
		           || opp.Sharing_Code__c == 'R131' || opp.Sharing_Code__c == 'R141' || opp.Sharing_Code__c == 'R151'
		           || opp.Sharing_Code__c == 'R181' || opp.Sharing_Code__c == 'K171')) {
			C3budgetCategory = 'WRP - Incentive';
		} else if (opp.Fund__c.contains('WOMR') && (opp.Sharing_Code__c == 'R191')) {
			C3budgetCategory = 'WRP - Special Sharing';
		} else if (opp.Fund__c.contains('WOMR') && (opp.Sharing_Code__c == 'K161')) {
			C3budgetCategory = 'WRP - Unshared Individuals';
		} else if (opp.Fund__c.contains('WOMR') && (opp.Sharing_Code__c == 'K165')) {
			C3budgetCategory = 'WRP - Grants';
		} else if (opp.Sharing_Code__c == 'Q003' && (opp.Fund__c.contains('SPCHTECH') || opp.Restriction__c .contains('SPT'))) {
			C3budgetCategory = 'Bequests - First Amendment 50/50';
		} else if ((opp.Sharing_Code__c == 'T400' || opp.Sharing_Code__c == 'Q001' || opp.Sharing_Code__c == 'Q002'
		            || opp.Sharing_Code__c == 'Q003' || opp.Sharing_Code__c == 'Q004' || opp.Sharing_Code__c == 'Q005')
		           && opp.Deposit_Site__c.contains('NAE') && (opp.Restriction__c.contains('CHST') || opp.Fund__c.contains('CHST'))) {
			C3budgetCategory = 'Bequests - Church/State - Endowment';
		} else if ((opp.Sharing_Code__c == 'T400' || opp.Sharing_Code__c == 'Q001' || opp.Sharing_Code__c == 'Q002'
		            || opp.Sharing_Code__c == 'Q003' || opp.Sharing_Code__c == 'Q004' || opp.Sharing_Code__c == 'Q005')
		           && opp.Deposit_Site__c.contains('NAE') && opp.Fund__c.contains('LGRP')) {
			C3budgetCategory = 'Bequests - LGBT - Endowment';
		} else if ((opp.Sharing_Code__c == 'T400') || ((opp.Sharing_Code__c == 'Q001' || opp.Sharing_Code__c == 'Q002'
		           || opp.Sharing_Code__c == 'Q003' || opp.Sharing_Code__c == 'Q004' || opp.Sharing_Code__c == 'Q005')
		           && (opp.Deposit_Site__c.contains('NAE')))) {
			C3budgetCategory = 'Bequests - General - Endowment';
		} else if (opp.Sharing_Code__c == 'Q001') {
			C3budgetCategory = 'Bequests - General 40/40/20';
		} else if (opp.Sharing_Code__c == 'Q002') {
			C3budgetCategory = 'Bequests - General 90/10';
		} else if (opp.Sharing_Code__c == 'Q003') {
			C3budgetCategory = 'Bequests - General 50/50';
		} else if (opp.Sharing_Code__c == 'Q004') {
			C3budgetCategory = 'Bequests - General 100';
		} else {
			C3budgetCategory = 'Unbudgeted - ' + opp.Fund__c + ' - '  + opp.Sharing_Code_Description__c;
		}
		return C3budgetCategory;
	}

	/*National Budget C4 Union method that will called from BatchNationalBudgetCreate.cls*/
	public static String fetchC4BudgetCategory(Opportunity opp) {
		if (opp.rC_Giving__Account_Number__c == null) opp.rC_Giving__Account_Number__c = '';
		if (opp.Fund__c == null) opp.Fund__c = '';
		if (opp.RPT_Package_Code__c == null) opp.RPT_Package_Code__c = '';
		if (opp.Sharing_Code__c == null) opp.Sharing_Code__c = '';
		if (opp.rC_Giving__Account_Number__c == null) opp.rC_Giving__Account_Number__c = '';

		String C4budgetCategory = '';
            
		If((opp.RPT_Package_Code__c.length() >= 6 && opp.RPT_Package_Code__c.substring(2, 6) == 'CPCC') &&  (opp.Sharing_Code__c == 'E121' ||
		        opp.Sharing_Code__c == 'E131' || opp.Sharing_Code__c == 'E141' || opp.Sharing_Code__c == 'E151' ||
		        opp.Sharing_Code__c == 'E181')
		   && opp.Fund__c.contains('CNTRJUS')) {
			C4budgetCategory = 'Centennial Campaign - Center for Justice - Incentive';
		}
		else If(opp.RPT_Package_Code__c.length() >= 6 && opp.RPT_Package_Code__c.substring(2, 6) == 'CPCC'
			        &&  opp.Sharing_Code__c == 'C165'
			        &&  opp.Fund__c.contains('CNTRJUS')) {
			C4budgetCategory = 'Centennial Campaign - Center for Justice - Grants';
		}
		else If(opp.RPT_Package_Code__c.length() >= 6
			        && opp.RPT_Package_Code__c.substring(2, 6) == 'CPCC'
			        && opp.Sharing_Code__c == 'E191'
			        && (opp.Fund__c.contains('LGRP') || opp.Fund__c.contains('OFFLGBTC4'))) {
			C4budgetCategory = 'Centennial Campaign - LGBT/OFF - Special Sharing';
		}
		else If((opp.RPT_Package_Code__c.length() >= 6 && opp.RPT_Package_Code__c.substring(2, 6) == 'CPCC')
			        &&  (opp.Sharing_Code__c == 'E121' || opp.Sharing_Code__c == 'E131' || opp.Sharing_Code__c == 'E141'
			             || opp.Sharing_Code__c == 'E151' || opp.Sharing_Code__c == 'E181')) {
			C4budgetCategory = 'Centennial Campaign - General - Incentive';
		}
		else If(opp.RPT_Package_Code__c.length() >= 6 && opp.RPT_Package_Code__c.substring(2, 6) == 'CPCC'
			        &&  opp.Sharing_Code__c == 'C161') {
			C4budgetCategory = 'Centennial Campaign - Unshared Individuals';
		}
		else If(opp.RPT_Package_Code__c.length() >= 6 && opp.RPT_Package_Code__c.substring(2, 6) == 'CPCC'
			        &&  opp.Sharing_Code__c == 'E191') {
			C4budgetCategory = 'Centennial Campaign - Special Sharing';
		}
		else If(opp.RPT_Package_Code__c.length() >= 6 && opp.RPT_Package_Code__c.substring(2, 6) == 'CPCC'
			        &&  opp.Sharing_Code__c == 'C165') {
			C4budgetCategory = 'Centennial Campaign - Grants';
		}
		else If((opp.Sharing_Code__c == 'E121' || opp.Sharing_Code__c == 'E131'
			         || opp.Sharing_Code__c == 'E141' || opp.Sharing_Code__c == 'E151' || opp.Sharing_Code__c == 'E181')
			        && opp.Fund__c.contains('CNTRJUS') && opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Shared - LG Center for Justice';
		}
		else If(opp.Sharing_Code__c == 'C161'
			        &&  opp.Fund__c.contains('CNTRJUS')
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Unshared - LG - Center for Justice';
		}
		else If(opp.Sharing_Code__c == 'C165'
			        &&  opp.Fund__c.contains('CNTRJUS')
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Unshared - Grants - Center for Justice';
		}
		else If(opp.Sharing_Code__c == 'C165'
			        &&  opp.Fund__c.contains('IHR')
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Unshared - Grants - Human Rights';
		}
		else If(opp.Sharing_Code__c == 'C165'
			        &&  opp.Fund__c.contains('IRP')
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Unshared - Grants - Immig Rights';
		}
		else If((opp.Sharing_Code__c == 'E121' || opp.Sharing_Code__c == 'E131' || opp.Sharing_Code__c == 'E141'
			         || opp.Sharing_Code__c == 'E151' || opp.Sharing_Code__c == 'E181')
			        && (opp.Fund__c.contains('SEC') || opp.Fund__c.contains('SCTY'))
			        && opp.rC_Giving__Account_Number__c != '51789311' ) {
			C4budgetCategory = 'Shared - LG - Natl Security';
		}
		else If(opp.Sharing_Code__c == 'C161'
			        &&  (opp.Fund__c.contains('SEC') || opp.Fund__c.contains('SCTY'))
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Unshared - LG - Natl Security';
		}
		else If(opp.Sharing_Code__c == 'C165'
			        &&  (opp.Fund__c.contains('SEC') || opp.Fund__c.contains('SCTY'))
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Unshared - Grants - Natl Security';
		}
		else If((opp.Sharing_Code__c == 'E121' || opp.Sharing_Code__c == 'E131' || opp.Sharing_Code__c == 'E141'
			         || opp.Sharing_Code__c == 'E151' || opp.Sharing_Code__c == 'E181')
			        &&  opp.Fund__c.contains('LGRP')
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Shared - LG - LGBT/Out for Freedom';
		}
		else If(opp.Sharing_Code__c == 'E191'
			        &&  opp.Fund__c.contains('LGRP')
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Special Sharing - LG - LGBT/Out for Freedom';
		}
		else If(opp.Sharing_Code__c == 'C165'
			        &&  opp.Fund__c.contains('LGRP')
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Unshared - Grants - LGBT/Out for Freedom';
		}
		else If(opp.Sharing_Code__c == 'C165'
			        &&  opp.Fund__c.contains('RJP')
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Unshared - Grants - Racial Justice';
		}
		else If(opp.Sharing_Code__c == 'C161'
			        &&  opp.Fund__c.contains('RFP')
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Unshared - LG - Repro Rights';
		}

		else If(opp.Sharing_Code__c == 'C165'
			        &&  opp.Fund__c.contains('SPT')
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Unshared - Grants - SPT';
		}

		else If((opp.Sharing_Code__c == 'E121' || opp.Sharing_Code__c == 'E131' || opp.Sharing_Code__c == 'E141'
			         || opp.Sharing_Code__c == 'E151' || opp.Sharing_Code__c == 'E181')
			        &&  opp.Fund__c.contains('VOTRG')
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Shared - LG - Voting Rights';
		}
		else If(opp.Sharing_Code__c == 'C161'
			        &&  opp.Fund__c.contains('VOTRG')
			        &&  opp.rC_Giving__Account_Number__c != '51789311') {
			C4budgetCategory = 'Unshared - LG - Voting Rights';
		}
		else If((opp.Sharing_Code__c == 'P001' || opp.Sharing_Code__c == 'P002' || opp.Sharing_Code__c == 'P003')
			        &&  opp.rC_Giving__Account_Number__c != '51789311'
			        &&  opp.Amount < 5000 ) {
			C4budgetCategory = 'Shared - First Renewal';
		}
		else If((opp.Sharing_Code__c == 'D009' || opp.Sharing_Code__c == 'D010' || opp.Sharing_Code__c == 'D011'
			         || opp.Sharing_Code__c == 'D012' || opp.Sharing_Code__c == 'E017')
			        &&  opp.rC_Giving__Account_Number__c != '51789311'
			        &&  opp.Amount < 5000) {
			C4budgetCategory = 'Shared - Renewal';
		}
		else If((opp.Sharing_Code__c == 'E013' || opp.Sharing_Code__c == 'E015' || opp.Sharing_Code__c == 'E016'
			         || opp.Sharing_Code__c == 'C171')
			        &&  opp.rC_Giving__Account_Number__c != '51789311'
			        &&  opp.Amount < 5000) {
			C4budgetCategory = 'Shared - Extra';
		}
		else If((opp.Sharing_Code__c == 'E121' || opp.Sharing_Code__c == 'E131' || opp.Sharing_Code__c == 'E141'
			         || opp.Sharing_Code__c == 'E151' || opp.Sharing_Code__c == 'E181')
			        &&  opp.rC_Giving__Account_Number__c != '51789311'
			        &&  opp.Sharing_Code__c != 'C161'
			        &&  opp.Fundraising_Department__c == 'MG') {
			C4budgetCategory = 'Shared - Leadership Gelse Ifts';
		}
		else If(opp.Sharing_Code__c == 'E191'
			        &&  opp.rC_Giving__Account_Number__c != '51789311'
			        &&  opp.Sharing_Code__c != 'C161'
			        &&  opp.Fundraising_Department__c == 'MG') {
			C4budgetCategory = 'Special Sharing - Leadership Gelse Ifts';
		}
		else If((opp.Sharing_Code__c == 'A001' || opp.Sharing_Code__c == 'A002' || opp.Sharing_Code__c == 'A003'
			         || opp.Sharing_Code__c == 'C005')
			        &&  opp.rC_Giving__Account_Number__c != '51789311'
			        &&  opp.Amount < 5000) {
			C4budgetCategory = 'Unshared - New Member';
		}
		else If(opp.Sharing_Code__c == 'B003' &&  opp.rC_Giving__Account_Number__c != '51789311'
			        &&  opp.Amount < 5000) {
			C4budgetCategory = 'Unshared - Recapture';
		}
		else If(opp.Sharing_Code__c == 'C161' &&  opp.rC_Giving__Account_Number__c != '51789311'
			        &&  opp.Fundraising_Department__c == 'MG') {
			C4budgetCategory = 'Unshared - Leadership Gelse Ifts';
		}
		else If(opp.Sharing_Code__c == 'C165' &&  opp.rC_Giving__Account_Number__c != '51789311'
			        &&  opp.Fundraising_Department__c == 'MG') {
			C4budgetCategory = 'Unshared - Grants';
		}
		else If((opp.Sharing_Code__c == 'U001' || opp.Sharing_Code__c == 'U002' || opp.Sharing_Code__c == 'U003'
			         || opp.Sharing_Code__c == 'U004' || opp.Sharing_Code__c == 'U005') &&  opp.Deposit_Site__c.contains('NAE')) {
			C4budgetCategory = 'Bequests - Endowment';
		}
		else If((opp.Sharing_Code__c == 'U001' || opp.Sharing_Code__c == 'U002' || opp.Sharing_Code__c == 'U003'
			         || opp.Sharing_Code__c ==  'U004' || opp.Sharing_Code__c == 'U005') &&  opp.Fund__c.contains('LGRP')) {
			C4budgetCategory = 'Bequests - LGBT';
		}

		else If(opp.Sharing_Code__c == 'U001') {
			C4budgetCategory = 'Bequests - General 40/40/20';
		}
		else If(opp.Sharing_Code__c == 'U002') {
			C4budgetCategory = 'Bequests - General 90/10';
		}
		else If(opp.Sharing_Code__c == 'U003') {
			C4budgetCategory = 'Bequests - General 50/50';
		}
		else If(opp.Sharing_Code__c == 'U004') {
			C4budgetCategory = 'Bequests - General 100';
		}
		else If(opp.Sharing_Code__c == 'U005') {
			C4budgetCategory = 'Bequests - General Other';
		}
		else If(opp.Sharing_Code__c == 'C171') {
			C4budgetCategory = 'Shared - General Union Memorial/Tribute';
		}
		else {
			C4budgetCategory = 'Unbudgeted - ' + opp.Fund__c + ' - ' + opp.Sharing_Code_Description__c;
		}
		return C4budgetCategory;

	}

	public static National_Budget__c getSummaryLabel(Opportunity opp, National_Budget__c nb) {
		if (opp.Sharing_Code__c == 'E181' || opp.Sharing_Code__c == 'R818') {
			nb.Summary_Label__c = 'InKind Gifts';
		} else if (opp.Fundraising_Department__c == 'Foundation Relations') {
			if (nb.Budget_Category__c != null && nb.Budget_Category__c.startsWith('Centennial Campaign')) {
				if (nb.Tax_Designation__c == 'Union') {
					nb.Summary_Label__c = 'Foundation C4 Centennial';
				} else {
					nb.Summary_Label__c = 'Foundation C3 Centennial';
				}
			} else {
				if (nb.Tax_Designation__c == 'Union') {
					nb.Summary_Label__c = 'Foundation C4 Annual';
				} else {
					nb.Summary_Label__c = 'Foundation C3 Annual';
				}
			}
		} else if (opp.Fundraising_Department__c == 'Leadership Gifts') {
			if (nb.Budget_Category__c != null && nb.Budget_Category__c.startsWith('Centennial Campaign')) {
				if (nb.Tax_Designation__c == 'Union') {
					nb.Summary_Label__c = 'Leadership Gifts C4 Centennial';
				} else {
					nb.Summary_Label__c = 'Leadership Gifts C3 Centennial';
				}
			} else if (nb.Budget_Category__c != null && nb.Budget_Category__c.startsWith('LFF Campaign')) {
				nb.Summary_Label__c = 'Leadership Gifts LFF Campaign';
			} else {
				if (nb.Tax_Designation__c == 'Union') {
					nb.Summary_Label__c = 'Leadership Gifts C4 Annual';
				} else {
					nb.Summary_Label__c = 'Leadership Gifts C3 Annual';
				}
			}
		} else if (opp.Fundraising_Department__c == 'Membership' || opp.Fundraising_Department__c == 'Annual Fund'
		           || opp.Fundraising_Department__c == 'Strategic Partnerships') {
			nb.Summary_Label__c = 'Membership C4 Annual';
		} else if (opp.Fundraising_Department__c == 'Planned Giving') {
			if (nb.Budget_Category__c.contains('Endowment')) {
				if (nb.Tax_Designation__c == 'Union') {
					nb.Summary_Label__c = 'Planned Giving Endowment C4';
				} else {
					nb.Summary_Label__c = 'Planned Giving Endowment C3';
				}
			} else {
				if (nb.Tax_Designation__c == 'Union') {
					nb.Summary_Label__c = 'Planned Giving C4';
				} else {
					nb.Summary_Label__c = 'Planned Giving C3';
				}
			}
		} else if (opp.Fundraising_Department__c == 'Special Gifts' || opp.Fundraising_Department__c == 'Mid + Major Gifts') {
			if (nb.Tax_Designation__c == 'Union') {
				nb.Summary_Label__c = 'Special Gifts C4 Annual';
			} else {
				nb.Summary_Label__c = 'Special Gifts C3 Annual';
			}
		}
		return nb;
	}
	
	public static void updateReportStatus(Boolean flag) {
		
		National_Budget_Report_Status__c nbrs;
		if(National_Budget_Report_Status__c.getOrgDefaults()!=null)
		nbrs = National_Budget_Report_Status__c.getOrgDefaults();
		/*Validating and updating Report_Request_In_Progress__c=true */
		if (flag) {
			nbrs.Report_Request_In_Progress__c = flag;
			//nbrs.Sender_Email__c = userEmailId;
		} else  {
			nbrs.Report_Request_In_Progress__c = flag;
		}/*resetting the custom setting*/
		upsert nbrs;

	}
}