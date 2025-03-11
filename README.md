# cvcli: A Better Way to Copy and Paste in the Command Line  

> Project under development  

On GUI interfaces, there are many excellent clipboard enhancement tools like `Ditto` or the more commonly used Windows clipboard accessible via the `Windows + V` shortcut.  
However, in the command-line interface, we lack similarly convenient clipboard tools. When we want to persist our clipboard contents, the process becomes complicated. Sometimes, we want to save our clipboard contents without leaving the command line.  
**`cvcli` provides a key-value storage clipboard tool for the command line**, implemented in `Lua` and compiled into an executable using [`srlua`](https://github.com/LuaDist/srlua).  

---

## Installation  

### Using the Installation Script  

> The installation script is currently unavailable; manual installation is required for now.  

`cvcli` provides an installation script for one-click installation.  

- **Windows**:  
  - Download `cvcli-win64.zip` from the `release` section and extract it locally.  
  - Run `install.bat` as an administrator, then restart your device.  
  - By default, `cvcli` will be installed in the `C:\Program Files\cvcli` directory.  
  - If you wish to change the default installation directory, edit the target directory configuration in the `install.bat` file.  

> Currently, only `Windows` is supported.  

### Manual Installation  

- **Windows**:  
  - Download `cvcli-win64.zip` from the `release` section and extract it locally.  
  - Move the `cvcli.exe` file from the `program` folder to your desired installation directory.  
  - Add this directory to your system environment variable `PATH`, then restart your device.  

> For self-building: Run `build.bat` in the `build` folder. The project includes a pre-built `srlua` for Win64. For custom builds, visit the [srlua project page](https://github.com/LuaDist/srlua).  

---

## Getting Started  

`cvcli` uses key-value pairs for data storage, saved in `cvcli.yml` located in the same directory as the program.  
If you have installed `cvcli` correctly following the instructions, open the terminal and type `cvcli`. You should see the following:  

```cmd
C:\Users\linzh>cvcli  
[cvcli]
ver: 0.1
env: win
key(s): 0
lastkey: ---last--- 
```  

This output includes the following information:  

- **Version**: 0.1  
- **Environment**: Windows  
- **Number of stored keys**: 0  
- **Last used key**: ---last---  

During runtime, `cvcli` will check if `cvcli.yml` is functioning properly. If not, `cvcli` will display an error message:  

```cmd
C:\Users\linzh>cvcli  
[cvcli]
ver: 0.1
env: win
---YML ERR---
Input 'rebuild' to rebuild (WARN: all data will lost)>>>
```

Type `rebuild` to recreate `cvcli.yml`. Upon successful rebuild, you should see `---REBUILD SUCCESS---`.  

### First Usage Example  

Follow the steps below to try out your first example:  

```cmd
PS C:\Users\linzh> cvcli -w key1 value1
---WRITTEN IN `key1`---
PS C:\Users\linzh> cvcli key1
---`key1` COPIED TO CLIPBOARD---
PS C:\Users\linzh> cvcli -wv key2
---WRITTEN IN `key2`---
PS C:\Users\linzh> cvcli -l
---`key2` COPIED TO CLIPBOARD---
PS C:\Users\linzh> cvcli -mk "."
FOR key MATCHING: .
---3 RESULTS---
| KEY            |  VALUE |
| key1             |  value1 |
| ---last---       |  key2 |
| key2             |  value1 |
```

The above performs the following actions:  

1. Writes `value1` to the key `key1`.  
2. Reads the value of `key1` and copies it to the clipboard.  
3. Writes the current clipboard value (`value1`) to the key `key2`.  
4. Reads the previously used key (`key2`).  
5. Displays all stored keys.  

> Due to terminal limitations, non-ASCII characters may display incorrectly.  

---

## Commands  

### Write Operations  

The standard syntax for storing data in `cvcli` is:  

```bash
cvcli -w [k] [v]
```

- `[k]` is the key name.  
- `[v]` is the value.  

#### Key Naming Rules  

Keys in `cvcli` must follow these rules:  

1. **Cannot start with three consecutive `-`** (reserved by `cvcli`).  
2. **Cannot contain special characters**, such as spaces.  
3. **Cannot use the following reserved words:**  
   - `-w`, `-wv`, `-wl`, `-wvl`, `-wr`, `-wvlr`, `-l`, `-mk`, `-mv`, `-cc`, `-cr`.  
4. **Must not exceed 16 characters.**  

Keys must be unique. If a duplicate key is used, it will overwrite the previous value.  

#### Variants of Write Commands  

##### Standard Write  

To write a key-value pair:  

```bash  
cvcli -w hello "hello world!"
```  

This writes the value `"hello world!"` to the key `hello`.  

##### Write Clipboard Value  

To write the current clipboard content as the value:  

```bash  
cvcli -wv [k]
```  

Example:  

```bash
cvcli -wv p
```

This writes the current clipboard content to the key `p`.  

##### Write to Existing Keys Only  

To write a value to an existing key:  

```bash
cvcli -wr [k] [v]
```

Example:  

```bash
cvcli -wr hello "updated value"
```

This writes `"updated value"` to the key `hello`, but only if `hello` already exists.  

### Read Operations  

`cvcli` provides two ways to read data:  

1. **Read the value of a specific key:**  

   ```bash
   cvcli [k]
   ```

   Example:  

   ```bash
   cvcli hello
   ```

   This reads the value for the key `hello`.  

   **Note:** The value will automatically be copied to the system clipboard for easy pasting.  

2. **Read the value of the last used key:**  

   ```bash
   cvcli -l
   ```

   - `-l` stands for *last*.  
   - The value is also automatically copied to the system clipboard.  

### Delete Operations  

To delete a key and its value:  

```bash
cvcli -r [k]
```

Example:  

```bash
cvcli -r hello
```

This deletes the key `hello` and its value.  

### Search Operations  

`cvcli` supports searching keys or values using regular expressions:  

> To list all keys, use `"."` as the pattern, e.g., `cvcli -mk "."`.  

1. **Search keys:**  

   ```bash
   cvcli -mk [pattern]
   ```

   Example:  

   ```bash
   cvcli -mk "^h.*"
   ```

   This searches for all keys starting with `h`.  

2. **Search values:**  

   ```bash
   cvcli -mv [pattern]
   ```

   Example:  

   ```bash
   cvcli -mv "world"
   ```

   This searches for all values containing `world`.  

### Merge or Replace Files  

`cvcli` allows merging or replacing external `.yml` files with the current storage:  

1. **Merge Files:**  

   ```bash
   cvcli -cc [filename]
   ```

   - This combines the contents of `filename.yml` with the current storage.  
   - If a key conflict occurs, a conflict resolution prompt will appear.  

2. **Replace Files:**  

   ```bash
   cvcli -cr [filename]
   ```

   - This replaces the current storage with the contents of `filename.yml`.  
   - Triple confirmation is required to prevent accidental data loss.