#####################
# Unit tests
#####################

facts("MvGaussianDistribution unit tests") do
    context("MvGaussianDistribution() should initialize a Gaussian distribution") do
        @fact MvGaussianDistribution().V => eye(1)
        @fact MvGaussianDistribution().m => [0.0]
        @fact MvGaussianDistribution(m=[0.0], W=eye(1)).W => eye(1)
        @fact MvGaussianDistribution(xi=[0.0], W=eye(1)).W => eye(1)
        @fact typeof(MvGaussianDistribution(m=[1.0], V=eye(1)).V) => Array{Float64, 2} # cast single value to matrix
        @fact MvGaussianDistribution(m=[0.0, 0.0], V=eye(2)).V => eye(2) # multivariate
        @fact_throws MvGaussianDistribution(V=eye(1), W=eye(1))
        @fact_throws MvGaussianDistribution(m=[0.0], xi=[0.0])
        @fact_throws MvGaussianDistribution(xi=[0.0])
        @fact_throws MvGaussianDistribution(m=[0.0, 0.0], V=[0. 0.;0. 0.])  # V should be positive definite
        @fact_throws MvGaussianDistribution(m=[0.0, 0.0], V=[Inf 0.;0. 1.]) # V should be bounded
        @fact_throws MvGaussianDistribution(m=[0.0, 0.0], W=[0. 0.;0. 0.])  # W should be positive definite
        @fact_throws MvGaussianDistribution(m=[0.0, 0.0], W=[Inf 0.;0. 1.]) # W should be bounded
    end

    context("vague() should initialize a vague (almost uninformative) Gaussian distribution") do
        dist = vague(MvGaussianDistribution)
        @fact dist.m => [0.0]
        @fact dist.V => reshape([huge],1,1)

        dist = vague(MvGaussianDistribution, dim=2)
        @fact dist.m => zeros(2)
        @fact dist.V => huge*eye(2)
    end

    context("isProper() should indicate whether a Gaussian distribution is proper") do
        @fact isProper(MvGaussianDistribution()) => true
        @fact isProper(MvGaussianDistribution(m=[0.0], V= -1*eye(1))) => false
        @fact isProper(MvGaussianDistribution(m=[0.0], W= -1*eye(1))) => false
    end

    context("MvGaussianDistribution can be sampled") do
        @fact typeof(sample(MvGaussianDistribution(m=[1.2, 2.7], V=[2.0 -0.5; -0.5 1.5]))) => Array{Float64, 1}
    end

    context("Underdetermined MvGaussianDistribution should be detected by isWellDefined()") do
        @fact isWellDefined(MvGaussianDistribution()) => true
        @fact isWellDefined(MvGaussianDistribution(m=[0.0], V=eye(1))) => true
        @fact isWellDefined(MvGaussianDistribution(m=[0.0], W=eye(1))) => true
        @fact isWellDefined(MvGaussianDistribution(xi=[0.0], V=eye(1))) => true
        @fact isWellDefined(MvGaussianDistribution(xi=[0.0], W=eye(1))) => true
        @fact isWellDefined(MvGaussianDistribution(m=[0.0], xi=[0.0], W=eye(1), V=eye(1))) => true

        dist = MvGaussianDistribution(m=[0.0], V=eye(1))
        invalidate!(dist.m)
        @fact isWellDefined(dist) => false

        dist = MvGaussianDistribution(m=[0.0], V=eye(1))
        invalidate!(dist.V)
        @fact isWellDefined(dist) => false

        dist = MvGaussianDistribution(xi=[0.0], W=eye(1))
        invalidate!(dist.xi)
        @fact isWellDefined(dist) => false

        dist = MvGaussianDistribution(xi=[0.0], W=eye(1))
        invalidate!(dist.W)
        @fact isWellDefined(dist) => false

        dist = MvGaussianDistribution(m=[0.0], V=eye(1), W=eye(1))
        invalidate!(dist.m)
        @fact isWellDefined(dist) => false

        dist = MvGaussianDistribution(m=[0.0], xi=[0.0], V=eye(1))
        invalidate!(dist.V)
        @fact isWellDefined(dist) => false
    end
    context("Conversions between valid parametrizations of a MvGaussianDistribution should be consistent") do
        # Defined as (m,V)
        @fact isConsistent(ensureMWParametrization!(MvGaussianDistribution(m=[0.0], V=eye(1)))) => true
        @fact isConsistent(ensureXiVParametrization!(MvGaussianDistribution(m=[0.0], V=eye(1)))) => true
        @fact isConsistent(ensureXiWParametrization!(MvGaussianDistribution(m=[0.0], V=eye(1)))) => true
        # Defined as (m,W)
        @fact isConsistent(ensureMVParametrization!(MvGaussianDistribution(m=[0.0], W=eye(1)))) => true
        @fact isConsistent(ensureXiVParametrization!(MvGaussianDistribution(m=[0.0], W=eye(1)))) => true
        @fact isConsistent(ensureXiWParametrization!(MvGaussianDistribution(m=[0.0], W=eye(1)))) => true
        # Defined as (xi,V)
        @fact isConsistent(ensureMVParametrization!(MvGaussianDistribution(xi=[2.0], V=eye(1)))) => true
        @fact isConsistent(ensureMWParametrization!(MvGaussianDistribution(xi=[2.0], V=eye(1)))) => true
        @fact isConsistent(ensureXiWParametrization!(MvGaussianDistribution(xi=[2.0], V=eye(1)))) => true
        # Defined as (xi,W)
        @fact isConsistent(ensureMVParametrization!(MvGaussianDistribution(xi=[2.0], W=eye(1)))) => true
        @fact isConsistent(ensureMWParametrization!(MvGaussianDistribution(xi=[2.0], W=eye(1)))) => true
        @fact isConsistent(ensureXiVParametrization!(MvGaussianDistribution(xi=[2.0], W=eye(1)))) => true
    end
    context("mean(d), var(d), cov(d) should return correct results") do
        @fact mean(MvGaussianDistribution(m=[1.0, 2.0], V=eye(2))) => [1.0, 2.0]
        @fact mean(MvGaussianDistribution(xi=[1.0, 2.0], V=2.0*eye(2))) => [2.0, 4.0]
        @fact isValid(mean(MvGaussianDistribution(xi=[1.0, 2.0], V=-2.0*eye(2)))) => false
        @fact var(MvGaussianDistribution(m=[1.0, 2.0], V=diagm([2.0, 4.0]))) => [2.0, 4.0]
        @fact var(MvGaussianDistribution(m=[1.0, 2.0], W=diagm([2.0, 4.0]))) => [0.5, 0.25]
        @fact isValid(var(MvGaussianDistribution(m=[1.0, 2.0], W=diagm([-2.0, 4.0])))) => false
        @fact cov(MvGaussianDistribution(m=[1.0, 2.0], V=[2.0 1.0;1.0 2.0])) => [2.0 1.0;1.0 2.0]
        @fact cov(MvGaussianDistribution(m=[1.0, 2.0], W=[2.0 1.0;1.0 2.0])) => inv([2.0 1.0;1.0 2.0])
        @fact isValid(cov(MvGaussianDistribution(m=[1.0, 2.0], W=diagm([-2.0, 4.0])))) => false
    end
    context("Inconsistent overdetermined MvGaussianDistribution should be detected by isConsistent()") do
        @fact isConsistent(MvGaussianDistribution(m=[0.0], xi=[1.0], W=eye(1))) => false
        @fact isConsistent(MvGaussianDistribution(m=[0.0], V=eye(1), W=2*eye(1))) => false
        @fact isConsistent(MvGaussianDistribution(m=[0.0], xi=[1.0], V=eye(1), W=2*eye(1))) => false
    end
end

facts("Marginal calculations for the MvGaussian") do
    context("calculateMarginal!(edge) should give correct result and save the marginal to the edge") do
        initializePairOfTerminalNodes(MvGaussianDistribution(m=[0.0], V=eye(1)), MvGaussianDistribution(m=[0.0], V=eye(1)))
        edge = n(:t1).i[:out].edge
        n(:t1).i[:out].message = Message(MvGaussianDistribution(m=[0.0], V=eye(1)))
        n(:t2).i[:out].message = Message(MvGaussianDistribution(m=[0.0], V=eye(1)))
        marginal_dist = calculateMarginal!(edge)
        @fact edge.marginal => marginal_dist
        ensureMVParametrization!(marginal_dist)
        @fact edge.marginal.m => [0.0]
        @fact isApproxEqual(edge.marginal.V, reshape([0.5], 1, 1)) => true
    end

    context("calculateMarginal(forward_msg, backward_msg) should give correct result") do
        marginal_dist = calculateMarginal(
                                MvGaussianDistribution(m=[0.0], V=eye(1)),
                                MvGaussianDistribution(m=[0.0], V=eye(1)))
        ensureMVParametrization!(marginal_dist)
        @fact marginal_dist.m => [0.0]
        @fact isApproxEqual(marginal_dist.V, reshape([0.5], 1, 1)) => true
    end
end

facts("MvGaussianDistribution converts") do
    context("DeltaDistribution should be convertible to MvGaussianDistribution with tiny variance") do
        @fact convert(MvGaussianDistribution, MvDeltaDistribution([1.0, 2.0])) => MvGaussianDistribution(m=[1.0, 2.0], V=tiny*eye(2)) # Vector
    end

    context("Message{DeltaDistribution} should be convertible to Message{MvGaussianDistribution} with tiny variance") do
        @fact convert(Message{MvGaussianDistribution}, Message(MvDeltaDistribution([1.0, 2.0]))) => Message(MvGaussianDistribution(m=[1.0, 2.0], V=tiny*eye(2))) # Vector
    end

    context("GaussianDistribution should be convertible to MvGaussianDistribution") do
        @fact convert(MvGaussianDistribution, GaussianDistribution(m=1.0, V=2.0)) => MvGaussianDistribution(m=[1.0], V=2.0*eye(1))
    end

    context("MvGaussianDistribution should be convertible to GaussianDistribution") do
        @fact convert(GaussianDistribution, MvGaussianDistribution(m=[1.0], V=2.0*eye(1))) => GaussianDistribution(m=1.0, V=2.0)
        @fact_throws convert(GaussianDistribution, MvGaussianDistribution(m=ones(2), V=eye(2)))
    end
end