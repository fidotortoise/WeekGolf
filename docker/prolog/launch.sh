#!/bin/sh
# this script is to be run from a docker image
countNbTest=$1
cd /home/weekgolf/
cp /mnt/in/prog.prolog prog.pl
set +e # support errors

# Added some stuff to extract data from prolog interpreter.
# We open the 'bla' file to write standard output.
# We open the 'blaerr' file to write standard error.
# We add a trailing "=-=-=-=-=-..." pattern
# to remove the variable number of extra lines generated
# by the interpreter that we want to separate from user data.
cat <<EOF > base.txt
[prog].
open(bla,write,Out,[alias(custom_out)]), 
open(blaerr,write,Output,[alias(custom_error)]),
set_prolog_IO(user_input, custom_out, custom_error),
main,
writeln("=-=-=-=-=-=-=-=-=-=-=-=-=-="),
writeln("=-=-=-=-=-=-=-=-=-=-=-=-=-="),
writeln("=-=-=-=-=-=-=-=-=-=-=-=-=-="),
writeln("=-=-=-=-=-=-=-=-=-=-=-=-=-="),
writeln("=-=-=-=-=-=-=-=-=-=-=-=-=-="),
writeln("=-=-=-=-=-=-=-=-=-=-=-=-=-="),
writeln("=-=-=-=-=-=-=-=-=-=-=-=-=-="),
writeln("=-=-=-=-=-=-=-=-=-=-=-=-=-="),
writeln("=-=-=-=-=-=-=-=-=-=-=-=-=-="),
writeln("=-=-=-=-=-=-=-=-=-=-=-=-=-=").
EOF
for testcount in `seq 0 1 $countNbTest`
do
    cp base.txt foo
    # add the user source code to foo:
    cat /mnt/in/input$testcount.txt >> foo
    # execute the whole bunch
    /home/weekgolf/prolog/bin/swipl < foo 2> /dev/null
    # store error code
    echo $? > /mnt/out/errcode$testcount.txt
    # removes an error that shows up
    sed -z "s/ERROR. Type error. .character_code. expected. found ..1. (an integer)\nERROR. In.\nERROR.   .11. char_code([_0-9]*..1)\nERROR.   .10. ..in_reply.(.1...h.) at \/home\/weekgolf\/prolog\/lib\/swipl\/boot\/init.pl.*$//" blaerr > blaerr2 2> /dev/null
    # remove trailing 'halt' display and put blaerr2 in the right location
    cat blaerr2 | grep -v '^\%\ halt$' > /mnt/out/err$testcount.txt
    # remove the first 4 lines (generated by the interpreter, but sometimes
    # it is less), remove padding pattern ('grep -v ...')  and put the
    # remaining stdout from user in the right file
    cat bla | head -n -4 | grep -v "=-=-=-=-=-=-=-=-=-=-=-=-=-=" \
        > /mnt/out/out$testcount.txt
done
