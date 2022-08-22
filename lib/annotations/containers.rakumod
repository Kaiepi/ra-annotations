use v6.e.PREVIEW;

my class DEALLOC is Nil is repr<Uninstantiable> {
    method Str { self.Mu::Str }

    method gist { self.Mu::gist }

    method raku { self.Mu::raku }
}

my class REALLOC is Nil is repr<Uninstantiable> {
    method Str { self.Mu::Str }

    method gist { self.Mu::gist }

    method raku { self.Mu::raku }
}

my class Binder is Proxy {
    has $!value is default(DEALLOC);
    has $!guard is default(False);

    method new is raw {
        callwith :&FETCH, :&STORE
    }

    #|[ Makes a raw STORE call without deconting the topic. ]
    method BIND(Mu \SELF: Mu $topic is raw --> Nil) {
        STORE SELF, $topic
    }
    #=[ Call me on VAR please! ]

    my method FETCH is raw {
        $!value
    }

    my method STORE(Mu $topic is raw --> Nil) {
        use nqp;
        # If $!value is a RW container, check if $!guard has already been
        # toggled. The first call to STORE binds; any that follow assign, but
        # only when possible to do so because of any container provided then.
        nqp::if(
          nqp::isrwcont($!value),
          nqp::cas($!guard, False, True)
            ?? ($!value = $topic)
            !! ($!value := $topic))
    }
}

my class Buffer does Positional {
    has @!buffer is default(REALLOC);
    has $!allocs = Lock.new;
    has $!cursor is default(0);

    #|[ Allocates a number of slots via lazily reified sequence. ]
    method ALLOC(::?CLASS:D: Mu $values --> Seq:D) {
        gather do {
            my $binder := Binder.new;
            ENTER { $!allocs.lock }
            KEEP  { $!allocs.unlock; take-rw $binder }
            CATCH { default { $!allocs.unlock; $_.resume } }
            my $offset = ⚛$!cursor;
            @!buffer.BIND-POS: $offset, $binder;
            $!cursor ⚛= $offset + 1;
        } xx $values
    }

    #|[ Binds each values to a new slot for each allocation as it reifies. ]
    method STAMP(::?CLASS:D: +@values is raw --> Seq:D) {
        gather for @values -> Mu $bindee is raw {
            my $binder := Binder.new;
            $binder.VAR.BIND: $bindee;
            ENTER { $!allocs.lock }
            KEEP  { $!allocs.unlock; take-rw $binder }
            CATCH { default { $!allocs.unlock; $_.resume } }
            my $offset = ⚛$!cursor;
            @!buffer.BIND-POS: $offset, $binder;
            $!cursor ⚛= $offset + 1;
        }
    }

    #|[ Given an array of assignable containers, lazily allocates slots for
        each of them, forwarding offsets via intermediate assignments to their
        corresponding containers along the way. ]
    method POINT(::?CLASS:D: +@bridge is raw --> Seq:D) {
        gather for @bridge -> Mu $bridge is raw {
            my $binder := Binder.new;
            ENTER { $!allocs.lock }
            KEEP  { $!allocs.unlock; take $binder }
            CATCH { default { $!allocs.unlock; $_.resume } }
            $!allocs.lock;
            my $offset = ⚛$!cursor;
            @!buffer.BIND-POS: $offset, $binder = $bridge = $offset;
            $!cursor ⚛= $offset + 1;
        }
    }
    #=[ The combination of a store operation given an offset and a fetch
        operation while storing it in its slot allows for injections of new
        values to be made with a Proxy, e.g. symbols. Otherwise, this can be
        used as an ALLOC that records offsets of values to an empty array. ]

    #|[ If the SEGMENT adverb is given, caches the given sequence; if the
        THROUGH adverb is given, protects an eager evaluation of the given
        sequence; otherwise, sinks the given sequence, returning this buffer. ]
    method YIELD(::?CLASS:D: Sequence:D $store, *%adverbs --> Positional:D) {
        %adverbs<SEGMENT>
          ?? $store.cache
          !! %adverbs<THROUGH>
            ?? $!allocs.protect(-> { $store.eager })
            !! $!allocs.protect(-> { $store.sink // self })
    }

    #|[ YIELDs bindings of the topic to newly allocated slots. ]
    method STORE(::?CLASS:D: +@topic is raw, *%adverbs --> Positional:D) {
        self.YIELD: self.STAMP(@topic), |%adverbs
    }

    method elems(::?CLASS:D: --> Int:D) {
        ⚛$!cursor
    }

    method EXISTS-POS(::?CLASS:D: Int:D $pos --> Bool:D) {
        0 <= $pos < ⚛$!cursor
    }

    method AT-POS(::?CLASS:D: Int:D $pos) is raw {
        if 0 <= $pos < ⚛$!cursor {
            @!buffer.AT-POS: $pos
        } else {
            REALLOC
        }
    }

    method BIND-POS(::?CLASS:D: Int:D $pos, Mu $value is raw) is raw {
        if 0 <= $pos < ⚛$!cursor {
            my $binder := @!buffer.AT-POS: $pos;
            $binder.VAR.BIND: $value;
            $binder
        } else {
            REALLOC
        }
    }

    method ASSIGN-POS(::?CLASS:D: Int:D $pos, Mu $value) is raw {
        if 0 <= $pos < ⚛$!cursor {
            @!buffer.ASSIGN-POS: $pos, $value
        } else {
            REALLOC
        }
    }

    method list(::?CLASS:D: --> List:D) {
        @!buffer[^⚛$!cursor]
    }

    method Seq(::?CLASS:D: --> Seq:D) {
        @!buffer.head: ⚛$!cursor
    }
}

my class Keeper is Buffer {
    has @!idents is Buffer;

    only infix:<snd>(Mu \a, Mu \b) { # Intentionally reconts as readonly.
        b
    }

    only IDENT(Str(Mu) $key) is raw {
        my $symbol := IntStr;
        only FETCH(Mu) is raw { $symbol }
        only STORE(Mu, Mu $value is raw --> Nil) { $symbol := IntStr.new: $value, $key }
        Proxy.new: :&FETCH, :&STORE
    }

    #|[ YIELDs newly allocated slots mapped to symbols. ]
    method STORE(::?CLASS:D: +@topic is raw, *%adverbs --> Positional:D) {
        self.YIELD: (self.ALLOC(*) Z[snd] @!idents.POINT(@topic.map: &IDENT)), |%adverbs
    }

    method list(::?CLASS:D: :@of is raw = @!idents.Seq --> List:D) {
        self[@of]
    }

    method hash(::?CLASS:D: :@of is raw = @!idents.Seq --> Map:D) {
        Map.new: reverse @of Z=> self.Seq
    }
}

module annotations::containers {
    OUR::<DEALLOC> := DEALLOC;
    OUR::<REALLOC> := REALLOC;
    OUR::<Binder>  := Binder;
    OUR::<Buffer>  := Buffer;
    OUR::<Keeper>  := Keeper;
}

my package EXPORT {
    OUR::<DEFAULT> := annotations::containers;
}
