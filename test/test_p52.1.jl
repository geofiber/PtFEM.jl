using PtFEM, Test

data = Dict(
# Plane(ndim, nst, nxe, nye, nip, direction=(:x|:y), finite_element(nod, nodof), axisymmetric=false)
# Plane(ndim, nst, nxe, nye, nip, direction=:z, finite_element(nod, nodof), axisymmetric=true)
# Plane(ndim, nst, nre, nze, nip, direction=:r, finite_element(nod, nodof), axisymmetric=false)
  :struc_el => Plane(2, 6, 1, 5, 4, :r, Quadrilateral(8, 3), false),
  :properties => [1.0e5 0.3;],
  :r_coords => [0.0, 0.5],
  :z_coords => [10.0, 8.0, 6.0, 4.0, 2.0, 0.0],
  :support => [
    ( 1, [1 0 1]),
    ( 4, [1 0 1]),
    ( 6, [1 0 1]),
    ( 9, [1 0 1]),
    (11, [1 0 1]),
    (14, [1 0 1]),
    (16, [1 0 1]),
    (19, [1 0 1]),
    (21, [1 0 1]),
    (24, [1 0 1]),
    (26, [0 0 0]),
    (27, [0 0 0]),
    (28, [0 0 0])
    ],
  :loaded_nodes => [
    (3, [1/pi 0.0 0.0])
    ],
  :lth => 1,
  :iflag => 1,
  :chi => 0.0
)

@time m, dis_df, sigma_df = p52(data)

@test m.loads[0:65] ≈ [0.0,0.0675569552650584,-0.06755339718587051,
  0.0675550611183897,-0.0025282635314929514,-0.06754930096906765,
  0.06755376595399615,-0.005063646782360032,-0.06754378259701828,
  0.05743046037889881,-0.057432490517240836,0.057441944750754405,
  -0.005005739743328588,-0.05742749087610757,0.04753054505535036,
  -0.04752501175531152,0.04752761039720702,-0.0024265026287448132,
  -0.04751826130337188,0.04753200512262878,-0.00485859624896776,
  -0.04750446544560081,0.0380108152341777,-0.03801430582540627,
  0.038043595025430185,-0.004598096664133727,-0.0379939151061887,
  0.029138408322084745,-0.029128707630258533,0.029131687887729216,
  -0.002121143506426845,-0.02911866562356955,0.029141015554487087,
  -0.0042482014668140024,-0.029092503165066133,0.021034656820675384,
  -0.021040857210335804,0.021090965865308207,-0.0037823104185696304,
  -0.021005867287750803,0.014004054458491054,-0.013993277627426427,
  0.013994731459463667,-0.0016135944093911055,-0.013978288565264622,
  0.014005550176560485,-0.00323312039147469,-0.01394313064790418,
  0.008132647707849692,-0.008137157612832228,0.008212440365727661,
  -0.0025592520670215577,-0.008085266130752576,0.003764582745644812,
  -0.0037356644208552323,0.003738861252011861,-0.0009009830493624234,
  -0.003731710717854891,0.0037540460087339984,-0.0018087025205919894,
  -0.0036869554668832335,0.000937846981324757,-0.0009620426947358215,
  0.0010519661074415124,-0.0009218802871890891,-0.0008805978030738389]