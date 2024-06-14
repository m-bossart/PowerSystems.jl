abstract type ProductionVariableCost{T <: ValueCurve} end

IS.serialize(val::ProductionVariableCost) = IS.serialize_struct(val)
IS.deserialize(T::Type{<:ProductionVariableCost}, val::Dict) = IS.deserialize_struct(T, val)

"Get the underlying `ValueCurve` representation of this `ProductionVariableCost`"
get_value_curve(cost::ProductionVariableCost) = cost.value_curve
"Get the variable operation and maintenance cost in \$/(power_units h)"
get_vom_cost(cost::ProductionVariableCost) = cost.vom_cost
"Get the units for the x-axis of the curve"
get_power_units(cost::ProductionVariableCost) = cost.power_units
"Get the `FunctionData` representation of this `ProductionVariableCost`'s `ValueCurve`"
get_function_data(cost::ProductionVariableCost) = get_function_data(get_value_curve(cost))
"Get the `initial_input` field of this `ProductionVariableCost`'s `ValueCurve` (not defined for input-output data)"
get_initial_input(cost::ProductionVariableCost) = get_initial_input(get_value_curve(cost))
"Calculate the convexity of the underlying data"
is_convex(cost::ProductionVariableCost) = is_convex(get_value_curve(cost))

Base.:(==)(a::T, b::T) where {T <: ProductionVariableCost} =
    IS.double_equals_from_fields(a, b)

Base.isequal(a::T, b::T) where {T <: ProductionVariableCost} = IS.isequal_from_fields(a, b)

Base.hash(a::ProductionVariableCost) = IS.hash_from_fields(a)

"""
Direct representation of the variable operation cost of a power plant in currency. Composed
of a [`ValueCurve`][@ref] that may represent input-output, incremental, or average rate
data. The default units for the x-axis are megawatts and can be specified with
`power_units`.
"""
@kwdef struct CostCurve{T <: ValueCurve} <: ProductionVariableCost{T}
    "The underlying `ValueCurve` representation of this `ProductionVariableCost`"
    value_curve::T
    "The units for the x-axis of the curve; defaults to natural units (megawatts)"
    power_units::UnitSystem = UnitSystem.NATURAL_UNITS
    "Additional proportional Variable Operation and Maintenance Cost in \$/(power_unit h)"
    vom_cost::Float64 = 0.0
end

CostCurve(value_curve) = CostCurve(; value_curve)
CostCurve(value_curve, vom_cost::Float64) =
    CostCurve(; value_curve, vom_cost = vom_cost)
CostCurve(value_curve, power_units::UnitSystem) =
    CostCurve(; value_curve, power_units = power_units)

Base.:(==)(a::CostCurve, b::CostCurve) =
    (get_value_curve(a) == get_value_curve(b)) &&
    (get_power_units(a) == get_power_units(b)) &&
    (get_vom_cost(a) == get_vom_cost(b))

"Get a `CostCurve` representing zero variable cost"
Base.zero(::Union{CostCurve, Type{CostCurve}}) = CostCurve(zero(ValueCurve))

"""
Representation of the variable operation cost of a power plant in terms of fuel (MBTU,
liters, m^3, etc.), coupled with a conversion factor between fuel and currency. Composed of
a [`ValueCurve`][@ref] that may represent input-output, incremental, or average rate data.
The default units for the x-axis are megawatts and can be specified with `power_units`.
"""
@kwdef struct FuelCurve{T <: ValueCurve} <: ProductionVariableCost{T}
    "The underlying `ValueCurve` representation of this `ProductionVariableCost`"
    value_curve::T
    "The units for the x-axis of the curve; defaults to natural units (megawatts)"
    power_units::UnitSystem = UnitSystem.NATURAL_UNITS
    "Either a fixed value for fuel cost or the key to a fuel cost time series"
    fuel_cost::Union{Float64, TimeSeriesKey}
    "Additional proportional Variable Operation and Maintenance Cost in \$/(power_unit h)"
    vom_cost::Float64 = 0.0
end

FuelCurve(
    value_curve::ValueCurve,
    power_units::UnitSystem,
    fuel_cost::Real,
    vom_cost::Float64,
) =
    FuelCurve(value_curve, power_units, Float64(fuel_cost), vom_cost)

FuelCurve(value_curve, fuel_cost) = FuelCurve(; value_curve, fuel_cost)
FuelCurve(value_curve, fuel_cost::Union{Float64, TimeSeriesKey}, vom_cost::Float64) =
    FuelCurve(; value_curve, fuel_cost, vom_cost = vom_cost)
FuelCurve(value_curve, power_units::UnitSystem, fuel_cost::Union{Float64, TimeSeriesKey}) =
    FuelCurve(; value_curve, power_units = power_units, fuel_cost = fuel_cost)

Base.:(==)(a::FuelCurve, b::FuelCurve) =
    (get_value_curve(a) == get_value_curve(b)) &&
    (get_power_units(a) == get_power_units(b)) &&
    (get_fuel_cost(a) == get_fuel_cost(b)) &&
    (get_vom_cost(a) == get_vom_cost(b))

"Get a `FuelCurve` representing zero fuel usage and zero fuel cost"
Base.zero(::Union{FuelCurve, Type{FuelCurve}}) = FuelCurve(zero(ValueCurve), 0.0)

"Get the fuel cost or the name of the fuel cost time series"
get_fuel_cost(cost::FuelCurve) = cost.fuel_cost

Base.show(io::IO, m::MIME"text/plain", curve::ProductionVariableCost) =
    (get(io, :compact, false)::Bool ? _show_compact : _show_expanded)(io, m, curve)

# The strategy here is to put all the short stuff on the first line, then break and let the value_curve take more space
function _show_compact(io::IO, ::MIME"text/plain", curve::CostCurve)
    print(
        io,
        "$(nameof(typeof(curve))) with power_units $(curve.power_units), vom_cost $(curve.vom_cost), and value_curve:\n  ",
    )
    vc_printout = sprint(show, "text/plain", curve.value_curve; context = io)  # Capture the value_curve `show` so we can indent it
    print(io, replace(vc_printout, "\n" => "\n  "))
end

function _show_compact(io::IO, ::MIME"text/plain", curve::FuelCurve)
    print(
        io,
        "$(nameof(typeof(curve))) with power_units $(curve.power_units), fuel_cost $(curve.fuel_cost), vom_cost $(curve.vom_cost), and value_curve:\n  ",
    )
    vc_printout = sprint(show, "text/plain", curve.value_curve; context = io)
    print(io, replace(vc_printout, "\n" => "\n  "))
end

function _show_expanded(io::IO, ::MIME"text/plain", curve::ProductionVariableCost)
    print(io, "$(nameof(typeof(curve))):")
    for field_name in fieldnames(typeof(curve))
        val = getproperty(curve, field_name)
        val_printout =
            replace(sprint(show, "text/plain", val; context = io), "\n" => "\n  ")
        print(io, "\n  $(field_name): $val_printout")
    end
end
