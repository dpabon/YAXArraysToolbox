using YAXArrays, Statistics, Zarr, NetCDF


axlist = [
    RangeAxis("time", range(1, 20, length=20)),
    RangeAxis("x", range(1, 10, length=10)),
    RangeAxis("y", range(1, 5, length=15)),
    CategoricalAxis("Variable", ["var1", "var2"])]

data = rand(20, 10, 15, 2)


props = Dict(
    "time" => "days",
    "x" => "lon",
    "y" => "lat",
    "var1" => "one of your variables",
    "var2" => "your second variable",
)

ds = YAXArray(axlist, data, props)

cube_in = ds


function masking_time_rela_1(cube_out, cube_in, cube_mask; val=val)
    cube_out .= cube_in
    if any(ismissing, cube_out)
        replace!(cube_out, missing => NaN)
    end
    if length(findall(>=(val), cube_mask)) > 0
        if length(findall(>=(val), cube_mask)) > 1
            cube_out[findall(>=(val), cube_mask)] .= NaN
        else
            cube_out[findall(>=(val), cube_mask)] = NaN
        end
        
    end
end


function masking_time_rela_2(cube_out, cube_in, cube_mask; val=val)
    cube_out .= cube_in
    if any(ismissing, cube_out)
        replace!(cube_out, missing => NaN)
    end
    if length(findall(>(val), cube_mask)) > 0
        if length(findall(>(val), cube_mask)) > 1
            cube_out[findall(>(val), cube_mask)] .= NaN
        else
            cube_out[findall(>(val), cube_mask)] = NaN
        end

        
    end
end


function masking_time_rela_3(cube_out, cube_in, cube_mask; val=val)
    cube_out .= cube_in
    if any(ismissing, cube_out)
        replace!(cube_out, missing => NaN)
    end
    if length(findall(<=(val), cube_mask)) > 0
        if length(findall(<=(val), cube_mask)) > 1
            cube_out[findall(<=(val), cube_mask)] .= NaN
        else
            cube_out[findall(<=(val), cube_mask)] = NaN
        end
        
    end
end

function masking_time_rela_4(cube_out, cube_in, cube_mask; val=val)
    cube_out .= cube_in
    if any(ismissing, cube_out)
        replace!(cube_out, missing => NaN)
    end
    if length(findall(<(val), cube_mask)) > 0
        if length(findall(<(val), cube_mask)) > 1
            cube_out[findall(<(val), cube_mask)] .= NaN
        else
            cube_out[findall(<(val), cube_mask)] = NaN
        end
    end
end


function masking_time_rela_5(cube_out, cube_in, cube_mask; val=val)
    cube_out .= cube_in
    if any(ismissing, cube_out)
        replace!(cube_out, missing => NaN)
    end
    if length(findall(>=(val), cube_mask)) > 0
        if length(findall(>=(val), cube_mask)) > 1
            cube_out[findall(>=(val), cube_mask)] .= NaN
        else
            cube_out[findall(>=(val), cube_mask)] = NaN
        end
    end
end

function masking_time_rela_1_quant(cube_out, cube_in; p = p)
    cube_out .= cube_in
    if any(ismissing, cube_out)
        replace!(cube_out, missing => NaN)
    end
    if !all(isnan, cube_out)
        if length(findall(>=(quantile(filter(!isnan,cube_out), p)), cube_out)) > 0
            if length(findall(>=(quantile(filter(!isnan,cube_out), p)), cube_out)) > 1

                cube_out[findall(>=(quantile(filter(!isnan,cube_out), p)), cube_out)] .= NaN
            else
                cube_out[findall(>=(quantile(filter(!isnan,cube_out), p)), cube_out)] = NaN
        end
    end
end

rela = [">=", ">", "<=", "<", "=="]


#=
All variables are masked based on var value.

if var = Nothing and p !== nothing, all variables are masked based on the quantile distribution of each one of the variables.

=#

cube_in

function masking_time(cube_in; time_axis="time", var_axis="Variable", var_mask="var1", val=0.1, p=nothing, rela=">", showprog=true, max_cache="100MB")

    if typeof(cube_in) == Dataset
        error("$cube_in is a Dataset, use Cube() function to transform a Dataset into a cube.")
    end

    if last(max_cache, 2) == "MB"
        max_cache = parse(Float64, max_cache[begin:end-2]) / (10^-6)

    elseif last(max_cache, 2) == "GB"

        max_cache = parse(Float64, max_cache[begin:end-2]) / (10^-9)

    else
        error("only MB or GB values are accepted for max_cache")
    end

    if typeof(var_mask) == String && typeof(p) == Nothing && typeof(val) != Nothing

        # In this case one variable is used to mask the others. e.g. Mask the values of all the variables presented in the cube where radiation is lower than X.

        kwarg = (; Symbol(var_axis) => var_mask)

        cube_mask = getindex(cube_in; kwarg...)

        indims = (InDims(time_axis), InDims(time_axis))

        outdims = OutDims()

        if rela == ">="
            return mapCube(masking_time_rela_1, (cube_in, cube_mask), indims=indims, outdims=outdims; val=val, showprog=showprog, max_cache=max_cache)

        elseif rela == ">"
            return mapCube(masking_time_rela_2, (cube_in, cube_mask), indims=indims, outdims=outdims; val=val, showprog=showprog, max_cache=max_cache)

        elseif rela == "<="
            return mapCube(masking_time_rela_3, (cube_in, cube_mask), indims=indims, outdims=outdims; val=val, showprog=showprog, max_cache=max_cache)

        elseif rela == "<"
            return mapCube(masking_time_rela_4, (cube_in, cube_mask), indims=indims, outdims=outdims; val=val, showprog=showprog, max_cache=max_cache)

        elseif rela == "=="
            return mapCube(masking_time_rela_5, (cube_in, cube_mask), indims=indims, outdims=outdims; val=val, showprog=showprog, max_cache=max_cache)

        else
            error("incorrect 'rela' value. 'rela' can be '>=', '>', '<=', '<', '=='")
        end

    elseif typeof(var_mask) == Nothing && typeof(p) != Nothing && typeof(val) == Nothing

        # in this case the mask is applied based on the quantile value (p) of the time series for each one of the variables in the cube.

        indims = InDims(time_axis)

        outdims = OutDims()






    end

end