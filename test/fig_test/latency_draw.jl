using Plots
function assing_valiables(scale, dir, data_dir, file_name_suffix)
    test_shape_fig_y_file = open("$(data_dir)/log_latency_$(file_name_suffix).txt")
    x_vec = Vector{Any}()
    y_vec = Vector{Any}()
    cnt = 1
    curline_fig_y_vec = "@"
    while true
        curline_fig_y_vec = readline(test_shape_fig_y_file)
        if curline_fig_y_vec == ""
            break
        end
        if cnt < scale # == 0
            push!(x_vec, cnt)
            push!(y_vec, parse(Float64, curline_fig_y_vec))
        end
        cnt += 1
    end
    return [x_vec, y_vec]
end

function draw_latency(file_name_suffix)
    dir = pwd() * "/test/fig_test"
    data_dir = pwd() * "/files"
    result_vec = assing_valiables(1000_000, dir, data_dir, file_name_suffix)

    x_array = result_vec[1]
    x_array = x_array[2 : end]
    y_array = result_vec[2]
    y_array = y_array[2 : end]

    scatter(x_array, y_array, label="Performance", mc=:white, msc=colorant"#EF4035", legend=:best, 
    bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
    xlabel!("Number of Mmessages received", fontsize=18)
    ylabel!("Latency Time (milliseconds)", fontsize=18)


    savefig("$(dir)/pic_$(file_name_suffix).pdf")
end

# include("test/fig_test/latency_draw.jl")