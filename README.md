# cvcli: A Better Way to Copy and Paste in the Command Line  

> Project under development  

On GUI platforms, there are plenty of excellent clipboard enhancement tools, such as `Ditto` and the built-in Windows clipboard manager accessible via `Windows + V`.  
However, the command-line interface lacks similarly convenient clipboard tools. When we want to persistently store clipboard content, the process can be cumbersome.  
**`cvcli` provides a command-line clipboard key-value store tool**, implemented in `lua` and compiled into executable files for `Windows`, `Linux`, and `macOS` using `luastatic`.

---

## Installation  

> Future plans include supporting installation via `winget`, `yum`, and `apt`. For now, `cvcli` requires a manual installation process.

### Using the Installation Script  

`cvcli` provides an installation script for one-click setup.  

- **Windows**:  
  - Download `cvcli-win64.zip` from the `release` page and extract it locally.  
  - Run `install.bat` as an administrator.  
  - By default, `cvcli` will be installed in the `C:\Program Files\cvcli` directory.  
  - To change the default installation path, edit the target directory configuration in `install.bat`.  

> Currently, only `Windows` is supported.  

### Manual Installation  

- **Windows**:  
  - Download `cvcli-win64.zip` from the `release` page and extract it locally.  
  - Move the `cvcli.exe` and `cvcli.yml` files from the `program` folder to your desired installation directory.  
  - Add this directory to the system `PATH` environment variable.  

- **Linux/macOS**:  
  - Download the corresponding platform's compressed package from the `release` page and extract it.  
  - Add the executable file to the system path (e.g., `/usr/local/bin`).  
  - Ensure the file has executable permissions (`chmod +x cvcli`).  

---

## Getting Started  

`cvcli` stores data as key-value pairs, saved in the `cvcli.yml` file located in the program's directory.  
If you’ve followed the installation instructions correctly, open your terminal and type `cvcli`. You should see something like this:  

```cmd
C:\Users\linzh>cvcli  
[cvcli]
ver: 0.1
env: win
key(s): 0
lastkey: ---last--- 
```  

This output contains the following information:  

- **Version**: 0.1  
- **Environment**: Windows  
- **Number of stored keys**: 0  
- **Last used key**: ---last---  

During execution, `cvcli` will check if `cvcli.yml` is functioning properly. If not, it will display an error message:  

```cmd
C:\Users\linzh>cvcli  
[cvcli]
ver: 0.1
env: win
---YML ERR---
Input 'rebuild' to rebuild (WARN: all data will lost)>>>
```

Enter `rebuild` to reconstruct `cvcli.yml`. Upon successful reconstruction, you should see `---REBUILD SUCCESS---`.

---

## Features and Commands  

### Write Operations  

The standard syntax for storing data in `cvcli` is as follows:

```bash
cvcli -w [k] [v]
```

- `[k]` is the key.  
- `[v]` is the value.  

#### Key Naming Rules  

Keys in `cvcli` must follow these rules:  

1. **Cannot start with three consecutive `-`** (this is reserved by `cvcli`).  
2. **Cannot contain special characters**, such as spaces.  
3. **Cannot use any of the following reserved keywords:**  
   - `-w`, `-wv`, `-wl`, `-wvl`, `-wr`, `-wvlr`, `-l`, `-mk`, `-mv`, `-cc`, `-cr`  
4. **Must not exceed 16 characters.**  

Keys must be unique. If a key is reused, its previous value will be overwritten.  

#### Variants of the Write Command  

##### Standard Write  

The following example demonstrates how to write a key-value pair:

```bash  
cvcli -w hello "hello world!"
```  

This writes the value `"hello world!"` to the key `hello`.

##### Write Clipboard Content as the Value  

Insert the current clipboard content as the value:

```bash  
cvcli -wv [k]
```  

Example:

```bash
cvcli -wv p
```

This writes the current clipboard content to the key `p`.

##### Restrict Writing to Existing Keys  

Write a value to an existing key only:

```bash
cvcli -wr [k] [v]
```

Example:

```bash
cvcli -wr hello "updated value"
```

This writes `"updated value"` to the key `hello` only if the key already exists.

### Read Operations  

`cvcli` provides two ways to retrieve stored data:

1. **Read the value of a specific key:**

   ```bash
   cvcli [k]
   ```

   Example:

   ```bash
   cvcli hello
   ```

   This retrieves the value associated with the key `hello`.

   **Note:**
   - Retrieved values are automatically copied to the system clipboard for easy pasting.

2. **Read the value of the last used key:**

   ```bash
   cvcli -l
   ```

   - `-l` stands for *last* and retrieves the value of the last used key.  
   - Like specific key reads, the value is copied to the clipboard.  

### Delete Operations  

To delete a specific key and its value:

```bash
cvcli -r [k]
```

Example:

```bash
cvcli -r hello
```

This deletes the key `hello` and its associated value.

### Search Operations  

`cvcli` supports regular expression-based searches for keys or values:

1. **Search for keys:**

   ```bash
   cvcli -mk [pattern]
   ```

   Example:

   ```bash
   cvcli -mk "^h.*"
   ```

   This searches for all keys that start with `h`.

2. **Search for values:**

   ```bash
   cvcli -mv [pattern]
   ```

   Example:

   ```bash
   cvcli -mv "world"
   ```

   This searches for entries where the value contains `world`.

### Merge or Replace Files  

`cvcli` allows you to merge or replace the current storage with an external `.yml` file:

1. **Merge Files:**

   ```bash
   cvcli -cc [filename]
   ```

   - `-cc` stands for *copy and combine*. It merges the content of the specified `filename.yml` with the existing storage.  
   - If duplicate keys exist, a conflict resolution prompt will appear.  

2. **Replace Files:**

   ```bash
   cvcli -cr [filename]
   ```

   - `-cr` stands for *copy and replace*. It replaces the current storage with the content of the specified `filename.yml`.  
   - To prevent accidental data loss, this operation requires three confirmations.