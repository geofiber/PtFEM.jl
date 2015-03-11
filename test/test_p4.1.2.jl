using Compat, CSoM

include(Pkg.dir("CSoM", "examples", "StaticEquilibrium", "FE4_1.jl"))

data = @compat Dict(
  # Beam(ndim, nst, nxe, nye, nip, direction, finite_element(nod, nodof), axisymmetric)
  :element_type => Beam(1, 1, 4, 1, :x, Line(2, 1), false),
  :properties => [2.0e3; 1.0e3],
  :etype => [2, 2, 1, 1],
  :x_coords => linspace(0, 1, 5),
  :support => [
    (1, [0])
    ],
  :fixed_freedoms => [
    (5, 1, 0.05)
    ]
)

@time m = FE4_1(data)

@test round(m.displacements, 7) == [0.0 0.0166667 0.0333333 0.0416667 0.05]'