
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
"""
    bioquivalence(data;
    variable = nothing,
    subject = :subject,
    period = :period, formulation = :formulation, sequence = :sequence, reference = nothing, design = nothing, io::IO = stdout, seqcheck = true, dropcheck = true)


"""
function bioquivalence(data;
    variable = nothing,
    subject = :subject,
    period = :period, formulation = :formulation, sequence = :sequence, reference = nothing, design = nothing, io::IO = stdout, seqcheck = true, dropcheck = true)

    dfnames = Symbol.(names(data))

    fac = [subject, formulation]

    fac ⊆ dfnames || error("Subject or formulation column not found in dataframe!")

    disallowmissing!(data, subject)

    disallowmissing!(data, formulation)

    subjects = unique(data[!, subject])

    formulations = sort!(unique(data[!, formulation]))

    if isnothing(reference)
        @info "Reference formulation not specified. First used: \"$(first(formulations))\"."
        reference = first(formulations)
    else
        reference ∈ formulations || error("Reference formulation \"$(reference)\" not found in dataframe.")
    end

    local dropout = nothing
    local periods = nothing
    local sequences = nothing

    if isnothing(period) && isnothing(sequence) && isnothing(design)
        length(subjects) == length(data[!, subject]) || error("Trial design seems parallel, but subjects not unique!")
        design = :parallel
        println(io, "Parallel desigh used.")
    end


    if isnothing(design) || design != :parallel

        !isnothing(period) || error("Trial design seems NOT parallel, but period is nothing")

        !isnothing(sequence) || error("Trial design seems NOT parallel, but sequence is nothing")

        period ∈ dfnames || error("Period not found in dataframe!")

        sequence ∈ dfnames || error("Sequence not found in dataframe!")

        periods = unique(data[!, period])

        sequences = unique(data[!, sequence])

        push!(fac, period, sequence)

        disallowmissing!(data, period)

        disallowmissing!(data, sequence)

        unstdata = unstack(data, [subject, sequence], period, formulation)

        pnames = Symbol.(periods)
        if dropcheck
            if !all(completecases(unstdata, pnames))
                dropout = true
                dropmissing!(unstdata)
                 @info "Dropuot(s) found in dataframe!"
            else
                @info "No dropuot(s) found in dataframe!"
                dropout = false
            end
        end

        if seqcheck
            seqdict = Dict()
            for i  in 1:size(unstdata, 1)
                if ht_keyindex(seqdict, unstdata[i, pnames]) > 0
                    if seqdict[unstdata[i, pnames]] != unstdata[i, sequence] error("Sequence error!") end
                else
                    seqdict[unstdata[i, pnames]] = unstdata[i, sequence]
                end
            end
            @info "Sequences looks correct..."
        end

        if isnothing(design)
            @info "Trying to find out the design..."
            design = Symbol("$(length(formulations))X$(length(sequences))X$(length(periods))")
            @info  "Seems design type is: $design"
        else
            spldes = split(uppercase(string(design)), "X")
            if length(spldes) != 3 &&  uppercase(string(design)) != "2X2" error("Unknown design type. Use fXsXp format or \"2Х2\".") end
            if length(formulations) != parse(Int, spldes[1]) error("Design error: formulations count wrong!") end
            if length(sequences) != parse(Int, spldes[2]) error("Design error: sequences count wrong!") end
            if length(periods) != parse(Int, spldes[3]) error("Design error: periods count wrong!") end
            @info "Design type seems fine..."
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
