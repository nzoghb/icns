import Types "./Types.mo";

/// A general-purpose inteface for resolvers.
actor {

    public query func resolverType() : async Types.ResolverType {
        return #text;
    };

};
