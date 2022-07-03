
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

    dfnames = Symbol.(names(data))

    fac = [subject, formulation]

    fac ⊆ dfnames || error("Subject or formulation column not found in dataframe!")

    disallowmissing!(data, subject)

    disallowmissing!(data, formulation)

    obsnum = size(data, 1)

    subjects = unique(data[!, subject])

    subjnum = length(subjects)

    formulations = sort!(unique(data[!, formulation]))

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
        length(subjects) == length(data[!, subject]) || error("Trial design seems parallel, but subjects not unique!")
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

        periods = sort!(unique(data[!, period]))
        push!(fac, period)
        disallowmissing!(data, period)

        if autoseq || seqcheck
            subjdict = Dict()
            for p in periods
                for i = 1:obsnum
                    if data[i, period] == p
                        subj = data[i, subject]
                        if haskey(subjdict, subj)
                            subjdict[subj] *= string(data[i, formulation])
                        else
                            subjdict[subj] = string(data[i, formulation])
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
            sequences = unique(data[!, sequence])
            push!(fac, sequence)
            disallowmissing!(data, sequence)
        end

        if dropcheck
            if !isnothing(variable) && !all(completecases(data, variable))
                dropout = true
                 @info "Dropuot(s) found in dataframe!"
            elseif !isnothing(variable)
                info && @info "No dropuot(s) found in dataframe!"
                dropout = false
            end

        end

        if seqcheck && !isnothing(sequence)
            for i = 1:obsnum
                if data[i, sequence] != subjdict[data[i, subject]] error("Sequence error or data is incomplete! \n Subject: $(data[i, subject]), Sequence: $(data[i, sequence]), auto: $(subjdict[data[i, subject]])") end
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
