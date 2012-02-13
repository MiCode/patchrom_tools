import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.Writer;
import java.util.ArrayList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
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

public class XMLMerge {
	private ArrayList<File> mSrcFiles;
	private ArrayList<File> mDestFiles;

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
			DocumentBuilderFactory dbFactory = DocumentBuilderFactory
					.newInstance();
			DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
			Document doc = dBuilder.parse(file);

			Element root = adjustMergeRoot(doc);
			if(null == root){
				return;
			}

			System.out.println("***************START MERGE***********");
			System.out.println("SRC XML FILE: " + file.getName());

			traverseMergeXML(root);
			System.out.println("---------------END   MERGE-----------");
			System.out.println();
			System.out.println();

		} catch (Exception e) {
			e.printStackTrace();
		}
		return;
	}

	private Element adjustMergeRoot(Document doc) {
		Element root = doc.getDocumentElement();
		if (true == hasNode("/resources/string-array", doc)) {
			//System.out.println("Node find :xmlns:xliff");
			root = adjustStringArrayMergeRoot(doc);
		} else if (true == hasNode("/resources/add-resource", doc)) {
			//System.out.println("IS ADD RESOURCES");
			root = adjustAddResources(doc);
		
		} else if (true == hasNode("/resources/style", doc)) {
			root = adjustStyleRoot(doc);
		}
		 else {
		}
		return root;
	}

	private Element adjustStringArrayMergeRoot(Document doc) {
		NodeList nList = doc.getElementsByTagName("resources");
		Element root = (Element) nList.item(0);
		root.removeAttribute("xmlns:xliff");
		nList = root.getElementsByTagName("xliff:g");

		//System.out.println("xliff:g num: " + nList.getLength());
		ArrayList<String> vals = new ArrayList<String>();
		Node papa = nList.item(0).getParentNode().getParentNode();

		while (root.getElementsByTagName("xliff:g").getLength() != 0) {
			vals.add(nList.item(0).getTextContent());
			nList.item(0).getParentNode().getParentNode()
					.removeChild(nList.item(0).getParentNode());
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

	private void mergeNode(Node node) {
		String xpathStr = getXpathStr(node);
		String textContent = node.getTextContent();
		System.out.println();
		System.out.println(xpathStr + ":" + node.getTextContent());

		if(xpathStr.contains("/resources/add-resource")){
			System.out.println("DONT NEED TO ADD NODE: add-resource");
			return;
		}
		
		File destFile = getDestFile(xpathStr);
		if (null == destFile) {
			System.out.println("DEST FILE: DONT FOUND");
			return;
		}
		
		System.out.println("DEST FILE --> " + destFile.getName());

		mergeNodeToDestFile(xpathStr, textContent, destFile);
	}

	private void mergeNodeToDestFile(String xpathStr, String textContent,
			File destFile) {
		String tryMatchStr = new String(xpathStr);
		try {
			while (null != xpathStr && false == xpathStr.equals("/resources")) {
				XPathFactory factory = XPathFactory.newInstance();
				XPath xpath = factory.newXPath();
				XPathExpression expr = xpath.compile(tryMatchStr);

				DocumentBuilderFactory dbFactory = DocumentBuilderFactory
						.newInstance();
				DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
				Document doc = dBuilder.parse(destFile);
				doc.getDocumentElement().normalize();
				NodeList nList = (NodeList) expr.evaluate(doc,
						XPathConstants.NODESET);
				
				if(tryMatchStr == null){
					System.out.println("tmp is null");
					return;
				}
				
				if (null != nList && 0 != nList.getLength()) {
					String lostMatchStr = new String(xpathStr);
					System.out.println(getLineNumberString(new Exception()) + "Match: " + tryMatchStr);
					//System.out.println(getLineNumberString(new Exception()) + "LostMatch: " + lostMatchStr);
					//lostMatchStr = lostMatchStr.replaceFirst(tryMatchStr, "");					
					
					if(true == lostMatchStr.equals(tryMatchStr)){
						String subStr = tryMatchStr.substring(tryMatchStr.lastIndexOf('/') + 1);
						if(true == subStr.contains("@")){
							//System.out.println(getLineNumberString(new Exception()) + "Match ALL ELEMENT ");
							nList.item(0).setTextContent(textContent);
							writeXML(doc, destFile);
							System.out.println(getLineNumberString(new Exception()) + "ADD NODE: " + getXpathStr(nList.item(0)) + ": " + textContent);
							return;
							
						}else{
							//System.out.println(getLineNumberString(new Exception()) + "Match ALL ELEMENT ");
							
							Node papa = nList.item(0).getParentNode();
							String nodeName = nList.item(0).getNodeName();
							for(int i = 0; i < nList.getLength(); i++){
								if(nList.item(i).getTextContent().equals(textContent)){
									System.out.println(getLineNumberString(new Exception()) + "DONT NEED ADD NODE");
									return;
								}
							}
							
							Element e = doc.createElement(nodeName);							
							papa.appendChild(e);						
							e.setTextContent(textContent);
							writeXML(doc, destFile);
							System.out.println(getLineNumberString(new Exception()) + "ADD NODE: " + getXpathStr(nList.item(0)) + ": " + textContent);
							return;
							
						}
					}else{
						lostMatchStr = lostMatchStr.replace(tryMatchStr, "");
					}
					
					//System.out.println(getLineNumberString(new Exception()) + "LostMatch: " + lostMatchStr);
					
					if(lostMatchStr.substring(0, 1).equals("/")){
						//System.out.println("noMatchStr.substring(0, 1).is /");
						addNode(doc, (Element)(nList.item(0)), destFile,lostMatchStr, textContent);
						return;
					}else if(lostMatchStr.substring(0, 1).equals("[")){
						//System.out.println("noMatchStr.substring(0, 1).is [");
						String attrName = lostMatchStr.substring(lostMatchStr.indexOf('@') + 1, 
														   lostMatchStr.indexOf('='));
						lostMatchStr = lostMatchStr.replaceFirst("\'", "");
						String attrContent = lostMatchStr.substring(lostMatchStr.indexOf('=') + 1, 
								   								  lostMatchStr.indexOf('\''));
						//System.out.println(getLineNumberString(new Exception()) + attrName + " :" + attrContent);
						
						String nodeName = nList.item(0).getNodeName();
						
						Element e = doc.createElement(nodeName);
						e.setAttribute(attrName, attrContent);
						//System.out.println(getLineNumberString(new Exception()) + "attrName: " + attrName + " attrContent:" + attrContent);
						nList.item(0).getParentNode().appendChild(e);
						if(lostMatchStr.indexOf('/') < 0){
							//System.out.println(getLineNumberString(new Exception()) + "e.appendChild(doc.createTextNode(textContent)" + textContent);
							e.appendChild(doc.createTextNode(textContent));
							writeXML(doc, destFile);
							System.out.println(getLineNumberString(new Exception()) + "ADD NODE: " + getXpathStr(e) + ": " + textContent);
							return;
						}else{
							addNode(doc, e, destFile,
									lostMatchStr.substring(lostMatchStr.indexOf('/')), 
									textContent);	
							return;
						}						
					}
					//System.out.println("noMatchStr.substring(0, 1).is " + lostMatchStr.substring(0, 1));
				}
				tryMatchStr = getUpperXpathStr(tryMatchStr);
				//System.out.println(getLineNumberString(new Exception()) + "TryMatch: " + tryMatchStr);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private void addNode(Document doc, Element element, File destFile, String xpathStr, String textContent){
		String tmp = new String(xpathStr);
		while(tmp.indexOf('/') > -1){
			tmp = tmp.replaceFirst("/", "");
			if(tmp.indexOf('/') > -1){
				String subTmp = tmp.substring(0, tmp.indexOf('/'));
				if(subTmp.indexOf('[') > -1){
					String nodeName = new String(subTmp.substring(0, subTmp.indexOf('[')));
					String attrName = new String(subTmp.substring(subTmp.indexOf('@') + 1, subTmp.indexOf('=')));
					String attrContent = new String(subTmp.substring(subTmp.indexOf('\'') + 1, subTmp.lastIndexOf('\'')));
					
					//System.out.println(getLineNumberString(new Exception()) + "nodeName:  " + nodeName + "  attrName:  " + attrName + "attrContent  " + attrContent);					
					Element subElement = doc.createElement(nodeName);
					subElement.setAttribute(attrName, attrContent);
					element.appendChild(subElement);
					element = subElement;
				}else{
					String nodeName = new String(subTmp);
					
					//System.out.println(getLineNumberString(new Exception()) + "nodeName:  " + nodeName);					
					Element subElement = doc.createElement(nodeName);
					element = subElement;
				}
				tmp = tmp.substring(tmp.indexOf('/'));
			}else{
				String subTmp = tmp;
				if(subTmp.indexOf('[') > -1){
					String nodeName = new String(subTmp.substring(0, subTmp.indexOf('[')));
					String attrName = new String(subTmp.substring(subTmp.indexOf('@') + 1, subTmp.indexOf('=')));
					String attrContent = new String(subTmp.substring(subTmp.indexOf('\'') + 1, subTmp.lastIndexOf('\'')));
					
					//System.out.println(getLineNumberString(new Exception()) + "nodeName:  " + nodeName + "  attrName:  " + attrName + "attrContent  " + attrContent);
					Element subElement = doc.createElement(nodeName);
					subElement.setAttribute(attrName, attrContent);
					element.appendChild(subElement);
					element = subElement;
				}else{
					String nodeName = new String(subTmp);
					
					//System.out.println(getLineNumberString(new Exception()) + "nodeName:  " + nodeName);
					Element subElement = doc.createElement(nodeName);
					element = subElement;
				}
				element.appendChild(doc.createTextNode(textContent));
				writeXML(doc, destFile);
				System.out.println(getLineNumberString(new Exception()) + "ADD NODE: " + getXpathStr(element) + ": " + textContent);
				return;
			}
		}
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
					DocumentBuilderFactory dbFactory = DocumentBuilderFactory
							.newInstance();
					DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
					Document doc = dBuilder.parse(mDestFiles.get(i));
					doc.getDocumentElement().normalize();
					NodeList nList = (NodeList) expr.evaluate(doc,
							XPathConstants.NODESET);
					if (null != nList && 0 != nList.getLength()) {
						// System.out.println("\tfind doc$$$\t" +
						// nList.getLength());
						return mDestFiles.get(i);
					}
				}
				xpathStr = getUpperXpathStr(xpathStr);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		// System.out.println("\tno find doc***");
		return null;
	}

	private String getUpperXpathStr(String xpathStr) {
		if ((xpathStr != null) && (xpathStr.length() > 0)) {
			int pos1 = xpathStr.lastIndexOf(']');
			int pos2 = xpathStr.lastIndexOf('[');
			int pos3 = xpathStr.lastIndexOf('/');
			if (pos1 > -1 && pos2 > -1 && pos3 > -1 && pos1 > pos2
					&& pos2 > pos3) {
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

			NodeList nList = (NodeList) expr.evaluate(doc,
					XPathConstants.NODESET);
			if (null != nList && 0 != nList.getLength()) {
				// System.out.println("\tfind$$$\t" + nList.getLength());
				return true;
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		// System.out.println("\tno find***");
		return false;
	}

	public void traverseMergeXML(Node node) {
		if (true == isElementLeaf(node)) {
			mergeNode(node);
		}
		// Now traverse the rest of the tree in depth-first order.
		if (node.hasChildNodes()) {
			NodeList nList = node.getChildNodes();
			int size = nList.getLength();
			for (int i = 0; i < size; i++) {
				// Recursively traverse each of the children.
				traverseMergeXML(nList.item(i));
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
				return true;
			} else {
				return true;
			}
		} else {
			return false;
		}
	}
	
	private void writeXML(Document doc, File file){
		try{			
			//TransformerFactory transformerFactory = TransformerFactory.newInstance();
			//Transformer transformer = transformerFactory.newTransformer();
			//DOMSource source = new DOMSource(doc);
			//StreamResult result = new StreamResult(file);
			// Output to console for testing
			// StreamResult result = new StreamResult(System.out);
			//transformer.transform(source, result);
			
			OutputFormat format = new OutputFormat(doc);
			format.setIndenting(true);
			format.setIndent(4);
			Writer output = new BufferedWriter( new FileWriter(file) );
			XMLSerializer serializer = new XMLSerializer(output, format);
			serializer.serialize(doc);
			//System.out.println("Write Xml File");
			
		}/*catch (TransformerException tfe) {
			tfe.printStackTrace();
		}*/catch (Exception e){
			//e.printTrace();
			
		  }
	}

	public String getXpathStr(Node node) {
		String xpathStr = "";
		while (null != node) {
			if (true == node.hasAttributes()) {
				xpathStr = "/" + node.getNodeName() + "[@"
						+ node.getAttributes().item(0).getNodeName() + "='"
						+ node.getAttributes().item(0).getNodeValue() + "']"
						+ xpathStr;

			} else {
				xpathStr = "/" + node.getNodeName() + xpathStr;
			}

			node = node.getParentNode();
		}
		xpathStr = "/" + xpathStr;
		// System.out.println("pre: " + xpathStr);

		ArrayList<String> subStrArray = new ArrayList<String>();
		subStrArray.add("//#document");
		subStrArray.add("android:");
		xpathStr = delSubString(xpathStr, subStrArray);
		// System.out.println("post:" + xpathStr);
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
	
	class NodeInfo{
		public static final int NO_MATCH_OP = 0;
		public static final int MATCH_NODE_NAME = 1;
		public static final int MATCH_NODE_NAME_ATTRS = 2;
		public static final int NO_MATCH = 3;
		int matchLevel;
		String nodeName;
		ArrayList<AttrInfo>	attrs;
		NodeInfo(){
			nodeName = null;
			attrs = null;
			matchLevel = NO_MATCH_OP;
		}
	}
	
	class AttrInfo{
		String attrName;
		String attrValue;
		AttrInfo(){
			attrName = null;
			attrValue = null;
		}
	}
	
	public static String getLineNumberString(Exception e){
		StackTraceElement[] trace =e.getStackTrace();
		if(trace==null||trace.length==0){
			return "ERROR: -1";
		} 
		//return new String("LINE" + String.format("%d", trace[0].getLineNumber()) + "--> ");
		return new String("");
	}
	
	public static int getLineNumber(Exception e){
		StackTraceElement[] trace =e.getStackTrace();
		if(trace==null||trace.length==0){
			return -1;
		}			 
		return trace[0].getLineNumber();
	}
}
