import java.util.ArrayList;

public class ResultRecord {
	
	private static ResultRecord mResultInstance = null;
	
	public static final String IS_NOT_DIR = " :is not folder";
	public static final String IS_NOT_XML = " :is not xml file";
	public static final String NO_XML_FILES = " : no xml files in this folder";
	public static final String MERGE_FAILED = " : merge element failed";
	
	private ArrayList<String> mResult;
	
	private ResultRecord() {
		mResult = new ArrayList<String>();
	}
	
	public static ResultRecord create(){
		if(null == mResultInstance){
			mResultInstance = new ResultRecord();	
		}
		return mResultInstance;
	}
	
	public void addRecord(String s) {
		mResult.add(s);
	}

	public void printResult(){
		for(int i = 0; i < mResult.size(); i ++){
			System.out.println(mResult.get(i));	
		}		
	}
}
