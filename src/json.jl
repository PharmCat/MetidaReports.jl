

pd_text_en = JSON.parsefile(joinpath(path, "json", "pd_text_en.json"); dicttype=Dict, inttype=Int64, use_mmap=true)
pk_text_en = JSON.parsefile(joinpath(path, "json", "pk_text_en.json"); dicttype=Dict, inttype=Int64, use_mmap=true)
stat_text_en = JSON.parsefile(joinpath(path, "json", "stat_text_en.json"); dicttype=Dict, inttype=Int64, use_mmap=true)
