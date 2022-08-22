use v6.e.PREVIEW;
use annotations::containers;

my role MetamodelX::AnnotationHOW[Positional ::C, ::H] is H {
    has @!annotations;

    submethod BUILD(::?ROLE:D:) {
        @!annotations := C.new;
    }

    method yield_annotations(::?ROLE:D: Mu) is raw {
        @!annotations
    }
}

my role MetamodelX::AnnotationHOW[Associative ::C, ::H] is H {
    has %!annotations;

    submethod BUILD(::?ROLE:D:) {
        %!annotations := C.new;
    }

    method yield_annotations(::?ROLE:D: Mu) is raw {
        %!annotations
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
