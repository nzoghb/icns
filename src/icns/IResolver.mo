import Types "./Types.mo";

actor {

    public query func resolverType() : async Types.ResolverType {
        return #text;
    };

};
