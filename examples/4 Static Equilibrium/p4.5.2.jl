using CSoM

include("FE4_5.jl")

data = Dict(
  # Frame(nels, nn, ndim, nst, nip, finite_element(nod, nodof))
  :element_type => Frame(12, 10, 3, 1, 1, Line(2, 3)),
  :properties => [
    1.0 1.0e4 1.0e4 1.0 1.0 1.0 1.0e8;
     ],
  :gamma => [
    0.0, 0.0, 0.0, 0.0, 
    0.0, 0.0, 0.0, 0.0, 
    0.0, 0.0, 0.0, 0.0],
  :x_coords => [
    0.0, 1.0, 1.0, 2.0,
    2.0, 2.0, 3.0, 3.0,
    3.0, 3.0],
  :y_coords => [
    0.0, 0.0, 1.0, 0.0,
    1.0, 2.0, 0.0, 1.0,
    2.0, 3.0],
  :z_coords => [
    0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0,
    0.0, 0.0],
  :g_num => [
    1 2 2 3 4 5 4 5 6 7 8  9;
    2 3 4 5 5 6 7 8 9 8 9 10],
  :support => [
    (1, [0 0 0 0 0 0]),
    (3, [0 0 0 0 0 0]),
    (6, [0 0 0 0 0 0]),
    (10, [0 0 0 0 0 0])
    ],
  :loaded_nodes => [
    (7, [0.0 0.0 1.0 0.0 0.0 0.0])
    ],
  :limit => 200,
  :tol => 0.00001,
  :incs => 5,
  :dload => [0.5; 0.5; 0.5; 0.05; 0.05]
)

data |> display
println()

@time m = FE4_5(data)
println()