import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

module {

    public type Record = {
        owner: Principal;
        resolver: Principal;
        expiry: Time.Time;
    };

    public type ResolverType = {
        #text;
        #neuron_id;
    };

    public type ResolverResponse = {
        #text : Text;
        #neuron_id : Nat64;
        #other : Blob;
    };

    public func hashForHashes(x: Hash.Hash) : Hash.Hash { x };

    public func recordHumanReadable(record: Record) : Text {
        var retval = "  {\n";
        retval #= "    owner: " # Principal.toText(record.owner) # "; ";
        retval #= "resolver: " # Principal.toText(record.resolver) # "; ";
        retval #= "expiry: " # Int.toText(record.expiry) # ";\n";
        retval #= "  }";
        retval
    };

};
