############################################
# EqualityNode
############################################
# Description:
#   Equality constraint node with variable
#   number of (symmetrical) interfaces (ports).
#   Example:
#       EqualityNode(name="3_port_equ") # 3 interfaces is default
#       EqualityNode(5; name="5_port_equ")
# Interface ids, (names) and supported message types:
#   1. (none):
#       GaussianMessage
#   2. (none):
#       GaussianMessage
#   3. (none):
#       GaussianMessage
#   ...
#   N. (none):
#       GaussianMessage
############################################

export EqualityNode

type EqualityNode <: Node
    num_interfaces::Uint16
    interfaces::Array{Interface,1}
    name::ASCIIString

    function EqualityNode(num_interfaces::Integer; args...)
        name = "#undef"
        for (key, val) in args
            if key==:name
                name=val
            end
        end
        @assert(num_interfaces>2, "An EqualityNode should have at least 3 interfaces")
        self = new(num_interfaces, Array(Interface, num_interfaces), name)
        # Create interfaces
        for interface_id=1:num_interfaces
            self.interfaces[interface_id] = Interface(self)
        end
        return self
    end
end
EqualityNode(; args...) = EqualityNode(3; args...)

############################################
# GaussianMessage methods
############################################

function calculateMessage!( outbound_interface_id::Int,
                            node::EqualityNode,
                            inbound_messages::Array{GaussianMessage,1})
    # The following update rules correspond to node 1 from Table 4.1 in:
    # Korl, Sascha. “A Factor Graph Approach to Signal Modelling, System Identification and Filtering.” Hartung-Gorre, 2005.
    # In this implementation, we calculate the (xi,W) parametrization of all incoming messages if it's not already present.
    # TODO: check if there is a more efficient implementation.

    # Create accumulators for W and xi of the correct size
    first_incoming_id = (outbound_interface_id==1) ? 2 : 1
    if !is(inbound_messages[first_incoming_id].W, nothing)
        W_sum = zeros(size(inbound_messages[first_incoming_id].W))
    else
        W_sum = zeros(size(inbound_messages[first_incoming_id].V))
    end
    if !is(inbound_messages[first_incoming_id].xi, nothing)
        xi_sum = zeros(size(inbound_messages[first_incoming_id].xi))
    else
        xi_sum = zeros(size(inbound_messages[first_incoming_id].m))
    end

    # Sum W and xi of all incoming messages
    for incoming_interface_id = 1:length(node.interfaces)
        if incoming_interface_id==outbound_interface_id
            continue
        end
        # Calculate (xi,W) parametrization if it's not available yet
        ensureXiWParametrization!(inbound_messages[incoming_interface_id])
        W_sum += inbound_messages[incoming_interface_id].W
        xi_sum += inbound_messages[incoming_interface_id].xi
    end

    return node.interfaces[outbound_interface_id].message = GaussianMessage(xi=xi_sum, W=W_sum)
end