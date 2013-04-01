import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;

import javax.xml.parsers.DocumentBuilderFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.Text;

import com.sun.org.apache.xml.internal.serialize.OutputFormat;
import com.sun.org.apache.xml.internal.serialize.XMLSerializer;

public class XMLMerge {
    private static Map<File, Document> sSrc = new HashMap<File, Document>();
    private static Map<File, Document> sDes = new HashMap<File, Document>();
    private static Map<String, HashSet<String>> sIncludeRule = new HashMap<String, HashSet<String>>();
    private static Map<String, HashSet<String>> sExcludeRule = new HashMap<String, HashSet<String>>();
    private static Map<String, HashSet<String>> sInsertRule = new HashMap<String, HashSet<String>>();

    private static final int MERGE_DONT_NEED_MERGE = 1;
    private static final int MERGE_DONT_FIND_DEST_FILE = 2;
    private static final int MERGE_ADD_ELEMENT = 3;
    private static final int MERGE_MODIFY_ELEMENT = 4;
    private static final int MERGE_INCERT_ITEMS = 5;
    private static final int MERGE_INVALID_NODE = 6;
    private static final String RESOURCES_TAG = "resources";
    private static final String STRING_ARRAY_TAG = "string-array";
    private static final String STRING_TAG = "string";
    private static final String XLIFF_TAG = "xliff:g";
    private static final String ITEM_TAG = "item";
    private static final String NAME_TAG = "name";
    private static final String LOG_TAG = "merge xml";
    private static final String MSGID_TAG = "msgid";

    public XMLMerge(ArrayList<File> srcFiles, ArrayList<File> desFiles, ArrayList<File> configFiles) {
        for (File srcFile : srcFiles) {
            try {
                sSrc.put(srcFile,
                        DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(srcFile));
            } catch (Exception e) {
                e.printStackTrace();
                Log.w(LOG_TAG, "src file:" + srcFile.getName() + " is invalid xml file");
            }
        }

        for (File desFile : desFiles) {
            try {
                sDes.put(desFile,
                        DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(desFile));
            } catch (Exception e) {
                e.printStackTrace();
                Log.w(LOG_TAG, "dest file:" + desFile.getName() + " is invalid xml file");
            }
        }

        parseConfigFile(configFiles);
        printConfig();
    }

    private void parseConfigFile(ArrayList<File> configFiles) {
        for (File f : configFiles) {
            String l;
            BufferedReader r = null;
            try {
                r = new BufferedReader(new FileReader(f));
                while ((l = r.readLine()) != null) {
                    l = l.trim();
                    if (l.length() == 0 || l.startsWith("#")) {
                        continue;
                    }
                    String[] item = l.split(" ");
                    if (item.length > 1
                            && ("-".equals(item[0]) || "+".equals(item[0]) || "I"
                                    .equalsIgnoreCase(item[0]))) {
                        String nodeName = item[1];
                        HashSet<String> nameAttrs;
                        if ("-".equals(item[0])) {
                            nameAttrs = sExcludeRule.get(nodeName);
                            if (nameAttrs == null) {
                                nameAttrs = new HashSet<String>();
                                sExcludeRule.put(nodeName, nameAttrs);
                            }
                        } else if ("+".equals(item[0])) {
                            nameAttrs = sIncludeRule.get(nodeName);
                            if (nameAttrs == null) {
                                nameAttrs = new HashSet<String>();
                                sIncludeRule.put(nodeName, nameAttrs);
                            }
                        } else {
                            nameAttrs = sInsertRule.get(nodeName);
                            if (nameAttrs == null) {
                                nameAttrs = new HashSet<String>();
                                sInsertRule.put(nodeName, nameAttrs);
                            }
                        }
                        if (item.length == 2) {
                            nameAttrs.add("*");
                        } else {
                            String nameAttrValue = item[2];
                            nameAttrs.add(nameAttrValue);
                        }
                    }
                }
            } catch (IOException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            } finally {
                if (r != null) {
                    try {
                        r.close();
                    } catch (IOException e1) {
                        // TODO Auto-generated catch block
                        e1.printStackTrace();
                    }
                }
            }
        }
    }

    private void printConfig() {
        Log.i("------------------------------------------------");
        Log.i(LOG_TAG, "Include:");
        for (Map.Entry<String, HashSet<String>> e : sIncludeRule.entrySet()) {
            Log.i(LOG_TAG, "-->" + e.getKey());
            for (String s : e.getValue()) {
                Log.i(LOG_TAG, "----->" + s);
            }
        }
        Log.i("");
        Log.i(LOG_TAG, "Exclude:");
        for (Map.Entry<String, HashSet<String>> e : sExcludeRule.entrySet()) {
            Log.i(LOG_TAG, "-->" + e.getKey());
            for (String s : e.getValue()) {
                Log.i(LOG_TAG, "----->" + s);
            }
        }
        Log.i("");
        Log.i(LOG_TAG, "Insert:");
        for (Map.Entry<String, HashSet<String>> e : sInsertRule.entrySet()) {
            Log.i(LOG_TAG, "-->" + e.getKey());
            for (String s : e.getValue()) {
                Log.i(LOG_TAG, "----->" + s);
            }
        }
        Log.i("");
        Log.i("------------------------------------------------");
    }

    private boolean chcekFile() {
        for (Map.Entry<File, Document> src : sSrc.entrySet()) {
            if (src.getValue().getElementsByTagName(RESOURCES_TAG).getLength() != 1) {
                Log.w(LOG_TAG, "src file:" + src.getKey().getName() + " don't include a valid \""
                        + RESOURCES_TAG + "\" node");
                sSrc.remove(src.getKey());
            }
        }

        for (Map.Entry<File, Document> des : sDes.entrySet()) {
            if (des.getValue().getElementsByTagName(RESOURCES_TAG).getLength() != 1) {
                Log.w(LOG_TAG, "dest file:" + des.getKey().getName() + " don't include a valid \""
                        + RESOURCES_TAG + "\" node");
                sDes.remove(des.getKey());
            }
        }

        if (sSrc.isEmpty()) {
            Log.w(LOG_TAG, "no vaild src files");
            return false;
        }

        if (sDes.isEmpty()) {
            Log.w(LOG_TAG, "no valid dest files");
            return false;
        }
        return true;
    }

    public void merge() {
        if (!chcekFile()) {
            return;
        }

        for (Map.Entry<File, Document> entry : sSrc.entrySet()) {
            Log.i("------------------------------------------------");
            Log.i(LOG_TAG, "merge file: " + entry.getKey().getName());
            mergeFile(entry);
            Log.i("------------------------------------------------");
            Log.i("");
        }

        saveDestFile();
    }

    private void saveDestFile() {
        for (Map.Entry<File, Document> des : sDes.entrySet()) {
            writeXML(des.getValue(), des.getKey());
        }
    }

    private void mergeFile(Map.Entry<File, Document> entry) {
        Document doc = entry.getValue();
        formatDoc(doc);
        Node resNode = doc.getElementsByTagName(RESOURCES_TAG).item(0);
        NodeList subTypes = resNode.getChildNodes();
        for (int i = 0; i < subTypes.getLength(); i++) {
            if (Node.ELEMENT_NODE == subTypes.item(i).getNodeType()) {
                mergeNode(subTypes.item(i));
            }
        }
        return;
    }

    private int mergeNode(Node node) {
        if (!checkNode(node)) {
            Log.i(LOG_TAG, "invalid src node: " + node.getNodeName());
            return MERGE_INVALID_NODE;
        }

        if (!needMerge(node)) {
            Log.i(LOG_TAG, "dont need merge src node: " + node.getNodeName() + "[" + "name="
                    + ((Element) node).getAttribute(NAME_TAG) + "]");
            return MERGE_DONT_NEED_MERGE;
        }

        if (tryInsertItemsToDesArrayNode(node)) {
            Log.i(LOG_TAG, "inscert new items to dest array node: " + node.getNodeName() + "["
                    + "name="
                    + ((Element) node).getAttribute(NAME_TAG) + "]");
            return MERGE_INCERT_ITEMS;
        }

        if (tryReplaceDesNode(node)) {
            Log.i(LOG_TAG, "replace node to dest: " + node.getNodeName() + "[" + "name="
                    + ((Element) node).getAttribute(NAME_TAG) + "]");
            return MERGE_MODIFY_ELEMENT;
        }

        if (tryAddDesNode(node)) {
            Log.i(LOG_TAG, "add node to dest: " + node.getNodeName() + "[" + "name="
                    + ((Element) node).getAttribute(NAME_TAG) + "]");
            return MERGE_ADD_ELEMENT;
        }
        Log.i(LOG_TAG, "can't find dest file for node: " + node.getNodeName() + "[" + "name="
                + ((Element) node).getAttribute(NAME_TAG) + "]");
        return MERGE_DONT_FIND_DEST_FILE;
    }

    private void formatDoc(Document doc) {
        removeXliffgNode(doc);
        removeMsgidAttr(doc);
    }

    private boolean checkNode(Node node) {
        // check if node has a "name" attribute
        return !"".equals(((Element) node).getAttribute(NAME_TAG));
    }

    private boolean needMerge(Node node) {
        // search Include and Insert config firstly
        if (matchConfig(node, sIncludeRule) || matchConfig(node, sInsertRule)) {
            return true;
        }
        // search Exclude config secondly
        return !matchConfig(node, sExcludeRule);
    }

    private boolean matchConfig(Node node, Map<String, HashSet<String>> configs) {
        HashSet<String> nameAttrValues;
        if ((nameAttrValues = configs.get(node.getNodeName())) == null) {
            return false;
        }
        if (nameAttrValues.contains("*")
                || nameAttrValues.contains(((Element) node).getAttribute(NAME_TAG))) {
            return true;
        }
        return false;
    }

    // try insert the new items to array node
    private boolean tryInsertItemsToDesArrayNode(Node node) {
        String nodeName = node.getNodeName();
        String nameAttrValue = ((Element) node).getAttribute(NAME_TAG);
        if (matchConfig(node, sInsertRule)) {
            for (Map.Entry<File, Document> des : sDes.entrySet()) {
                Document desDoc = des.getValue();
                NodeList desNodes = desDoc.getElementsByTagName(nodeName);
                for (int i = 0; i < desNodes.getLength(); i++) {
                    Node desNode = desNodes.item(i);
                    try {
                        if (nameAttrValue.equals(((Element) desNode).getAttribute(NAME_TAG))) {
                            NodeList desItems = ((Element) desNode).getElementsByTagName(ITEM_TAG);
                            NodeList srcItems = ((Element) node).getElementsByTagName(ITEM_TAG);
                            if (desItems.getLength() == 0 || srcItems.getLength() == 0) {
                                return false;
                            }
                            ArrayList<String> desItemTexts = new ArrayList<String>();
                            for (int j = 0; j < desItems.getLength(); j++) {
                                desItemTexts.add(desItems.item(j).getTextContent());
                            }

                            for (int j = 0; j < srcItems.getLength(); j++) {
                                String srcText = srcItems.item(j).getTextContent();
                                if (!desItemTexts.contains(srcText)) {
                                    Element item = desDoc.createElement(ITEM_TAG);
                                    item.appendChild(desDoc.createTextNode(srcText));
                                    desNode.insertBefore(item, desItems.item(0));
                                }
                            }
                            return true;
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                        return false;
                    }
                }
            }
        }
        return false;
    }

    // if dest node with same node name and "name" attribute
    // just to replace the dest node with src node
    private boolean tryReplaceDesNode(Node node) {
        String nodeName = node.getNodeName();
        String nameAttrValue = ((Element) node).getAttribute(NAME_TAG);
        for (Map.Entry<File, Document> des : sDes.entrySet()) {
            Document desDoc = des.getValue();
            NodeList desNodes = des.getValue().getElementsByTagName(nodeName);
            for (int i = 0; i < desNodes.getLength(); i++) {
                Node desNode = desNodes.item(i);
                try {
                    if (nameAttrValue.equals(((Element) desNode).getAttribute(NAME_TAG))) {
                        desNode.getParentNode().replaceChild(desDoc.importNode(node, true),
                                desNode);
                        return true;
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    return false;
                }
            }
        }
        return false;
    }

    // add node to the doc which include same node name
    private boolean tryAddDesNode(Node node) {
        String nodeName = node.getNodeName();
        for (Map.Entry<File, Document> des : sDes.entrySet()) {
            Document desDoc = des.getValue();
            if (existNode(des.getValue(), nodeName)) {
                try {
                    desDoc.getElementsByTagName(nodeName).item(0).getParentNode()
                            .appendChild(desDoc.importNode(node, true));
                    return true;
                } catch (Exception e) {
                    e.printStackTrace();
                    return false;
                }
            }
        }
        return false;
    }

    private boolean existNode(Document doc, String nodeName) {
        NodeList nodes = doc.getElementsByTagName(nodeName);
        return nodes.getLength() > 0;
    }

    private void removeXliffgNodeFromStringArray(Document doc) {
        NodeList stringArrays = doc.getElementsByTagName(STRING_ARRAY_TAG);
        for (int i = 0; i < stringArrays.getLength(); i++) {
            Element stringArray = (Element) stringArrays.item(i);
            NodeList xliffs = stringArray.getElementsByTagName(XLIFF_TAG);
            if (xliffs.getLength() > 0) {
                Node papa = xliffs.item(0).getParentNode().getParentNode();
                ArrayList<String> vals = new ArrayList<String>();
                while (stringArray.getElementsByTagName(XLIFF_TAG).getLength() != 0) {
                    vals.add(xliffs.item(0).getTextContent());
                    xliffs.item(0).getParentNode().getParentNode()
                            .removeChild(xliffs.item(0).getParentNode());
                }
                for (int j = 0; j < vals.size(); j++) {
                    Element e = doc.createElement(ITEM_TAG);
                    e.appendChild(doc.createTextNode(vals.get(j)));
                    papa.appendChild(e);
                }
            }
        }
    }

    private void removeXliffgNodeFromString(Document doc) {
        Element res = (Element) doc.getElementsByTagName(RESOURCES_TAG).item(0);
        NodeList xliffs = res.getElementsByTagName(XLIFF_TAG);
        int len = xliffs.getLength();
        while (len > 0) {
            Node xliff = xliffs.item(0);
            Text text = doc.createTextNode(xliff.getTextContent());
            xliff.getParentNode().replaceChild(text, xliff);

            xliffs = res.getElementsByTagName(XLIFF_TAG);
            len = xliffs.getLength();
        }
    }

    private void removeXliffgNode(Document doc) {
        removeXliffgNodeFromStringArray(doc);
        removeXliffgNodeFromString(doc);
    }

    private void removeMsgidAttr(Document doc) {
        Node resNode = doc.getElementsByTagName(RESOURCES_TAG).item(0);
        NodeList nodes = resNode.getChildNodes();
        for (int i = 0; i < nodes.getLength(); i++) {
            Node node = nodes.item(i);
            if (Node.ELEMENT_NODE == node.getNodeType()) {
                ((Element) node).removeAttribute(MSGID_TAG);
            }
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
        } catch (Exception e) {
            e.printStackTrace();
            Log.e(LOG_TAG, "write xml file " + file.getName() + " failed");
        }
    }
}
