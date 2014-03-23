part of webeditor;


class Toolbar
{
	DomNode domNode;


	Toolbar()
	{
        this.domNode = new DomNode(querySelector("#webeditor-toolbar"));
	}

	updateCursorDisplay(DomNode domNode, int offset)
	{
		DomNode cursorDisplay = new DomNode((this.domNode.getRawNode() as Element)
				.querySelector(".webeditor-toolbar-cursorposition"));
		String cursorPosition = "";
		DomNode currentDomNode = domNode;

		while (currentDomNode != null && !currentDomNode.isEqualTo(webEditor.editable)) {
			String nodeString = generateStringForCursorDisplay(currentDomNode);

			if (!cursorPosition.isEmpty) {
    			cursorPosition = nodeString + " > " + cursorPosition;
    		} else {
    			cursorPosition += nodeString + cursorPosition;
    		}

			currentDomNode = currentDomNode.getParentNode();
		}

		cursorPosition = "editable" + (cursorPosition.isEmpty ? "" : " > ") + cursorPosition;

		// Add information about the current offset
		cursorPosition += "#" + offset.toString();
		if (offset > 0 && domNode.getType() == Node.ELEMENT_NODE) {
			List<DomNode> domNodeChildNodes = domNode.getChildNodes();
			cursorPosition += " (After <" +
					generateStringForCursorDisplay(domNodeChildNodes[offset -1]) + ">)";
		}

		(cursorDisplay.getRawNode() as InputElement).value = cursorPosition;
	}

	String generateStringForCursorDisplay(DomNode currentDomNode)
	{
		if (currentDomNode.getType() == Node.TEXT_NODE) {
			return "Text";
		} else if (currentDomNode.getType() == Node.ELEMENT_NODE) {
			return currentDomNode.getNodeName();
		}

		return "HtmlNode";
	}
}
