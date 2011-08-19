<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ page import="com.sforce.soap.partner.sobject.SObject"%>

<%  
	SObject salesOrder = (SObject)request.getAttribute("salesOrder");
	SObject[] orderItems = (SObject[])request.getAttribute("orderItems");
%>

<%@ include file="/jsp/top.jsp" %>

<span class="nav"><a href="/salesOrderDisplay.htm?salesOrderId=<%= (String)salesOrder.getField("Id") %>">Back</a></span><p/>
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
	
	<p/><span class="title">New RMA</span><p/>
		
	<form:form method="post">
	<input type="hidden" name="account" value="<%= (String)salesOrder.getField("Account__c") %>">
	<input type="hidden" name="salesOrder" value="<%= (String)salesOrder.getField("Id") %>">
	
	<table border="0" cellspacing="1" cellpadding="5" bgcolor="#CCCCCC">
	<tr bgcolor="#407BA8">
		<td style="color: #ffffff; font-weight: bold;">Contact Name</td>
		<td bgcolor="#ffffff"><form:input path="contactName"/></td>
	</tr>		
	<tr bgcolor="#407BA8">
		<td style="color: #ffffff; font-weight: bold;">Contact Email</td>
		<td bgcolor="#ffffff"><form:input path="contactEmail"/></td>
	</tr>		
	<tr bgcolor="#407BA8">
		<td style="color: #ffffff; font-weight: bold;">Contact Phone</td>
		<td bgcolor="#ffffff"><form:input path="contactPhone"/></td>
	</tr>		
	<tr bgcolor="#407BA8">
		<td style="color: #ffffff; font-weight: bold;">Product</td>
		<td bgcolor="#ffffff">
		<select name="product">
			<% for (SObject item : orderItems) { %>
			<option value="<%= (String)item.getField("Id") %>"><%= (String)item.getField("Name") %>
			<% } %>
		</select>
		</td>
	</tr>	
	<tr bgcolor="#407BA8">
		<td style="color: #ffffff; font-weight: bold;">Quantity</td>
		<td bgcolor="#ffffff"><form:input path="quantity"/></td>
	</tr>	
	<tr bgcolor="#407BA8">
		<td style="color: #ffffff; font-weight: bold;">Return Reason</td>
		<td bgcolor="#ffffff">
		<select name="reason">
			<option>Wrong color
			<option>Wrong size
			<option>Did not work
			<option>Broken
			<option>Not what I ordered
		</select>
		</td>
	</tr>	
	<tr bgcolor="#407BA8">
		<td style="color: #ffffff; font-weight: bold;">Description</td>
		<td bgcolor="#ffffff"><form:textarea path="description" /></td>
	</tr>		
	<tr>
		<td colspan="2" bgcolor="#ffffff" align="center"><input type="submit" value="Submit"></td>
	</tr>			
	</table></p>
	</form:form>
	
<% } %>
      
<%@ include file="/jsp/bottom.jsp" %>