import java.io.File;
import java.util.ArrayList;

public class ResValuesModify {
    private ArrayList<File> mSrcFiles = new ArrayList<File>();
    private ArrayList<File> mDestFiles = new ArrayList<File>();
    private ArrayList<File> mConfigFiles = new ArrayList<File>();
    private static final String LOG_TAG = "CHECK";

    public static void main(String[] args) {
        ResValuesModify resVM = new ResValuesModify();
        if (!resVM.checkArgs(args) || !resVM.checkPath(args)) {
            resVM.usage();
            return;
        }
        resVM.mergeXML();
    }

    private boolean checkArgs(String[] args) {
        boolean ret = true;
        if (args.length < 2) {
            Log.e(LOG_TAG, "invalid argument count");
            return false;
        }

        if (args[0].equals(args[1])) {
            Log.e(LOG_TAG, "src dir is the same with dest dir");
            ret = false;
        }

        for (int i = 2; i < args.length; i++) {
            File f = new File(args[i]);
            if (f.exists() && f.isFile()) {
                mConfigFiles.add(f);
            } else {
                Log.i(LOG_TAG, "ignore config file:" + f.getName());
            }
        }
        return ret;
    }

    private boolean checkPath(String[] args) {
        return perpareXmlFiles(args[0], mSrcFiles) && perpareXmlFiles(args[1], mDestFiles);
    }

    private void mergeXML() {
        (new XMLMerge(mSrcFiles, mDestFiles, mConfigFiles)).merge();
    }

    private void usage() {
        Log.i("USAGE: ");
        Log.i("ResValuesModify src-values-dir dest-values-dir [config-files ...]");
        Log.i("    config-files: config file that explicitly declare merge-rule");
        Log.i("");
    }

    private boolean perpareXmlFiles(String path, ArrayList<File> xmlFiles) {
        File dir = new File(path);
        if (!dir.isDirectory()) {
            Log.w(LOG_TAG, path + " : no such directory");
            return false;
        }

        File[] files = dir.listFiles();
        for (File f : files) {
            if (f.isFile()) {
                if (f.getName().endsWith(".xml") || f.getName().endsWith(".xml.part")) {
                    xmlFiles.add(f);
                }
            }
        }

        if (0 == xmlFiles.size()) {
            Log.w(LOG_TAG, "No xml file in " + path);
            return false;
        }
        return true;
    }
}
