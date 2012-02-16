import java.io.File;
import java.util.ArrayList;

public class ResValuesModify {
    private ArrayList<File> mSrcFileArray;
    private ArrayList<File> mDestFileArray;

    public static void main(String[] args) {
        ResValuesModify resVM = new ResValuesModify();
        boolean bRet = resVM.parseCommandLine(args);
        if (false == bRet) {
            return;
        }

        bRet = resVM.pathCheck(args);
        if (false == bRet) {
            return;
        }
        resVM.mergeXML();
    }

    public ResValuesModify() {
        mSrcFileArray = new ArrayList<File>();
        mDestFileArray = new ArrayList<File>();
    }

    public String delPrefixString(String src, String needDel) {
        return null;
    }

    private boolean parseCommandLine(String[] args) {
        if (2 != args.length) {
            usage();
            return false;
        }

        if (args[0].equals(args[1])) {
            System.out.println("ERROR: src dir is the same with dest dir");
            usage();
            return false;
        }
        return true;
    }

    private boolean pathCheck(String[] args) {
        boolean bRet = FileCheck.getXmlFiles(args[0], mSrcFileArray);
        if (false == bRet) {
            usage();
            return false;
        }
        bRet = FileCheck.getXmlFiles(args[1], mDestFileArray);
        if (false == bRet) {
            usage();
            return false;
        }
        /*
        System.out.println("###################################################");
        System.out.println("*** Source Files: ***********");
        for (int i = 0; i < mSrcFileArray.size(); i++) {
            System.out.println("\t" + mSrcFileArray.get(i).getName());
        }
        System.out.println("------------------------------------------------");
        System.out.println("*** Destination Files: ******");
        for (int i = 0; i < mDestFileArray.size(); i++) {
            System.out.println("\t" + mDestFileArray.get(i).getName());
        }
        System.out.println("###################################################");
        */

        return true;
    }

    private void mergeXML() {
        XMLMerge xmlMerge = new XMLMerge(mSrcFileArray, mDestFileArray);
        xmlMerge.merge();
    }

    private void usage() {
        System.out.println("usage: ResValuesModify $1 $2");
        System.out.println("\t$1: Miui values dir");
        System.out.println("\t$2: ThirdParty values dir");
    }
}
