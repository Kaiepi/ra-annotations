use v6.e.PREVIEW;

module annotations:ver<0.0.1>:auth<zef:kaiepi>:api<0> {
    use annotations::containers;
    use annotations::how;
    use annotations::core;
}

my package EXPORT {
    package MANDATORY {
        OUR.WHO.BIND-KEY: .key, .value
            for annotations::core::;
        OUR.WHO.BIND-KEY: .key, .value
            for annotations::containers::;
    }
}

my enum Mode (:DECLARE<declare>, :SUPERSEDE<supersede>);
my enum Kind (:DIRECT<direct>, :SYMBOLIC<symbolic>);
my subset Package of Str:D where { $*LANG andthen .know_how: $^how };

my package EXPORTHOW { } # Spooky vanishing dummy.
my constant D = anon package EXPORTHOW { package DECLARE { } }
my constant S = anon package EXPORTHOW { package SUPERSEDE { } }

my constant EMPTY = Map.new;

proto EXPORT(+ --> Map:D) {*}
multi EXPORT(+ [Mode(Str:D) $mode, Kind(Str:D) $kind, Package $package]) {
    samewith $mode, $kind, $package
}
multi EXPORT(DECLARE, DIRECT, Str:D $package --> EMPTY) {
    LEXICAL::<EXPORTHOW>     := D;
    D::DECLARE::<annotation> := annotations::how[annotations::containers::Buffer, $*LANG.how: $package];
}
multi EXPORT(DECLARE, SYMBOLIC, Str:D $package --> EMPTY) {
    LEXICAL::<EXPORTHOW>     := D;
    D::DECLARE::<annotation> := annotations::how[annotations::containers::Keeper, $*LANG.how: $package];
}
multi EXPORT(SUPERSEDE, DIRECT, Str:D $package --> EMPTY) {
    LEXICAL::<EXPORTHOW>     := S;
    S::SUPERSEDE::{$package} := annotations::how[annotations::containers::Buffer, $*LANG.how: $package];
}
multi EXPORT(SUPERSEDE, SYMBOLIC, Str:D $package --> EMPTY) {
    LEXICAL::<EXPORTHOW>     := S;
    S::SUPERSEDE::{$package} := annotations::how[annotations::containers::Keeper, $*LANG.how: $package];
}
