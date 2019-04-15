                 _                     _ 
      /\  /\__ _| |_   _  __ _ _ __ __| |
     / /_/ / _` | | | | |/ _` | '__/ _` |
    / __  / (_| | | |_| | (_| | | | (_| |
    \/ /_/ \__,_|_|\__, |\__,_|_|  \__,_|
                   |___/    
             ____________________        
             Virtualized Memcheck 



## Install

```bash
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/parkerduckworth/halyard/master/install)"
```
- If you do not have permission to write to /usr/local/, you may need to run with sudo
- Ensure /usr/local/bin is included in $PATH

## Usage

1. Load files into container (I want to rename this dir to something better)
```
$ halyard load <file(s) or directory>
```

2. Run it
```
$ halyard run
```

3. Make sure container is clean before testing a different set of programs
```
$ halyard clean
```

4. You can see the current contents of the container at any time
```
$ halyard peek
```

> After editing program source files, you will need to reload the files into container. By default, you will be prompted to overwrite the preexisting files.  To select yes to all:

```
$ halyard load -y <file(s) / directory>
