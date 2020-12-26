<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="prelude.jsp"%>
<%@ page import="org.apache.lucene.analysis.miscellaneous.ASCIIFoldingFilter" %>
<%@ page import="alix.fr.Tag" %>
<%@ page import="alix.lucene.analysis.tokenattributes.CharsAtt" %>
<%@ page import="alix.lucene.analysis.FrDics" %>
<%@ page import="alix.lucene.analysis.FrDics.LexEntry" %>
<%@ page import="alix.lucene.search.FieldText" %>
<%@ page import="alix.lucene.search.TermList" %>
<%@ page import="alix.util.Char" %>
<%!

final static HashSet<String> FIELDS = new HashSet<String>(Arrays.asList(new String[] {Alix.BOOKID, "byline", "year", "title"}));
static final DecimalFormat dfscore = new DecimalFormat("0.00000000", ensyms);

final static Sort bookSort = new Sort(
  new SortField[] {
    new SortField(YEAR, SortField.Type.INT),
    new SortField(Alix.BOOKID, SortField.Type.STRING),
  }
);

private static final int OUT_HTML = 0;
private static final int OUT_CSV = 1;
private static final int OUT_JSON = 2;

static public enum Ranking implements Option {
  occs("Occurrences") {
    @Override
    public Specif specif() {
      return new SpecifOccs();
    }
  },
  
  bm25("BM25") {
    @Override
    public Specif specif() {
      return new SpecifBM25();
    }
    
  },

  tfidf("tf-idf") {
    @Override
    public Specif specif() {
      return new SpecifTfidf();
    }
    
  },

  jaccard("Jaccard") {
    @Override
    public Specif specif() {
      return new SpecifJaccard();
    }
    
  },
  
  /* pas bon
  jaccardtf("Jaccard") {
    @Override
    public Specif specif() {
      return new SpecifJaccardTf();
    }
  },
  */
  
  /*
  dice("Dice (par livre)") {
    @Override
    public Specif specif() {
      return new SpecifDice();
    }
  },
  */
  
  dicetf("Dice") {
    @Override
    public Specif specif() {
      return new SpecifDiceTf();
    }
  },


  hypergeo("Distribution hypergeometrique (Lafon)") {
    @Override
    public Specif specif() {
      return new SpecifHypergeo();
    }
    
  },

  
  ;

  abstract public Specif specif();

  
  private Ranking(final String label) {  
    this.label = label ;
  }

  // Repeating myself
  final public String label;
  public String label() { return label; }
  public String hint() { return null; }
}

static public enum Cat implements Option {
  NOSTOP("Mots pleins"), 
  SUB("Substantifs"), 
  NAME("Noms propres"),
  VERB("Verbes"),
  ADJ("Adjectifs"),
  ADV("Adverbes"),
  ALL("Tout"),
  ;
  private Cat(final String label) {  
    this.label = label ;
  }

  final public String label;
  public String label() { return label; }
  public String hint() { return null; }
}

static public enum Order implements Option {
  top("Scores le + haut"), 
  last("Scores le + bas (hors 0)"), 
  ;
  private Order(final String label) {  
    this.label = label ;
  }

  final public String label;
  public String label() { return label; }
  public String hint() { return null; }
}


private static String lines(final FormEnum terms, final Mime mime, final String q)
{
  StringBuilder sb = new StringBuilder();

  CharsAtt att = new CharsAtt();
  int no = 1;
  Tag zetag;
  // dictonaries coming fron analysis, wev need to test attributes
  boolean first = true;
  while (terms.hasNext()) {
    terms.next();
    // if (term.isEmpty()) continue; // ?
    // get nore info from dictionary
    
    switch(mime) {
      case json:
        if (!first) sb.append(",\n");
        jsonLine(sb, terms, no);
        break;
      case csv:
        csvLine(sb, terms, no);
        break;
      default:
        // sb.append(entry+"<br/>");
        htmlLine(sb, terms, no, q);
    }
    no++;
    first = false;
  }

  return sb.toString();
}

/**
 * An html table row &lt;tr&gt; for lexical frequence result.
 */
private static void htmlLine(StringBuilder sb, final FormEnum forms, final int no, final String q)
{
  String term = forms.label();
  // .replace('_', ' ') ?
  sb.append("  <tr>\n");
  sb.append("    <td class=\"no left\">").append(no).append("</td>\n");
  sb.append("    <td class=\"form\">");
  sb.append("    <a");
  {
    sb.append(" href=\"" + kwic + "?sort=score&amp;q=");
    if (q != null) sb.append(Jsp.escUrl(q));
    // sb.append(" %2B")
    sb.append(Jsp.escUrl(term));
    // sb.append("&amp;expression=on");
    sb.append("\"");
  }
  sb.append(">");
  sb.append(term);
  sb.append("</a>");
  sb.append("</td>\n");
  sb.append("    <td>");
  sb.append(Tag.label(forms.tag()));
  sb.append("</td>\n");
  sb.append("    <td class=\"num\">");
  sb.append(forms.occsMatching()) ;
  sb.append("</td>\n");
  sb.append("    <td class=\"num\">");
  sb.append(forms.docsMatching()) ;
  sb.append("</td>\n");
  // fréquence
  // sb.append(dfdec1.format((double)forms.occsMatching() * 1000000 / forms.occsPart())) ;
  sb.append("    <td class=\"num\">");
  sb.append(forms.score());
  sb.append("</td>\n");
  sb.append("    <td></td>\n");
  sb.append("    <td class=\"no right\">").append(no).append("</td>\n");
  sb.append("  </tr>\n");
}

private static void csvLine(StringBuilder sb, final FormEnum terms, final int no)
{
  sb.append(terms.label().replaceAll("\t\n", " "));
  sb.append("\t").append(Tag.label(terms.tag())) ;
  sb.append("\t").append(terms.docsMatching()) ;
  sb.append("\t").append(terms.occsMatching()) ;
  sb.append("\n");
}

static private void jsonLine(StringBuilder sb, final FormEnum terms, final int no)
{
  sb.append("    {\"word\" : \"");
  sb.append(terms.label().replace( "\"", "\\\"" ).replace('_', ' ')) ;
  sb.append("\"");
  sb.append(", \"weight\" : ");
  sb.append(dfdec3.format(terms.score()));
  sb.append(", \"attributes\" : {\"class\" : \"");
  sb.append(Tag.label(Tag.group(terms.tag())));
  sb.append("\"}");
  sb.append("}");
}%>
<%
  // parameters
final String q = tools.getString("q", null);


// final FacetSort sort = (FacetSort)tools.getEnum("sort", FacetSort.freq, Cookies.freqsSort);
Cat cat = (Cat)tools.getEnum("cat", Cat.NOSTOP);
Ranking ranking = (Ranking)tools.getEnum("ranking", Ranking.occs);
String format = tools.getString("format", null);
//if (format == null) format = (String)request.getAttribute(Dispatch.EXT);
Mime mime = (Mime)tools.getEnum("format", Mime.html);
Order order = (Order)tools.getEnum("order", Order.top);


int limit = tools.getInt("limit", -1);
// limit a bit if not csv
if (mime == Mime.csv);
else if (limit < 1 || limit > 5000) limit = 2000;


int left = tools.getInt("left", 5);
if (left < 0) left = 0;
else if (left > 10) left = 10;
int right = tools.getInt("right", 5);
if (right < 0) right = 0;
else if (right > 10) right = 10;

Corpus corpus = null;

BitSet filter = null; // if a corpus is selected, filter results with a bitset
String bookid = tools.getString("book", null);
if (bookid != null) filter = Corpus.bits(alix, Alix.BOOKID, new String[]{bookid});

final String field = TEXT; // the field to process

FieldText fstats = alix.fieldText(field);

Specif specif = ranking.specif();


TagFilter tags = new TagFilter();
// filtering
switch (cat) {
  case SUB:
    tags.setGroup(Tag.SUB);
    break;
  case NAME:
    tags.setGroup(Tag.NAME);
    break;
  case VERB:
    tags.setGroup(Tag.VERB);
    break;
  case ADJ:
    tags.setGroup(Tag.ADJ);
    break;
  case ADV:
    tags.setGroup(Tag.ADV);
    break;
  case NOSTOP:
    tags.setAll().noStop(true);
    break;
  case ALL:
    tags = null;
    break;
}
boolean reverse = false;
if (order == Order.last) reverse = true;

FormEnum terms = fstats.iterator(limit, filter, specif, tags, reverse);





if (Mime.json.equals(mime)) {
  response.setContentType(Mime.json.type);
  out.println("{");
  out.println("  \"data\":[");
  out.println( lines(terms, mime, q));
  out.println("\n  ]");
  out.println("\n}");
}
else if (Mime.csv.equals(mime)) {
  response.setContentType(Mime.csv.type);
  StringBuffer sb = new StringBuffer().append(baseName);
  if (corpus != null) {
    sb.append('-').append(corpus.name());
  }
  
  if (q != null) {
    String zeq = q.trim().replaceAll("[ ,;]+", "-");
    final int len = Math.min(zeq.length(), 30);
    char[] zeqchars = new char[len*4]; // 
    ASCIIFoldingFilter.foldToASCII(zeq.toCharArray(), 0, zeqchars, 0, len);
    sb.append('_').append(zeqchars, 0, len);
  }
  response.setHeader("Content-Disposition", "attachment; filename=\""+sb+".csv\"");
  out.print("Mot\tType\tChapitres\tOccurrences");
  out.println();
  out.print( lines(terms, mime, q));
}
else {
%>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title><%=props.get("label")%> [Alix]</title>
    <!-- 
    <link href="<%=hrefHome%>static/ddrlab.css" rel="stylesheet"/>
     -->
    <style type="text/css">

body {
  font-family: monospace;
  font-size:20px;
  line-height: 110%;
}
button,
select {
  font-family: inherit;
  font-size: inherit;
  line-height: inherit;
  /*
  -moz-appearance: none;
  -webkit-appearance: none;
  appearance: none;
  */
  border: 1px solid #000;
  background: #fff;
  cursor: pointer;
}
body {
  padding: 0 45px;
  background-color: #fff;
  background-image: 
    url('data:image/svg+xml;utf-8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 72" fill="rgb(64, 64, 64)" stroke="rgb(192, 192, 192)" stroke-width="3%"><circle cx="24" cy="24" r="8"/></svg>'),
    url('data:image/svg+xml;utf-8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 72" fill="rgb(64, 64, 64)" stroke="rgb(192, 192, 192)" stroke-width="3%"><circle cx="24" cy="24" r="8"/></svg>')
  ;
   background-position: left, right;
   background-size: 43px;
   background-repeat: repeat-y;
}
main {
  border-left: 1.5px #ccc dashed;
  border-right: 1.5px #ccc dashed;
  padding: 0 6px;
}

.sortable thead tr th{
  background: rgba(255, 255, 255, 1);
  position: sticky;
  top: 0;
  z-index: 10;
  border-bottom: 2px solid #666;
}
table.sortable {
  border-spacing: 0;
}
table.sortable caption {
  text-align: left;
}
table.sortable th {
  color: #000 !important;
  text-align: left;
  font-weight: bold;
}
.mod1,
.mod5,
.mod6,
.mod0 {
  background-color: #eeffee;
}
.mod3, .mod8 {
  background-color: #ccffcc;
}
.mod0 td {
  border-bottom: 2px solid #666;
}
.mod5 td {
  border-bottom: 1px solid #000;
}

th.form,
td.form {
  padding-left: 1rem;
}
td.no {
  vertical-align: middle;
  color:  #33CC33;
  font-size: 60%;
  background: #fff;
  border: none;
}
caption {
  padding: 0 30px;
}
td.num {
  text-align: right;
  padding-left: 1ex;
}
td.no.left {
  text-align: right;
  padding-right: 5px;
}
td.no.right {
  text-align: left;
  padding-left: 5px;
}
td.form {
  white-space: nowrap;
}
    </style>
  </head>
  <body>
    <main>
      <table class="sortable" width="100%">
        <caption>
          <form id="sortForm">
             <br/>
               <%
                 if (q == null) {
                                          // out.println(max+" termes");
                                        }
                                        else {
                                          out.println("&lt;<input style=\"width: 2em;\" name=\"left\" value=\""+left+"\"/>");
                                          out.print(q);
                                          out.println("<input style=\"width: 2em;\" name=\"right\" value=\""+right+"\"/>&gt;");
                                          out.println("<input type=\"hidden\" name=\"q\" value=\""+Jsp.escape(q)+"\"/>");
                                        }
               %>
             <label>Sélectionner un livre de Rougemont (ou bien tous les livres)
             <br/><select name="book" onchange="this.form.submit()">
                  <option value="">TOUT</option>
                  <%
                    int[] books = alix.books(bookSort);
                    for (int docId: books) {
                      Document doc = reader.document(docId, FIELDS);
                      String abid = doc.get(Alix.BOOKID);
                      out.print("<option value=\"" + abid + "\"");
                      if (abid.equals(bookid)) out.print(" selected=\"selected\"");
                      out.print(">");
                      out.print(doc.get("year"));
                      out.print(", ");
                      out.print(doc.get("title"));
                      out.println("</option>");
                    }
                  %>
               </select>
             </label>
             
             <br/><label>Filtrer par catégorie grammaticale
             <br/><select name="cat" onchange="this.form.submit()">
                 <option/>
                 <%= cat.options() %>
              </select>
             </label>
             <br/><label>Algorithme d’ordre
             <br/><select name="ranking" onchange="this.form.submit()">
                 <option/>
                 <%= ranking.options() %>
              </select>
             </label>
             <br/><label>Direction
             <br/><select name="order" onchange="this.form.submit()">
                 <option/>
                 <%= order.options() %>
              </select>
             </label>
             
             <br/>
             <br/><button style="width: 100%; text-align: center;" type="submit">Lancer la requête</button>
             <br/>
             <br/>
             <br/>
          </form>
        </caption>
        <thead>
          <tr>
            <td/>
            <th title="Forme graphique indexée">Graphie</th>
            <th title="Catégorie grammaticale">Catégorie</th>
            <th title="Nombre d’occurrences"> Occurrences</th>
            <th title="Nombre de chapitres"> Chapitres</th>
            <th title="Score selon l’algorithme"> Score</th>
            <th width="100%"/>
          <tr>
        </thead>
        <tbody>
          <%= lines(terms, mime, q) %>
        </tbody>
      </table>
      <pre style="text-align: center; line-height: 125%; font-size: 14px;">
██████╗░░█████╗░██╗░░░██╗░██████╗░███████╗███╗░░░███╗░█████╗░███╗░░██╗████████╗░░░░██████╗░░░░░█████╗░
██╔══██╗██╔══██╗██║░░░██║██╔════╝░██╔════╝████╗░████║██╔══██╗████╗░██║╚══██╔══╝░░░░╚════██╗░░░██╔═███╗
██████╔╝██║░░██║██║░░░██║██║░░██╗░█████╗░░██╔████╔██║██║░░██║██╔██╗██║░░░██║░░░░░░░░░███╔═╝░░░██║█╔██║
██╔══██╗██║░░██║██║░░░██║██║░░╚██╗██╔══╝░░██║╚██╔╝██║██║░░██║██║╚████║░░░██║░░░░░░░██╔══╝░░░░░███╔╝██║
██║░░██║╚█████╔╝╚██████╔╝╚██████╔╝███████╗██║░╚═╝░██║╚█████╔╝██║░╚███║░░░██║░░░░░░░███████╗██╗╚█████╔╝
╚═╝░░╚═╝░╚════╝░░╚═════╝░░╚═════╝░╚══════╝╚═╝░░░░░╚═╝░╚════╝░╚═╝░░╚══╝░░░╚═╝░░░░░░░╚══════╝╚═╝░╚════╝░
</pre>
    </main>
    <% out.println("<!-- time\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\" -->"); %>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
  </body>
  <!-- <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
</html>
<%
}
%>
