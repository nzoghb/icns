import Hash "mo:base/Hash";
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
    stable var persisted_data: [(Hash.Hash, NeuronId)] = [];

    var data = HashMap.HashMap<Hash.Hash, NeuronId>(0, Hash.equal, Types.hashForHashes);

    public query func resolverType() : async Types.ResolverType {
        return #neuron_id;
    };

    public query func get(record_hash: Hash.Hash) : async NeuronId {
        let dummy_val : Nat64 = 0;
        Option.get(data.get(record_hash), dummy_val)
    };

    public shared(msg) func set(record_hash: Hash.Hash, neuron_id: NeuronId) : async Bool {
        if (msg.caller == owner) {
            data.put(record_hash, neuron_id);
            return true;
        };
        false
    };

    system func preupgrade() {
        persisted_data := Iter.toArray(data.entries());
    };

    system func postupgrade() {
        data := HashMap.fromIter(persisted_data.vals(), persisted_data.size(), Hash.equal, Types.hashForHashes);
        persisted_data := [];
    };

};
