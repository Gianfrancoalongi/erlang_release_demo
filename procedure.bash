#!/bin/bash

main()
{
    write_rel_file
    compile-applications
    make-boot-script
    test-startup-with-boot-file
    make-release
    cleanup
    show-tar-file
}

write_rel_file()
{
cat > proj.rel <<EOF
{release, 
  {"project","1.0"},
  {erts,"5.10.4.1"},
  [{kernel,"2.16.4.1"},
   {stdlib,"1.19.4"},
   {sasl,"2.3.4"},
   {one,"1.0"},
   {two,"1.0"}]
}.
EOF
}

compile-applications ()
{
    (cd app-one && rebar compile)
    (cd app-two && rebar compile)
}

make-boot-script()
{
     erl -eval 'systools:make_script("proj",[{path,["app-*/ebin/"]},local]).' \
	 -eval 'init:stop().'
}

test-startup-with-boot-file() 
{
    erl -boot proj \
	-eval 'io:format("~p~n",[[element(1,X) || X <- application:which_applications()] -- [sasl,stdlib,kernel]]).' \
        -eval 'init:stop().' &> boot.log
    grep -q '\[two,one\]' ./boot.log
    [[ $? != 0 ]] && echo boot test failed && exit 1
}

make-release() 
{
     erl -eval 'systools:make_tar("proj",[{path,["app-*/ebin/"]}]).' \
	 -eval 'init:stop().'    
}

cleanup()
{
    (cd app-one && rebar clean)
    (cd app-two && rebar clean)
    rm -f proj.{boot,script,rel}
}

show-tar-file()
{
    file proj.tar.gz
    ls -al proj.tar.gz
}

main

