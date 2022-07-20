
const HTML_BODY = mt"""<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD>
<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf-8">
<TITLE>{{:TITLE}}</TITLE>
<META NAME="GENERATOR" CONTENT="MetidaReports">
<META NAME="Operator" CONTENT="MetidaReports">
<STYLE TYPE="text/css">
{{{:T_CSS}}}
</STYLE>
</HEAD>
<BODY LANG="en-US" DIR="LTR" leftmargin="40" rightmargin="20" topmargin="20" bottommargin="20">
{{{:TABLE}}}
</BODY>
</HTML>
"""

const T_CSS = """
@page { margin-left: 1in; margin-right: 1in; margin-top: 0.5in; margin-bottom: 0.5in }
P { margin-bottom: 0.08in }

table {
border-collapse: collapse;
min-width: 300px;
width: 100%;
}
P.cell {
 margin-left: 0.04in;
 margin-right: 0.04in;
 margin-top: 0.04in;
 widows: 0;
 orphans: 0
}
P.pbr {
margin-bottom: 0in;
line-height: 0.28in;
widows: 0;
orphans: 0
}
TD.title {
 background-color: #ffffff;
 border: none;
 padding: 0in
}
FONT.title {
 font-size: 9pt;
 color: #010205;
 font-family: Arial,serif;
}
FONT.cell {
 font-size: 8pt;
 color: #010205;
 font-family: Arial,serif;
}
FONT.comment {
 font-size: 7pt;
 color: #010205;
 font-family: Arial,serif;
}
TD.cell {
 min-width: 60px;
 max-width: 100px;
 background-color: #ffffff;
 border-top: 1.00pt solid #aeaeae;
 border-bottom: 1.00pt solid #aeaeae;
 border-left: 1.00pt solid #e0e0e0;
 border-right: 1.00pt solid #e0e0e0;
 padding: 0in
}
TD.hcell {
 background-color: #cccccc;
 border-top: 1.00pt solid #152935;
 border-bottom: 1.00pt solid #152935;
 border-left: 1.00pt solid #152935;
 border-right: 1.00pt solid #152935;
 padding: 0in
}
TD.cell:first-of-type {
 border-left: 1.00pt solid #152935;
}
TD.cell:last-of-type {
 border-right: 1.00pt solid #152935;
}
TR.cell:last-of-type > TD {
 border-bottom: 2.00pt solid #152935;
}
TD.midcell {
min-width: 60px;
max-width: 100px;
background-color: #ffffff;
border-top: 1.00pt solid #aeaeae;
border-bottom: 1.00pt solid #aeaeae;
border-left: 1.00pt solid #e0e0e0;
border-right: 1.00pt solid #e0e0e0;
padding: 0in
}
TD.foot {
border-top: 2.00pt solid #152935;
border-bottom: 2.00pt solid #152935;
}
"""

const HTML_F = """</BODY>
</HTML>"""

const HTML_PBR ="""<P LANG="en-US" ALIGN=LEFT STYLE="margin-bottom: 0in; line-height: 0.28in; widows: 0; orphans: 0"><BR></P>"""


const HTML_TABLE = mt"""
<TABLE CELLPADDING=0 CELLSPACING=0>
    <THEAD>
        <TR CLASS=cell>
            <TD COLSPAN={{:COLN}} CLASS=title>
                <P ALIGN=CENTER CLASS=cell>
                <FONT CLASS=title><B>{{:TITLE}}</B></FONT></P>
            </TD>
        </TR>
        {{{:HEADROW}}}
    </THEAD>
    <TBODY>
        {{{:TBODY}}}
    </TBODY>
    <TFOOT>
        <TR><TD COLSPAN={{:COLN}} class=foot>{{{:FOOTTXT}}} </TD><TR
    </TFOOT>
</TABLE>
"""
