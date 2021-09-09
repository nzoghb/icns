import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "./Types";

actor class ResolverText(initial_owner: Principal) {

    stable var owner = initial_owner;
    stable var persisted_data: [(Hash.Hash, Text.Text)] = [];

    var data = HashMap.HashMap<Hash.Hash, Text.Text>(0, Hash.equal, Types.hashForHashes);

    public query func resolverType() : async Types.ResolverType {
        return #text;
    };

    public query func get(record_hash: Hash.Hash) : async Text {
        Option.get(data.get(record_hash), "")
    };

    public shared(msg) func set(record_hash: Hash.Hash, text: Text) : async Bool {
        if (msg.caller == owner) {
            data.put(record_hash, text);
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
