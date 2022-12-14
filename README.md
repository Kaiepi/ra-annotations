![Build Status](https://github.com/Kaiepi/ra-annotations/actions/workflows/test.yml/badge.svg)

NAME
====

annotations - Thread-safe static buffer

SYNOPSIS
========

```raku
use v6.e.PREVIEW;

my constant LATIN = 'a'..'z';

module Upper {
    use annotations <declare symbolic class>;
    # We may now declare a class with a symbolic object buffer associated with
    # it. This can be retrieved by parameterizing ANN with our type object,
    # which is typically knowable at compile-time.

    role Alphabet[@LOOKUP is raw] is repr<Uninstantiable> {
        # The annotated operator makes some allocations in an annotation's ANN
        # buffer eagerly given some Str-coercive objects. These become IntStr:D
        # symbols, which is to say they're a name and a position in the buffer
        # for this mixin. Because we take care of this immediately, this can
        # act as our compile-time check for whether or not we really are
        # composing an annotation. Such allocating in ANN is thread-safe.
        my @SYMBOLS := $?CLASS annotate @LOOKUP;

        # The bare slots can be fetched by ANN's list method given these
        # symbols. Because these carry containers regardless of whether or not
        # a value is being stored, this can always be assigned to dynamically.
        method alphabet(::?CLASS: --> List:D) {
            ANN[$?CLASS].list: :of(@SYMBOLS)
        }

        # Likewise, these symbols can form the keys of a map by the ANN's hash
        # method.
        method dictionary(::?CLASS: --> Map:D) {
            ANN[$?CLASS].hash: :of(@SYMBOLS)
        }

        # This will find a letter given the key of a booked symbol.
        method translate(::?CLASS: Str:D --> Str) { ... }
    }

    annotation Half does Alphabet[LATIN] is repr<Uninstantiable> {
        CHECK $?CLASS.alphabet = 'A'..'Z';

        my %DICTIONARY := $?CLASS.dictionary;

        method translate(::?CLASS: Str:D $letter --> Str) {
            %DICTIONARY.AT-KEY: $letter
        }
    }

    annotation Full does Alphabet[LATIN] is repr<Uninstantiable> {
        CHECK $?CLASS.alphabet = '???'..'???';

        my %DICTIONARY := $?CLASS.dictionary;

        method translate(::?CLASS: Str:D $letter --> Str) {
            %DICTIONARY.AT-KEY: $letter
        }
    }
}

# Despite the inner alphabet list being static, public, mutable state by
# technicality, its inner Binder slots each only respects its first assignment.
put Upper::Full.alphabet = Upper::Half.alphabet; # OUTPUT:
# ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ???
put Upper::Full.translate: 'a'; # OUTPUT:
# ???

# But because we can achieve all this with static input alone, we can write a
# cheaper annotation.
module LowerPsychUpper {
    use annotations <declare direct class>;
    # Now the ANN buffer is purely a buffer. Direct annotations' ANN buffer is
    # a lower level construct compared to before; because we get references
    # over symbols, we generally need to track any value bound ourselves.

    annotation Full is repr<Uninstantiable> {
        # Note the RW array this time around.
        my constant @ALPHABET = $?CLASS annotate ['???'..'???'];

        my constant %DICTIONARY = Map.new: LATIN Z=> @ALPHABET;

        method alphabet(::?CLASS: --> List:D) {
            @ALPHABET
        }

        method dictionary(::?CLASS: --> Map:D) {
            %DICTIONARY
        }

        method translate(::?CLASS: Str:D $letter --> Str) {
            %DICTIONARY{$letter}
        }
    }
}

# Unlike before, the RW containers provided by the RW array we annotated are
# preserved, so an assignment will carry through.
put LowerPsychUpper::Full.alphabet = Upper::Full.alphabet; # OUTPUT:
# ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ??? ???
put LowerPsychUpper::Full.translate: 'z'; # OUTPUT:
# ???

# In this example, we have code resembling what's possible to write with OUR.
# Unlike a Stash in a WHO or a PseudoStash, ANN errs more toward order and
# immutability, but deconts of a Scalar are cheaper than those of a wrapper
# Proxy. An OUR-scoped value skips a call we need otherwise on top of this, and
# would thus be more efficient if the WHO Stash's inherent mutability is OK.
```

DESCRIPTION
===========

`annotations` is a collection of containers in a package trench coat. Through `MetamodelX::AnnotationHOW`, a `Positional` or `Associative` container may be associated with any kind of type, regardless of whether or not it actually can support stashing. These can be retrieved with `ANN`, and appended to via the infix `=`, `annotate`, and `graffiti` operators (see `t/02-direct.t` for an example of `graffiti`).

Importing `annotations` can either create an `annotation` declarator with `<declare>` or override another (e.g. `<role>`) with `<supersede>` (though this produces an erroneous deprecation warning as of v2020.07). As demonstrated, the `<direct>` and `<symbolic>` arguments determine the mode of assignment to a package's `ANN`. Finally, a package declarator must be provided in order to retrieve its HOW.

AUTHOR
======

Ben Davies (Kaiepi)

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Ben Davies

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

