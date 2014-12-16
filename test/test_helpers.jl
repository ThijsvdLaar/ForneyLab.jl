#####################
# Unit tests
#####################

facts("Helper function unit tests") do
    context("ensureMatrix should convert an array with one element to a matrix type") do
        @fact typeof(ForneyLab.ensureMatrix([1.0])) => Array{Float64, 2} # Cast 1D to 2D array
        @fact ForneyLab.ensureMatrix([1.0]) => reshape([1.0], 1, 1)
        @fact ForneyLab.ensureMatrix(eye(2)) => eye(2)
    end

    context("isApproxEqual should work for scalars, vectors and matrices") do
        @fact isApproxEqual(1.0, 1.0+1e-15) => true
        @fact isApproxEqual(1.0, 1.0+1e-9) => false
        @fact isApproxEqual([1.0, 1.0], [1.0, 1.0]+1e-15) => true
        @fact isApproxEqual([1.0, 1.0], [1.0, 1.0]+1e-9) => false
        @fact isApproxEqual(eye(3,3), eye(3,3)+1e-15) => true
        @fact isApproxEqual(eye(3,3), eye(3,3)+1e-9) => false
    end

    context("getOrCreateMessage should assign a message to an interface if there is none or of non-matching type, and otherwise set a standard message") do
        node = TerminalNode(GaussianDistribution())
        @fact node.out.message => nothing
        ForneyLab.getOrCreateMessage(node.out, GaussianDistribution)
        @fact typeof(node.out.message) => Message{GaussianDistribution}
        node2 = TerminalNode(DeltaDistribution(2.0))
        @fact node2.out.message => nothing
        ForneyLab.getOrCreateMessage(node2.out, DeltaDistribution{Float64})
        @fact typeof(node2.out.message.payload) <: DeltaDistribution => true
        ForneyLab.updateNodeMessage!(node2, 1, nothing)
        @fact mean(ForneyLab.getOrCreateMessage(node2.out, DeltaDistribution{Float64}).payload) => 2.0
    end
end