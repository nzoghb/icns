import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "./Types";

actor class ResolverText(initial_owner: Principal) {

    stable var owner = initial_owner;
    stable var persisted_data: [(Text, Text)] = [];

    var data = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);

    public query func resolverType() : async Types.ResolverType {
        return #text;
    };

    public query func get(entry: Text) : async Text {
        Option.get(data.get(entry), "")
    };

    public shared(msg) func set(entry: Text, text: Text) : async Bool {
        if (msg.caller == owner) {
            data.put(entry, text);
            return true;
        };
        false
    };

    system func preupgrade() {
        persisted_data := Iter.toArray(data.entries());
    };

    system func postupgrade() {
        data := HashMap.fromIter(persisted_data.vals(), persisted_data.size(), Text.equal, Text.hash);
        persisted_data := [];
    };

};
