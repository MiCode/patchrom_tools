import java.io.File;
import java.util.ArrayList;

public class FileCheck {
    
    public static final String IS_NOT_DIR = "  is not folder";
    public static final String IS_NOT_XML = "  is not xml file";
    public static final String NO_XML_FILES = "   no xml files in this folder";
    public static final String MERGE_FAILED = "   merge element failed";
    
    public static boolean getXmlFiles(String Path, ArrayList<File> fileArray) {        
        File dir = new File(Path);
        if (true != dir.isDirectory()) {
            System.out.println("ERROR: " + Path + IS_NOT_DIR);
            return false;
        }

        File[] files = dir.listFiles();
        for (File f : files) {
            if (true == f.isFile()) {
                //if (true == getExtensionName(f.getName()).equals("xml")) {
                if(true == f.getName().endsWith(".xml") || true == f.getName().endsWith(".xml.part")){
                    fileArray.add(f);
                }
            } else {
                //System.out.println("WARNING" + f.getName() + IS_NOT_XML);
            }
        }

        if (0 == fileArray.size()) {
            System.out.println(Path + NO_XML_FILES);
            return false;
        }

        return true;
    }

    public static String getExtensionName(String filename) {
        if ((filename != null) && (filename.length() > 0)) {
            int dot = filename.lastIndexOf('.');
            if ((dot > -1) && (dot < (filename.length() - 1))) {
                return filename.substring(dot + 1);
            }
        }
        return filename;
    }
}
