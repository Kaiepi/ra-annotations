use v6.e.PREVIEW;
use annotations::containers;

#|[ Inherits from a HOW, exposing a binding of a Positional of sorts. ]
my role MetamodelX::AnnotationHOW[Positional ::C, ::H] is H {
    has @!annotations;

    submethod BUILD(::?ROLE:D:) {
        @!annotations := C.new;
    }

    method ANN(::?ROLE:D:) is raw {
        @!annotations
    }

    #|[ Returns a list associated with a metaobject. ]
    method yield_annotations(::?ROLE:D: Mu) is raw {
        self.ANN
    }
}

#|[ Inherits from a HOW, exposing a binding of an Associative of sorts. ]
my role MetamodelX::AnnotationHOW[Associative ::C, ::H] is H {
    has %!annotations;

    submethod BUILD(::?ROLE:D:) {
        %!annotations := C.new;
    }

    method ANN(::?ROLE:D:) is raw {
        %!annotations
    }

    #|[ Returns a hash associated with a metaobject. ]
    method yield_annotations(::?ROLE:D: Mu) is raw {
        self.ANN
    }
}

package annotations {
    OUR::<how> := MetamodelX::AnnotationHOW;
}

my package EXPORT {
    package DEFAULT {
        OUR::<MetamodelX> := MetamodelX;
    }
}
