<%@ page import="com.sforce.soap.partner.sobject.SObject"%>

<%  
	SObject[] salesOrders = (SObject[])request.getAttribute("salesOrders");
%>

<%@ include file="/jsp/top.jsp" %>

<form method="post" action="salesOrderLookup.htm">
	<span class="heading">Sales Order Lookup:</span>
	<p/>
	<input type="text" name="name" value="<% if (request.getParameter("name") != null) { %><%= request.getParameter("name") %><% } else { %>SO<% } %>" style="width: 300px"/>
	&nbsp
	<input type="submit" value="Search"/>
	&nbsp 
</form>
<p/>

<% if (salesOrders != null) { %>

	<% if (salesOrders.length > 0) { %>
		<span class="heading"><%= salesOrders.length %> Sales Orders matching your search criteria:</span>
			
		<p/>
		<table border="0" cellspacing="1" cellpadding="5" bgcolor="#CCCCCC" width="50%">
		<tr bgcolor="#407BA8">
			<td style="color: #ffffff; font-weight: bold;">Name</td>
			<td style="color: #ffffff; font-weight: bold;">Account</td>
			<td style="color: #ffffff; font-weight: bold;">RMAs</td>
		</tr>
		<% for (SObject salesOrder : salesOrders) { %>
			<tr style="background:#ffffff" onMouseOver="this.style.background='#eeeeee';" onMouseOut="this.style.background='#ffffff';">
				<td><a href="salesOrderDisplay.htm?salesOrderId=<%= (String)salesOrder.getField("Id") %>"><%= (String)salesOrder.getField("Name") %></a></td>
				<td><%= (String)salesOrder.getChild("Account__r").getField("Name") %></td>
				<td><%= ((String)salesOrder.getField("RMAs__c")).substring(0,1) %></td>
			</tr>
		<% } %>
		</table>
	
	<% } else { %>
		<span class="heading">No matching accounts found.</span>
	<% } %>

<% } %>

<%@ include file="/jsp/bottom.jsp" %>