
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
    vars
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
        design = :parallel
        println(io, "Parallel desigh used.")
    end


    if isnothing(design) || design != :parallel

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
            spldes = split(uppercase(string(design)), "X")
            if length(spldes) != 3 &&  uppercase(string(design)) != "2X2" error("Unknown design type. Use fXsXp format or \"2Х2\".") end
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
    vars = [:Cmax, :AUClast],
    stats = [:n, :posn, :mean, :geom, :sd, :se, :median, :min, :max, :q1, :q3],
    ncasettings = Dict(:adm => :ev, :calcm => :lint, :intpm => nothing),
    design = "2X2",
    subject = :subject,
    period = :period,
    formulation = :formulation,
    sequence = nothing,
    reference = nothing,
    )
    BEReport{type}(data,
    vars,
    stats,
    ncasettings,
    design,
    subject,
    period,
    formulation,
    sequence,
    reference)
end


function writereport(file, report; tpl = tplpath, doctype = "md2html", css = csspath)
    weave(tpl; out_path = file, args = (report = report,), doctype = doctype)
end
