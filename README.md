# PLT - Perl Logger Tool

## What it is?


This project is a logging library with some additional tweaks used for rapid development.

It was created out of pain with working in sharp environment without propper testing practices...

## What it does

- Multi-level messages logging to output, files
-- INFO, WARN, ERR, DEBUG, DRY, and its extensions e.g. INFO_IMPORTANT
- Exec code and deal with returned data & exit codes
- Dry runs (+ generating code if needed)
- Colorful (because it was pain to read single color

## What it should be
 
- Should be easily [bendable, shapable](https://www.youtube.com/watch?v=PSHo146tQjQ&t=41s) 
- Copy-pasting, 

## Install

```
curl TODO
```

## How to use it

TODO

## How to use it

all examples
```perl
/main.pl --print_args --print_config --print_status --exs_all
```


print arguments and configs
```perl
./main.pl --print_args --print_config --print_status
```

example_args
```perl
./main.pl --exs --example_args
```

example_cmd_exec
```perl
./main.pl --exs --example_cmd_exec
```


example_should_ex1
```perl
./main.pl --exs --example_should_ex1
```
```perl
./main.pl --exs --ex1
```

example_should_ex2
```perl
./main.pl --exs --example_should_ex2
```

example_block_spacing
```perl
./main.pl --exs --example_block_spacing --print_args --print_config
```

## History

I have created sketch of this tool when I was refactoring not mine and old scripts

