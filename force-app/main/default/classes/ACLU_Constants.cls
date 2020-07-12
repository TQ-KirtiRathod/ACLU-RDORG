/*
*
*Name  :  ACLU_Constants
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  April 14, 2017
*Purpose : Contains static constants to be used in other classes
*
*/
public class ACLU_Constants {
    // Opportunity Stages
	public static final String CONST_OPPTY_STAGE_OPEN = 'Open';
    public static  final String CONST_OPPTY_STAGE_COMPLETED = 'Completed'; 


    //test 1
    // Opportunity Matching Status
    public static final String t2 = 't21';
    // Testing Constant class updates
    public static final String CONST_MATCHING_STATUS_POTENTIAL = 'Potential';
    public static final String CONST_MATCHING_STATUS_MATCHED = 'Matched';
    // @@ >> -- james appirio branch - testing prod tag now try 11
    // Opportunity Record Type Names 
    public static final String CONST_RCDTYPE_PLEDGE_PAYMENT = 'Pledge Payment';
    public static final String CONST_RCDTYPE_PLEDGE = 'Pledge';
    public static final String CONST_RCDTYPE_TRANSACTION = 'Transaction';
    public static final String CONST_RCDTYPE_DONATION = 'Donation';
    public static final String CONST_RCDTYPE_SOFTCREDIT = 'Soft Credit';
    public static final String CONST_RCDTYPE_ADJUSTMENT = 'Adjustment';
    public static final String CONST_RCDTYPE_PROPOSAL = 'Proposal';
    
    // Opportunity Transaction Types
    public static final String CONST_TRANSACTYPE_PAYMENT = 'Payment';
    
    // Soft Credit Types
    public static final String CONST_SCTYPE_MATCHING_CONT = 'MC - Matching contribution';
    public static final String CONST_SCTYPE_WORKPLACE_GIVING = 'WG - Workplace Giving';
    public static final String CONST_SCTYPE_GIFT_MEMBERSHIP = 'GF - Gift Membership';
    
    // Account Types
    public static final String CONST_ACCTYPE_MATCHING_COMPANY = 'Matching Company';
    public static final String CONST_ACCTYPE_WORKPLACE_GIVING_ORG = 'Workplace Giving Organization';
    
    // Relationship Roles
    public static final String CONST_ROLE1_DONOR = 'Donor';
    public static final String CONST_ROLE1_EMPLOYEE = 'Employee';
    public static final String CONST_ROLE2_MATCHING_COMPANY = 'Matching Gift Company';
    public static final String CONST_ROLE2_EMPLOYER = 'Employer';
    public static final String CONST_CATEGORY_EMPLOYMENT = 'Employment';
    
    //BatchLog Record Type Names
    public static final String CONST_RCDTYPE_MANUAL = 'Manual';
    public static final String CONST_RCDTYPE_VENDOR = 'Vendor';
    public ACLU_Constants(){}
}