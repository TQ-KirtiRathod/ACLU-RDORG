public class BatchUpload_CreateSoftCreditScheduler implements System.Schedulable {
	public void execute(System.SchedulableContext sc) {
		Database.executeBatch(new BatchUpload_CreateSoftCreditBatch(), 200);
    }
}