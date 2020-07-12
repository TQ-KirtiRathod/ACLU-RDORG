/**
 * Test Class for UserTriggerHandler
 **/
 @isTest
private class UserTriggerHandlerTEST {
    @isTest private static void testWhitelist() {
        User u;
        Id profileId = UserInfo.getProfileId();
        
        list<User> userList = new list<User>();
        for(Integer i = 0; i<5; i++) {
        	u = TestUtils.createUser('Z'+i, 'test'+ i + '@aclu.org', null, false);
        	u.Email = 'test'+ i + '@aclu.org';
        	userList.add(u);
        }
        insert userList; // Should succeed.
        
        u = TestUtils.createUser('R', 'test@trash.com', null, false);
        u.Email = 'test@trash.com';
        
        Database.SaveResult[] srs = Database.insert(new List<User>{u}, false);

        System.assertEquals(false, srs[0].isSuccess());
        System.assertEquals(1, srs[0].getErrors().size());
        System.assert(srs[0].getErrors()[0].getMessage().contains('approved'));
    }
}