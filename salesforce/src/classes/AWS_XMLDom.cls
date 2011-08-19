/*
Copyright (c) 2008 salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/*  
	This class implements a small portion of the wc3 xml dom model.  
	Generally useful for simple XML return objects. Note: stores namespaces 
	in the attributes map for now. No node typing done at this time  
	
	can parse into DOM trees the XML return objects from Google, Amazon and others.
	large parse trees will consume suprising amounts of memory
 */
public class AWS_XMLDom {
	// Constructor 
	public AWS_XMLDom(string str) { parseFromString(str); }	
	public AWS_XMLDom(          ) { }
	public void parseFromString(string str) {   
		XmlStreamReader reader = new XmlStreamReader(str);
		reader.setCoalescing(true);
		parseXmlReader (root , reader);	
	} 
	 
	// debugging assistance
	public void dumpAll() { root.dumpAll(); } 
	public void dumpList(Element[] l) { for(Element e:l) e.dump(); }
	
	// given a parent node and a stream reader, populates the tree below here (recursive)
	void parseXmlReader( Element parent, XmlStreamReader reader ) {
		try {
		while(reader.hasNext()) {
		
			if (reader.getEventType() == XmlTag.START_ELEMENT) {
				Element child = new Element( reader.getLocalName() );
				
				// add all attributes from this element
				for (integer i=0; i<reader.getAttributeCount(); i++) { 
					System.debug('insider here...['+reader.getAttributeNamespace(i) + '];[' + reader.getAttributeLocalName(i) + ']; ['+reader.getAttributeValueAt(i)+']');
					
					child.attributes.put(	reader.getAttributeLocalName(i), reader.getAttributeValueAt(i) );
				}
				// add namespace info to each node/element ( for now storing on attributes map)
				for (integer j=0; j<reader.getNamespaceCount(); j++) { 
					string prefix = 'xmlns'; 
					if (reader.getnamespaceprefix(j)!=null)
						 prefix = reader.getnamespaceprefix(j);	
					child.attributes.put( prefix , reader.getnamespaceuriat(j) );
				} 
				
				parent.appendChild(child); // add the new element to current parent
				reader.next();
				
				parseXmlReader(child, reader) ; // recurse
				
			} else if (reader.getEventType() == XmlTag.END_ELEMENT) {	
				reader.next();
				return;	
				
			} else if (reader.getEventType() == XmlTag.CHARACTERS) {
				if ( ! reader.isWhitespace()) { 
					parent.nodeValue += reader.getText();  // add text to current element
				}
				reader.next();
				
			}
			else { 
				reader.next(); 
			} 	
		}
		} catch(Exception e) { // ParseError if we get a truncated response, allow it
			system.debug(e);
		}
	}	
	
	// access nodes in the tree using these getters
	public List<Element> getElementsByTagName(string nam) {
		return root.getElementsByTagName(nam); 
	}
	public List<Element> getElementsByPath(string path) {	
		return root.getElementsByPath( path);
	}
	public Element getElementByPath(string path) {	
		List<Element> r = root.getElementsByPath( path);
		if (r.size() == 0) return null; 
		return r[0];
	}
	public Element 		 getElementByTagName(string nam) {
		List<Element> r = root.getElementsByTagName(nam);
		if (r.size() == 0) return null; 
		return r[0];
	}

	// utility dom functions
	public Element ownerDocument() { return root; }

	// everything in the dom is found as childNodes under this root element
	public Element root = new Element('#document');
	public integer debug =0;
		// dump out the element tree
	public String toXmlString() { return root.toXmlString(); }
	
/* 
 *  Element  class definition
 
	This following class implements a small portion of the wc3 xml dom model.  
	Generally useful for simple XML return objects. 
	
	for a properties and methods complete list see: 
	http://www.w3schools.com/dom/dom_node.asp
	
	For simplicity, Nodes are the same as Elements in this class.
	Nodes have text directly in them, rather than a seperate text node child
	The following describes the implemented portion, some w3c properties are now methods.	
	
	Property 	Description 	
	 
	nodeName 	Returns the name of a node, depending on its type 
	nodeValue 	Sets or returns the value of a node, depending on its type 
	childNodes 	Returns a NodeList of child nodes for a node
	parentNode 	Returns the parent node of a node 
	attributes  	Returns a NamedNodeMap of attributes for the element, also contains name space entries
	
	getElementByTagName() Returns list of elements matching tag name (document and element)
	firstChild() 	Returns the first child of a node 
	removeChild() 	Removes a child node 
	appendChild() 	Adds a new child node to the end of the list of children of a node 
	getAttribute() 	Returns the value of an attribute 
	hasChildNodes() 	Returns whether the element has any child nodes 
	isEqualNode() 	Checks if two nodes are equal 
	textContent() 	returns the textual content of a node 
	cloneNode() 	Clones a node 
	hasAttributes() 	Returns whether the element has any attributes 
	isSameNode() 	Checks if two nodes are the same node 
	ownerDocument() 	Returns the root element (document object) for a node 
	
	
	*** NOT Implemented at this time *** 
	
	lastChild() 	Returns the last child of a node 
	nodeType 	Returns the type of a node , all nodes are the same type currently
	baseURI 	Returns the absolute base URI of a node 
	localName 	Returns the local part of the name of a node 
	namespaceURI 	Returns the namespace URI of a node 
	nextSibling 	Returns the node immediately following a node 
	insertBefore() 	Inserts a new child node before an existing child node 
	replaceChild() 	Replaces a child node 

 */
 public class Element {
	//	Element(Element p, string n) {		parentNode = p;			nodeName = n;		} 
	public Element(string n) {	nodeName = n; } 
	public Element() {	}
	
	public string getAttribute(string name) { 
		return attributes.get(name); 
	}
	public void appendChild(Element e) {
		e.ParentNode = this; 
		this.childNodes.add(e);		
	}
	public void removeChild(Element e) {
		Element p = e.parentNode;
		List<Element> kids = new List<Element> {};
		for( Element ee: e.parentNode.childNodes) {
			if (ee != e) 
				kids.add(ee); 
		}
		p.childNodes = kids;
	}
	// traverse below this node, returning all matching nodes by name
	public List<Element> getElementsByTagName(string nam) {	
		List<Element> ret = new List<Element>{};
		if (nam == this.nodeName) ret.add(this);
		for (Element c: this.childNodes) { 
			ret.addAll( c.getElementsByTagName(nam) ); // decend tree
		}
		return ret;
	}
	// like above, but just returns the first one that matches	
	public Element 		 getElementByTagName(string nam) {
		List<Element> r = 	getElementsByTagName(nam);
		if (r.size() == 0) return null; 
		return r[0];
	}
	// first one that matches, just return the nodeValue
	public string getValue(string nam) {
		Element e = getElementByTagName(nam); 
		return (e==null?null:e.nodeValue); 
	}

	// some debugging help	
	public void dump() { dump('');}
	public void dump(string pre) { // just current node
		system.debug( pre + ' ' +this.nodeName + '->' + this.nodeValue + ' ' + this.attributes );  
	}
	public void dumpAll() { dumpAll('');	}
	public void dumpAll(string pre) { // node and all children
		system.debug( pre + this.nodeName + '->' + this.nodeValue + ' ' + this.attributes );  
		for (Element c: this.childNodes) { 
			c.dumpAll(pre+'   '); 
		}
	}
	public string toXmlString() {
		string ret = '<' + this.nodeName + ' ';
		for (  string a : attributes.keySet() ) {
			ret += a + '=\'' + attributes.get(a) + '\' ' ;
		}
		
		if ( nodeValue == '' && childNodes.size() == 0 ) { 
			return ret + ' />\n'; 	
		}
		
		ret += '>';
		if (nodeValue == '' ) 
			ret += '\n';
		
		integer hasChilds = 0;
		string tmpRet = '';
		for (Element c: this.childNodes) {  
			tmpRet += c.toXmlString() ;
			hasChilds++; 
		}	
		if (hasChilds > 0 ) ret += tmpRet;
		
		if (nodeValue != '' ) 
			ret += nodeValue;
			
		return ret + '</' + this.nodeName + '>\n'; 
	}
	/* 
	 * experimental path based patern matching, sort of like xpath, 
	 * but simpler, just matches a path() string with the pattern supplied
	 */
	 // * /bookstore/book/.*
	 // /.*book/.*
	 // /.*/book$
	public List<Element> getElementsByPath(string path) {	
		List<Element> ret = new List<Element>{};
	//	 system.debug( path + ' ' + this.path());
		if ( Pattern.matches(path, this.path()) ) ret.add(this);
		for (Element c: this.childNodes) ret.addAll( c.getElementsByPath(path) );
		return ret;
	}	 
	public string path() { 
		Element t = this;
		string ret = t.nodeName; 
		while (t.parentNode != null && t.parentNode.nodeName != '#document') { 
			t = t.parentNode;
			ret = t.nodeName + '/'+ret;
		}
		return '/'+ret;
	}
	
	// utility methods
	public Element firstChild() { 
		if ( this.childNodes.size() == 0 ) return null; 
		return this.childNodes[0]; 
	}
	public string textContent() { return this.nodeValue; } 
	public boolean hasChildNodes() { return childNodes.size()>0; }
	public boolean isEqualNode(Element comp) { return this.nodeName == comp.nodeName; } 
	public Element cloneNode() { return this.clone(); } 
	public boolean hasAttributes() { return ! attributes.isEmpty(); } 
	public boolean isSameNode(Element comp) { return this === comp; }		
	public Element ownerDocument() { 
		Element ret = this; 
		while( ret.parentNode != null) { ret = ret.parentNode; } 			
		return ret; 
	} 
	
	// properties
	public Element parentNode = null; // only root has a null parent 
	public string nodeName = ''; 
	public string nodeValue = ''; 
	public List<Element> childNodes = new List<Element>();
	public map<String,String> attributes = new map<String,String>();
	
 }
 
 
  
    public static testmethod void test1() { 
        AWS_XMLDom d;        
        d = new AWS_XMLDom('<book  author="Manoj" >My Book</book>');
        //d.dumpAll(); 
        AWS_XMLDom.Element e = d.getElementsByTagName('book')[0];
        system.assert( e.getAttribute('author') =='Manoj' ); 
        
        d = new AWS_XMLDom(); d.parseFromString('<book  author="Manoj" >My Book</book>');
        //d.dumpAll(); 
         
        d = new AWS_XMLDom('<books><book>My Book</book></books>');
        //d.dumpAll(); 
        //system.debug( d.getElements() ); 
        system.debug ( d.getElementsByTagName('book')[0].nodeValue );
        system.assert ( d.getElementsByTagName('book')[0].nodeValue == 'My Book' );
        
        d = new AWS_XMLDom('<books><book author="Manoj" date="1999" >My Book</book><book author="Ron" >Your Book</book></books>'); 
        //d.dumpAll();
        system.debug ( d.getElementsByTagName('book') );
        for(AWS_XMLDom.Element ee:d.getElementsByTagName('book')) { system.debug( 'Author is ' + ee.getAttribute('author')); }
        AWS_XMLDom.Element ee  = new AWS_XMLDom.Element(); 
         
        string testListBucketResponse = 
             '<?xml version="1.0" encoding="UTF-8"?>'+ 
            '<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>klklklk-test-bucket</Name><Prefix>'+
            '</Prefix><Marker></Marker><MaxKeys>1000</MaxKeys><IsTruncated>false</IsTruncated><Contents><Key>/apex/adnDevSignup</Key>'+
            '<LastModified>2008-01-27T21:13:58.000Z</LastModified><ETag>&quot;630581ddc40fa0a3b7e521c67962baba&quot;</ETag><Size>27411</Size>'+
            '<Owner><ID>173ea00b3418d9a715d5f5a0d85290c3be11135ecf9a085504a4b1bbb6ea1</ID><DisplayName>vne</DisplayName></Owner>'+
            '<StorageClass>STANDARD</StorageClass></Contents><Contents><Key>apedfx/adnDevSignup</Key><LastModified>2008-01-31T09:50:41.000Z</LastModified>'+
            '<ETag>&quot;2d9ab36295e58d32db358aae0195c164&quot;</ETag><Size>27410</Size><Owner><ID>owner_id</ID><DisplayName>foobar</DisplayName></Owner>'+
            '<StorageClass>STANDARD</StorageClass></Contents><Contents><Key>apex/adnRoot</Key><LastModified>2008-01-31T09:50:40.000Z</LastModified>'+
            '<ETag>&quot;f956a9612c95c206f3208f023d1edefb&quot;</ETag><Size>20036</Size><Owner><ID>owner_id</ID><DisplayName>foobar</DisplayName></Owner>'+
            '<StorageClass>STANDARD</StorageClass></Contents><Contents><Key>test-key-public</Key><LastModified>2008-02-02T04:02:59.000Z</LastModified>'+
            '<ETag>&quot;12f3e46f80c24c997c4304953edc3612&quot;</ETag><Size>32</Size><Owner><ID>99999999999</ID>'+
            '<DisplayName>foobar</DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>test-two</Key>'+
            '<LastModified>2008-02-02T00:40:29.000Z</LastModified><ETag>&quot;327b6f07435811239bc47e1544353273&quot;</ETag><Size>7</Size>'+
            '<Owner><ID>173</ID><DisplayName>foobar</DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>';
        d = new AWS_XMLDom(testListBucketResponse); 
        //d.dumpAll();
        List<AWS_XMLDom.Element> keys = d.getElementsByTagName('Key');
        
        //system.debug ( keys ); 
        for(AWS_XMLDom.Element e2:keys) { system.debug( 'Key is '  + e2.nodeValue ); }
        
        integer count= keys.size();
        system.assert(count>1);
        system.debug(count);
        
        AWS_XMLDom.Element p = keys[0].parentNode;
        p.removeChild(p.firstChild());
        
        keys = d.getElementsByTagName('Key');
        system.assert(keys.size() == count-1);
        
        keys = d.root.getElementsByTagName('Key');
        for(AWS_XMLDom.Element e2: keys ) { 
        	system.debug( 'Key is ' + e2.nodeValue ); 
         	e2.dump(); 
         }
        count= keys.size();
        system.assert(count>1);
        system.debug(count);
        
        string testErrorResponse = 
         '<?xml version="1.0" encoding="UTF-8"?>'+ 
         '<Error><Code>NoSuchKey</Code><Message>The specified key does not exist.</Message><Key>test-key</Key><RequestId>49D135DD55EBD</RequestId>'+
         '<HostId>PB4hNZ</HostId></Error>';
    
        d = new AWS_XMLDom(testErrorResponse); 
        d.root.dumpAll();
        
        // uses namespaces
         string testACLResponse = 
	     '<?xml version="1.0" encoding="UTF-8"?>'+ 
	     '<AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>owner_id</ID><DisplayName>foobar</DisplayName></Owner>'+
	     '<AccessControlList><Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser" foo="bar" ><ID>owner_id</ID>'+
	     '<DisplayName>foobar</DisplayName></Grantee><Permission>FULL_CONTROL</Permission></Grant></AccessControlList></AccessControlPolicy>';
        d = new AWS_XMLDom(testACLResponse); 
        //d.dumpAll(); 
        system.assert( d.root.hasChildNodes() ); 
        
        system.assert(  d.root.isEqualNode(d.root) ,' is equal node');
        system.assert( d.root.textContent() == '' );
         
        d.getElementsByTagName('Grantee')[0].dump(); 
        
        system.assert( d.getElementsByTagName('Grantee')[0].hasAttributes() );
        
        d.getElementsByPath('/.*/Grantee/.*')[0].dump();    
        d.getElementByPath('/.*/Grantee/.*').dump();   
        system.assert( d.getElementByPath('bad') == null );   
        system.assert( d.getElementByTagName('badName') == null ); 
        system.assert( d.toXmlString() != null );   
    }
    
    public static testmethod void test4() { 
        AWS_XMLDom f = new AWS_XMLDom( '<RetrieveItem_Request_1 xmlns="http://www.reuters.com/ns/2006/05/01/webservices/rkd/Quotes_1"><ItemRequest Scope="All"><QoS xmlns="http://www.reuters.com/ns/2006/05/01/webservices/rkd/QuotesCommon"><TimelinessInfo Timeliness="DELAYED" /><RateInfo Rate="UNSPECIFIED" /></QoS><Fields xmlns="http://www.reuters.com/ns/2006/05/01/webservices/rkd/QuotesCommon" /><RequestKey xmlns="http://www.reuters.com/ns/2006/05/01/webservices/rkd/QuotesCommon" Name="MSFT.O" Service="" NameType="RIC" /></ItemRequest></RetrieveItem_Request_1>');            
        system.debug( f.toXmlString() );
    }
    
    public static testmethod void test_except() { 
         string testNotification = 
         '<?xml version="1.0" encoding="UTF-8"?>' +
            '<bookstore><book><title lang="eng">Harry Potter</title><price>29.99</price>' +
            '</book><book><title lang="eng">Learning '; // truncated
		AWS_XMLDom f = new AWS_XMLDom( testNotification );
		// should cause an exception which is caught , returning a truncated dom
		for ( AWS_XMLDom.element e : f.getElementsByTagName('title') ) {
			e.dump(); 
		}
		system.assert( f.getElementsByTagName('title')[0].nodeValue == 'Harry Potter' );
		system.assert( f.getElementsByTagName('title')[1].nodeValue == '' );

    }
    
    public static testmethod void test3() { 
         string testNotification = 
         '<?xml version="1.0" encoding="UTF-8"?>' +
            '<bookstore><book><title lang="eng">Harry Potter</title><price>29.99</price>' +
            '</book><book><title lang="eng">Learning XML</title><price>39.95</price></book></bookstore>';

        AWS_XMLDom d;
        d = new AWS_XMLDom(testNotification);  
        list<AWS_XMLDom.element> tmp ; 

        tmp =  d.root.getElementsByTagName('book');  // matching by name
        system.assertEquals( 2, tmp.size() ); 
        d.dumpList( tmp );
        
        AWS_XMLDom.Element a = d.ownerDocument();
        AWS_XMLDom.Element f = a.firstChild();
        AWS_XMLDom.Element c = f.ownerDocument(); 
        system.assert( a.isSameNode( c ) );
        AWS_XMLDom.Element b = a.cloneNode();
        system.assert( ! a.isSameNode(f) ); 
        
        a = new AWS_XMLDom.Element(); 
        system.assertEquals( a.firstChild(), null, ' must be null' );
        
        system.assertEquals( a.getElementByTagName('bad'), null);       
     }

    public static testmethod void testRSS() { 
        
        String feed = '<?xml version="1.0" encoding="UTF-8"?>'+
            '<feed xmlns="http://purl.org/atom/ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:feedburner="http://rssnamespace.org/feedburner/ext/1.0" version="0.3">'+
            '<title>Force.com Blog</title>' +
            '<link rel="alternate" type="text/html" href="http://blog.sforce.com/sforce/" />' +
            '<id>tag:typepad.com,2003:weblog-125619</id>' +
            '<link rel="service.post" type="application/x.atom+xml" href="http://www.typepad.com/t/atom/weblog/blog_id=125619" title="Force.com Blog" />' +
            '<modified>2008-01-23T20:27:30Z</modified>' +
            '<tagline></tagline>' +
            '<generator url="http://www.typepad.com/">TypePad</generator>' +
            '<info type="application/xhtml+xml">' +
            '<div xmlns="http://www.w3.org/1999/xhtml">This is an Atom formatted XML site feed. It is intended to be viewed in a Newsreader or syndicated to another site. Please visit <a href="http://blog.sforce.com/sforce/">Force.com Blog</a> for more info.</div>' +
            '</info><entry>' +
            '<title>Tour de Force Global Kickoff - it\'s a wrap!</title>' +
            '<link rel="alternate" type="text/html" href="http://feeds.feedburner.com/~r/SforceBlog/~3/221839184/tour-de-force-g.html" />' +
            '<link rel="service.edit" type="application/x.atom+xml" href="http://www.typepad.com/t/atom/weblog/blog_id=125619/entry_id=44564390" title="Tour de Force Global Kickoff - it\'s a wrap!" />' +
            '<id>tag:typepad.com,2003:post-44564390</id>' +
            '<issued>2008-01-23T12:27:30-08:00</issued>' +
            '<modified>2008-01-23T20:27:30Z</modified>' +
            '<created>2008-01-23T20:27:30Z</created>' +
            '<summary>Thank you to everyone that joined us last Thursday in San Francisco as we kicked off Tour de Force - we\'re delighted that you were able help us launch the Tour de Force roadshow to unleash the Force.com platform around...</summary>' +
            '<author><name>Mark Trang</name></author>' +
            '<content type="application/xhtml+xml" xml:lang="en-US" xml:base="http://blog.sforce.com/sforce/"><div xmlns="http://www.w3.org/1999/xhtml">'+
            '<p>Thank you to everyone that joined us last Thursday in San Francisco as we kicked off Tour de Force - </p></div></content>'+
            '<feedburner:origLink>http://blog.sforce.com/sforce/2008/01/tour-de-force-g.html</feedburner:origLink></entry></feed>';
        AWS_XMLDom d = new AWS_XMLDom(feed);  
        list<AWS_XMLDom.element> tmp ;  
        d.dumpAll();
        AWS_XMLDom.Element e2 = d.ownerDocument().getElementByTagName('entry');
        e2.dumpAll();   
        system.assertEquals('entry', e2.nodeName );         
        system.assertEquals( e2.getValue('title'), 'Tour de Force Global Kickoff - it\'s a wrap!');
        
        
        AWS_XMLDom.Element[] el = d.ownerDocument().getElementsByTagName('link');
        for(AWS_XMLDom.Element ee:el) { 
            system.debug( ee.path() );
            ee.dump(); 
        }
        
        e2 = d.ownerDocument().getElementByTagName('name');
        System.assertEquals('Mark Trang', e2.nodeValue);
        
        e2 = d.ownerDocument().getElementsByPath('/feed/title')[0];
        e2.dump();
        
        /* 
         * experimental path based patern matching, sort of like xpath, 
         * but simpler, just matches a path() string with 
         * the pattern supplied
         */
        // children of entry
        el= d.ownerDocument().getElementsByPath('/feed/entry/.*');
        d.dumpList(el);
        system.assertEquals( 14, el.size() );
        
        // just the entry node
        el= d.ownerDocument().getElementsByPath('/feed/entry');
        system.assertEquals( 1, el.size() );
        
        // entry and children
        el= d.ownerDocument().getElementsByPath('/.*/entry.*');
        system.assertEquals( 15, el.size() );
    }      
}