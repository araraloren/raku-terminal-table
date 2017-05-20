
use Terminal::Table::String;
use Terminal::Table::Frame;
use Terminal::Table::Shader;

class VisitorHelper {
    has %.callback-map;

    method __check_callback_map($name) {
        unless %!callback-map{$name}:exists {
            %!callback-map{$name} = Array.new;
        }
    }

    method add-helper(Str $name, &callback) {
        self.__check_callback_map($name);
		%!callback-map{$name}.push(&callback);
    }

	method FALLBACK($name, |c) {
		for @(%!callback-map{$name}) -> &cb {
			if c ~~ &cb.signature {
                return &cb(|c);
            }
		}
        fail "Not wrapper named: $name with signature {c.perl}!";
	}
}

sub visitor-helper() returns VisitorHelper is export is rw {
    state $helper = VisitorHelper.new;

    $helper.add-helper("colour",
    sub ($s, Bool $coloured) {
        return do given $s.visibility {
            when Visibility::VSPACE {
                $s.to-space();
            }
            when Visibility::VFALSE {
                "";
            }
            default {
                $s.Str();
            }
        };
    });
    $helper.add-helper("colour",
    sub ($s, $row, Bool $coloured) {
        return do given $s.visibility {
            when Visibility::VSPACE {
                $s.to-space();
            }
            when Visibility::VFALSE {
                "";
            }
            default {
                if $s ~~ Line {
                    $s.get-line($row);
                } else {
                    -> ($pleft, String $s, $pright)  {
                        $pleft ~ (
                            ?$coloured && $s.coloured() ??
                            Shader.colour($s.Str(), $s.style()) !! $s.Str()
                        ) ~ $pright;
                    }($s.get-line($row));
                }
            }
        };
    });
    $helper.add-helper("h-frame",
    sub (@h-frame, Bool $coloured) {
        return gather for @h-frame -> $f {
            take &visitor-helper().colour($f, $coloured) unless
                $f.check-visibility(Visibility::VFALSE)
        };
    });
    $helper.add-helper("v-frame",
    sub (@v-frame, @contents, Bool $coloured){
        my @ret = [];
        if +@v-frame > 0 && +@contents > 0 {
            for ^@contents[0].height -> $row {
                @ret.push(
                    gather {
                        for (@v-frame Z, @contents).flat -> $f-or-c {
                            unless $f-or-c.check-visibility(Visibility::VFALSE) {
                                take &visitor-helper().colour($f-or-c, $row, $coloured);
                            }
                        }
                        unless @v-frame[* - 1].check-visibility(Visibility::VFALSE) {
                            take &visitor-helper().colour(@v-frame[* - 1], $row, $coloured);
                        }
                    }
                );
            }
        } elsif +@contents > 0 { #`( v-frame will be empty when style is none)
            for ^@contents[0].height -> $row {
                @ret.push(
                    gather {
                        for @contents -> $c {
                            unless $c.check-visibility(Visibility::VFALSE) {
                                take &visitor-helper().colour($c, $row, $coloured);
                            }
                        }
                    }
                );
            }
        }
        return @ret;
    });
    $helper.add-helper("generate",
    sub (@h-frame, @v-frame, @contents, Bool $coloured) {
        my @ret = [];
        if +@h-frame > 0 {
            @ret.push(gather for @h-frame -> $f {
                unless $f.check-visibility(Visibility::VFALSE) {
                    take &visitor-helper().colour($f, $coloured);
                }
            });
        }
        if +@contents > 0 {
            @ret.append(
                &visitor-helper().v-frame(@v-frame, @contents, $coloured)
            );
        }
        return @ret;
    });
    $helper;
}
