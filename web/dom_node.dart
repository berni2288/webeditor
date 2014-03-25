part of webeditor;


class DomNode
{
	Node rawNode;


	DomNode(Node node)
	{
		this.rawNode = node;
	}

	Node getRawNode()
	{
		return this.rawNode;
	}

	setRawNode(Node node)
	{
		rawNode = node;
	}

	DomNode getLastChild()
	{
		Node rawLastChild = this.getRawNode().lastChild;

		if (rawLastChild == null) {
			return null;
		}

		return new DomNode(rawLastChild);
	}

	DomNode getPrevious()
	{
		Node rawPreviousNode = this.getRawNode().previousNode;

		if (rawPreviousNode == null) {
			return null;
		}

		return new DomNode(rawPreviousNode);
	}

	DomNode getNext()
	{
		Node rawNextNode = this.getRawNode().nextNode;

		if (rawNextNode == null) {
			return null;
		}

		return new DomNode(rawNextNode);
	}

	String getNodeName()
	{
		return this.getRawNode().nodeName.toLowerCase();
	}

	String getInnerHtml()
	{
		return (this.getRawNode() as Element).innerHtml;
	}

	setInnerHtml(value)
	{
		(this.getRawNode() as Element).innerHtml = value;
	}

	String getText()
	{
		return this.getRawNode().text;
	}

	setText(value)
	{
		this.getRawNode().text = value;
	}

	List<DomNode> getChildren()
	{
		List<Element> domObjectChildren = (this.getRawNode() as Element).children;
		List<DomNode> children = new List();
		for (var i = 0; i < domObjectChildren.length; i++) {
			children.add(new DomNode(domObjectChildren[i]));
		}

		return children;
	}

	List<DomNode> getChildNodes()
	{
		List<Node> domObjectChildNodes = this.getRawNode().childNodes;
		List<DomNode> childNodes = new List();
		for (int i = 0; i < domObjectChildNodes.length; i++) {
			childNodes.add(new DomNode(domObjectChildNodes[i]));
		}

		return childNodes;
	}

	getType()
	{
		return this.getRawNode().nodeType;
	}

	remove()
	{
		this.getRawNode().remove();
	}

	append(DomNode domNode)
	{
		this.getRawNode().append(domNode.getRawNode());
	}

	/*
	 * Inserts nodeToInsert before this.
	 * this must have a parent.
	 */
	insertBefore(DomNode nodeToInsert)
	{
		this.getParentNode().getRawNode().insertBefore(
				nodeToInsert.getRawNode(), this.getRawNode());
	}

    DomNode insertNodeIntoText(DomNode domNodeToInsert, int offset)
    {
		this.insertAfter(domNodeToInsert);

		String text = this.getText();
		String preText  = text.substring(0, offset);
		String postText = text.substring(offset);

		this.setText(preText);

		// We also need a second text node
		DomNode secondTextNode = new DomNode(new Text(postText));
		domNodeToInsert.insertAfter(secondTextNode);

		return secondTextNode;
    }

	insertText(String text, int offset)
	{
		String currentText = this.getText();
		String preText  = currentText.substring(0, offset);
		String postText = currentText.substring(offset);

		this.setText(preText + text + postText);
	}

	/*
	 * Inserts nodeToInsert after this
	 * this must have a parent.
	 */
	insertAfter(DomNode nodeToInsert)
	{
		DomNode nextNode = this.getNext();
		Node referenceNode;

		if (nextNode != null) {
			referenceNode = nextNode.getRawNode();
		}

		this.getParentNode().getRawNode().insertBefore(
        				nodeToInsert.getRawNode(), referenceNode);
	}

	DomNode getParentNode()
	{
		Node parentNode = this.getRawNode().parentNode;

		if (parentNode == null) {
			return null;
		}

		return new DomNode(parentNode);
	}

	bool isEqualTo(DomNode domNode)
	{
		return this.getRawNode() == domNode.getRawNode();
	}

    Map getDocumentOffsets() {
		final docElem = document.documentElement;
		final box     = (this.getRawNode() as Element).getBoundingClientRect();

		return {
			'x': box.left + window.pageXOffset - docElem.clientLeft,
			'y': box.top  + window.pageYOffset - docElem.clientTop
		};
    }

    /*
     * Warnings: This will probably remove existing textnodes.
     * Be sure to not rely on any reference to text nodes afterwards.
     */
    normalizeText() {
    	Node rawNode            = this.getRawNode();
    	DomNode currentTextNode = null;

    	List<DomNode> childNodes = this.getChildNodes();
    	for (int i = childNodes.length - 1; i >= 0; --i) {
    		DomNode childNode = childNodes[i];
    		if (childNode.getType() == Node.TEXT_NODE) {
    			if (currentTextNode == null) {
    				currentTextNode = childNode;
    			} else {
    				currentTextNode.setText(childNode.getText() + currentTextNode.getText());
    				childNode.remove();
    			}
    		} else {
    			currentTextNode = null;
    		}

    		if (currentTextNode != null && currentTextNode.getType() == Node.ELEMENT_NODE) {
    			childNode.normalizeText();
    		}
    	}
    }

    int getChildIndex()
    {
		List<DomNode> childNodes = this.getParentNode().getChildNodes();
		for (int i = 0; i < childNodes.length; i++) {
			if (childNodes[i].isEqualTo(this)) {
				return i;
			}
		}

		return -1;
    }

    bool contains(DomNode domNode)
    {
		return this.getRawNode().contains(domNode.getRawNode());
    }

    bool isContainedBy(DomNode domNode)
    {
    	return domNode.getRawNode().contains(this.getRawNode());
    }

    bool containsWhitespaceOnly()
    {
    	String text = this.getText();
    	for (int i=0; i < text.length; i++) {
    		if (" \t\r\n".indexOf(text[i]) == -1) {
    			return false;
    		}
    	}

    	return true;
    }

    bool isEmpty()
    {
    	List<DomNode> thisChildNodes = this.getChildNodes();
    	return thisChildNodes.length == 0;
    }

	static DomNode createElement(String tagName)
	{
		return new DomNode(document.createElement(tagName));
	}
}
