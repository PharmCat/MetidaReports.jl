#=
struct Bioequivalence
    data
    design
    dropout
    subject
    period
    formulation
    sequence
    reference
    subjects
    periods
    formulations
    sequences
end

struct BEReport{Symbol}
    data
    pktime
    pkconc
    vars
    pkvars
    stats
    ncasettings
    design
    subject
    period
    formulation
    sequence
    reference
end

getcol = Tables.getcolumn

function nomissing(data, col)
    c = Tables.getcolumn(data, col)
    !any(ismissing, c)
end

function nomissing(data, cols::AbstractVector)
    for col in cols
        !nomissing(data, col) || return false
    end
    true
end

"""
    bioquivalence(data;
    vars = nothing,
    subject = :subject,
    period = :period,
    formulation = :formulation,
    sequence = :sequence,
    reference = nothing,
    design = nothing,
    io::IO = stdout,
    seqcheck = true,
    dropcheck = true)


"""
function bioequivalence(data;
    vars = nothing,
    subject = :subject,
    period = :period,
    formulation = :formulation,
    sequence = nothing,
    reference = nothing,
    design = nothing,
    io::IO = stdout,
    seqcheck = true,
    dropcheck = true,
    info = true,
    autoseq = false)

    if isa(design, Symbol) design = string(design) end
    if isa(design, String) && design != "parallel" design = uppercase(design) end

    dfnames = Symbol.(Tables.columnnames(data))

    fac = [subject, formulation]

    fac ⊆ dfnames || error("Subject or formulation column not found in dataframe!")

    nomissing(data, subject) || error("Subject column have missing data")

    nomissing(data, formulation) || error("Formulation column have missing data")

    obsnum = size(data, 1)

    subjects = unique(Tables.getcolumn(data, subject))

    subjnum = length(subjects)

    formulations = sort!(unique(Tables.getcolumn(data, formulation)))

    if isnothing(reference)
        @info "Reference formulation not specified. First used: \"$(first(formulations))\"."
        reference = first(formulations)
    else
        reference ∈ formulations || error("Reference formulation \"$(reference)\" not found in dataframe.")
    end

    dropout = nothing
    periods = nothing
    sequences = nothing

    if isnothing(period) && isnothing(sequence) && isnothing(design)
        length(subjects) == length(Tables.getcolumn(data, subject)) || error("Trial design seems parallel, but subjects not unique!")
        design = "parallel"
        println(io, "Parallel desigh used.")
    end


    if isnothing(design) || design != "parallel"

        !isnothing(period) || error("Trial design seems NOT parallel, but period is nothing")

        autoseq || !isnothing(sequence) || error("Trial design seems NOT parallel, but sequence is nothing")

        period ∈ dfnames || error("Period not found in dataframe!")

        if !isnothing(sequence)
            sequence ∈ dfnames || error("Sequence not found in dataframe!")
        end

        periods = sort!(unique(Tables.getcolumn(data, period)))

        push!(fac, period)

        nomissing(data, period) || error("Period column have missing data")

        if autoseq || seqcheck
            subjdict = Dict()
            for p in periods
                for i = 1:obsnum
                    if Tables.getcolumn(data, period)[i] == p
                        subj = Tables.getcolumn(data, subject)[i]
                        if haskey(subjdict, subj)
                            subjdict[subj] *= string(getcol(data, formulation)[i])
                        else
                            subjdict[subj] = string(getcol(data, formulation)[i])
                        end
                    end
                end
            end
        end

        if isnothing(sequence) && autoseq
            sequences = unique(values(subjdict))
        elseif isnothing(sequence)
            error("Sequence is nothing, but autoseq is false")
        else
            if info && autoseq @info "autoseq is true, but sequence defined - sequence column used" end
            sequences = unique(getcol(data, sequence))
            push!(fac, sequence)

            nomissing(data, sequence) || error("Sequence column have missing data")
        end

        if dropcheck
            if !isnothing(vars) && !nomissing(data, vars)
                dropout = true
                @info "Dropuot(s) found in dataframe!"
            elseif !isnothing(vars)
                info && @info "No dropuot(s) found in dataframe!"
                dropout = false
            end
        end

        if seqcheck && !isnothing(sequence)
            for i = 1:obsnum
                if getcol(data, sequence)[i] != subjdict[getcol(data, subject)[i]]
                    error("Sequence error or data is incomplete! \n Subject: $(getcol(data, subject)[i]), Sequence: $(getcol(data, sequence)[i]), auto: $(subjdict[getcol(data, subject)[i]])")
                end
            end
            if length(unique(length.(sequences))) > 1
                error("Some sequence have different length!")
            end
            info && @info "Sequences looks correct..."
        end

        if isnothing(design)
            info && @info "Trying to find out the design..."
            design = Symbol("$(length(formulations))X$(length(sequences))X$(length(periods))")
            @info  "Seems design type is: $design"
        else
            spldes = split(design, "X")
            if length(spldes) != 3 && design != "2X2" error("Unknown design type. Use fXsXp format or \"2Х2\".") end
            if length(formulations) != parse(Int, spldes[1]) error("Design error: formulations count wrong!") end
            if length(sequences) != parse(Int, spldes[2]) error("Design error: sequences count wrong!") end
            if length(periods) != parse(Int, spldes[3]) error("Design error: periods count wrong!") end
            info && @info "Design type seems fine..."
        end
    end
    Bioequivalence(
        data,
        design,
        dropout,
        subject,
        period,
        formulation,
        sequence,
        reference,
        subjects,
        periods,
        formulations,
        sequences)
end

function bereport(data;
    type = :conc,
    pktime = :Time,
    pkconc = :Concentration,
    vars = [:Cmax, :AUClast],
    pkvars = [:Cmax, :AUClast, :Tmax, :Kel, :HL, :MRTlast, :AUCinf, :AUCpct],
    stats = [:n, :posn, :mean, :geom, :sd, :se, :median, :min, :max, :q1, :q3],
    ncasettings = Dict(:adm => :ev, :calcm => :lint, :intpm => nothing),
    design = nothing,
    subject = :Subject,
    period = nothing,
    formulation = :Formulation,
    sequence = nothing,
    reference = nothing
    )

    dfnames = Symbol.(Tables.columnnames(data))

    if type == :conc
        #∉
        pktime ∈ dfnames || error("No time" )
        pkconc ∈ dfnames || error("No concentration")
        subject ∈ dfnames || error("No subject" )
        formulation ∈ dfnames || error("No formulation" )
    end

    BEReport{type}(data,
    pktime,
    pkconc,
    vars,
    pkvars,
    stats,
    ncasettings,
    design,
    subject,
    period,
    formulation,
    sequence,
    reference)
end


function writereport(file, report::BEReport{:conc};
    tpl = tplpath,
    doctype = "md2html",
    css = csspath,
    seqcheck = true,
    dropcheck = true,
    info = true,
    io = stdout,
    autoseq = false)

    sort = [report.subject, report.formulation]

    isnothing(report.period) || push!(sort, report.period)
    isnothing(report.sequence) || push!(sort, report.sequence)

    nca_obj = nca(report.data, report.pktime, report.pkconc, sort; report.ncasettings...)

    nca_df = DataFrame(metida_table(nca_obj))

    sort!(nca_df, [report.formulation, report.subject])

    beobj = bioequivalence(nca_df, vars = report.vars,
    subject = report.subject,
    period = report.period,
    formulation = report.formulation,
    sequence = report.sequence,
    reference = report.reference,
    design = report.design,
    io = io,
    seqcheck = seqcheck,
    dropcheck = dropcheck,
    info = info,
    autoseq = autoseq)

    nca_ds = descriptives(nca_df, vars = report.pkvars, sort = report.formulation, stats = report.stats, skipmissing = true, skipnonpositive = true)

    conc_ds = descriptives(report.data, vars = report.pkconc, sort = [report.pktime, report.formulation], stats = [:mean, :lmeanci, :umeanci], skipmissing = true, skipnonpositive = true)

    nca_ds_df = metida_table(nca_ds)

    olsdict = Dict()


    for i in report.vars
        if beobj.design == "parallel"
            mform = @eval @formula($i ~ $(report.formulation))
            olsdict[i] = fit(LinearModel, mform, nca_df; dropcollinear = true, contrasts = Dict(:formulation => DummyCoding(base = beobj.reference)))
        elseif beobj.design == "2X2"

        end
    end

    be_df = DataFrame(param = [], pe = [], lci = [], uci = [], cv = [])

    weave(tpl; out_path = file,
        args = (report = report,
            beobj = beobj,
            df = [nca_df[:, append!([report.formulation, report.subject], report.pkvars)], nca_ds_df[:, append!([report.formulation, :Variable], report.stats)]],
            olsdict = olsdict),
        doctype = doctype)
end
=#