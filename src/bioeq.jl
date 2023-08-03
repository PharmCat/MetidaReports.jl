#=


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