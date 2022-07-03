const PD_DICT = Dict(
:AUCABL   => "AUC above BL",
:AUCBBL   => "AUC below BL",
:AUCATH   => "AUC above TH",
:AUCBTH   => "AUC below TH",
:AUCBLNET => "AUC BL NET",
:AUCTHNET => "AUC TH NET",
:AUCDBLTH => "AUC between BL/TH",
:TABL     => "Time above BL",
:TBBL     => "Time below BL",
:TATH     => "Time above TH",
:TBTH     => "Time below TH")

const PK_DICT = Dict(
:AUClast   => "AUClast",
:Cmax   => "Cmax",
:Tmax   => "Tmax",
:AUMClast   => "AUMClast",
:MRTlast => "MRTlast",
:Kel => "Kel",
:HL => "HL",
:Rsq     => "Rsq",
:AUCinf     => "AUCint",
:AUCpct     => "AUC%")


function dictnames(name::Any, dict::Union{Symbol, Dict})
    if !isa(dict, Dict) return name end
    dlist = keys(dict)
    if !(typeof(name) <: eltype(dlist)) return name end
    if name in dlist return dict[name] else return name end
end

function cellformat(val, missingval)
    if val === missing return missingval end
    if val === NaN return "NaN" end
    if val === nothing return missingval end
    if isa(val, AbstractFloat)
        return round(val, digits=3)
    else
        return val
    end
end

"""
    htmlexport(data, file; mode = "w",
        sort = nothing, nosort = false, rspan = nothing, title="Title",
        dict::Union{Symbol, Dict} = :undef, body = false, missingval = "")

HTLM export.

By default sort by first column.
"""
function htmlexport(data, file; mode = "w", sort = nothing, nosort = false, rspan = nothing, title="Title", dict::Union{Symbol, Dict} = :undef, body = false, missingval = "")
    out =  htmlexport_(data; sort = sort, nosort = nosort, rspan = rspan, title = title, dict = dict, body = body, missingval = missingval)
    open(file, mode) do io
        write(io, out)
    end
    nothing
end
"""
    htmlexport(data; io::Union{IO, Nothing, String} = stdout, strout = false,
        sort = nothing, nosort = false, rspan = nothing, title="Title",
        dict::Union{Symbol, Dict} = :undef, body = false, missingval = "")

HTLM export.

"""
function htmlexport(data; io::Union{IO, Nothing, String} = stdout, strout = false, sort = nothing, nosort = false, rspan = nothing, title="Title", dict::Union{Symbol, Dict} = :undef, body = false, missingval = "")
    out = htmlexport_(data; sort = sort, nosort = nosort, rspan = rspan, title=title, dict = dict, body = body, missingval = missingval)
    if isa(io, IO)
        write(io, out)
    end
    if strout return out end
    nothing
end

function htmlexport_(data; sort = nothing, nosort = false, rspan = nothing, title="Title", dict::Union{Symbol, Dict} = :undef, body = false, missingval = "")
    rowlist = Array{String,1}(undef, 0)
    cnames  = Symbol.(names(data))
    ###
    if isnothing(sort) nosort = true end
    if isa(sort, Vector) && length(sort) == 0 nosort = true end

    if !nosort
        if isa(sort, Symbol)
            sort = [sort]
        elseif !isa(sort, Vector)
            sort = [Symbol(sort)]
        end
        if isa(sort, Vector) && !(eltype(sort) <: Symbol)
            sort = Symbol.(sort)
        end
        if !(sort ⊆ cnames)
            error("$sort !⊆ $cnames")
        end
        cnames = append!(copy(sort), setdiff(cnames, sort))
        data = data[!, cnames]
    end
    ###

    ###
    if isnothing(rspan)
        rspan = []
    else
        if isa(rspan, Symbol)
            rspan = [rspan]
        elseif !isa(rspan, Vector)
            rspan = [Symbol(rspan)]
        end
        if isa(rspan, Vector) && !(eltype(rspan) <: Symbol) && length(rspan) > 0
            rspan = Symbol.(rspan)
        end
        if !(rspan ⊆ cnames)
            error("$rspan !⊆ $cnames")
        end
    end

    ###
    if dict == :pd
        dict = PD_DICT
    elseif dict == :pk
        dict = PK_DICT
    end


    html_f = HTML_F
    html_pbr = HTML_PBR
    rown        = size(data, 1)
    coln        = size(data, 2)
    tablematrix = zeros(Int, rown, coln)
    mdict = Dict(:TITLE => title, :COLN => coln)

    out = render(HTML_H, mdict)

    out *= """
    <TABLE CELLPADDING=0 CELLSPACING=0>
        <THEAD>
        <TR CLASS=cell>
            <TD COLSPAN="""*string(coln)*""" CLASS=title>
                <P ALIGN=CENTER CLASS=cell>
                <FONT CLASS=title><B> """*title*""" </B></FONT></P>
            </TD>
        </TR>"""

        out *= """
    <TR VALIGN=BOTTOM CLASS=cell>"""

        for c = 1:coln
            out *= """
        <TD CLASS=hcell>
            <P ALIGN=CENTER CLASS=cell>
            <FONT CLASS=cell> """*string(dictnames(cnames[c], dict))*""" </FONT></P>
        </TD>"""
        end

        out *= """
    </TR>
    </THEAD>
    <TBODY>"""
    if !nosort
        sort!(data, sort)
    end
    tablematrix .= 1
    for c = 1:coln
        s = true
        while s
            s = false
            for r = 2:rown
                if tablematrix[r,c] !=0 && !ismissing(data[r,c]) && !ismissing(data[r-1,c]) && data[r,c] == data[r-1,c]
                    tablematrix[r,c] -= 1;
                    tablematrix[r-1,c] += 1;
                    s = true;
                end
            end
        end
    end
    for c = 2:coln
        for r = 1:rown
            if tablematrix[r, c] > tablematrix[r, c - 1]
                for i = 1:tablematrix[r, c] - 1
                    if tablematrix[r + i, c - 1] > tablematrix[r + i, c]
                        tablematrix[r + i, c] = tablematrix[r, c] - i
                        tablematrix[r, c] = i
                        break
                    end
                end
            end
        end
    end
        #print(tablematrix)

    for r = 1:rown
        rowstr = ""
        for c = 1:coln
            if tablematrix[r,c] > 0 || !any(x -> x == cnames[c], rspan)
                rowstr *= """
            <TD ROWSPAN="""*(any(x -> x == cnames[c], rspan) ? string(tablematrix[r,c]) : "1")*""" VALIGN=TOP CLASS=\""""*((c > 1 && c < coln) ? "midcell" : "cell")*"""\">
                <P ALIGN=RIGHT CLASS=cell>
                <FONT CLASS=cell><SPAN LANG="ru-RU">"""*string(cellformat(data[r,c], missingval))*"""</SPAN></FONT></P>
            </TD>"""
            end
        end
        push!(rowlist, rowstr)
    end

    for r in rowlist
        out *="""
        <TR CLASS=cell> """*r*"""
        </TR>"""
    end

    out *= """
    </TBODY>
    <TFOOT><TR><TD COLSPAN="""*string(coln)*""" class=foot></TD><TR></TFOOT>
    </TABLE>"""
    out *= html_f

    out
end
