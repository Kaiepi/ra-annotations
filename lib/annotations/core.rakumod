use v6.e.PREVIEW;
use annotations::containers;
use annotations::how;

my class ANN {
    method ^parameterize(Mu, Mu $target is raw) is raw {
        $target.^yield_annotations
    }
}

module annotations::core {
    OUR::<ANN> := ANN;

    #|[ Makes an eager STORE call to a package's ANN, allowing us to obtain
        references to new allocations rather than itself as a return value. ]
    our only infix:<annotate>(Mu $package is raw, +@values is raw) is looser<...> {
        ANN[$package].STORE: @values, :THROUGH
    }

    #|[ Makes a cached STORE call to a package's ANN, allowing us to obtain
        references to new allocations rather than itself as a return value. ]
    our only infix:<graffiti>(Mu $package is raw, +@values is raw) is looser<...> {
        ANN[$package].STORE: @values, :SEGMENT
    }
}

my package EXPORT {
    OUR::<DEFAULT> := annotations::core;
}
