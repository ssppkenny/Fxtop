export getRatesForYears

import HTTP
using DataFrames
using Gumbo
using Cascadia
using Dates


function getRates(day, month, year, cur_from, cur_to)
    dat = Date(year, month, day)
    prev_dat = dat - Dates.Year(1) - Dates.Day(1)
    year_from = Dates.year(prev_dat)
    day_from = Dates.format(prev_dat, "YYYYmmdd")
    day_to = Dates.format(dat, "YYYYmmdd")
    year_to = string(year)
    year_from = string(Dates.year(prev_dat))
    month_from = lpad(string(Dates.month(prev_dat)), 2, "0")
    month_to = lpad(string(Dates.month(dat)), 2, "0")
    req = "https://fxtop.com/en/historical-exchange-rates.php?A=1&C1=$cur_from&C2=$cur_to&TR=1&DD1=$day_from&MM1=$month_from&YYYY1=$year_from&B=1&P=&I=1&DD2=$day_to&MM2=$month_to&YYYY2=$year_to&btnOK=Go%21"
    resp = HTTP.request("GET", req)
    txt = String(resp.body)
    html = parsehtml(txt)
    c = eachmatch(Selector("table[border=\"1\"]"), html.root)
    v = Vector{Float64}(undef, 365)
    d = Vector{DateTime}(undef, 365)
    l = min(length(c[1][1].children), 367)
    for i in 3:l
        v[i-2] = parse(Float64, Gumbo.text(c[1][1][i][2]))
        d[i-2] = DateTime(Gumbo.text(c[1][1][i][1]), dateformat"E d U Y")
    end
    df = DataFrame("Value" => v, "Date" => d)
    df
end

function getRatesForYears(day, month, year, cur_from, cur_to, years=1)
    v = Vector{DataFrame}(undef, years)
    df = DataFrame("Value" => [], "Date" => [])
    asyncmap(1:years) do i
        v[i] = getRates(day,month,year-i+1, cur_from, cur_to)
    end
    if years == 1
        df = v[1]
    else 
        for i in 1:(years)
            df = vcat(df, v[i])
        end
    end
    df
end

