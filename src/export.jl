#=
struct MRFormat{R, C}
    r::R
    c::C
    f::Function
end
=#

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
:Rsq     => "R²",
:ARsq     => "Adjusted R²",
:Clast_pred     => "Predicted Clast",
:AUCtau     => "AUC τ",
:AUCinf     => "AUCinf",
:AUCinf_pred => "Predicted AUCinf",
:AUCpct     => "AUC%",
:Accind => "Accumulation index",
:Fluc => "Fluctuation")


const STAT_DICT = Dict(
:mean   => "Mean",
:sd   => "SD",
:se   => "SE",
:median   => "Median",
:geom   => "Goemtric Mean",
:min => "Minimum",
:max => "Maximum",
:n => "N",
:posn     => "Positive N",
:cv     => "CV",
:lci     => "CI Lower",
:uci     => "CI Upper",
:q1 => "Q1",
:q3 => "Q3",
:iqr => "Interquartile range",
:umeanci => "Mean CI Lower",
:lmeanci => "Mean CI Upper",
:geocv => "CV(Geo)")

const STAT_DICT_RU = Dict(
:mean   => "Среднее арифметическое",
:sd   => "Стандартное отклонение",
:se   => "Стандартная ошибка",
:median   => "Медиана",
:geom   => "Среднее геометрическое",
:min => "Минимум",
:max => "Максимум",
:n => "Кол-во",
:posn     => "Не отриц. кол-во",
:cv     => "Коэф. вариации",
:lci     => "ДИ Нижн.",
:uci     => "ДИ Верхн.",
:q1 => "Нижн. квартиль",
:q3 => "Верхн. квартиль",
:iqr => "Интерквартильный размах",
:umeanci => "ДИ для среднего Верхн.",
:lmeanci => "ДИ для среднего Нижн.",
:geocv => "CV(Geo)")

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
#=
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
=#
function cellformat(data, missingval, r, c, ::Nothing)
    val = data[r, c]
    if val === missing return missingval end
    if val === NaN return "NaN" end
    if val === nothing return missingval end
    if isa(val, AbstractFloat)
        return round(val, digits=3)
    else
        return val
    end
end

function cellformat(data, missingval, r, c, digits::Int = 3)
    val = data[r, c]
    if val === missing return missingval end
    if val === NaN return "NaN" end
    if val === nothing return missingval end
    if isa(val, AbstractFloat)
        return round(val, digits=digits)
    else
        return val
    end
end

function cellformat(data, missingval, r, c, format::String)
    val = data[r, c]
    if val === missing return missingval end
    if val === NaN return "NaN" end
    if val === nothing return missingval end
    try
        return Printf.format(Printf.Format(format), val)
    catch
        return val
    end

    if isa(val, AbstractFloat)
        return round(val, digits=digits)
    else
        return val
    end
end

function cellformat(data, missingval, r, c, format::Function)
    val = data[r, c]
    return(format(r, c, val))
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
    htmlexport(data, file; mode = "w",
        sort = nothing, nosort = false, rspan = nothing, title="Title",
        dict::Union{Symbol, Dict} = :undef, body = false, missingval = "")

HTLM export.

By default sort by first column.
"""
function htmlexport(data, file::AbstractString; mode = "w", kwargs...)
    out =  htmlexport_(data; kwargs...)
    open(file, mode) do io
        write(io, out)
    end
    nothing
end
"""
    htmlexport(data; io::Union{IO, Nothing, String} = stdout, strout = false,
        sort = nothing, nosort = false, rspan = nothing, title="Title",
        dict::Union{Symbol, Dict} = :undef, format = nothing, body = false, missingval = "")

HTLM export.

* `sort`
* `nosort`
* `rspan`
* `title`
* `dict` 
* `format` - try to apply format to cells: if `nothing` try to round AbstractFloat to 3 digits, if String try to apply format with @sprintf, 
if Function return result of function `f(r,c,v)`, where r - row, c - column, v - cell value; 
* `body`
* `missingval`

"""
function htmlexport(data; io::Union{IO, Nothing, String} = stdout, strout = false, kwargs...)
    out = htmlexport_(data; kwargs...)
    if isa(io, IO)
        write(io, out)
    end
    if strout || isnothing(io) return out end
    nothing
end

function htmlexport_(data; 
    sort = nothing, 
    nosort = false, 
    rspan = nothing, 
    title="Title", 
    dict::Union{Symbol, Dict} = :undef, 
    format = nothing, 
    body = true, 
    missingval = "")

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


    rown        = size(data, 1)
    coln        = size(data, 2)
    tablematrix = zeros(Int, rown, coln)

    h_row = """
    <TR VALIGN=BOTTOM CLASS=cell>"""
    for c = 1:coln
        h_row *= """
        <TD CLASS=hcell>
            <P ALIGN=CENTER CLASS=cell>
                <FONT CLASS=cell> $(dictnames(cnames[c], dict)) </FONT>
            </P>
        </TD>"""
    end
    if !nosort
        sort!(data, sort)
    end

    tablematrix = make_tablematrix(data)

    for r = 1:rown
        rowstr = ""
        for c = 1:coln
            if tablematrix[r,c] > 0 || !any(x -> x == cnames[c], rspan)
                rowstr *= """
            <TD ROWSPAN=$(any(x -> x == cnames[c], rspan) ? string(tablematrix[r,c]) : "1") VALIGN=TOP CLASS=\"$(cell_class(r, rown, c, coln))\">
                <P ALIGN=RIGHT CLASS=cell>
                    <FONT CLASS=cell><SPAN LANG="en-US">$(cellformat(data, missingval, r, c, format))</SPAN></FONT>
                </P>
            </TD>"""
            end
        end
        push!(rowlist, rowstr)
    end
    t_body = ""
    for r in rowlist
        t_body *="""
        <TR CLASS=cell> $r
        </TR>"""
    end

    mdict = Dict(:TITLE => title, :COLN => coln, :T_CSS => T_CSS, :HEADROW => h_row, :TBODY => t_body, :FOOTTXT => HTML_PBR)

    table = render(HTML_TABLE, mdict)
    if body
        mdict[:TABLE] = table
        return render(HTML_BODY, mdict)
    end
    table
end

#=
function htmlexport_(data::ConTab; title = "Title", body = true)

    rowlist = Array{String, 1}(undef, 0)
    row_n = copy(data.coln)
    pushfirst!(row_n, "")
    push!(row_n, "Total")
    h_row = """
    <TR VALIGN=BOTTOM CLASS=cell>"""
    for c in row_n
        h_row *= """
        <TD CLASS=hcell>
            <P ALIGN=CENTER CLASS=cell>
                <FONT CLASS=cell> $c </FONT>
            </P>
        </TD>"""
    end

    tab  = hcat(data.tab, sum(data.tab, dims = 2))
    tab  = hcat(data.rown, tab)
    rown        = size(tab, 1)
    coln        = size(tab, 2)
    for r = 1:rown
        rowstr = ""
        for c = 1:coln
            rowstr *= """
            <TD VALIGN=TOP CLASS=\"$(cell_class(r, rown, c, coln))\">
                <P ALIGN=RIGHT CLASS=cell>
                    <FONT CLASS=cell><SPAN LANG="en-US">$(tab[r,c])</SPAN></FONT>
                </P>
            </TD>"""
        end
        push!(rowlist, rowstr)
    end
    t_body = ""
    for r in rowlist
        t_body *="""
        <TR CLASS=cell> $r
        </TR>"""
    end
    foottxt = ""
    if haskey(data.id, :ColName) foottxt *= string(data.id[:ColName]) end
    mdict = Dict(:TITLE => title, :COLN => size(data.tab, 2) + 2, :T_CSS => T_CSS, :HEADROW => h_row, :TBODY => t_body, :FOOTTXT => foottxt)
    table = render(HTML_TABLE, mdict)
    if body
        mdict[:TABLE] = table
        return render(HTML_BODY, mdict)
    end
    table
end
=#
#=
function htmlexport_(data::DataSet; title="Title", body = true)
    tables = ""
    for i in getdata(data)
        tables *= htmlexport_(i; title = "", body = false) * "\n"
    end
    mdict = Dict(:TITLE => title, :T_CSS => T_CSS)
    if body
        mdict[:TABLE] = tables
        return render(HTML_BODY, mdict)
    end
    tables
end
=#