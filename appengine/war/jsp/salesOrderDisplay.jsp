<%@ page import="com.sforce.soap.partner.sobject.SObject"%>

<%  
	SObject salesOrder = (SObject)request.getAttribute("salesOrder");
	SObject[] orderItems = (SObject[])request.getAttribute("orderItems");
	SObject[] rmas = (SObject[])request.getAttribute("rmas");
%>

<%@ include file="/jsp/top.jsp" %>

<span class="nav"><a href="/salesOrderLookup.htm">Search</a><% if (orderItems.length > 0) { %> &middot; <a href="/rmaCreate.htm?salesOrderId=<%= (String)salesOrder.getField("Id") %>">New RMA</a><% } %><p/></span><p/>
<span class="title">Sales Order Display</span>
<p/>

<table border="0" cellspacing="1" cellpadding="5" bgcolor="#CCCCCC">
<tr bgcolor="#407BA8">
	<td style="color: #ffffff; font-weight: bold;">Name</td>
	<td bgcolor="#ffffff"><%= (String)salesOrder.getField("Name") %></td>
</tr>	
<tr bgcolor="#407BA8">
	<td style="color: #ffffff; font-weight: bold;">Account</td>
	<td bgcolor="#ffffff"><%= (String)salesOrder.getChild("Account__r").getField("Name") %></td>
</tr>	
<tr bgcolor="#407BA8">
	<td style="color: #ffffff; font-weight: bold;">RMAs</td>
	<td bgcolor="#ffffff"><%= ((String)salesOrder.getField("RMAs__c")).substring(0,1) %></td>
</tr>	
</table>

<% if (orderItems.length > 0) { %>

	<p/><span class="title">Sales Order Items</span><p/>
	
	<table border="0" cellspacing="1" cellpadding="5" bgcolor="#CCCCCC">
	<tr bgcolor="#407BA8">
		<td style="color: #ffffff; font-weight: bold;">Name</td>
		<td style="color: #ffffff; font-weight: bold;">Product</td>
		<td style="color: #ffffff; font-weight: bold;">Quantity</td>
	</tr>
	<% for (SObject item : orderItems) { %>
		<tr style="background:#ffffff" onMouseOver="this.style.background='#eeeeee';" onMouseOut="this.style.background='#ffffff';">
			<td><%= (String)item.getField("Name") %></td>
			<td><%= (String)item.getChild("Product__r").getField("Name") %></td>
			<td><%= (String)item.getField("Quantity__c") %></td>
		</tr>
	<% } %>
	</table>
	
<% } %>

<% if (rmas.length > 0) { %>

	<p/><span class="title">RMAs</span><p/>
	
	<table border="0" cellspacing="1" cellpadding="5" bgcolor="#CCCCCC">
	<tr bgcolor="#407BA8">
		<td style="color: #ffffff; font-weight: bold;">Name</td>
		<td style="color: #ffffff; font-weight: bold;">Contact</td>
		<td style="color: #ffffff; font-weight: bold;">Status</td>
		<td style="color: #ffffff; font-weight: bold;">Origin</td>
		<td style="color: #ffffff; font-weight: bold;">Return Reason</td>
		<td style="color: #ffffff; font-weight: bold;">Item</td>
	</tr>
	<% for (SObject rma : rmas) { %>
		<tr style="background:#ffffff" onMouseOver="this.style.background='#eeeeee';" onMouseOut="this.style.background='#ffffff';">
			<td><a href="rmaDisplay.htm?rmaId=<%= (String)rma.getField("Id") %>"><%= (String)rma.getField("Name") %></a></td>
			<td><%= (String)rma.getField("Contact_Name__c") %></td>
			<td><%= (String)rma.getField("Status__c") %></td>
			<td><%= (String)rma.getField("Origin__c") %></td>
			<td><%= (String)rma.getField("Type__c") %></td>
			<td><%= (String)rma.getField("Type__c") %></td>
		</tr>
	<% } %>
	</table>
	
<% } %>
      
<%@ include file="/jsp/bottom.jsp" %>