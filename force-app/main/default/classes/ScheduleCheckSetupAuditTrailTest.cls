/*
 * Created by davidseidman on 5/1/18.
 */

@isTest
private class ScheduleCheckSetupAuditTrailTest {

	public static User user1 = TestUtils.createSysAdminUser('System Administrator');
    public static PermissionSet testPS = new PermissionSet(PermissionsViewEncryptedData = true, Name = 'testViewEncryptedPS', Label = 'testViewEncryptedPS');

	@isTest
	private static void testScheduleCheckSetupAuditTrail()
		{
            			insert testPS;

            insert user1;

			test.startTest();

			PermissionSetAssignment PSA = new PermissionSetAssignment(PermissionSetId = testPS.Id, AssigneeId = user1.Id);
			insert PSA;
			ScheduleCheckSetupAuditTrail S= new ScheduleCheckSetupAuditTrail();
			String sch = '0 0 23 * * ?';
			system.schedule('Test check', sch, S);
			test.stopTest();

		}


}