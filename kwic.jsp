<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/kwic.jsp" %>
<%@ include file="jsp/prelude.jsp" %>
<%
Pars pars = pars(pageContext);
pars.forms = alix.forms(pars.q);
pars.fieldName = TEXT;
Corpus corpus = (Corpus)session.getAttribute(corpusKey);
long nanos = System.nanoTime();
TopDocs topDocs = getTopDocs(pageContext, alix, corpus, pars.q, pars.sort);
out.println("<!-- get topDocs "+(System.nanoTime() - nanos) / 1000000.0 + "ms\" -->");

%>
<!DOCTYPE html>
<html>
  <head>
   <%@ include file="ddr_head.jsp" %>
   <title><%=props.get("label")%> [Alix]</title>
   <style>
span.left {display: inline-block; text-align: right; width: <%= Math.round(pars.left * 1.0)%>ex; padding-right: 1ex;}
    </style>
  </head>
  <body>
    <header>
    <%@ include file="tabs.jsp" %>
    </header>
    <main>
      <form>
        <input id="q" name="q" value="<%=JspTools.escape(pars.q)%>" autocomplete="off" size="60" autofocus="autofocus" 
          onfocus="this.setSelectionRange(this.value.length,this.value.length);"
          oninput="this.form['start'].value='';"
        />
        <select name="sort" onchange="this.form['start'].value=''; this.form.submit()" title="Ordre">
          <option/>
          <%= pars.sort.options() %>
        </select>
        <% // prev / next nav
        if (pars.start > 1 && pars.q != null) {
          int n = Math.max(1, pars.start-hppDefault);
          out.println("<button name=\"next\" type=\"submit\" onclick=\"this.form['start'].value="+n+"\">◀</button>");
        }
        if (topDocs != null) {
          long max = topDocs.totalHits.value;
          out.println("<input  name=\"start\" value=\""+ pars.start+"\" autocomplete=\"off\" class=\"start\"/>");
          out.println("<span class=\"hits\"> / "+ max  + "</span>");
          int n = pars.start + pars.hpp;
          if (n < max) out.println("<button name=\"next\" type=\"submit\" onclick=\"this.form['start'].value="+n+"\">▶</button>");
        }
        /*
        if (forms == null || forms.length < 2 );
        else if (expression) {
          out.println("<button title=\"Cliquer pour dégrouper les locutions\" type=\"submit\" name=\"expression\" value=\"false\">✔ Locutions</button>");
        }
        else {
          out.println("<button title=\"Cliquer pour grouper les locutions\" type=\"submit\" name=\"expression\" value=\"true\">☐ Locutions</button>");
        }
        */

        %>
        
            
       <% kwic(pageContext, alix, topDocs, pars); %>
      <form>
    <% 
    /*
if (start > 1 && q != null) {
  int n = Math.max(1, start-hppDefault);
  out.println("<button name=\"prev\" type=\"submit\" onclick=\"this.form['start'].value="+n+"\">◀</button>");
}
    
    //  <input type="hidden" id="q" name="q" 
if (topDocs != null) {
  long max = topDocs.totalHits.value;
  out.println("<input  name=\"start\" value=\""+start+"\" autocomplete=\"off\" class=\"start\"/>");
  out.println("<span class=\"hits\"> / "+ max  + "</span>");
  int n = start + hpp;
  if (n < max) out.println("<button name=\"next\" type=\"submit\" onclick=\"this.form['start'].value="+n+"\">▶</button>");
}
    */
        %>
      </form>
    </main>
  </body>
  <!-- <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
</html>