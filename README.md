dirsplitter
===========

Small script to split a directory containing many files into many subdirectories containing fewer files


Usage:

```bash
    dirsplit --num 254 --mode alpha source dest
```

Copies all files from directory `source` into subdirectories based on characters of the alphabet (that's the `alpha` mode). The subdirectories are created underneath `dest`.
