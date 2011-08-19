<%@ page import="com.sforce.soap.partner.sobject.SObject"%>

<%  
	SObject rma = (SObject)request.getAttribute("rma");
	SObject[] items = (SObject[])request.getAttribute("items");
	SObject[] attachments = (SObject[])request.getAttribute("attachments");
%>

<%@ include file="/jsp/top.jsp" %>

<span class="nav"><a href="/salesOrderLookup.htm">Search</a></span><p/>
<span class="title">RMA Display</span>

<% if (attachments.length > 0) { %><p/>
	
	<table border="0" cellspacing="1" cellpadding="5">
	<% for (SObject a : attachments) { %>
		<tr>
			<td><img src="pdf.jpeg" width="50"></td>
			<td><a href="https://s3.amazonaws.com/RMAforce/<%= (String)a.getField("Name") %>"><%= (String)a.getField("Name") %></td>
		</tr>
	<% } %>
	</table>
	
<% } %><p/>

<table border="0" cellspacing="1" cellpadding="5" bgcolor="#CCCCCC">
<tr bgcolor="#407BA8">
	<td style="color: #ffffff; font-weight: bold;">ID</td>
	<td bgcolor="#ffffff"><%= (String)rma.getField("Name") %></td>
</tr>
<tr bgcolor="#407BA8">
	<td style="color: #ffffff; font-weight: bold;">Contact Name</td>
	<td bgcolor="#ffffff"><%= (String)rma.getField("Contact_Name__c") %></td>
</tr>		
<tr bgcolor="#407BA8">
	<td style="color: #ffffff; font-weight: bold;">Contact Email</td>
	<td bgcolor="#ffffff"><%= (String)rma.getField("Contact_Email__c") %></td>
</tr>		
<tr bgcolor="#407BA8">
	<td style="color: #ffffff; font-weight: bold;">Contact Phone</td>
	<td bgcolor="#ffffff"><%= (String)rma.getField("Contact_Phone__c") %></td>
</tr>		
<tr bgcolor="#407BA8">
	<td style="color: #ffffff; font-weight: bold;">Description</td>
	<td bgcolor="#ffffff"><%= (String)rma.getField("Description__c") %></td>
</tr>		
<tr bgcolor="#407BA8">
	<td style="color: #ffffff; font-weight: bold;">Origin</td>
	<td bgcolor="#ffffff"><%= (String)rma.getField("Origin__c") %></td>
</tr>		
<tr bgcolor="#407BA8">
	<td style="color: #ffffff; font-weight: bold;">Status</td>
	<td bgcolor="#ffffff"><%= (String)rma.getField("Status__c") %></td>
</tr>		
<tr bgcolor="#407BA8">
	<td style="color: #ffffff; font-weight: bold;">Return Reason</td>
	<td bgcolor="#ffffff"><%= (String)rma.getField("Type__c") %></td>
</tr>		
<tr bgcolor="#407BA8">
	<td style="color: #ffffff; font-weight: bold;">Entered</td>
	<td bgcolor="#ffffff"><%= (String)rma.getField("CreatedDate") %></td>
</tr>		
<tr bgcolor="#407BA8">
	<td style="color: #ffffff; font-weight: bold;">Sales Order</td>
	<td bgcolor="#ffffff"><a href="salesOrderDisplay.htm?salesOrderId=<%= (String)rma.getField("Sales_Order__c") %>"><%= (String)rma.getChild("Sales_Order__r").getField("Name") %></a></td>
</tr>				
</table></p>

<% if (items.length > 0) { %>
	
	<table border="0" cellspacing="1" cellpadding="5" bgcolor="#CCCCCC">
	<tr bgcolor="#407BA8">
		<td style="color: #ffffff; font-weight: bold;">ID</td>
		<td style="color: #ffffff; font-weight: bold;">Sales Order Item</td>
		<td style="color: #ffffff; font-weight: bold;">Quantity</td>
	</tr>
	<% for (SObject item : items) { %>
		<tr style="background:#ffffff" onMouseOver="this.style.background='#eeeeee';" onMouseOut="this.style.background='#ffffff';">
			<td><%= (String)item.getField("Name") %></td>
			<td><%= (String)item.getChild("Sales_Order_Item__r").getField("Name") %></td>
			<td><%= ((String)item.getField("Quantity__c")).substring(0,1) %></td>
		</tr>
	<% } %>
	</table>
	
<% } %>

