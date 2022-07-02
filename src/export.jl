


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


const STAT_DICT = Dict(
:mean   => "Mean",
:sd   => "SD",
:median   => "Median",
:geom   => "Goemtric Mean",
:min => "Minimum",
:max => "Maximum",
:n => "Num",
:posn     => "Positive Num",
:cv     => "CV",
:lci     => "CI Lower",
:uci     => "CI Upper")

#ppath = dirname(@__FILE__)
#cd(ppath)
#f = open(joinpath(ppath, "json", "pd_text_en.json"), "w")
#JSON.print(f, PD_DICT)
#close(f)


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
#
#
# Make span matrix
function make_tablematrix(data)
    rown        = size(data, 1)
    coln        = size(data, 2)
    tablematrix = ones(Int, rown, coln)
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
    tablematrix
end

function cell_class(r, rn, c, cn)
    (c > 1 && c < cn) ? "midcell" : "cell"
end

"""
    htmlexport(data; io::IO = stdout, sort = [],
        rspan=:all, title="Title", dict::Union{Symbol, Dict} = :undef)

HTLM export.

By default sort by first column.
"""
function htmlexport(data; io::IO = stdout, sort = nothing, nosort = false, rspan = nothing, title="Title", dict::Union{Symbol, Dict} = :undef, body = false, missingval = "")
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
            <TD COLSPAN=$coln CLASS=title>
                <P ALIGN=CENTER CLASS=cell>
                <FONT CLASS=title><B> $title </B></FONT></P>
            </TD>
        </TR>"""

        out *= """
    <TR VALIGN=BOTTOM CLASS=cell>"""

        for c = 1:coln
            out *= """
        <TD CLASS=hcell>
            <P ALIGN=CENTER CLASS=cell>
            <FONT CLASS=cell> $(dictnames(cnames[c], dict)) </FONT></P>
        </TD>"""
        end

        out *= """
    </TR>
    </THEAD>
    <TBODY>"""
    if !nosort
        sort!(data, sort)
    end


    tablematrix = make_tablematrix(data)
    #=
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
    =#
        #print(tablematrix)

    for r = 1:rown
        rowstr = ""
        for c = 1:coln
            if tablematrix[r,c] > 0 || !any(x -> x == cnames[c], rspan)
                rowstr *= """
            <TD ROWSPAN=$(any(x -> x == cnames[c], rspan) ? string(tablematrix[r,c]) : "1") VALIGN=TOP CLASS=\"$(cell_class(r, rown, c, coln))\">
                <P ALIGN=RIGHT CLASS=cell>
                <FONT CLASS=cell><SPAN LANG="en-US">$(cellformat(data[r,c], missingval))</SPAN></FONT></P>
            </TD>"""
            end
        end
        push!(rowlist, rowstr)
    end

    for r in rowlist
        out *="""
        <TR CLASS=cell> $r
        </TR>"""
    end

    out *= """
    </TBODY>
    <TFOOT><TR><TD COLSPAN=$(coln) class=foot> </TD><TR></TFOOT>
    </TABLE>"""
    out *= html_f

        print(io, out)

end
