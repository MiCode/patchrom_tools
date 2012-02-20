import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.Writer;
import java.util.ArrayList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import com.sun.org.apache.xml.internal.serialize.OutputFormat;
import com.sun.org.apache.xml.internal.serialize.XMLSerializer;

import java.util.regex.Pattern;
import java.util.regex.Matcher;

public class XMLMerge {
    private ArrayList<File> mSrcFiles;
    private ArrayList<File> mDestFiles;

    public static final int MERGE_MATCH_ALL = 0;
    public static final int MERGE_DONT_NEED_MERGE = 1;
    public static final int MERGE_DONT_FIND_DEST_FILE = 2;
    public static final int MERGE_EXCEPTION = 3;
    public static final int MERGE_ADD_ELEMENT = 4;
    public static final int MERGE_MODIFY_ELEMENT = 5;
    public static final int MERGE_FAILED = 6;
    
    public XMLMerge(ArrayList<File> srcFiles, ArrayList<File> destFiles) {
        mSrcFiles = srcFiles;
        mDestFiles = destFiles;
    }

    public void merge() {
        for (int i = 0; i < mSrcFiles.size(); i++) {
            mergeFile(mSrcFiles.get(i));
        }
    }

    private void mergeFile(File file) {
        try {
            DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
            DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
            Document doc = dBuilder.parse(file);

            Element root = adjustMergeRoot(doc);
            if (null == root) {
                return;
            }

            //System.out.println("***************START MERGE***********");
            //System.out.println("SRC XML FILE: " + file.getName());

            traverseMergeXML(root, file);
            //System.out.println("---------------END   MERGE-----------");
            //System.out.println();
            //System.out.println();

        } catch (Exception e) {
            e.printStackTrace();
        }
        return;
    }

    private Element adjustMergeRoot(Document doc) {
        Element root = doc.getDocumentElement();
        if (true == hasNode("/resources/string-array", doc)) {
            // System.out.println("Node find :xmlns:xliff");
            root = adjustStringArrayMergeRoot(doc);
        } else if (true == hasNode("/resources/add-resource", doc)) {
            // System.out.println("IS ADD RESOURCES");
            root = adjustAddResources(doc);
        } else if (true == hasNode("/resources/style", doc)) {
            root = adjustStyleRoot(doc);
        } else {
        }
        return root;
    }

    private Element adjustStringArrayMergeRoot(Document doc) {
        NodeList nList = doc.getElementsByTagName("resources");
        Element root = (Element) nList.item(0);
        root.removeAttribute("xmlns:xliff");
        nList = root.getElementsByTagName("xliff:g");

        ArrayList<String> vals = new ArrayList<String>();
        Node papa = nList.item(0).getParentNode().getParentNode();

        while (root.getElementsByTagName("xliff:g").getLength() != 0) {
            vals.add(nList.item(0).getTextContent());
            nList.item(0).getParentNode().getParentNode().removeChild(nList.item(0).getParentNode());
        }

        for (int i = 0; i < vals.size(); i++) {
            Element e = doc.createElement("item");
            e.appendChild(doc.createTextNode(vals.get(i)));
            papa.appendChild(e);
        }
        return root;
    }

    private Element adjustStyleRoot(Document doc) {

        return doc.getDocumentElement();
    }

    private Element adjustAddResources(Document doc) {

        return doc.getDocumentElement();
    }

    private int mergeNode(Node node) {
        String xpathStr = getXpathStr(node);
        String textContent = node.getTextContent();
        //System.out.println();
        //System.out.println(xpathStr + ":" + node.getTextContent());

        if (xpathStr.contains("/resources/add-resource")) {
            //System.out.println("DONT NEED TO ADD ELEMENT: add-resource");
            return MERGE_DONT_NEED_MERGE;
        }

        File destFile = getDestFile(xpathStr);
        if (null == destFile) {
            //System.out.println("DEST FILE: DONT FOUND");
            return MERGE_DONT_FIND_DEST_FILE;
        }

        //System.out.println("DEST FILE --> " + destFile.getName());

        return mergeNodeToDestFile(xpathStr, textContent, destFile);
    }

    private int mergeNodeToDestFile(String xpathStr, String textContent, File destFile) {
        String tryMatchStr = new String(xpathStr);
        try {
            DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
            DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
            Document doc = dBuilder.parse(destFile);
            doc.getDocumentElement().normalize();
            
            String rootName = doc.getDocumentElement().getNodeName();  
            //matching until trymatchStr back to root or tryMatchStr is null
            while (null != tryMatchStr && false == tryMatchStr.equals("/" + rootName)) {    
                XPathFactory factory = XPathFactory.newInstance();
                XPath xpath = factory.newXPath();
                XPathExpression expr = xpath.compile(tryMatchStr);
                NodeList nList = (NodeList) expr.evaluate(doc, XPathConstants.NODESET);

                if (null != nList && 0 != nList.getLength()) {  //find a match, merge node to file 
                    String lostMatchStr = new String(xpathStr);
                    //System.out.println(getLineNumberString(new Exception()) + "Match: " + tryMatchStr);

                    if (true == xpathStr.equals(tryMatchStr)) {     //if absXpathStr is found in xml fine, write it into file directly
                        String subStr = tryMatchStr.substring(tryMatchStr.lastIndexOf('/') + 1);
                        if (true == subStr.contains("[@")) {    //if the element contain Attribute, just need to modify the element's textcontent
                            if(nList.item(0).getTextContent().equals(textContent)){
                                //System.out.println(getLineNumberString(new Exception()) + "ALL MATCH");
                                return MERGE_MATCH_ALL;
                            }else{
                                //System.out.println(getLineNumberString(new Exception()) + "MODIFY TEXTCONTENT: "
                                //        + nList.item(0).getTextContent() + " -> " + textContent);
                                nList.item(0).setTextContent(textContent);
                                writeXML(doc, destFile);
                                return MERGE_MODIFY_ELEMENT;
                            }
                        } else {    //element don't contain attriute, check if or not exist element with same textcontent  
                            Node papa = nList.item(0).getParentNode();
                            String nodeName = nList.item(0).getNodeName();
                            for (int i = 0; i < nList.getLength(); i++) {
                                if (nList.item(i).getTextContent().equals(textContent)) {
                                    //System.out.println(getLineNumberString(new Exception()) + "ALL MATCH");
                                    return MERGE_MATCH_ALL;
                                }
                            }
                            Element e = doc.createElement(nodeName);
                            papa.appendChild(e);
                            e.setTextContent(textContent);
                            writeXML(doc, destFile);
                            //System.out.println(getLineNumberString(new Exception()) + "ADD ELEMENT: " + getXpathStr(e) + ":" + textContent);
                            return MERGE_ADD_ELEMENT;
                        }
                    } else {
                        lostMatchStr = lostMatchStr.replace(tryMatchStr, "");
                    }

                    // System.out.println(getLineNumberString(new Exception()) +
                    // "LostMatch: " + lostMatchStr);

                    //match a part of absXpathStr 
                    if (true == lostMatchStr.startsWith("/")) {     
                        return addNode(doc, (Element) (nList.item(0)), destFile, lostMatchStr, textContent);
                    } else if (true == lostMatchStr.startsWith("[@")){
                        String attrName = lostMatchStr.substring(lostMatchStr.indexOf('@') + 1, lostMatchStr.indexOf('='));
                        lostMatchStr = lostMatchStr.replaceFirst("\'", "");
                        String attrContent = lostMatchStr.substring(lostMatchStr.indexOf('=') + 1, lostMatchStr.indexOf('\''));
                        String nodeName = nList.item(0).getNodeName();
                        Element e = doc.createElement(nodeName);
                        e.setAttribute(attrName, attrContent);
                        nList.item(0).getParentNode().appendChild(e);
                        if (lostMatchStr.indexOf('/') < 0) {
                            e.appendChild(doc.createTextNode(textContent));
                            writeXML(doc, destFile);
                            //System.out.println(getLineNumberString(new Exception()) + "ADD ELEMENT: " + getXpathStr(e) + ":" + textContent);
                            return MERGE_ADD_ELEMENT;
                        } else {
                            return addNode(doc, e, destFile, lostMatchStr.substring(lostMatchStr.indexOf('/')), textContent);
                        }
                    }else{
                        //System.out.println(getLineNumberString(new Exception()) + "INVAILD ELEMENT");
                    }
                }
                tryMatchStr = getUpperXpathStr(tryMatchStr);
                // System.out.println(getLineNumberString(new Exception()) +
                // "TryMatch: " + tryMatchStr);
            }
        } catch (Exception e) {
            e.printStackTrace();
            return MERGE_EXCEPTION;
        }
        return MERGE_FAILED;
    }

    private int addNode(Document doc, Element element, File destFile, String xpathStr, String textContent) {
        String tmp = new String(xpathStr);
        while (tmp.indexOf('/') > -1) {     //do until there is no element
            tmp = tmp.replaceFirst("/", "");
            if (tmp.indexOf('/') > -1) {    //this is not the last element
                String subTmp = tmp.substring(0, tmp.indexOf('/'));
                if (subTmp.contains("[@")) {    //element contains a Attributes
                    String nodeName = new String(subTmp.substring(0, subTmp.indexOf('[')));
                    String attrName = new String(subTmp.substring(subTmp.indexOf('@') + 1, subTmp.indexOf('=')));
                    String attrContent = new String(subTmp.substring(subTmp.indexOf('\'') + 1, subTmp.lastIndexOf('\'')));

                    Element subElement = doc.createElement(nodeName);
                    subElement.setAttribute(attrName, attrContent);
                    element.appendChild(subElement);
                    element = subElement;
                } else {
                    String nodeName = new String(subTmp);
                    Element subElement = doc.createElement(nodeName);
                    element = subElement;
                }
                tmp = tmp.substring(tmp.indexOf('/'));
            } else {
                String subTmp = tmp;
                if (subTmp.contains("[@")) {    //element contains a Attributes
                    String nodeName = new String(subTmp.substring(0, subTmp.indexOf('[')));
                    String attrName = new String(subTmp.substring(subTmp.indexOf('@') + 1, subTmp.indexOf('=')));
                    String attrContent = new String(subTmp.substring(subTmp.indexOf('\'') + 1, subTmp.lastIndexOf('\'')));
                    
                    Element subElement = doc.createElement(nodeName);
                    subElement.setAttribute(attrName, attrContent);
                    element.appendChild(subElement);
                    element = subElement;
                } else {
                    String nodeName = new String(subTmp);

                    Element subElement = doc.createElement(nodeName);
                    element = subElement;
                }
                element.appendChild(doc.createTextNode(textContent));
                writeXML(doc, destFile);
                //System.out.println(getLineNumberString(new Exception()) + "ADD ELEMENT: " + getXpathStr(element) + ":" + textContent);
                return MERGE_ADD_ELEMENT;
            }
        }
        return MERGE_FAILED;
    }

    private File getDestFile(String xpathStr) {
        if (null == xpathStr) {
            return null;
        }
        try {
            while (null != xpathStr && false == xpathStr.equals("/resources")) {
                XPathFactory factory = XPathFactory.newInstance();
                XPath xpath = factory.newXPath();
                XPathExpression expr = xpath.compile(xpathStr);
                for (int i = 0; i < mDestFiles.size(); i++) {
                    DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
                    DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
                    Document doc = dBuilder.parse(mDestFiles.get(i));
                    doc.getDocumentElement().normalize();
                    NodeList nList = (NodeList) expr.evaluate(doc, XPathConstants.NODESET);
                    if (null != nList && 0 != nList.getLength()) {
                        return mDestFiles.get(i);
                    }
                }
                xpathStr = getUpperXpathStr(xpathStr);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private String getUpperXpathStr(String xpathStr) {
        if ((xpathStr != null) && (xpathStr.length() > 0)) {
            int pos1 = xpathStr.lastIndexOf(']');
            int pos2 = xpathStr.lastIndexOf('[');
            int pos3 = xpathStr.lastIndexOf('/');
            if (pos1 > -1 && pos2 > -1 && pos3 > -1 && pos1 > pos2 && pos2 > pos3) {
                return xpathStr.substring(0, pos2);
            } else if (pos3 > pos1) {
                return xpathStr.substring(0, pos3);
            } else {

            }
        }
        return null;
    }

    private boolean hasNode(String xpathStr, Document doc) {
        try {
            XPathFactory factory = XPathFactory.newInstance();
            XPath xpath = factory.newXPath();
            XPathExpression expr = xpath.compile(xpathStr);

            NodeList nList = (NodeList) expr.evaluate(doc, XPathConstants.NODESET);
            if (null != nList && 0 != nList.getLength()) {
                return true;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public void traverseMergeXML(Node node, File file) {
        if (true == isElementLeaf(node)) {
            switch(mergeNode(node)){
            case MERGE_ADD_ELEMENT:
            case MERGE_MODIFY_ELEMENT:
            case MERGE_DONT_NEED_MERGE:
                break;
                
            case MERGE_DONT_FIND_DEST_FILE:
                System.out.println("  " + "{" + file.getName() + "}" + " DONT FIND DEST FILE: " + getXpathStr(node));
                break;
                
            case MERGE_FAILED:                
            case MERGE_EXCEPTION:
                System.out.println("  " + "{" + file.getName() + "}" + " MERGE FAILED: " + getXpathStr(node));
                break;
                
            default:
                break;
            }
        }
        // Now traverse the rest of the tree in depth-first order.
        if (node.hasChildNodes()) {
            NodeList nList = node.getChildNodes();
            int size = nList.getLength();
            for (int i = 0; i < size; i++) {
                // Recursively traverse each of the children.
                traverseMergeXML(nList.item(i), file);
            }
        }
    }

    private boolean isElementLeaf(Node node) {
        if (null == node) {
            return false;
        }

        if (Node.ELEMENT_NODE == node.getNodeType()) {
            if (true == node.hasChildNodes()) {
                NodeList sonList = node.getChildNodes();
                for (int i = 0; i < sonList.getLength(); i++) {
                    if (Node.ELEMENT_NODE == sonList.item(i).getNodeType()) {
                        return false;
                    }
                }
            }
            return true;
        } else {
            return false;
        }
    }

    private void writeXML(Document doc, File file) {
        try {
            OutputFormat format = new OutputFormat(doc);
            format.setIndenting(true);
            format.setIndent(4);
            Writer output = new BufferedWriter(new FileWriter(file));
            XMLSerializer serializer = new XMLSerializer(output, format);
            serializer.serialize(doc);
            // System.out.println("Write Xml File");

        }catch (Exception e) {
            e.printStackTrace();
        }
    }

    public String getXpathStr(Node node) {
        String xpathStr = "";
        while (null != node) {
            if (true == node.hasAttributes()) {
                xpathStr = "/" + node.getNodeName() + "[@" + node.getAttributes().item(0).getNodeName() 
                        + "='" + node.getAttributes().item(0).getNodeValue() + "']" + xpathStr;

            } else {
                xpathStr = "/" + node.getNodeName() + xpathStr;
            }

            node = node.getParentNode();
        }
        xpathStr = "/" + xpathStr;
        //System.out.println("pre: " + xpathStr);

        ArrayList<String> subStrArray = new ArrayList<String>();
        subStrArray.add("//#document");
        subStrArray.add("android:");
        xpathStr = delSubString(xpathStr, subStrArray);

        //System.out.println("post:" + xpathStr);
        return xpathStr;
    }

    public String delSubString(String str, ArrayList<String> subStrArray) {
        for (int i = 0; i < subStrArray.size(); i++) {
            if (str.contains(subStrArray.get(i))) {
                str = str.replace(subStrArray.get(i), "");
            }
        }
        return str;
    }

    public static String getLineNumberString(Exception e) {
        StackTraceElement[] trace = e.getStackTrace();
        if (trace == null || trace.length == 0) {
            return "ERROR: -1";
        }
        // return new String("LINE" + String.format("%d", trace[0].getLineNumber()) + "--> ");
        return new String("");
    }

    public static int getLineNumber(Exception e) {
        StackTraceElement[] trace = e.getStackTrace();
        if (trace == null || trace.length == 0) {
            return -1;
        }
        return trace[0].getLineNumber();
    }
}
