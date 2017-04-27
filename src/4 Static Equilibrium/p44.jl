"""
# p44

Method for static equilibrium analysis of a rod.

### Constructors
```julia
p44(data::Dict)
```
### Arguments
```julia
* `data` : Dictionary containing all input data
```

### Dictionary keys
```julia
* struc_el::StructuralElement                          : Type of  structural fin_el
* support::Array{Tuple{Int64,Array{Int64,1}},1}        : Fixed-displacements vector
* loaded_nodes::Array{Tuple{Int64,Array{Float64,1}},1} : Node load vector
* properties::Vector{Float64}                          : Material properties
* x_coords::LinSpace{Float64}                          : x coordinate vector
* y_coords::LinSpace{Float64}                          : y coordinate vector
* g_num::Array{Int64,2}                                : Element node connections
* fixed_freedoms::Array{Tuple{Vector{Int64}}           : Fixed freedoms
```

### Optional dictionary keys
```julia
* etype::Vector{Int64}                                 : Element material vector
* penalty::Float64                                     : Penalty for fixed freedoms
* eq_nodal_forces_and_moments                          : Equivalent nodal loads
* z_coords::LinSpace{Float64}                          : z coordinate vector
```

### Examples
```julia
using PtFEM

data = Dict(
  # Frame(nels, nn, ndim, nst, nip, finite_element(nod, nodof))
  :struc_el => Frame(6, 6, 2, 1, 1, Line(2, 3)),
  :properties => [
    5.0e9 6.0e4;
    1.0e9  2.0e4],
  :etype => [1, 1, 1, 2, 2, 2],
  :x_coords => [0.0, 6.0, 6.0, 12.0, 12.0, 14.0],
  :y_coords => [0.0, 0.0, -4.0, 0.0, -5.0, 0.0],
  :g_num => [
    1 2 4 3 3 5;
    2 4 6 2 4 4],
  :support => [
    (1, [0 0 1]),
    (3, [0 0 0]),
    (5, [0 0 0])
    ],
  :loaded_nodes => [
    (1, [0.0 -60.0 -60.0]),
    (2, [0.0 -180.0 -80.0]),
    (4, [0.0 -140.0 133.33]),
    (6, [0.0 -20.0 6.67])
    ],
  :penalty => 1e19,
  :eq_nodal_forces_and_moments => [
    (1, [0.0 -60.0 -60.0 0.0 -60.0 60.0]),
    (2, [0.0 -120.0 -140.0 0.0 -120.0 140.0]),
    (3, [0.0 -20.0 -6.67 0.0 -20.0 6.67])
  ]
)

fem, dis_dt, fm_dt = p44(data)

println("Displacements:")
dis_dt |> display
println()

println("Actions:")
fm_dt |> display
println()

```

### Related help
```julia
?StructuralElement  : Help on structural elements
?Rod                : Help on a Rod structural fin_el
?FiniteElement      : Help on finite element types
```
"""
function p44(data::Dict)
  
  # Parse & check FEdict data
  
  if :struc_el in keys(data)
    struc_el = data[:struc_el]
  else
    println("No fin_el type specified.")
    return
  end
  
  ndim = struc_el.ndim
  nst = struc_el.nst
  
  # Add radial stress
  if ndim == 3 && typeof(struc_el) !== Frame && struc_el.axisymmetric
    nst = 4
  end
  
  fin_el = struc_el.fin_el
  @assert typeof(fin_el) <: FiniteElement
  
  if typeof(fin_el) == Line
    if typeof(struc_el) == Frame
      nels = struc_el.nels
      nn = struc_el.nn
    else  
      (nels, nn) = mesh_size(fin_el, struc_el.nxe)
    end
  elseif typeof(fin_el) == Triangle || typeof(fin_el) == Quadrilateral
    (nels, nn) = mesh_size(fin_el, struc_el.nxe, struc_el.nye)
  elseif typeof(fin_el) == Hexahedron
    (nels, nn) = mesh_size(fin_el, struc_el.nxe, struc_el.nye, struc_el.nze)
  else
    println("$(typeof(fin_el)) is not a known finite element.")
    return
  end
  
  nodof = Int64(ndim == 2 ? 3 : 6)      # Degrees of freedom per node
  ndof = fin_el.nod * nodof             # Degrees of freedom per fin_el
  
  # Update penalty if specified in FEdict
  
  penalty = 1e20
  if :penalty in keys(data)
    penalty = data[:penalty]
  end
  
  # Allocate all arrays
  
  # Start with arrays to be initialized from FEdict
  
  if :properties in keys(data)
    prop = zeros(size(data[:properties], 1), size(data[:properties], 2))
    for i in 1:size(data[:properties], 1)
      prop[i, :] = data[:properties][i, :]
    end
  else
    println("No :properties key found in FEdict")
  end
  
  nf = ones(Int64, nodof, nn)
  
  if :support in keys(data)
    for i in 1:size(data[:support], 1)
      nf[:, data[:support][i][1]] = data[:support][i][2]
    end
  end
  
  
  x_coords = zeros(nn)
  if :x_coords in keys(data)
    x_coords = data[:x_coords]
  end
  
  y_coords = zeros(nn)
  if :y_coords in keys(data)
    y_coords = data[:y_coords]
  end
  
  z_coords = zeros(nn)
  if :z_coords in keys(data)
    z_coords = data[:z_coords]
  end

  etype = ones(Int64, nels)
  if :etype in keys(data)
    etype = data[:etype]
  end
  
  g_num = zeros(Int64, fin_el.nod, nels)
  if :g_num in keys(data)
    g_num = data[:g_num]
  end
  
  gamma = zeros(nels)
  if :gamma in keys(data)
    gamma = data[:gamma]
  end
  
  
  # All other arrays
  
  points = zeros(struc_el.nip, ndim)
  g = zeros(Int64, ndof)
  g_coord = zeros(ndim,nn)
  fun = zeros(fin_el.nod)
  coord = zeros(fin_el.nod, ndim)
  jac = zeros(ndim, ndim)
  der = zeros(ndim, fin_el.nod)
  deriv = zeros(ndim, fin_el.nod)
  bee = zeros(nst,ndof)
  km = zeros(ndof, ndof)
  mm = zeros(ndof, ndof)
  gm = zeros(ndof, ndof)
  kg = zeros(ndof, ndof)
  eld = zeros(ndof)
  weights = zeros(struc_el.nip)
  g_g = zeros(Int64, ndof, nels)
  num = zeros(Int64, fin_el.nod)
  actions = zeros(ndof, nels)
  displacements = zeros(size(nf, 1), ndim)
  gc = ones(ndim, ndim)
  dee = zeros(nst,nst)
  sigma = zeros(nst)
  axial = zeros(nels)
  
  # Set global coordinates
  
  g_coord[1,:] = data[:x_coords]
  if ndim > 1
    g_coord[2,:] = data[:y_coords]
  end
  if ndim > 2
    g_coord[3,:] = data[:z_coords]
  end
  
  formnf!(nodof, nn, nf)
  neq = maximum(nf)
  
  ell = zeros(nels)
  if :x_coords in keys(data)
    for i in 1:length(data[:x_coords])-1
      ell[i] = data[:x_coords][i+1] - data[:x_coords][i]
    end
  end
  
  for i in 1:nels
    num = g_num[:, i]
    num_to_g!(fin_el.nod, nodof, nn, ndof, num, nf, g)
    g_g[:, i] = g
  end
  
  println("There are $(neq) equations.")
  
  gsm = spzeros(neq, neq)
  for i in 1:nels
    num = g_num[:, i]
    coord = g_coord[:, num]'
    km = rigid_jointed!(km, prop, gamma, etype, i, coord)
    g = g_g[:, i]
    fsparm!(gsm, g, km)
  end
    
  lastind = neq + 1
  loads = OffsetArray(zeros(lastind+1), 0:lastind)
  if :loaded_nodes in keys(data)
    for i in 1:size(data[:loaded_nodes], 1)
      loads[nf[:, data[:loaded_nodes][i][1]]] = data[:loaded_nodes][i][2]
    end
  end
  
  fixed_freedoms = 0
  if :fixed_freedoms in keys(data)
    fixed_freedoms = size(data[:fixed_freedoms], 1)
  end
  no = zeros(Int64, fixed_freedoms)
  node = zeros(Int64, fixed_freedoms)
  sense = zeros(Int64, fixed_freedoms)
  value = zeros(Float64, fixed_freedoms)
  if fixed_freedoms > 0
    for i in 1:fixed_freedoms
      node[i] = data[:fixed_freedoms][i][1]
      sense[i] = data[:fixed_freedoms][i][2]
      no[i] = nf[sense[i], node[i]]
      value[i] = data[:fixed_freedoms][i][3]
      gsm[no[i], no[i]] += penalty
      loads[no[i]] = gsm[no[i], no[i]] .* value[i]
    end
  end
  
  # Compute Cholesky factored global stiffness matrix for
  # future re-use. If re-use is not appropriate the loads
  # can be computed directly using gsm:
  #   loads[1:neq] = gsm \ loads[1:neq]

  cfgsm = cholfact(gsm)
  loads[1:neq] = cfgsm \ loads[1:neq]
  println()

  displacements = zeros(size(nf))
  for i in 1:size(displacements, 1)
    for j in 1:size(displacements, 2)
      if nf[i, j] > 0
        displacements[i,j] = loads[nf[i, j]]
      end
    end
  end
  
  loads[0] = 0.0
  for i in 1:nels
    num = g_num[:, i]
    coord = g_coord[:, num]'
    g = g_g[:, i]
    eld = loads[g]
    km = rigid_jointed!(km, prop, gamma, etype, i, coord)
    actions[:, i] = km * eld
  end

  
  if ndim == 2
    dis_dt = DataTable(
      x_translation = displacements[1, :],
      y_translation = displacements[2, :],
      rotation = displacements[3, :]
    )
    fm_dt = DataTable(
      x1_Force = actions[1, :],
      y1_Force = actions[2, :],
      z1_Moment = actions[3, :],
      x2_Force = actions[4, :],
      y2_Force = actions[5, :],
      z2_Moment = actions[6, :]
    )
  elseif ndim == 3
    dis_dt = DataTable(
      x_translation = displacements[1, :],
      y_translation = displacements[2, :],
      z_translation = displacements[3, :],
      x_rotation = displacements[4, :],
      y_rotation = displacements[5, :],
      z_rotation = displacements[6, :]
    )
    fm_dt = DataTable(
      x1_Force = actions[1, :],
      y1_Force = actions[2, :],
      z1_Force = actions[3, :],
      x1_Moment = actions[4, :],
      y1_Moment = actions[5, :],
      z1_Moment = actions[6, :],
      x2_Force = actions[7, :],
      y2_Force = actions[8, :],
      z2_Force = actions[9, :],
      x2_Moment = actions[10, :],
      y2_Moment = actions[11, :],
      z2_Moment = actions[12, :]
    )
  end
  
  # Correct element forces and moments for equivalent nodal
  # forces and moments introduced for loading between nodes
  if :eq_nodal_forces_and_moments in keys(data)
    k = data[:struc_el].fin_el.nod * data[:struc_el].fin_el.nodof
    eqfm = data[:eq_nodal_forces_and_moments]
    for t in eqfm
      vals = convert(Array, fm_dt[t[1], :])
      for i in 1:k
        fm_dt[t[1], i] = round(vals[i] - t[2][i], 2)
      end
    end
  end
  
  fem = jFEM(struc_el, fin_el, ndim, nels, nst, ndof, nn, nodof, neq, penalty,
    etype, g, g_g, g_num, nf, no, node, num, sense, actions, 
    bee, coord, gamma, dee, der, deriv, displacements, eld, fun, gc,
    g_coord, jac, km, mm, gm, cfgsm, loads, points, prop, sigma, value,
    weights, x_coords, y_coords, z_coords, axial)
  
  (fem, dis_dt, fm_dt)
end