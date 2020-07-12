/*
*
*Name  :  LimitsHistoryHandler
*Author:  ACLU  (davidseidman)
*Date  :  April 09, 2018
*Purpose : Check for a permission set has View Encrypted Data = true and identify users; this will account for both permission sets and 
*          profiles that have had the View Encrypted Data permission set to true. Idenitfy users who made changes to enable users to have 
*          Encrypted Data permissions. Identify users with Encrypted Data permissions. Send email with data
*
*/
global class ScheduleCheckSetupAuditTrail implements Schedulable {
   global void execute(SchedulableContext SC) {
      setupAuditTrailCheck(); 
   }


    
    public static String permissionSetAssignmentViewEncryptedQuery;
    public static String profileViewEncryptedQuery;
    public static String usersWithProfileViewEncryptedQuery;
    public static String emailText = '';
    public static Set<Id> profilesWithEncrypt;
    public static Map<Id,User> auditedUserMap;
    public static Map<Id,Datetime> auditedUserTimeMap;
    public static Map<Id,User> adminUserMap;
    public static Map<Id,List<Id>> adminUserToAuditUserMap;
    public static Integer setupAuditTrailLookBack = 1;  // days worth of change to alert
    public static Datetime lookback = Datetime.now() - setupAuditTrailLookBack;

    // EMAIL PARAMETERS HERE
    public static List<String> toAddresses;
    public static String emailSubject;
    public static String emailIntro;
    public static String haveEncryption;
    public static String permissionActions;
    public static String sectionDelimiter;

    //TODO optionally later
    // String userPermissionActions = 'USER ASSIGNMENTS RESULTING IN ENCRYPTED DATA PERMISSION GRANTS';

    public void setupAuditTrailCheck() {

        permissionSetAssignmentViewEncryptedQuery =
                'SELECT p.Id, p.Assignee.Name,p.Assignee.IsActive, p.Assignee.Profile.Name, p.PermissionSet.Label, p.PermissionSet.lastmodifieddate  FROM PermissionSetAssignment p WHERE p.PermissionSet.PermissionsViewEncryptedData = true';
        // profileViewEncryptedQuery = 'SELECT Id FROM Profile where PermissionsViewEncryptedData = true';
        // usersWithProfileViewEncryptedQuery = 'Select Id, Name from User where ProfileId in :profilesWithEncrypt';
        List<SetupAuditTrail> setupAudits = new List<SetupAuditTrail>();
        auditedUserMap = new Map<Id,User>();
        auditedUserTimeMap = new Map<Id,Datetime>();
        adminUserMap = new Map<Id,User>();
        adminUserToAuditUserMap = new Map<Id,List<Id>>();
        getUsersWithEncryption();

        if (!auditedUserMap.isEmpty()) {
            configureEmail();
            emailText += (emailIntro + '\n');

            // still need to create the map betewen audit record and users impacted...for now...
            emailText += sectionDelimiter + haveEncryption + sectionDelimiter;
            for (User u : auditedUserMap.values()) {
                Datetime auditTime = auditedUserTimeMap.get(u.Id);
                emailText += u.name + ' - ' +  u.Id +') - ' + u.Profile.Name + ' - ' + auditTime + '\n';
            }

            emailText += sectionDelimiter + permissionActions + sectionDelimiter;

            setupAudits = [ SELECT Action,CreatedById,CreatedBy.Name,CreatedDate,DelegateUser,Display,Id,ResponsibleNamespacePrefix,Section FROM SetupAuditTrail where (action =  'PermSetEnableUserPerm' or action = 'profilePermChangedCustom' or action = 'PermSetAssign') and CreatedDate  > :lookback];
            for (SetupAuditTrail audit : setupAudits) {
                Integer displaySize = audit.Display.length();
                String truncDisplay = audit.Display.substring(0,displaySize);
                if (truncDisplay.indexOf('View Encrypted Data') != -1 && truncDisplay.indexOf('disabled to enabled') != -1) {
                    emailText += audit.CreatedDate + ' - ' + audit.CreatedBy.Name  + ' - ' + audit.Display + '\n';
                }
            }

            /* TODO later potentially
             * output the relevant permission assignment activities
             */
            
            /* emailText += '\n' + userPermissionActions + sectionDelimiter;

            for (SetupAuditTrail audit : setupAudits) {
                if (audit.action == 'PermSetAssign') {
                    Integer displaySize = audit.Display.length();
                    String truncDisplay = audit.Display.substring(0, displaySize - 1);
                     // FOR EACH PERMISSION SET CHANGED
                    if (truncDisplay.indexOf(<permission set name>) != -1) {
                        emailText += audit.CreatedDate + ': ' + audit.CreatedBy.Name + ': ' + audit.Display + '\n';
                    }
                }
            }
            */
        }
        if (emailText != '') {
            Messaging.SingleEmailMessage  mail = new Messaging.SingleEmailMessage ();
            setToAddresses();
            mail.setToAddresses(toAddresses);
            mail.setPlainTextBody(emailText);
            mail.setSubject(emailSubject);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        }
    }

    public void getUsersWithEncryption() {
        for (PermissionSetAssignment psa : Database.query(permissionSetAssignmentViewEncryptedQuery)) {
            auditedUserMap.put(psa.AssigneeId, psa.Assignee);
            auditedUserTimeMap.put(psa.AssigneeId, psa.PermissionSet.lastmodifieddate );
        }
    }

    public void setToAddresses() {
        List<User> queueUsers = [SELECT Email FROM User WHERE Id IN (
            SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Security_Alerts'
        )];
        Set<String> uniqueEmails = new Set<String>();

        if (!queueUsers.isEmpty()) {
            for (User user : queueUsers) uniqueEmails.add(user.Email);
            toAddresses = new List<String>(uniqueEmails);
        }
    }

    public static void configureEmail() {
        emailSubject = 'Setup Audit Trail Report: Potential Access to Encrypted Data';
        emailIntro = 'Setup Audit Trail data changes in the past 24 hours which may have potentially allowed access to encrypted data\n';
        haveEncryption = 'USERS WHO CURRENTLY HAVE VIEW ENCRYPTED DATA PERMISSION\nName - Id - Profile - Permissions Last Changed';
        permissionActions = 'CHANGES TO PERMISSION SETS AND PROFILES RESULTING IN ENCRYPTED DATA PERMISSION GRANTS\nTimestamp - User - Audited Activity';
        sectionDelimiter = '\n--------------------------------------------------\n';
    }


}