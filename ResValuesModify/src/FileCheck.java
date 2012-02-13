import java.io.File;
import java.util.ArrayList;


public class FileCheck {
	public static boolean getXmlFiles(String Path, ArrayList<File> fileArray){
		ResultRecord result = ResultRecord.create();
		File  dir = new File(Path);
		if(true != dir.isDirectory()){
			result.addRecord(Path + ResultRecord.IS_NOT_DIR);
			return false;
		}
		
		File[] files = dir.listFiles();
		for(File f : files){
			if(true == f.isFile()){
				if(true == getExtensionName(f.getName()).equals("xml")){
					fileArray.add(f);
				}
			}else{
				result.addRecord(f.getName() + ResultRecord.IS_NOT_XML);
			}
		}
		
		if(0 == fileArray.size()){
			result.addRecord(Path + ResultRecord.NO_XML_FILES);
			return false;
		}
		
		return true;
	}
	
    public static String getExtensionName(String filename) {   
        if ((filename != null) && (filename.length() > 0)) {   
            int dot = filename.lastIndexOf('.');   
            if ((dot >-1) && (dot < (filename.length() - 1))) {   
                return filename.substring(dot + 1);   
            }   
        }   
        return filename;   
    }
}
