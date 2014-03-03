
import 'dart:html';



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
		return new DomNode(this.getRawNode().lastChild);
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

	insertBefore(DomNode newChild, DomNode refChild)
	{
		this.getRawNode().insertBefore(newChild.getRawNode(), refChild.getRawNode());
	}

	DomNode getParentNode()
	{
		return new DomNode(this.getRawNode().parentNode);
	}
}
