const RECOMPILE_BY_DEFAULT = true

abstract type AbstractODEFunction{iip} <: AbstractDiffEqFunction{iip} end
struct ODEFunction{iip,F,Ta,Tt,TJ,TW,TWt,TPJ,S} <: AbstractODEFunction{iip}
  f::F
  analytic::Ta
  tgrad::Tt
  jac::TJ
  invW::TW
  invW_t::TWt
  paramjac::TPJ
  syms::S
end

struct SplitFunction{iip,F1,F2,C,Ta} <: AbstractODEFunction{iip}
  f1::F1
  f2::F2
  cache::C
  analytic::Ta
end

abstract type AbstractDiscreteFunction{iip} <: AbstractDiffEqFunction{iip} end
struct DiscreteFunction{iip,F,Ta} <: AbstractDiscreteFunction{iip}
  f::F
  analytic::Ta
end

abstract type AbstractDAEFunction{iip} <: AbstractDiffEqFunction{iip} end
struct DAEFunction{iip,F,Ta,Tt,TJ,TW,TWt,TPJ,S} <: AbstractDAEFunction{iip}
  f::F
  analytic::Ta
  tgrad::Tt
  jac::TJ
  invW::TW
  invW_t::TWt
  paramjac::TPJ
  syms::S
end

######### Backwards Compatibility Overloads

(f::ODEFunction)(args...) = f.f(args...)
(f::ODEFunction)(::Type{Val{:analytic}},args...) = f.analytic(args...)
(f::ODEFunction)(::Type{Val{:tgrad}},args...) = f.tgrad(args...)
(f::ODEFunction)(::Type{Val{:jac}},args...) = f.jac(args...)
(f::ODEFunction)(::Type{Val{:invW}},args...) = f.invW(args...)
(f::ODEFunction)(::Type{Val{:invW_t}},args...) = f.invW_t(args...)
(f::ODEFunction)(::Type{Val{:paramjac}},args...) = f.paramjac(args...)

(f::SplitFunction)(u,p,t) = f.f1(u,p,t) + f.f2(u,p,t)
(f::SplitFunction)(::Type{Val{:analytic}},args...) = f.analytic(args...)
function (f::SplitFunction)(du,u,p,t)
    f.f1(f.cache,u,p,t)
    f.f2(du,u,p,t)
    du .+= f.cache
end

(f::DiscreteFunction)(args...) = f.f(args...)
(f::DiscreteFunction)(::Type{Val{:analytic}},args...) = f.analytic(args...)

(f::DAEFunction)(args...) = f.f(args...)
(f::DAEFunction)(::Type{Val{:analytic}},args...) = f.analytic(args...)
(f::DAEFunction)(::Type{Val{:tgrad}},args...) = f.tgrad(args...)
(f::DAEFunction)(::Type{Val{:jac}},args...) = f.jac(args...)
(f::DAEFunction)(::Type{Val{:invW}},args...) = f.invW(args...)
(f::DAEFunction)(::Type{Val{:invW_t}},args...) = f.invW_t(args...)
(f::DAEFunction)(::Type{Val{:paramjac}},args...) = f.paramjac(args...)

######### Basic Constructor

function ODEFunction{iip,true}(f;
                 analytic=nothing,
                 tgrad=nothing,
                 jac=nothing,
                 invW=nothing,
                 invW_t=nothing,
                 paramjac = nothing,
                 syms = nothing) where iip
                 ODEFunction{iip,typeof(f),typeof(analytic),typeof(tgrad),
                 typeof(jac),typeof(invW),typeof(invW_t),
                 typeof(paramjac),typeof(syms)}(
                 f,analytic,tgrad,jac,invW,invW_t,
                 paramjac,syms)
end
function ODEFunction{iip,false}(f;
                 analytic=nothing,
                 tgrad=nothing,
                 jac=nothing,
                 invW=nothing,
                 invW_t=nothing,
                 paramjac = nothing,
                 syms = nothing) where iip
                 ODEFunction{iip,Any,Any,Any,
                 Any,Any,Any,
                 Any,typeof(syms)}(
                 f,analytic,tgrad,jac,invW,invW_t,
                 paramjac,syms)
end
ODEFunction(f; kwargs...) = ODEFunction{isinplace(f, 4),RECOMPILE_BY_DEFAULT}(f; kwargs...)

@add_kwonly function SplitFunction(f1,f2,cache,analytic)
  f1 = ODEFunction(f1)
  f2 = ODEFunction(f2)
  SplitFunction{isinplace(f2),typeof(f1),typeof(f2),
              typeof(cache),typeof(analytic)}(f1,f2,cache,analytic)
end
SplitFunction{iip,true}(f1,f2; _func_cache=nothing,analytic=nothing) where iip =
SplitFunction{iip,typeof(f1),typeof(f2),typeof(_func_cache),typeof(analytic)}(f1,f2,_func_cache,analytic)
SplitFunction{iip,false}(f1,f2; _func_cache=nothing,analytic=nothing) where iip =
SplitFunction{iip,Any,Any,Any}(f1,f2,_func_cache,analytic)
SplitFunction(f1,f2; kwargs...) = SplitFunction{isinplace(f2, 4)}(f1, f2; kwargs...)
SplitFunction{iip}(f1,f2; kwargs...) where iip =
SplitFunction{iip,RECOMPILE_BY_DEFAULT}(ODEFunction{iip}(f1), ODEFunction{iip}(f2); kwargs...)

function DiscreteFunction{iip,true}(f;
                 analytic=nothing) where iip
                 DiscreteFunction{iip,typeof(f),typeof(analytic)}(
                 f,analytic)
end
function DiscreteFunction{iip,false}(f;
                 analytic=nothing) where iip
                 DiscreteFunction{iip,Any,Any}(
                 f,analytic)
end
DiscreteFunction(f; kwargs...) = DiscreteFunction{isinplace(f, 4),RECOMPILE_BY_DEFAULT}(f; kwargs...)

function DAEFunction{iip,true}(f;
                 analytic=nothing,
                 tgrad=nothing,
                 jac=nothing,
                 invW=nothing,
                 invW_t=nothing,
                 paramjac = nothing,
                 syms = nothing) where iip
                 DAEFunction{iip,typeof(f),typeof(analytic),typeof(tgrad),
                 typeof(jac),typeof(invW),typeof(invW_t),
                 typeof(paramjac),typeof(syms)}(
                 f,analytic,tgrad,jac,invW,invW_t,
                 paramjac,syms)
end
function DAEFunction{iip,false}(f;
                 analytic=nothing,
                 tgrad=nothing,
                 jac=nothing,
                 invW=nothing,
                 invW_t=nothing,
                 paramjac = nothing,
                 syms = nothing) where iip
                 DAEFunction{iip,Any,Any,Any,
                 Any,Any,Any,
                 Any,typeof(syms)}(
                 f,analytic,tgrad,jac,invW,invW_t,
                 paramjac,syms)
end
DAEFunction(f; kwargs...) = DAEFunction{isinplace(f, 5),RECOMPILE_BY_DEFAULT}(f; kwargs...)


########## Existance Functions

has_jac(f::ODEFunction) = f.jac != nothing
has_analytic(f::ODEFunction) = f.analytic != nothing
has_tgrad(f::ODEFunction) = f.tgrad != nothing
has_invW(f::ODEFunction) = f.invW != nothing
has_invW_t(f::ODEFunction) = f.invW_t != nothing
has_paramjac(f::ODEFunction) = f.paramjac != nothing
has_syms(f::ODEFunction) = f.syms != nothing

has_analytic(f::SplitFunction) = f.analytic != nothing
has_jac(f::SplitFunction) = f.f1.jac != nothing
has_tgrad(f::SplitFunction) = f.f1.tgrad != nothing
has_invW(f::SplitFunction) = f.f1.invW != nothing
has_invW_t(f::SplitFunction) = f.f1.invW_t != nothing
has_paramjac(f::SplitFunction) = f.f1.paramjac != nothing

has_analytic(f::DiscreteFunction) = f.analytic != nothing

has_jac(f::DAEFunction) = f.jac != nothing
has_analytic(f::DAEFunction) = f.analytic != nothing
has_tgrad(f::DAEFunction) = f.tgrad != nothing
has_invW(f::DAEFunction) = f.invW != nothing
has_invW_t(f::DAEFunction) = f.invW_t != nothing
has_paramjac(f::DAEFunction) = f.paramjac != nothing
has_syms(f::DAEFunction) = f.syms != nothing

######### Compatibility Constructor from Tratis

ODEFunction(f::T) where T = return T<:ODEFunction ? f : convert(ODEFunction,f)
ODEFunction{iip}(f::T) where {iip,T} = return T<:ODEFunction ? f : convert(ODEFunction{iip},f)
function Base.convert(::Type{ODEFunction},f)
  if __has_analytic(f)
    analytic = (args...) -> f(Val{:analytic},args...)
  else
    analytic = nothing
  end
  if __has_jac(f)
    @warn("The overloading form for Jacobians is deprecated. Use the DiffEqFunction")
    jac = (args...) -> f(Val{:jac},args...)
  else
    jac = nothing
  end
  if __has_tgrad(f)
    tgrad = (args...) -> f(Val{:tgrad},args...)
  else
    tgrad = nothing
  end
  if __has_invW(f)
    invW = (args...) -> f(Val{:invW},args...)
  else
    invW = nothing
  end
  if __has_invW_t(f)
    invW_t = (args...) -> f(Val{:invW_t},args...)
  else
    invW_t = nothing
  end
  if __has_paramjac(f)
    paramjac = (args...) -> f(Val{:paramjac},args...)
  else
    paramjac = nothing
  end
  if __has_syms(f)
    syms = f.syms
  else
    syms = nothing
  end
  ODEFunction(f,analytic=analytic,tgrad=tgrad,jac=jac,invW=invW,
              invW_t=invW_t,paramjac=paramjac,syms=syms)
end
function Base.convert(::Type{ODEFunction{iip}},f) where iip
  if __has_analytic(f)
    analytic = (args...) -> f(Val{:analytic},args...)
  else
    analytic = nothing
  end
  if __has_jac(f)
    @warn("The overloading form for Jacobians is deprecated. Use the DiffEqFunction")
    jac = (args...) -> f(Val{:jac},args...)
  else
    jac = nothing
  end
  if __has_tgrad(f)
    tgrad = (args...) -> f(Val{:tgrad},args...)
  else
    tgrad = nothing
  end
  if __has_invW(f)
    invW = (args...) -> f(Val{:invW},args...)
  else
    invW = nothing
  end
  if __has_invW_t(f)
    invW_t = (args...) -> f(Val{:invW_t},args...)
  else
    invW_t = nothing
  end
  if __has_paramjac(f)
    paramjac = (args...) -> f(Val{:paramjac},args...)
  else
    paramjac = nothing
  end
  if __has_syms(f)
    syms = f.syms
  else
    syms = nothing
  end
  ODEFunction{iip,RECOMPILE_BY_DEFAULT}(f,analytic=analytic,tgrad=tgrad,jac=jac,invW=invW,
              invW_t=invW_t,paramjac=paramjac,syms=syms)
end

DiscreteFunction(f::T) where T = return T<:DiscreteFunction ? f : convert(DiscreteFunction,f)
DiscreteFunction{iip}(f::T) where {iip,T} = return T<:DiscreteFunction ? f : convert(DiscreteFunction{iip},f)
function Base.convert(::Type{DiscreteFunction},f)
  if __has_analytic(f)
    analytic = (args...) -> f(Val{:analytic},args...)
  else
    analytic = nothing
  end
  DiscreteFunction(f,analytic=analytic)
end
function Base.convert(::Type{DiscreteFunction{iip}},f) where iip
  if __has_analytic(f)
    analytic = (args...) -> f(Val{:analytic},args...)
  else
    analytic = nothing
  end
  DiscreteFunction{iip,RECOMPILE_BY_DEFAULT}(f,analytic=analytic)
end

DAEFunction(f::T) where T = return T<:DAEFunction ? f : convert(DAEFunction,f)
DAEFunction{iip}(f::T) where {iip,T} = return T<:DAEFunction ? f : convert(DAEFunction{iip},f)
function Base.convert(::Type{DAEFunction},f)
  if __has_analytic(f)
    analytic = (args...) -> f(Val{:analytic},args...)
  else
    analytic = nothing
  end
  if __has_jac(f)
    @warn("The overloading form for Jacobians is deprecated. Use the DiffEqFunction")
    jac = (args...) -> f(Val{:jac},args...)
  else
    jac = nothing
  end
  if __has_tgrad(f)
    tgrad = (args...) -> f(Val{:tgrad},args...)
  else
    tgrad = nothing
  end
  if __has_invW(f)
    invW = (args...) -> f(Val{:invW},args...)
  else
    invW = nothing
  end
  if __has_invW_t(f)
    invW_t = (args...) -> f(Val{:invW_t},args...)
  else
    invW_t = nothing
  end
  if __has_paramjac(f)
    paramjac = (args...) -> f(Val{:paramjac},args...)
  else
    paramjac = nothing
  end
  if __has_syms(f)
    syms = f.syms
  else
    syms = nothing
  end
  DAEFunction(f,analytic=analytic,tgrad=tgrad,jac=jac,invW=invW,
              invW_t=invW_t,paramjac=paramjac,syms=syms)
end
function Base.convert(::Type{DAEFunction{iip}},f) where iip
  if __has_analytic(f)
    analytic = (args...) -> f(Val{:analytic},args...)
  else
    analytic = nothing
  end
  if __has_jac(f)
    @warn("The overloading form for Jacobians is deprecated. Use the DiffEqFunction")
    jac = (args...) -> f(Val{:jac},args...)
  else
    jac = nothing
  end
  if __has_tgrad(f)
    tgrad = (args...) -> f(Val{:tgrad},args...)
  else
    tgrad = nothing
  end
  if __has_invW(f)
    invW = (args...) -> f(Val{:invW},args...)
  else
    invW = nothing
  end
  if __has_invW_t(f)
    invW_t = (args...) -> f(Val{:invW_t},args...)
  else
    invW_t = nothing
  end
  if __has_paramjac(f)
    paramjac = (args...) -> f(Val{:paramjac},args...)
  else
    paramjac = nothing
  end
  if __has_syms(f)
    syms = f.syms
  else
    syms = nothing
  end
  DAEFunction{iip,RECOMPILE_BY_DEFAULT}(f,analytic=analytic,tgrad=tgrad,jac=jac,invW=invW,
              invW_t=invW_t,paramjac=paramjac,syms=syms)
end
