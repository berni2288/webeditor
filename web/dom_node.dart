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

	String getTextContent()
	{
		return this.getRawNode().text;
	}

	setTextContent(value)
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

    Map getOffsets() {
		final docElem = document.documentElement;
		final box     = (this.getRawNode() as Element).getBoundingClientRect();

		return {
			'x': box.left + window.pageXOffset - docElem.clientLeft,
			'y': box.top  + window.pageYOffset - docElem.clientTop
		};
    }

    void normalizeText() {
    	var currentText = null;

    	Node rawNode = this.getRawNode();
    	for (var i = rawNode.nodes.length - 1; i >= 0; --i) {
    		var child = rawNode.nodes[i];
    		if (child is Text) {
    			if (currentText == null) {
    				currentText = child;
    			} else {
    				currentText.text = child.text + currentText.text;
    				child.remove();
    			}
    		} else {
    			currentText = null;
    		}
    		if (child is Element) {
    			new DomNode(child).normalizeText();
    		}
    	}
    }

	static DomNode createElement(String tagName)
	{
		return new DomNode(document.createElement(tagName));
	}
}
