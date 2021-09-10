import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "./Types";

actor class ResolverNeuron(initial_owner: Principal) {

    type NeuronId = Nat64.Nat64;

    stable var owner = initial_owner;
    stable var persisted_data: [(Text, NeuronId)] = [];

    var data = HashMap.HashMap<Text, NeuronId>(0, Text.equal, Text.hash);

    public query func resolverType() : async Types.ResolverType {
        return #neuron_id;
    };

    public query func get(entry: Text) : async NeuronId {
        let dummy_val : Nat64 = 0;
        Option.get(data.get(entry), dummy_val)
    };

    public shared(msg) func set(entry: Text, neuron_id: NeuronId) : async Bool {
        // if (msg.caller == owner) {
            data.put(entry, neuron_id);
            return true;
        // };
        // false
    };

    system func preupgrade() {
        persisted_data := Iter.toArray(data.entries());
    };

    system func postupgrade() {
        data := HashMap.fromIter(persisted_data.vals(), persisted_data.size(), Text.equal, Text.hash);
        persisted_data := [];
    };

};
