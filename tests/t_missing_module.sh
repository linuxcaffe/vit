# A missing Perl module gets a plain message naming it and how to install it, not Perl's @INC dump
source "$(dirname "$0")/lib.sh"
mkdir -p "$T/perl"
echo 'die "simulated: not installed\n";' > "$T/perl/Curses.pm"
out="$(PERL5LIB="$T/perl" "$VIT" --version 2>&1)"; rc=$?
check "exit 1 (got $rc)" test "$rc" = 1
check "names the module (got: $out)" grep -q 'Curses' <<<"$out"
check "names the Debian package" grep -q 'libcurses-perl' <<<"$out"
check "no @INC dump" bash -c "! grep -q '@INC' <<<\"\$1\"" _ "$out"
